// backend/signer-service/index.js

const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const { getSignedUrl } = require("@aws-sdk/cloudfront-signer");

const {
  AWS_REGION,
  CLOUDFRONT_DOMAIN_NAME,
  CLOUDFRONT_PUBLIC_KEY_ID,
  CLOUDFRONT_PRIVATE_KEY_SECRET_ARN
} = process.env;

const secretsManagerClient = new SecretsManagerClient({ region: AWS_REGION });
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
    const privateKeyString = await getPrivateKey();
    const videoUrl = `${CLOUDFRONT_DOMAIN_NAME}/videos/${videoId}`; // Adjust path as needed

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
