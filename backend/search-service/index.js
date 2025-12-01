// backend/search-service/index.js

const { Client } = require("@opensearch-project/opensearch");
const { AwsSigv4Signer } = require("@opensearch-project/opensearch/aws");
const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");

const {
  AWS_REGION,
  OPENSEARCH_ENDPOINT,
} = process.env;

const s3Client = new S3Client({ region: AWS_REGION });
const osClient = new Client({
  ...AwsSigv4Signer({
    region: AWS_REGION,
    service: 'aoss',
  }),
  node: OPENSEARCH_ENDPOINT,
});

const INDEX_NAME = 'videos';

// Helper to stream S3 object content to a string
const streamToString = (stream) => new Promise((resolve, reject) => {
  const chunks = [];
  stream.on("data", (chunk) => chunks.push(chunk));
  stream.on("error", reject);
  stream.on("end", () => resolve(Buffer.concat(chunks).toString("utf-8")));
});

exports.handler = async (event) => {
  console.log("Search Service triggered with event:", JSON.stringify(event, null, 2));

  for (const record of event.Records) {
    if ((record.eventName === 'INSERT' || record.eventName === 'MODIFY') && record.dynamodb.NewImage.transcriptUri?.S) {
      try {
        const newImage = record.dynamodb.NewImage;
        const transcriptUri = newImage.transcriptUri.S;

        // Fetch the transcript from S3
        const [bucket, ...keyParts] = transcriptUri.replace("s3://", "").split("/");
        const key = keyParts.join("/");

        const getObjectCommand = new GetObjectCommand({ Bucket: bucket, Key: key });
        const s3Response = await s3Client.send(getObjectCommand);
        const transcriptJson = await streamToString(s3Response.Body);
        const transcriptData = JSON.parse(transcriptJson);
        const transcriptText = transcriptData.results.transcripts.map(t => t.transcript).join(' ');

        // Construct the document to be indexed
        const document = {
          videoId: newImage.VideoID.S,
          title: newImage.title?.S,
          description: newImage.description?.S,
          tags: newImage.rekognitionLabels?.L.map(item => item.S) || [],
          transcript: transcriptText,
        };

        console.log(`Indexing document for VideoID: ${document.videoId}`);

        // Index the document in OpenSearch
        await osClient.index({
          index: INDEX_NAME,
          id: document.videoId,
          body: document,
          refresh: true,
        });

        console.log(`Successfully indexed document for VideoID: ${document.videoId}`);
      } catch (error) {
        console.error(`Failed to index document for record: ${record.eventID}. Error:`, error);
      }
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Indexing process completed." }),
  };
};
