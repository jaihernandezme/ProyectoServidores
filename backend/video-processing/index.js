// backend/video-processing/index.js

const { MediaConvertClient, CreateJobCommand, DescribeEndpointsCommand } = require("@aws-sdk/client-mediaconvert");
const fs = require("fs").promises;
const path = require("path");

const {
  AWS_REGION,
  RAW_BUCKET_NAME,
  PROCESSED_BUCKET_NAME,
  MEDIA_CONVERT_ROLE_ARN
} = process.env;

// Cache the MediaConvert endpoint
let mcClient;

async function setupMediaConvertClient() {
  if (mcClient) {
    return;
  }
  const client = new MediaConvertClient({ region: AWS_REGION });
  try {
    const { Endpoints } = await client.send(new DescribeEndpointsCommand({ MaxResults: 1 }));
    if (!Endpoints || Endpoints.length === 0) {
      throw new Error("Could not find MediaConvert endpoint.");
    }
    const endpointUrl = Endpoints[0].Url;
    mcClient = new MediaConvertClient({ region: AWS_REGION, endpoint: endpointUrl });
    console.log("MediaConvert client initialized with endpoint:", endpointUrl);
  } catch (err) {
    console.error("Error retrieving MediaConvert endpoint:", err);
    throw err;
  }
}

exports.handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  // Extract S3 object details from the EventBridge event
  const bucket = event.detail.bucket.name;
  const key = decodeURIComponent(event.detail.object.key.replace(/\+/g, " "));

  if (bucket !== RAW_BUCKET_NAME) {
    console.warn(`Event is for bucket ${bucket}, but we're only configured for ${RAW_BUCKET_NAME}. Skipping.`);
    return;
  }

  try {
    // Ensure MediaConvert client is ready
    await setupMediaConvertClient();

    // Load and parse the job template
    const templatePath = path.join(__dirname, "job-template.json");
    const jobTemplateString = await fs.readFile(templatePath, "utf-8");
    const jobSettings = JSON.parse(jobTemplateString);

    // Dynamically update the job settings with event data and env vars
    jobSettings.Settings.Inputs[0].FileInput = `s3://${bucket}/${key}`;

    const hlsGroup = jobSettings.Settings.OutputGroups.find(group => group.Name === "Apple HLS");
    if (hlsGroup) {
      const outputKey = key.split('.').slice(0, -1).join('.');
      hlsGroup.OutputGroupSettings.HlsGroupSettings.Destination = `s3://${PROCESSED_BUCKET_NAME}/hls/${outputKey}/`;
    }

    const fileGroup = jobSettings.Settings.OutputGroups.find(group => group.Name === "File Group");
    if (fileGroup) {
      const outputKey = key.split('.').slice(0, -1).join('.');
      fileGroup.OutputGroupSettings.FileGroupSettings.Destination = `s3://${PROCESSED_BUCKET_NAME}/thumbnails/${outputKey}/`;
    }

    jobSettings.Role = MEDIA_CONVERT_ROLE_ARN;

    // Create the MediaConvert job
    const command = new CreateJobCommand({
      Settings: jobSettings.Settings,
      Role: jobSettings.Role,
    });

    const response = await mcClient.send(command);
    console.log("Successfully created MediaConvert job:", JSON.stringify(response.Job, null, 2));

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "MediaConvert job created successfully.", jobId: response.Job.Id }),
    };
  } catch (error) {
    console.error("Error creating MediaConvert job:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal Server Error: Could not create MediaConvert job." }),
    };
  }
};
