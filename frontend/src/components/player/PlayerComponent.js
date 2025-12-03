// frontend/src/components/player/PlayerComponent.js

import React, { useEffect, useRef, useState } from 'react';
import videojs from 'video.js';
import 'video.js/dist/video-js.css';

import { API_ENDPOINT } from '../../config';

const PlayerComponent = ({ videoId }) => {
  const videoRef = useRef(null);
  const playerRef = useRef(null);
  const [error, setError] = useState('');

  useEffect(() => {
    const initializePlayer = async () => {
      if (!videoId) return;

      try {
        // 1. Fetch the signed URL from our backend
        const response = await fetch(`${API_ENDPOINT}/videos/${videoId}/play`);
        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.message || 'Failed to fetch signed URL');
        }
        const { signedUrl } = await response.json();

        // 2. Initialize the Video.js player
        if (videoRef.current) {
          if (!playerRef.current) {
            // Initialize a new player
            playerRef.current = videojs(videoRef.current, {
              autoplay: true,
              controls: true,
              responsive: true,
              fluid: true,
              sources: [{
                src: signedUrl,
                type: 'application/x-mpegURL', // HLS
              }],
            });
          } else {
            // If player already exists, just update the source
            playerRef.current.src({
              src: signedUrl,
              type: 'application/x-mpegURL',
            });
          }
        }
      } catch (err) {
        console.error('Error initializing player:', err);
        setError(`Error: ${err.message}`);
      }
    };

    initializePlayer();

  }, [videoId]); // Re-run effect when videoId changes

  // Dispose the player on component unmount
  useEffect(() => {
    const player = playerRef.current;
    return () => {
      if (player && !player.isDisposed()) {
        player.dispose();
        playerRef.current = null;
      }
    };
  }, []);

  return (
    <div>
      {error && <p style={{ color: 'red' }}>{error}</p>}
      <div data-vjs-player>
        <video ref={videoRef} className="video-js vjs-default-skin" />
      </div>
    </div>
  );
};

export default PlayerComponent;
