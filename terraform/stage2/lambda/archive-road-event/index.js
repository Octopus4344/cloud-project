'use strict';

const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');

const s3 = new S3Client({
  region: process.env.AWS_ACCOUNT_REGION || 'us-east-1',
});
const BUCKET = process.env.ARCHIVE_BUCKET;

/**
 * Lambda function triggered by SQS (archive-queue).
 * Messages originate from SNS (road-events-completed topic) and arrive
 * wrapped in the SNS notification envelope.
 */
exports.handler = async (event) => {
  const results = await Promise.allSettled(
    event.Records.map((record) => processRecord(record)),
  );

  const failures = results.filter((r) => r.status === 'rejected');
  if (failures.length > 0) {
    console.error(`${failures.length} records failed to archive`);
    // Re-throw so SQS retries the batch (messages will land in DLQ after maxReceiveCount)
    throw new Error(`Partial batch failure: ${failures.length} records`);
  }
};

async function processRecord(record) {
  let body;
  try {
    body = JSON.parse(record.body);
  } catch {
    console.error('Failed to parse SQS message body', record.body);
    return;
  }

  // Unwrap SNS envelope when raw message delivery is disabled
  if (body.Type === 'Notification') {
    try {
      body = JSON.parse(body.Message);
    } catch {
      console.error('Failed to parse SNS Message field', body.Message);
      return;
    }
  }

  const eventData = body.data || body;
  const eventId = eventData.eventId ?? record.messageId;
  const timestamp = Date.now();
  const key = `events/${eventId}/${timestamp}.json`;

  await s3.send(
    new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: JSON.stringify({
        archivedAt: new Date().toISOString(),
        ...eventData,
      }),
      ContentType: 'application/json',
      ServerSideEncryption: 'AES256',
    }),
  );

  console.log(`Archived event ${eventId} → s3://${BUCKET}/${key}`);
}
