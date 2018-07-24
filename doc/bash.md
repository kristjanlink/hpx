# hpx


### Example: Running a hacker pixel in a Bash script (Dogfooding HPX)

One of our first uses of the hacker pixel is to instrument our own application. As we continue to develop HPX, we wanted to get real data about the user's experience trying to run HPX. In particular, we wanted to get some basic data:

* How many people actually try to create an HPX stack?
* Are they successful?
* If they run into problems, what's the most common error?
* Do they continue to update HPX after the initial install?

If you are building a website, there are plenty of javascript based tools available for getting user analytics, but what about getting analytics from a bash script? Fortunately, instrumenting bash with HPX is pretty easy. Let's look at some examples taken directly from ```hpx-deploy.sh```

``` bash
pixel() {
  local subcommand="$1"
  local requestid="$(uuidgen 2>/dev/null || true)"

  if [ -z "${HPX_COOKIE:-}" ]; then
    HPX_COOKIE="$(uuidgen 2>/dev/null || true)"
    printf "HPX_COOKIE=\"$HPX_COOKIE\"\n" >> "$HPX_CFG" 2>/dev/null || true
  fi

  local pixurl=$(printf "http://d3heinlctv8z2v.cloudfront.net/1x1.gif?a=%s&b=%s&c=%s&d=%s" $subcommand $HPX_VERSION $HPX_COOKIE $requestid) 2>/dev/null || true
  local out=$(curl -qfse 'http://github.com/Bright-Labs/hpx' --url "$pixurl" 2>/dev/null || true)
  #echo "$out"
}
```

To make our lives easier, we wrapped our hacker pixel with a simple function that does the following:

* Creates basic cookie and request uuids to uniquely identify both the user and the request
* Assembles our pixel url, adding the subcommand that was called in the current version of the app
* Uses curl to call our pixel, ignoring the result

We use this function throughout our code. For instance, we want to know when a new stack is created:

```bash
pixel "hpx-deploy.create"
```

Similarly, if there's an error on stack creation, we want to know the AWS status code:

```bash
pixel "hpx-deploy.aws.$status"
```

![Using Quicksight to view pixel data](https://github.com/Bright-Labs/hpx/doc/quicksight.png)
