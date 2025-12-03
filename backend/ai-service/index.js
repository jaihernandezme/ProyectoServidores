// backend/ai-service/index.js

const { RekognitionClient, StartLabelDetectionCommand, StartContentModerationCommand } = require("@aws-sdk/client-rekognition");
const { TranscribeClient, StartTranscriptionJobCommand } = require("@aws-sdk/client-transcribe");
const path = require("path");

const {
  AWS_REGION,
  SNS_TOPIC_ARN, // Topic to notify when AI jobs are complete
  SNS_ROLE_ARN,  // Role for AI services to assume to publish to SNS
  PROCESSED_BUCKET_NAME // Bucket where transcription output will be stored
} = process.env;

const rekognitionClient = new RekognitionClient({ region: AWS_REGION });
const transcribeClient = new TranscribeClient({ region: AWS_REGION });

exports.handler = async (event) => {
  console.log("AI Service triggered with event:", JSON.stringify(event, null, 2));

  // Extract the original source video file from the MediaConvert job details
  if (event.detail.status !== 'COMPLETE' || !event.detail.inputDetails || event.detail.inputDetails.length === 0) {
    console.log("Job status is not COMPLETE or input details are missing. Skipping.");
    return;
  }

  const inputUri = event.detail.inputDetails[0].uri;
  const [bucket, ...keyParts] = inputUri.replace("s3://", "").split("/");
  const key = keyParts.join("/");

  // A unique identifier for the video, derived from the key
  const videoId = path.basename(key, path.extname(key));

  const s3Location = {
    S3Object: {
      Bucket: bucket,
      Name: key,
    },
  };

  // Common notification channel for async jobs
  const notificationChannel = {
    SNSTopicArn: SNS_TOPIC_ARN,
    RoleArn: SNS_ROLE_ARN,
  };

  try {
    // 1. Start Rekognition Label Detection
    const labelDetectionParams = {
      Video: s3Location,
      NotificationChannel: notificationChannel,
      JobTag: `label-${videoId}`, // Pass videoId for tracking
    };
    const labelDetectionCommand = new StartLabelDetectionCommand(labelDetectionParams);
    const labelDetectionResponse = await rekognitionClient.send(labelDetectionCommand);
    console.log("Started Rekognition Label Detection. Job ID:", labelDetectionResponse.JobId);

    // 2. Start Rekognition Content Moderation
    const moderationParams = {
      Video: s3Location,
      NotificationChannel: notificationChannel,
      JobTag: `moderation-${videoId}`,
    };
    const moderationCommand = new StartContentModerationCommand(moderationParams);
    const moderationResponse = await rekognitionClient.send(moderationCommand);
    console.log("Started Rekognition Content Moderation. Job ID:", moderationResponse.JobId);

    // 3. Start Transcribe Transcription Job
    const transcriptionJobName = `${videoId}-${Date.now()}`;
    const transcriptionParams = {
      TranscriptionJobName: transcriptionJobName,
      LanguageCode: "en-US", // Or detect language
      Media: {
        MediaFileUri: inputUri,
      },
      OutputBucketName: PROCESSED_BUCKET_NAME,
      OutputKey: `transcripts/${transcriptionJobName}.json`,
      Settings: {
        ShowSpeakerLabels: true,
        MaxSpeakerLabels: 2,
      },
    };
    const transcriptionCommand = new StartTranscriptionJobCommand(transcriptionParams);
    await transcribeClient.send(transcriptionCommand);
    console.log("Started Transcribe Job:", transcriptionJobName);

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "AI processing jobs started successfully." }),
    };

  } catch (error) {
    console.error("Error starting AI jobs:", error);
    throw error; // Let Lambda retry if configured
  }
};
