# Overview
The Hacker Pixel (HPX) is a simple, open source project that makes it easy for teams to measure what matters in as little as a single line of code. Track application parameters instantly without data engineering or prioritization discussions. 

This repo contains scripts that will quickly spin up a simple data pipeline in AWS. It will set up Cloudfront, Kinesis and Redshift to allow your users to hit a pixel that will record their IP, User-agent and 4 custom parameters. 

# Installation Options
The scripts in the repo can be executed via command line or a simple web UI. 

### Option 1: Command Line
If you prefer to use the command line, grab the [latest release](https://github.com/TurboVentures/hpx/releases) or clone this repo and follow the [quickstart guide](https://github.com/Bright-Labs/hpx/wiki/Quickstart:-Command-Line). 

### Option 2: Web UI
Installing HPX using the [web UI](https://cdn.rawgit.com/Bright-Labs/hpx/ae1bf418/launch.html) does not require any downloads. You must provide information related to your AWS account (e.g., keys, passwords), but none of the data is sent to us (the page uses Amazon’s client-side SDK). If you are not comfortable inputting this data in a web browser, we recommend you use the command line option.

# Using HPX
Once you spin up the service, HPX is extremely simple to use. Learn how to [track](https://github.com/Bright-Labs/hpx/wiki/Tracking-Data-via-HPX) and [access](https://github.com/Bright-Labs/hpx/wiki/Accessing-Your-Data) your data. You can also [read how we instrumented the HPX project](https://github.com/Bright-Labs/hpx/wiki/Example:-Running-a-hacker-pixel-in-a-Bash-script-(Dogfooding-HPX)) with a hacker pixel to get insights into usage.

# Costs
Running HPX uses Cloudformation, S3, Kinesis, Cloudfront, Lambda and Redshift services in your AWS account. You are responsible for any costs associated with using the service. You may estimate the costs using [Amazon’s cost calculator](http://calculator.s3.amazonaws.com/index.html?key=cloudformation/aab57d78-a09f-4deb-8619-c3c29b279313).

# More Details
* [HPX Design](https://github.com/Bright-Labs/hpx/wiki/HPX-Design)
* [Developing Custom HPX Scripts](https://github.com/Bright-Labs/hpx/wiki/Developing-Custom-HPX-Scripts)
* [Advanced Configuration Options](https://github.com/Bright-Labs/hpx/wiki/Advanced-Configuration-Options)
* [Deleting the HPX Stack from AWS](https://github.com/Bright-Labs/hpx/wiki/Deleting-the-HPX-Stack)

![](https://due51c15d7bfn.cloudfront.net/1x1.gif?a=readme&b=readme)
