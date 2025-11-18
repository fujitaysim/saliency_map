% Script for modeling and simulations presented in Fujita Y. et al. 2025.
% (https://doi.org/10.3389/fnins.2025.1614468)

function [] = visualizeSaliencyMap(saliency_map)

% visualize activity of saliency map (heatmap)

figure, imagesc(double(saliency_map));colorbar;

end

