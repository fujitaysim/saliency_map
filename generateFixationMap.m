% Script for modeling and simulations presented in Fujita Y. et al. 2025.
% (https://doi.org/10.3389/fnins.2025.1614468)

% artificially generating fixation points from a saliency map

function [output_fixation_map] = generateFixationMap(saliency_map, number_of_fixation_points_to_generate)

saliencymap_for_generating_fixation = saliency_map;
height = size(saliency_map, 1);
width = size(saliency_map, 2);

normalized_saliencymap = saliencymap_for_generating_fixation / sum(saliencymap_for_generating_fixation(:));

reshaped_normalized_saliencymap = reshape(normalized_saliencymap, [], 1);
cumulative_sum = cumsum(reshaped_normalized_saliencymap);

r = rand(1, number_of_fixation_points_to_generate);

generated_fixations_reshaped = reshaped_normalized_saliencymap * 0;

for i = 1:number_of_fixation_points_to_generate
    index_of_fixation = find(r(i)<cumulative_sum, 1);
    generated_fixations_reshaped(index_of_fixation) = generated_fixations_reshaped(index_of_fixation) + 1;
end

output_fixation_map = reshape(generated_fixations_reshaped, height, width);

end

