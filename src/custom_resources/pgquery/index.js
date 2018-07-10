var response = require('cfn-response');
const { Client } = require('pg');
const dns = require('dns');

exports.handler = function(event, context) {
  context.callbackWaitsForEmptyEventLoop = false;
  console.log( JSON.stringify({
    RequestType: event.RequestType,
    ResponseURL: event.ResponseURL
  }));

  dns.lookup(event.ResourceProperties.Host, (err, address, family) => {
    console.log("Host address: %j Family: IPv%s", address, family);
  });

  if (event.RequestType == "Create" || event.RequestType == "Update") {
    var client = new Client({
      user: event.ResourceProperties.User,
      host: event.ResourceProperties.Host,
      database: event.ResourceProperties.Database,
      password: event.ResourceProperties.Password,
      port: event.ResourceProperties.Port,
    });

    client.connect((err) => {
      if (err) {
        console.log("Connection Error:", err, err.stack);
        response.send(event, context, response.FAILED);
      } else {
        console.log("Connected:");
        client.query(event.ResourceProperties.Query, (err, res) => {
          var status = response.SUCCESS;
          if (err) {
            console.log("Error:", err, err.stack);
            status = response.FAILED;
          } else {
            console.log("Success:", res.rows);
          }
          client.end((err) => {
            console.log("Client has disconnected");
            if (err) {
              console.log("Error during disconnection", err.stack);
            };
            response.send(event, context, status);
          });
        });
      }
    });
  } else {
    response.send(event, context, response.SUCCESS);
    return;
  }
};
