var response = require('cfn-response');
const { Client } = require('pg');
const dns = require('dns');

exports.handler = function(event, context) {
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
          if (err) {
            console.log("Error:", err, err.stack);
            response.send(event, context, response.FAILED);
          } else {
            console.log("Success:", res.rows);
            response.send(event, context, response.SUCCESS, { "Rows" : res.rows });
          }
          client.end((err) => {
            console.log('client has disconnected');
            if (err) {
              console.log('error during disconnection', err.stack);
            };
          });
        });
      }
    });
  } else {
    response.send(event, context, response.SUCCESS, {});
  }
};
