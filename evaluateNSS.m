function [output_NSS_score] = evaluateNSS(saliency_map, fixation_map)

% This function computes the Normalized Scanpath Saliency (NSS) score,
% which quantifies the correspondence between a saliency map and fixation data.

resized_map = double(imresize(saliency_map, size(fixation_map)));
normalized_map = double((resized_map - mean(resized_map(:)))/std(resized_map(:)));
output_NSS_score = mean(normalized_map(logical(fixation_map)));

end