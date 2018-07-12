var response = require('cfn-response');
var aws = require('aws-sdk');
var s3 = new aws.S3();

var allKeys = [];
function listAllKeys(s3bucket, token, cb) {
  var opts = { Bucket: s3bucket };
  if(token) opts.ContinuationToken = token;

  s3.listObjectsV2(opts, function(err, data) {
    if (err) {
      cb(err, data);
    } else {
      allKeys = allKeys.concat(data.Contents);
      if(data.IsTruncated) {
        listAllKeys(s3bucket, data.NextContinuationToken, cb);
      } else {
        cb(err, allKeys);
      }
    }
  });
}

exports.handler = function(event, context) {
  if (event.RequestType == "Delete") {
    listAllKeys(event.ResourceProperties.Bucket, false, function(err, data) {
      if (err) {
        console.log("Error:", err, err.stack);
        response.send(event, context, response.FAILED)
      } else {
        var objects = [];
        data.forEach( function(obj) {
          objects.push( { Key: obj.Key } );
        });
        let del_request = s3.deleteObjects( {
          Bucket: event.ResourceProperties.Bucket,
          Delete: { Objects: objects }
        }, function(err, data) {
          if (err) {
            console.log("Error:", err, err.stack);
            response.send(event, context, response.FAILED)
          } else {
            console.log("Successful delete:", data);
            response.send(event, context, response.SUCCESS, data)
          }});
      }
    });
  } else {
    response.send(event, context, response.SUCCESS, {})
  }
};
