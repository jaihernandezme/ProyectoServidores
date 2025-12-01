// backend/metadata-service/index.js

const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, UpdateCommand } = require("@aws-sdk/lib-dynamodb");
const { RekognitionClient, GetLabelDetectionCommand, GetContentModerationCommand } = require("@aws-sdk/client-rekognition");
const { TranscribeClient, GetTranscriptionJobCommand } = require("@aws-sdk/client-transcribe");

const { AWS_REGION, DYNAMODB_TABLE_NAME } = process.env;

const dbClient = new DynamoDBClient({ region: AWS_REGION });
const docClient = DynamoDBDocumentClient.from(dbClient);
const rekognitionClient = new RekognitionClient({ region: AWS_REGION });
const transcribeClient = new TranscribeClient({ region: AWS_REGION });

// Helper to extract Video ID from different job identifiers
const getVideoId = (message) => {
  if (message.JobTag) { // Rekognition
    return message.JobTag.split('-').slice(1).join('-');
  }
  if (message.TranscriptionJob?.TranscriptionJobName) { // Transcribe
    return message.TranscriptionJob.TranscriptionJobName.split('-')[0];
  }
  return null;
};

exports.handler = async (event) => {
  console.log("Metadata Service triggered with event:", JSON.stringify(event, null, 2));

  for (const record of event.Records) {
    try {
      const message = JSON.parse(record.Sns.Message);
      const videoId = getVideoId(message);

      if (!videoId) {
        console.warn("Could not determine videoId from message. Skipping.", message);
        continue;
      }

      let updateExpression = 'SET #updatedAt = :updatedAt';
      let expressionAttributeNames = { '#updatedAt': 'updatedAt' };
      let expressionAttributeValues = { ':updatedAt': new Date().toISOString() };

      // Case 1: Rekognition Job Completion
      if (message.JobId && message.Status === 'SUCCEEDED') {
        if (message.API === 'StartLabelDetection') {
          const { Labels } = await rekognitionClient.send(new GetLabelDetectionCommand({ JobId: message.JobId }));
          updateExpression += ', #labels = :labels';
          expressionAttributeNames['#labels'] = 'rekognitionLabels';
          expressionAttributeValues[':labels'] = Labels.map(l => l.Label.Name);
        } else if (message.API === 'StartContentModeration') {
          const { ModerationLabels } = await rekognitionClient.send(new GetContentModerationCommand({ JobId: message.JobId }));
          updateExpression += ', #moderation = :moderation';
          expressionAttributeNames['#moderation'] = 'rekognitionModeration';
          expressionAttributeValues[':moderation'] = ModerationLabels.map(m => m.ModerationLabel.Name);
        }
      }

      // Case 2: Transcribe Job Completion
      else if (message.TranscriptionJob?.TranscriptionJobStatus === 'COMPLETED') {
        const { TranscriptionJob } = await transcribeClient.send(new GetTranscriptionJobCommand({ TranscriptionJobName: message.TranscriptionJob.TranscriptionJobName }));
        const transcriptUri = TranscriptionJob.Transcript.TranscriptFileUri;
        updateExpression += ', #transcriptUri = :transcriptUri, #status = :status';
        expressionAttributeNames['#transcriptUri'] = 'transcriptUri';
        expressionAttributeNames['#status'] = 'status';
        expressionAttributeValues[':transcriptUri'] = transcriptUri;
        expressionAttributeValues[':status'] = 'READY'; // Mark as ready for playback
      }

      // Update DynamoDB record
      if (Object.keys(expressionAttributeNames).length > 1) {
        const updateCommand = new UpdateCommand({
          TableName: DYNAMODB_TABLE_NAME,
          Key: { VideoID: videoId },
          UpdateExpression: updateExpression,
          ExpressionAttributeNames: expressionAttributeNames,
          ExpressionAttributeValues: expressionAttributeValues,
        });
        await docClient.send(updateCommand);
        console.log(`Successfully updated metadata for VideoID: ${videoId}`);
      }

    } catch (error) {
      console.error("Error processing SNS message and updating DynamoDB:", error);
      // Continue to next record instead of failing the whole batch
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Metadata processing complete." }),
  };
};
