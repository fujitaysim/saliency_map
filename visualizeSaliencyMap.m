function [] = visualizeSaliencyMap(saliency_map)

% visualize activity of saliency map (heatmap)

figure, imagesc(double(saliency_map));colorbar;

end

