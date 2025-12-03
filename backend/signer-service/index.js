// backend/signer-service/index.js

const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const { getSignedUrl } = require("@aws-sdk/cloudfront-signer");
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand } = require("@aws-sdk/lib-dynamodb");

const {
  AWS_REGION,
  CLOUDFRONT_DOMAIN_NAME,
  CLOUDFRONT_PUBLIC_KEY_ID,
  CLOUDFRONT_PRIVATE_KEY_SECRET_ARN,
  DYNAMODB_TABLE_NAME
} = process.env;

const secretsManagerClient = new SecretsManagerClient({ region: AWS_REGION });
const dbClient = new DynamoDBClient({ region: AWS_REGION });
const docClient = DynamoDBDocumentClient.from(dbClient);
let privateKey; // Cache the private key

// Helper to fetch the private key from Secrets Manager
async function getPrivateKey() {
  if (privateKey) {
    return privateKey;
  }
  const command = new GetSecretValueCommand({ SecretId: CLOUDFRONT_PRIVATE_KEY_SECRET_ARN });
  const { SecretString } = await secretsManagerClient.send(command);
  privateKey = SecretString;
  return privateKey;
}

exports.handler = async (event) => {
  console.log("Signer Service triggered with event:", JSON.stringify(event, null, 2));

  const videoId = event.pathParameters?.id;

  if (!videoId) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Bad Request: Missing 'id' in path parameters." }),
    };
  }

  try {
    // 1. Get video metadata from DynamoDB
    const getCommand = new GetCommand({
      TableName: DYNAMODB_TABLE_NAME,
      Key: { VideoID: videoId },
    });
    const { Item } = await docClient.send(getCommand);

    if (!Item || !Item.hlsManifestPath) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: "Video not found or HLS manifest path is missing." }),
      };
    }

    // 2. Get the private key
    const privateKeyString = await getPrivateKey();

    // 3. Construct the URL to the HLS manifest
    const videoUrl = `${CLOUDFRONT_DOMAIN_NAME}/${Item.hlsManifestPath}`;

    // 4. Generate the signed URL
    const signedUrl = getSignedUrl({
      url: videoUrl,
      keyPairId: CLOUDFRONT_PUBLIC_KEY_ID,
      privateKey: privateKeyString,
      dateLessThan: new Date(Date.now() + 1000 * 60 * 60), // 1 hour expiration
    });

    return {
      statusCode: 200,
      headers: { "Access-Control-Allow-Origin": "*" },
      body: JSON.stringify({ signedUrl }),
    };

  } catch (error) {
    console.error("Error generating signed URL:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal Server Error: Could not generate signed URL." }),
    };
  }
};
