
%% Generate fixed terrain map
rng(42);  % Fixed random seed

mapSize = 200;

% Step 1: Generate random noise
noise = rand(mapSize, mapSize);

% Step 2: Smooth noise to create connected regions
kernel = ones(11, 11) / 121;
smoothNoise = conv2(noise, kernel, 'same');

% Step 3: Classify terrain into 5 types
% Quantiles give approximately equal terrain proportions
edges = quantile(smoothNoise(:), [0.2 0.4 0.6 0.8]);

terrain = ones(mapSize, mapSize);

terrain(smoothNoise > edges(1)) = 2;
terrain(smoothNoise > edges(2)) = 3;
terrain(smoothNoise > edges(3)) = 4;
terrain(smoothNoise > edges(4)) = 5;

% Step 4: Display map
figure;
imagesc(terrain);
axis image;
colormap([
    0.55 0.75 0.45;  % Open
    0.20 0.45 0.30;  % Forest
    0.35 0.65 0.85;  % Water
    0.65 0.62 0.60;  % Urban
    0.65 0.50 0.35   % Hills
    ]);
colorbar;
title('Fixed Search and Rescue Terrain');
xlabel('X coordinate');
ylabel('Y coordinate');

% Step 5: Save fixed terrain
save('terrain_fixed.mat', 'terrain');
