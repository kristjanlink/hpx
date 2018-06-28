# hpx

## Prerequisites
- git
- awscli (instructions below if you haven't done this yet.)

## Updating HPX Using CloudFormation

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
