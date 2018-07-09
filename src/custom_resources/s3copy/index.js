var response = require('cfn-response');
var aws = require('aws-sdk');
var s3 = new aws.S3();

exports.handler = function(event, context) {
  if (event.RequestType == "Create" || event.RequestType == "Update") {
    var request = s3.copyObject( {
      "CopySource": `${event.ResourceProperties.SourceBucket}/${event.ResourceProperties.SourceKey}`,
      "Bucket": event.ResourceProperties.DestinationBucket,
      "Key": event.ResourceProperties.DestinationKey
    }, function(err, data) {
        if (err) {
          console.log("Error:", err, err.stack);
          response.send(event, context, response.FAILED)
        } else {
          console.log("Success:", data);
          response.send(event, context, response.SUCCESS, data)
        }});
  } else {
    response.send(event, context, response.SUCCESS, {});
  }
};
