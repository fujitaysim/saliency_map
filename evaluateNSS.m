% Script for modeling and simulations presented in Fujita Y. et al. 2025.
% (https://doi.org/10.3389/fnins.2025.1614468)

% This function computes the Normalized Scanpath Saliency (NSS) score,
% which quantifies the correspondence between a saliency map and fixation data.

function [output_NSS_score] = evaluateNSS(saliency_map, fixation_map)

resized_map = double(imresize(saliency_map, size(fixation_map)));
normalized_map = double((resized_map - mean(resized_map(:)))/std(resized_map(:)));
output_NSS_score = mean(normalized_map(logical(fixation_map)));

end