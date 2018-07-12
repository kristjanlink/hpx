var response = require('cfn-response');
var aws = require('aws-sdk');
var s3 = new aws.S3();

exports.handler = function(event, context) {
  if (event.RequestType == "Delete") {
    var truncated = true;
    var error = false;
    //while (truncated && !error) {
      let list = s3.listObjectsV2( {
        "Bucket": event.ResourceProperties.Bucket
      }, function(err, data) {
        if (err) {
          error = true;
          console.log("Error:", err, err.stack);
          response.send(event, context, response.FAILED)
        } else {
          truncated = data.IsTruncated;
          console.log("Listed keys for bucket!", truncated);
          let objects = [];
          for (let o in data.Contents) {
            console.log("Found key to delete:", o.Key);
            objects.push( { "Key": o.Key } );
          }
          let del_request = s3.deleteObjects( {
            "Bucket": event.ResourceProperties.Bucket,
            "Objects": objects
          }, function(err, data) {
            if (err) {
              error = true;
              console.log("Error:", err, err.stack);
              response.send(event, context, response.FAILED)
            } else {
              console.log("Successful delete:", data);
              response.send(event, context, response.SUCCESS, data)
            }});
        }
      });
    //}
  } else {
    response.send(event, context, response.SUCCESS, {})
  }
};
