# hpx

## Getting started (OSX)
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
