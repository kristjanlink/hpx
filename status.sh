STACK=hpxmaster-us-west-2

REDSHIFT_CLUSTER=`aws cloudformation describe-stack-resources --stack-name $STACK --output text  | awk '{if ($2 == "HPXRedshiftCluster") print $3;}'`
REDSHIFT_ENDPOINT=`aws redshift describe-clusters --cluster-identifier hpxmaster --output text | awk '{if ($1 == "ENDPOINT") print $2 ":" $3;}'`

echo "Your redshift endpoint is $REDSHIFT_ENDPOINT"

CLOUDFRONT=`aws cloudformation describe-stack-resources --stack-name hpxmaster-us-west-2 --output text  | awk '{if ($2 == "PixelServerCloudfrontDistribution") print $3;}'`

CLOUDFRONT_HOST=`aws cloudfront get-distribution --id E3VA8SSVH6TYF7 --output text | awk '{if ($1 == "DISTRIBUTION") print $3}'`

echo "Your pixel url is http://$CLOUDFRONT_HOST/1x1.gif?a=value1&b=value2&c=value3&value4"

