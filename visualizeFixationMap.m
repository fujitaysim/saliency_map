function [] = visualizeFixationMap(fixation_map)

% visualize a fixation map

figure
[row, col] = find(fixation_map);
plot(col, row, '.k')
xlim([0, size(fixation_map, 2)]);
ylim([0, size(fixation_map, 1)]);
set(gca, 'YDir','reverse')

end

