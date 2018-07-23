'use strict'

const url = require('url')
const AWS = require('aws-sdk')
const firehose = new AWS.Firehose()
const s3 = new AWS.S3()
const zlib = require('zlib')
const util = require('util')
const gunzip = util.promisify(zlib.gunzip)
const querystring = require('querystring')

// TODO: what to do with failed responses
exports.handler = async function(event, context, callback) {
  let firehose_records = []
  let line_count = 0
  let success_count = 0
  let error_count = 0
  let outstanding_put = null
  console.info('Reading S3 file')
  for (const record of event.Records) {
    const response = await s3.getObject( { Bucket: record.s3.bucket.name, Key: record.s3.object.key }).promise()
    const data = (await gunzip(response.Body)).toString()
    for(const line of data.trim().split("\n")) {
      const fh_record = []
      if(line.startsWith("#")) {
        continue
      }
      const fields = line.split("\t")
      fh_record.push(fields[0] + " " + fields[1]) // date
      fh_record.push(fields[4]) // IP
      fh_record.push(fields[10]) // User agent
      fh_record.push(fields[7] + "?" + fields[11]) // uri
      const query = querystring.parse(fields[11])
      fh_record.push(query.a || '')
      fh_record.push(query.b || '')
      fh_record.push(query.c || '')
      fh_record.push(query.d || '')
      fh_record.push(fields[9]) // referrer
      fh_record.push(fields[12]) // cookie

      firehose_records.push({Data: fh_record.join("\t") + "\n"})
      line_count += 1

      // Batch will only take 500 records
      if(firehose_records.length == 500) {
        // We allow only one outstanding promise, because otherwise
        // the memory blows up
        const last_put = outstanding_put
        outstanding_put = firehose.putRecordBatch({
          DeliveryStreamName: process.env.KINESIS_DELIVERY_STREAM,
          Records: firehose_records
        }).promise()

        if (last_put) {
          const fh_response = await last_put
          error_count += fh_response.FailedPutCount
          success_count += fh_response.RequestResponses.length
        }
        console.info(`Flushing. Lines: ${line_count} ok: ${success_count} errors: ${error_count}`)
        firehose_records = []
      }
    }

    const final_put = firehose.putRecordBatch({
      DeliveryStreamName: process.env.KINESIS_DELIVERY_STREAM,
      Records: firehose_records
    }).promise()

    if (outstanding_put) {
      const fh_response = await outstanding_put
      error_count += fh_response.FailedPutCount
      success_count += fh_response.RequestResponses.length
    }

    const fh_response = await final_put
    error_count += fh_response.FailedPutCount
    success_count += fh_response.RequestResponses.length

  }
  console.info(`Completed. Lines: ${line_count} ok: ${success_count} errors: ${error_count}`)
  callback(null, {
    success_count,
    error_count,
    line_count
  })
}
