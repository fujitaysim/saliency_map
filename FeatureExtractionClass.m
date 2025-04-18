classdef FeatureExtractionClass < handle
  
    properties
        SourceImage
        ScaledImages
        GaborFilters
        SpatialAspectRatio
        SigmaOfGabor
        FrequencyOfGabor
        Orientations
        ColorFeatureImages
        LuminanceFeatureImages
        OrientationFeatureImages
    end
    
    methods(Static)
        function output = getIntensity(image)
            output = mean(image, 3);
        end
        
        function output = attenuateBorders(image, bordersize)
          % attenuate values in areas near each border
            img = image;
            border_coeffs = [1:bordersize] / (bordersize + 1);
            border_range_right = size(img,2) - bordersize + 1 : size(img,2);
            border_range_bottom = size(img,1) - bordersize + 1 : size(img,1);
            for y = 1:size(img,1)  % attenuate left and right borders
                img(y, 1:bordersize) = img(y, 1:bordersize) .* border_coeffs;
                img(y, border_range_right) = img(y, border_range_right) .* flip(border_coeffs);
            end
            for x = 1:size(img,2)  % attenuate top and bottom borders
                img(1:bordersize, x) = img(1:bordersize, x) .* border_coeffs';
                img(border_range_bottom, x) = img(border_range_bottom, x) .* flip(border_coeffs');
            end
            output = img;
        end
        
    end
    
    methods
        function obj = FeatureExtractionClass(source_image)
            % Create an instance of this class
            obj.setSourceImage(source_image);
            obj.prepareScaledImages(1);
            obj.Orientations = [0, 45, 90, 135];
            obj.SpatialAspectRatio = 0.5;
            obj.SigmaOfGabor = 2;
            obj.FrequencyOfGabor = 2;
            obj.setGaborFilters;
        end
        
        function setSourceImage(obj, source_image)
            img = source_image;
            img(img < 0) = 0;      % applying imresize to double type matrix can cause negative value
            if isa(img, 'uint8')
                img = double(img)/255;
            end
            if size(img, 3) == 1
                img = cat(3, img,img,img);   % change grayscale image to RGB
            end
            obj.SourceImage = img;
            obj.ColorFeatureImages = cell(0);
            obj.LuminanceFeatureImages = cell(0);
            obj.OrientationFeatureImages = cell(0);
        end
        
        function resizeSourceImage(obj, scale)
            resized_img = imresize(obj.SourceImage, scale);
            resized_img(resized_img < 0) = 0;   % applying imresize to double type matrix can cause negative value
            obj.setSourceImage(resized_img);
        end
        
        function prepareScaledImages(obj, scale_array)
            obj.ScaledImages = cell(1, length(scale_array));
            for i = 1:length(scale_array)
                resized_img = imresize(obj.SourceImage, scale_array(i));
                resized_img(resized_img < 0) = 0;   % applying imresize to double type matrix can cause negative value
                obj.ScaledImages{i} = resized_img;
            end
        end
        
        function setGaborFilters(obj)
            x_range = -27:27;
            y_range = flip(-27:27);
            gamma = obj.SpatialAspectRatio;
            sigma = obj.SigmaOfGabor;
            omega = obj.FrequencyOfGabor;
            for k = 1:length(obj.Orientations)
                theta = obj.Orientations(k) * pi/180;
                gabor_matrix = zeros(length(y_range), length(x_range));
                for row = 1:length(y_range)
                    for col = 1:length(x_range)
                        y = y_range(row);
                        x = x_range(col);
                        rx = x * cos(theta) + y * sin(theta);
                        ry = -x * sin(theta) + y * cos(theta);
                        gaussian_factor = exp(-(rx^2 + (gamma*ry)^2) / (2 * sigma^2));
                        sinusoidal_factor = exp(1i * omega * rx);  % complex number
                        gabor_matrix(row,col) = gaussian_factor * sinusoidal_factor;
                    end
                end
                obj.GaborFilters{k} = gabor_matrix;
            end
        end
        
        function extractLuminance(obj)
            obj.LuminanceFeatureImages{1} = obj.getIntensity(obj.SourceImage);
        end
        
        function extractColor(obj)
                image_R = obj.SourceImage(:,:,1);
                image_G = obj.SourceImage(:,:,2);
                image_B = obj.SourceImage(:,:,3);
                image_I = obj.getIntensity(obj.SourceImage);
                % Blue-Yellow
                B_Y = max(0, image_B - min(image_R,image_G)) ./ image_I;
                B_Y(image_I == 0) = 0;
                obj.ColorFeatureImages{1} = B_Y;
                % Yellow-Blue
                Y_B = max(0, min(image_R,image_G) - image_B) ./ image_I;
                Y_B(image_I == 0) = 0;
                obj.ColorFeatureImages{2} = Y_B;
                % Red-Green
                R_G = max(0, image_R - image_G) ./ image_I;
                R_G(image_I == 0) = 0;
                obj.ColorFeatureImages{3} = R_G;
                % Green-Red
                G_R = max(0, image_G - image_R) ./ image_I;
                G_R(image_I == 0) = 0;
                obj.ColorFeatureImages{4} = G_R;
        end
        
        function extractOrientation(obj)
            for i = 1:length(obj.Orientations)
                filtered_image_array = zeros(size(obj.SourceImage, 1), size(obj.SourceImage, 2), length(obj.ScaledImages));
                for j = 1:length(obj.ScaledImages)
                    % get intensity image for each resolutions
                    img = obj.getIntensity(obj.ScaledImages{j});
                    % extend the borders of image to reduce extracting orientation at borders
                    ext = 30;
                    extended_img = [repmat(img(1,1),ext), repmat(img(1,:),ext,1), repmat(img(1,end),ext); ...
                                    repmat(img(:,1),1,ext), img, repmat(img(:,end),1,ext); ...
                                    repmat(img(end,1),ext), repmat(img(end,:),ext,1), repmat(img(end,end),ext)];
                    % use Gabor filter
                    filtered_image_complex_number = conv2(extended_img, obj.GaborFilters{i}, "same");
                    filtered_image = abs(filtered_image_complex_number);
                    % restore image size
                    filtered_image = filtered_image(ext+1:ext+size(img,1), ext+1:ext+size(img,2));
                    % attenuate values in areas near each border
                    border_size = floor((size(img,1)+size(img,2))/20);
                    img = obj.attenuateBorders(filtered_image, border_size);
                    % resize images into the size of SourceImage
                    filtered_image_array(:,:,j) = imresize(img, [size(obj.SourceImage, 1), NaN]);
                end
                obj.OrientationFeatureImages{i} = mean(filtered_image_array, 3);
            end
        end
        
        function visualizeFeatures(obj)
            cols = max([length(obj.ColorFeatureImages), length(obj.LuminanceFeatureImages), length(obj.OrientationFeatureImages)]);
            figure
            for i = 1:length(obj.ColorFeatureImages)
                subplot(3, cols, i), imshow(obj.ColorFeatureImages{i}, [0 1])
            end
            for i = 1:length(obj.LuminanceFeatureImages)
                subplot(3, cols, cols + i), imshow(obj.LuminanceFeatureImages{i}, [0 1])
            end
            for i = 1:length(obj.OrientationFeatureImages)
                subplot(3, cols, cols * 2 + i), imshow(obj.OrientationFeatureImages{i}, [0 1])
            end
        end
        
    end
end

