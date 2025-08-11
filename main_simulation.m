% This script calculates and visualizes a saliency map from a given image.
% Make sure that all required function and class files are located in the working directory 
% or in a directory included in the MATLAB path.

% --------------------------------------------------------
% set the values of the variables below before running
% --------------------------------------------------------
%   The height or width of the visual stimulus should be around 256 pixels
%   Set image_resizing_scale to adjust the image to the appropriate size.
%   For example, if the input image has a resolution of 1920Å~1080,
%   set image_resizing_scale = 0.2 to resize the visual stimulus to 384Å~216 pixels.
image_filename = 'xxxxxxx.jpg';
image_resizing_scale = 0.2;
%   set parameters for the neural network
parameter_set.W_e = 2;
parameter_set.W_i = 140;
parameter_set.Sigma_L = 3.2;
parameter_set.Beta = 15;
parameter_set.baseline_activity = 0;
parameter_set.fraction_of_reducing_synaptic_connections = 0;
% ----------------------------------------------------------

visual_stimulus = prepareVisualStimulus(image_filename, image_resizing_scale);

output_saliency_map = calculateSaliencyMap(visual_stimulus, parameter_set);

visualizeSaliencyMap(output_saliency_map);