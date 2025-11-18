% Script for modeling and simulations presented in Fujita Y. et al. 2025.
% (https://doi.org/10.3389/fnins.2025.1614468)

function [] = visualizeFixationMap(fixation_map)

% visualize a fixation map

figure
[row, col] = find(fixation_map);
plot(col, row, '.k')
xlim([0, size(fixation_map, 2)]);
ylim([0, size(fixation_map, 1)]);
set(gca, 'YDir','reverse')

end

