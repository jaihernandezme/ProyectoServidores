// backend/upload-service/index.js

const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");

const s3Client = new S3Client({ region: process.env.AWS_REGION });
const BUCKET_NAME = process.env.RAW_BUCKET_NAME;

exports.handler = async (event) => {
  if (!event.body) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Bad Request: Missing request body." }),
    };
  }

  const body = JSON.parse(event.body);
  const { fileName } = body;

  if (!fileName) {
    return {
      statusCode: 400,
      body: JSON.stringify({ message: "Bad Request: Missing 'fileName' in request body." }),
    };
  }

  const command = new PutObjectCommand({
    Bucket: BUCKET_NAME,
    Key: `uploads/${Date.now()}_${fileName}`,
  });

  try {
    const signedUrl = await getSignedUrl(s3Client, command, {
      expiresIn: 300, // 5 minutes
    });

    return {
      statusCode: 200,
      headers: {
        "Access-Control-Allow-Origin": "*", // Permitir CORS para el frontend
        "Access-Control-Allow-Headers": "Content-Type",
      },
      body: JSON.stringify({
        uploadUrl: signedUrl,
        key: command.input.Key,
      }),
    };
  } catch (error) {
    console.error("Error generating presigned URL:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Internal Server Error: Could not generate presigned URL." }),
    };
  }
};
