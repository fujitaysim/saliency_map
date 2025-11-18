% Script for modeling and simulations presented in Fujita Y. et al. 2025.
% (https://doi.org/10.3389/fnins.2025.1614468)

% Use this function instead of the calculateSaliencyMap function
% to compute saliency map using the Brecht-Saiki model (de Brecht and Saiki, 2006).
% Note: This implementation includes slight modifications from the original model  
% to accommodate differences in visual stimuli, while preserving its fundamental structure.

function [outputSaliencyMap] = useBrechtSaikiModel(visual_stimulus)

% feature extraction

fe = FeatureExtractionClass(visual_stimulus);

fe.prepareScaledImages([0.25]);

fe.resizeSourceImage(0.25);

fe.Orientations = [0, 90];
fe.setGaborFilters;
fe.extractOrientation;
fe.ColorFeatureImages{1} = fe.SourceImage(:,:,1);
fe.ColorFeatureImages{2} = fe.SourceImage(:,:,2);
fe.extractLuminance;

n_orientations = 2;
n_colors = 2;
n_luminances = 0;

height = size(fe.LuminanceFeatureImages{1}, 1);
width = size(fe.LuminanceFeatureImages{1}, 2);

% setting neural networks

n_features = n_orientations + n_colors;

layers = cell(1, n_features * 2 + 3);

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
for i = 1 : n_features
    if i <= n_orientations
        orientation_maps = [orientation_maps, layers{n_features + i}];
    elseif i <= (n_orientations + n_colors)
        color_maps = [color_maps, layers{n_features + i}];
    end
end
% conspicuity maps
layers{n_features * 2 + 1} = NeuralLayerClass(height, width, orientation_maps);
layers{n_features * 2 + 2} = NeuralLayerClass(height, width, color_maps);
conspicuity_maps = [layers{n_features * 2 + 1}, layers{n_features * 2 + 2}];
% saliency map
layers{n_features * 2 + 3} = NeuralLayerClass(height, width, conspicuity_maps);

% stimuli

stimuli = cell(1, n_features);
for i = 1 : n_orientations
    stimuli{i} = fe.OrientationFeatureImages{i} * 30;
end
for i = 1 : n_colors
    stimuli{n_orientations + i} = fe.ColorFeatureImages{i} * 30;
end

% parameters
for i = 1:length(layers)
    layers{i}.W_e = 5;
    layers{i}.W_i = 250;
    layers{i}.Sigma_e = 3.2;
    layers{i}.Sigma_i = 48;
    layers{i}.W_x_feedforward = [0.4, 0.25, 0.05] * 8^0.5;
    layers{i}.setLateralConnections;
    if i == length(layers)   % no lateral connections in saliency map in the Brecht-Saiki model
        layers{i}.LateralConnections = layers{i}.LateralConnections * 0;
    end
    layers{i}.setFeedforwardConnections;
    layers{i}.DescriptionForDebug = ['layer ', num2str(i)];
end

for i = 1:length(layers)
    layers{i}.BasalActivity = 0;
end

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

outputSaliencyMap = layers{end}.ActivityTimecourse{end};

end

