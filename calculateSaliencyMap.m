% Script for modeling and simulations presented in Fujita Y. et al. 2025.
% (https://doi.org/10.3389/fnins.2025.1614468)

% This function computes a saliency map from a given input image
% using a specified set of parameters.

function [outputSaliencyMap] = calculateSaliencyMap(visual_stimulus, parameter_set)

% feature extraction

fe = FeatureExtractionClass(visual_stimulus);

fe.prepareScaledImages([1 0.5 0.25]);

fe.resizeSourceImage(0.25);

fe.extractLuminance;
fe.extractOrientation;
fe.extractColor;

n_orientations = 4;
n_colors = 4;
n_luminances = 1;

height = size(fe.LuminanceFeatureImages{1}, 1);
width = size(fe.LuminanceFeatureImages{1}, 2);

% prepare neural networks

n_features = n_orientations + n_colors + n_luminances;

layers = cell(1, n_features * 2 + 4);

input_layer_indices = 1 : n_features;
subsequent_layer_indices = n_features + 1 : length(layers);

% input layers
for i = 1 : n_features
    layers{i} = NeuralLayerClass(height, width, []);
end
% feature maps
for i = n_features + 1 : n_features * 2
    layers{i} = NeuralLayerClass(height, width, [layers{i - n_features}]);
end
orientation_maps = [];
color_maps = [];
luminance_maps = [];
for i = 1 : n_features
    if i <= n_orientations
        orientation_maps = [orientation_maps, layers{n_features + i}];
    elseif i <= (n_orientations + n_colors)
        color_maps = [color_maps, layers{n_features + i}];
    else
        luminance_maps = [luminance_maps, layers{n_features + i}];
    end
end
% conspicuity maps
layers{n_features * 2 + 1} = NeuralLayerClass(height, width, orientation_maps);
layers{n_features * 2 + 2} = NeuralLayerClass(height, width, color_maps);
layers{n_features * 2 + 3} = NeuralLayerClass(height, width, luminance_maps);
conspicuity_maps = [layers{n_features * 2 + 1}, layers{n_features * 2 + 2}, layers{n_features * 2 + 3}];
% saliency map
layers{n_features * 2 + 4} = NeuralLayerClass(height, width, conspicuity_maps);

% set stimuli

stimuli = cell(1, n_features);
for i = 1 : n_orientations
    stimuli{i} = fe.OrientationFeatureImages{i} * 20;
end
for i = 1 : n_colors
    stimuli{n_orientations + i} = fe.ColorFeatureImages{i} * 15;
end
for i = 1 : n_luminances
    stimuli{n_orientations + n_colors + i} = fe.LuminanceFeatureImages{i} * 30;
end

% set parameters
for i = 1:length(layers)
    layers{i}.W_e = parameter_set.W_e;
    layers{i}.W_i = parameter_set.W_i;
    layers{i}.Sigma_e = parameter_set.Sigma_L;
    layers{i}.Sigma_i = parameter_set.Sigma_L * parameter_set.Beta;
    
    layers{i}.setLateralConnections;
    if parameter_set.fraction_of_reducing_synaptic_connections > 0
        layers{i}.setLateralConnectionsWithRandomLoss(parameter_set.fraction_of_reducing_synaptic_connections);
    end
    layers{i}.setFeedforwardConnections;
    layers{i}.DescriptionForDebug = ['layer ', num2str(i)];
end

for i = 1:length(layers)
    layers{i}.BasalActivity = parameter_set.baseline_activity;
end

% run neural networks

t_range = 1:600;
time_to_present_stimulus = 200;

for t = t_range
    if t == time_to_present_stimulus
        for i = input_layer_indices
            layers{i}.Activity = stimuli{i};
        end
    end
    for i = subsequent_layer_indices
        layers{i}.updateDepressingEffects;
        layers{i}.updateActivity;
        layers{i}.ActivityTimecourse{t} = layers{i}.Activity;
        layers{i}.TimePoint = layers{i}.TimePoint + 1; % for debug
    end
end

outputSaliencyMap = layers{n_features*2+4}.ActivityTimecourse{max(t_range)};

end