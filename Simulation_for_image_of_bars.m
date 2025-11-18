% Script for modeling and simulations presented in Fujita Y. et al. 2025.
% (https://doi.org/10.3389/fnins.2025.1614468)

% Simulation with visual stimulus of red and blue bars
% Plotting average activity of neural populations for the area of each bar

% making the image of bars
bars_array = {'vertical', 'red', [7,27];
                 'horizontal', 'blue', [12,40];
                 'horizontal', 'blue', [7,61];
                 'horizontal', 'blue', [18,64];
                 'horizontal', 'blue', [23,37];
                 'horizontal', 'blue', [32,21];
                 'horizontal', 'blue', [31,62];
                 'horizontal', 'blue', [38,42];
                 'horizontal', 'blue', [45,23];
                 'horizontal', 'blue', [45,65];};
             
visual_stimuli = uint8(zeros(54, 96, 3) + 30);

for j = 1:size(bars_array, 1)
    bars_temp = bars_array;
    y = bars_temp{j,3}(1);
    x = bars_temp{j,3}(2);
    if strcmp(bars_temp{j,1}, 'horizontal')
        bar_position_y = y:y+1;
        bar_position_x = x:x+14;
    elseif strcmp(bars_temp{j,1}, 'vertical')
        bar_position_y = y:y+14;
        bar_position_x = x:x+1;
    end
    if strcmp(bars_temp{j,2}, 'red')
        visual_stimuli(bar_position_y, bar_position_x, 1) = 255;
        visual_stimuli(bar_position_y, bar_position_x, 2) = 60;
        visual_stimuli(bar_position_y, bar_position_x, 3) = 60;
    elseif strcmp(bars_temp{j,2}, 'blue')
        visual_stimuli(bar_position_y, bar_position_x, 1) = 60;
        visual_stimuli(bar_position_y, bar_position_x, 2) = 60;
        visual_stimuli(bar_position_y, bar_position_x, 3) = 255;
    end
end

visual_stimuli = imresize(visual_stimuli, 4);
image_uint8 = uint8(imgaussfilt(visual_stimuli, 1));

%%

fe = FeatureExtractionClass(image_uint8);

fe.prepareScaledImages([1 0.5 0.25]);

fe.resizeSourceImage(0.25);

fe.extractLuminance;
fe.extractOrientation;
fe.extractColor;

n_orientations = 4;
n_colors = 4;
n_luminances = 1;

% fe.visualizeFeatures

height = size(fe.LuminanceFeatureImages{1}, 1);
width = size(fe.LuminanceFeatureImages{1}, 2);

%%

% setting neural networks

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

% stimuli

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

% parameters
for i = 1:length(layers)
    layers{i}.W_e = 2;
    layers{i}.W_i = 140;
    layers{i}.Sigma_e = 3.2;
    layers{i}.Sigma_i = layers{i}.Sigma_e * 15;
    
    layers{i}.setLateralConnections;
    layers{i}.setFeedforwardConnections;
    layers{i}.DescriptionForDebug = ['layer ', num2str(i)];
end

for i = 1:length(layers)
    layers{i}.BasalActivity = 0;
end

%%

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

%%
% plot the lateral connection weights

figure, plot(0:width-1, layers{1}.LateralConnections(height, width:end))
hold on
plot(0:width-1, zeros(1,width),'Color',[0.5 0.5 0.5])
hold off
set(gca,'FontSize',11);
xlim([0 width-1]);

%%

% visualize activity of each layer (heatmap)

r = 5;
c = max([3, n_orientations, n_colors, n_luminances]);

figure

% feature maps
for i = 1 : n_features
    if i <= n_orientations
        subplot(r,c,i);
        imagesc(double(layers{n_features+i}.ActivityTimecourse{max(t_range)}));colorbar;
    elseif i <= (n_orientations + n_colors)
        subplot(r,c,c+i-n_orientations);
        imagesc(double(layers{n_features+i}.ActivityTimecourse{max(t_range)}));colorbar;
    else
        subplot(r,c,c*2+i-n_orientations-n_colors);
        imagesc(double(layers{n_features+i}.ActivityTimecourse{max(t_range)}));colorbar;
    end
end

% conspicuity maps
subplot(r,c,c*3+1), imagesc(double(layers{n_features*2+1}.ActivityTimecourse{max(t_range)}));colorbar;
subplot(r,c,c*3+2), imagesc(double(layers{n_features*2+2}.ActivityTimecourse{max(t_range)}));colorbar;
subplot(r,c,c*3+3), imagesc(double(layers{n_features*2+3}.ActivityTimecourse{max(t_range)}));colorbar;

% source image, sliency map, normalized saliency map
subplot(r,c,c*4+1), imshow(double(fe.SourceImage)/ max(max(max(fe.SourceImage))));
saliency_map = layers{n_features*2+4}.ActivityTimecourse{max(t_range)};
subplot(r,c,c*4+2), imagesc(double(saliency_map));colorbar;
subplot(r,c,c*4+3), imagesc(double((saliency_map - mean(saliency_map(:)))/std(saliency_map(:))));colorbar;

%%

figure, imshow(double(fe.SourceImage)/ max(max(max(fe.SourceImage))));

%%
% get timecourse of activities and depressing effects
% in the area of each bar

bars_temp = bars_array;
number_of_bars = size(bars_temp, 1);

for map = subsequent_layer_indices
    
    for j = 1:number_of_bars
        
        y = bars_temp{j,3}(1);
        x = bars_temp{j,3}(2);
        if strcmp(bars_temp{j,1}, 'horizontal')
            bar_position_y = y:y+1;
            bar_position_x = x:x+14;
        elseif strcmp(bars_temp{j,1}, 'vertical')
            bar_position_y = y:y+14;
            bar_position_x = x:x+1;
        end
        
        for t = 1:max(t_range)
            activity_timecourse_bar{map, j}(t) = mean(mean(layers{map}.ActivityTimecourse{t}(bar_position_y, bar_position_x)));
        end
    end
    
end

%%

% plot acitivity for a specified map

figure

t_range_for_plot = t_range - time_to_present_stimulus;
          
for map = 22
    
    plot(t_range_for_plot, activity_timecourse_bar{map, 1},'Color',[1 0 0]);
    hold on
    for j = 2:number_of_bars
        plot(t_range_for_plot, activity_timecourse_bar{map, j},'Color',[0.3 0.3 0.6]);
    end
    hold off
    set(gca,'FontSize',12);
    xlim([-100 max(t_range_for_plot)]);
% xlabel('Timepoint');
% ylabel('Activity');

end