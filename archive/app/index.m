figure;
imagesc(terrain);
axis image;

exportgraphics(gcf, 'terrain.png', 'Resolution', 300);