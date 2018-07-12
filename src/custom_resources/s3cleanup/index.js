var response = require('cfn-response');
var aws = require('aws-sdk');
var s3 = new aws.S3();

exports.handler = function(event, context) {
  if (event.RequestType == "Delete") {
    var truncated = true;
    var error = false;
    while (truncated && !error) {
      let list = s3.listObjectsV2( {
        "Bucket": event.ResourceProperties.Bucket
      }, function(err, data) {
        if (err) {
          error = true;
          console.log("Error:", err, err.stack);
          response.send(event, context, response.FAILED)
        } else {
          truncated = data.IsTruncated;
          for (let o in data.Contents) {
            let del_request = s3.deleteObject( {
              "Bucket": blah,
              "Key": blah
            }, function(err, data) {
              if (err) {
                error = true;
                console.log("Error:", err, err.stack);
                response.send(event, context, response.FAILED)
              } else {
                console.log("Successful delete:", data);
              }
          }});
        }});
      if (!error) {
        console.log("Done cleaning up bucket:", event.ResourceProperties.Bucket);
        response.send(event, context, response.SUCCESS, {})
      }
    }
  } else {
    response.send(event, context, response.SUCCESS, {})
  }
};
