---
layout: post
title: Serverless website
---

# This post is WIP, it will be completed soon!

When you start creating a new web application many people start with writing Javascript and HTML for the frontend and something like JAVA or PHP for the backend, but they don't start with thinking about the platform it will run on. I tend to do the latter and first choose where and how I want to deploy my application. Recently I've started working on a small facebook application for my company that had to replace an older application that was running on-premise in one of our servers. I wanted to make it cheap to run, but also use state of the art technology.

I came up with the following setup:

* AWS S3 - for static and semi-static content
* Auth0 - to secure the application
* AWS Lambda - for management functions and security validation
* AWS API Gateway - to expose the Lambda functions
* AWS CloudFront - to bring it all together

## AWS S3

_TODO_

## Auth0

_TODO_

## AWS Lambda

_TODO_

## AWS API Gateway

_TODO_

## AWS CloudFront

_TODO_
