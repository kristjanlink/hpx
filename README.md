# hpx

## Prerequisites
- git
- awscli (instructions below if you haven't done this yet.)

## Quickstart: Updating HPX Using CloudFormation

First, get your code into S3 and create a stack changeset.
A script is provided for your convenience:
```
./bin/deploy.sh
```

Second, either from the AWS Console or the AWS Cli (the Console is easier for this), find the changeset you just created within the stack (i.e. hpx-master->changesets). Review the changeset to confirm that the predicted changes match what you expect and execute!

Assuming all goes well, commit your code and have a beer.

### Environments, Stacks and Changesets

```${Environment}``` is set based on your current branch:
If in master, the environment is set to "prod", otherwise the environment is set to your branch name.

The *Environment* is used to identify which Stack should be updated as well as passed as a parameter to CloudFormation to uniquely name AWS resources within each Stack.




## Appendix: Setting up the AWS Cli
### Get Python
```bash
brew install python@3
```

### Install AWS Cli
```bash
sudo -H pip3 install awscli
```
Optional: add ```complete -C aws_completer aws``` to your .bashrc file to enable command line completion.

### Setup AWS Credentials
Create ```~/.aws/credentials``` with contents as follows:

```ini
[default]
aws_access_key_id=<create in aws console>
aws_secret_access_key=<create in aws console>
region=us-east-1
```

### Test

```bash
aws iam list-users
```
