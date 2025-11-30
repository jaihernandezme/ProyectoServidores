// Handler for the video-processing Lambda function
exports.handler = async (event) => {
  // TODO: Implement MediaConvert job trigger logic
  console.log("Starting video processing...");
  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Video processing started successfully" }),
  };
};
