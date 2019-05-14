---
layout:     post
title:      Serverless authentication
date:       2019-05-08 13:42:23
summary:    A blog post how to setup serverless authentication using AWS CloudFront, AWS Lambda and Auth0
categories: serverless
thumbnail:  shield
tags:
  - serverless
  - security
  - authentication
  - aws
---

### Securing a static website

![security](https://marketplace.canva.com/MAC4Wd8rv5s/1/screen/canva-privacy-policy%2C-it%2C-computer%2C-security%2C-password-MAC4Wd8rv5s.jpg)

Most (frontend) developers at some point create a webpage that has to be secured with credentials.

But when you've built your webapp as a static website, you're probably hosting it on something like Amazon S3, Netlify or Github Pages against extremely low cost. Securing a static website normally means you'll need a server which handles the user session or validates a token that the client sends in the headers of its requests.

The problem with this is that a solution with a running server is less resilient, costly and less scalable. You were probably hosting it on a serverless platform for a reason right?

Let's see if we can find a cheap, but extremely scalable solution to fix our problem!

### Amazon Cloudfront signed cookies

We need a static content delivery service which can do some form of verification on requests.
Amazon Cloudfront is the Content Delivery Network (CDN) service that Amazon offers. It's directly connected to S3, but also to other Amazon services such as AWS Shield for DDoS mitigation.

One of the Cloudfront features is verification of signed cookies. This means that requests that do not contain a cookie are denied, which is exactly what we want! In order to get such a signed cookie someone or something has to generate it for you.

We would like to have a signed cookie per user so we can allow or deny access to individual users. This means we need to find a way to identify individual users.

### Authentication and Authorization

If we're going to secure our website or at least parts of our website, we need to be able to validate that a user is who he claims he is (authentication) and he should only be able to see the content we want him to see (authorization). There are some great services you can start using who do exactly this.

A few examples are Auth0, Okta and OneLogin. All of them have a free tier or cheap low usage plan.

Since I was already using Auth0 for another project I'll stick with Auth0 for this article.
Auth0 allows you to create your own users in their database or link to a public Identity Provider such as Facebook or Google.

If the Role Based Access (RBAC) model suits your case you can simply add roles to your individual users from within the Auth0 console. Of course there's also other (more automated) ways of doing this, but for our simple example this solution will do.

### Auth0 and Cloudfront

Auth0 provides an authenticated user with a JSON Web Token (JWT) while Cloudfront needs a signed cookie to allow requests to secured content. We need some way to turn a JWT token into a signed cookie.

We have a requirement to execute some business logic (convert JWT token) and we need a way to return the result (signed cookie) to the client. AWS Lambda is perfectly fit for this, it lets you run code without provisioning or managing servers.
Together with API Gateway you can build a serverless API which is resilient, cheap and scalable.

![auth-architecture](/images/auth-architecture.png)

### What is the flow for the user?

I want my users to go through the following flow in order to view my secured page:

1. Visit the main (unsecured) page, this can be the root of the page or some other section.
2. When the user navigates to a secured section the server sends back a 401 Unauthorized with an automated redirect to Auth0.
3. The user logs in to Auth0 with his own credentials and is redirected back to the website.
4. A piece of Javascript runs in the browser which calls the `convert-jwt` API. The API returns a cookie which the browser stores in it's cache.
5. The secured content of the website is returned and now browsable.

In a flow diagram this is what happens:

![auth-flow](/images/auth-flow.png)

### Cloudfront

Now let's look at some code!

We start with configuring the Cloudfront distribution and S3 bucket:

~~~ yaml
AWSTemplateFormatVersion: 2010-09-09

Resources:
  ExampleIdentity:
    Type: AWS::CloudFront::CloudFrontOriginAccessIdentity
    Properties:
      CloudFrontOriginAccessIdentityConfig:
        Comment: Identity for example distribution

  ExampleBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: REPLACE-ME
      AccessControl: Private

  ExampleBucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket:
        Ref: ExampleBucket
      PolicyDocument:
        Statement:
          -
            Effect: Allow
            Action: s3:GetObject
            Resource: !Sub '${ExampleBucket.Arn}/*'
            Principal:
              CanonicalUser:
                !GetAtt ExampleIdentity.S3CanonicalUserId

  ExampleDistribution:
    Type: AWS::CloudFront::Distribution
    Properties:
      DistributionConfig:
        DefaultRootObject: index.html
        Enabled: true
        PriceClass: PriceClass_100

        ViewerCertificate:
          CloudFrontDefaultCertificate: true

        Origins:
          - DomainName: !GetAtt ExampleBucket.DomainName
            Id: example
            S3OriginConfig:
              OriginAccessIdentity:
                !Join
                - ''
                - - 'origin-access-identity/cloudfront/'
                  - Ref: ExampleIdentity

        DefaultCacheBehavior:
          ViewerProtocolPolicy: redirect-to-https
          TargetOriginId: example
          AllowedMethods:
            - GET
            - HEAD
          CachedMethods:
            - GET
            - HEAD
          Compress: true
          DefaultTTL: 0
          MaxTTL: 0
          MinTTL: 0
          TrustedSigners:
            - Ref: AWS::AccountId
          ForwardedValues:
            QueryString: false
            Cookies:
              Forward: none

        CacheBehaviors:
          - PathPattern: /error-pages/*
            ViewerProtocolPolicy: redirect-to-https
            TargetOriginId: example
            AllowedMethods:
              - GET
              - HEAD
            CachedMethods:
              - GET
              - HEAD
            Compress: true
            DefaultTTL: 0
            MaxTTL: 0
            MinTTL: 0
            ForwardedValues:
              QueryString: false
              Cookies:
                Forward: none
          - PathPattern: /assets/*
            ViewerProtocolPolicy: redirect-to-https
            TargetOriginId: example
            AllowedMethods:
              - GET
              - HEAD
            CachedMethods:
              - GET
              - HEAD
            Compress: true
            DefaultTTL: 0
            MaxTTL: 0
            MinTTL: 0
            ForwardedValues:
              QueryString: false
              Cookies:
                Forward: none
          - PathPattern: /callback.html
            ViewerProtocolPolicy: redirect-to-https
            TargetOriginId: example
            AllowedMethods:
              - GET
              - HEAD
            CachedMethods:
              - GET
              - HEAD
            Compress: true
            DefaultTTL: 0
            MaxTTL: 0
            MinTTL: 0
            ForwardedValues:
              QueryString: false
              Cookies:
                Forward: none

        CustomErrorResponses:
          - ErrorCachingMinTTL: 0
            ErrorCode: 403
            ResponseCode: 403
            ResponsePagePath: /error-pages/403.html
          - ErrorCachingMinTTL: 0
            ErrorCode: 404

        Restrictions:
          GeoRestriction:
            RestrictionType: none
~~~

### 403-Unauthorized page

When a user hasn't logged in yet and navigates to a secured page he needs to be redirected to Auth0. We do this by using a custom 401.html page.

~~~ html
<!doctype html>
<html lang="en">

<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

  <meta http-equiv="refresh" content="0; url=https://mdekort.eu.auth0.com/authorize?response_type=id_token&scope=openid email&client_id=emDpriN0VCVVCjvcAZ10&nonce=04yXcHwu26hdln3j&redirect_uri=https://REPLACE-ME/callback.html"/>
  <script type="text/javascript">
    window.location.href = "https://mdekort.eu.auth0.com/authorize?response_type=id_token&scope=openid email&client_id=emDpriN0VCVVCjvcAZ10&nonce=04yXcHwu26hdln3j&redirect_uri=https://REPLACE-ME/callback.html"
  </script>

  <title>Example</title>
</head>

<body>
  If you are not redirected automatically, follow this <a href='https://mdekort.eu.auth0.com/authorize?response_type=id_token&scope=openid email&client_id=emDpriN0VCVVCjvcAZ10&nonce=04yXcHwu26hdln3j&redirect_uri=https://REPLACE-ME/callback.html'>link</a>.
</body>

</html>
~~~

As you can see we already configure the URL where the client should return to after logging in with Auth0. Auth0 redirects the user to that URL. Since we need to have our Auth0 JWT token converted, we let the client return to a page that handles the conversion.

### Convert the JWT token

The browser needs to call our API to convert the token and store the cookie, this is all being handled a single Javascript block:

~~~ javascript
function getToken() {
  if (window.location.href.includes('#id_token=')) {
    var parts = window.location.href.split('#');
    var token_parts = parts[1].split('=');
    return token_parts[1];
  }
  return '';
}

function httpGetAsync(endpoint, callback) {
  var xmlHttp = new XMLHttpRequest();
  xmlHttp.onreadystatechange = function () {
    if (xmlHttp.readyState == 4 && xmlHttp.status == 200) {
      callback(xmlHttp.responseText);
    }
  }
  xmlHttp.open('GET', endpoint, true);
  xmlHttp.send(null);
}

function setCookies(responseText) {
  try {
    cookieObject = JSON.parse(responseText);
    expiration = '; Expires=' + new Date(cookieObject.Expiration*1000).toUTCString() + "; ";
    staticInfo = '; Path=/; Secure';

    document.cookie = 'CloudFront-Policy=' + cookieObject.Policy + expiration + staticInfo;
    document.cookie = 'CloudFront-Signature=' + cookieObject.Signature + expiration + staticInfo;
    document.cookie = 'CloudFront-Key-Pair-Id=' + cookieObject.Key + expiration + staticInfo;
  } catch (e) {
    alert("We're very sorry, but your token seems to be invalid.")
  } finally {
    window.location.href = '/';
  }
}

var APIURL = 'https://REPLACE-ME/api/convert-jwt?id_token=' + getToken();
httpGetAsync(APIURL, setCookies);
~~~

### The convert-jwt API

This API consists of 2 parts, the Lambda and the API Gateay, I've packaged them with AWS SAM so it can be easily tested and deployed.

The project is available at <https://github.com/melvyndekort/convert-jwt>

## Conclusion

As you can see it's mostly linking existing components together to form a resilient and scalable solution against minimal costs.

How to proceed from here? You'll probably want to add some throttling of the Lambda to prevent DoS attacks that drive up your AWS bill. Considering adding some metrics and alerting for your Lambda to inform you when something fails. Also think about the caching behavior of your Cloudfront distribution, this can decrease latency for your clients and potentially lower your costs.

![metrics](https://marketplace.canva.com/MADGw941Xqk/6/screen/canva-black-samsung-tablet-computer-MADGw941Xqk.jpg)
