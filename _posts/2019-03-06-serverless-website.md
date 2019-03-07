---
layout: post
title: Serverless website
---

# This post is WIP, it will be completed soon!

When you start creating a new web application many people start with writing Javascript and HTML for the frontend and something like JAVA or PHP for the backend, but most developers don't start with thinking about the platform it will run on. I tend to do the latter and first choose where and how I want to deploy my application before writing any code. Recently I've started working on a small static website for my company which needed authentication. I wanted to make it extremely cheap to run, but also use state of the art technology.

I came up with the following setup:

* AWS S3 - for hosting the static content
* AWS CloudFront - for its CDN purposes, TLS termination and for its token verification functionality (signed cookies)
* Auth0 - for the authentication functionality itself
* AWS Lambda - convert the Auth0 token to a CloudFront signed cookie
* AWS API Gateway - to expose the Lambda function

## AWS S3

_TODO_

## AWS CloudFront

_TODO_

## Auth0

_TODO_

## AWS Lambda

_TODO_

## AWS API Gateway

_TODO_

# Lessons learned

# Next steps
