% Script for modeling and simulations presented in Fujita Y. et al. 2025.
% (https://doi.org/10.3389/fnins.2025.1614468)

function [output] = prepareVisualStimulus(image_filename, image_resizing_scale)

loaded_image = imread(image_filename);
resized_image = imresize(loaded_image, image_resizing_scale);

% adjust the size of visual stimulus to be a multiple of 4 in both dimensions.
adjusted_height = floor(size(resized_image, 1) / 4) * 4;
adjusted_width  = floor(size(resized_image, 2) / 4) * 4;
adjusted_image = resized_image(1:adjusted_height, 1:adjusted_width, :);

output = adjusted_image;

end

