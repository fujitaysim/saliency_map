classdef NeuralLayerClass < handle
    
    properties
        DescriptionForDebug = '' % not necessary
        Height
        Width
        PreviousLayers   % array of NeuralLayerClass instance
        W_e = 2 % constant in the difference-of-Gaussians for lateral connections
        W_i = 180 % constant in the difference-of-Gaussians for lateral connections
        Sigma_e = 3.2 % constant in the difference-of-Gaussians for lateral connections
        Sigma_i = 48 % constant in the difference-of-Gaussians for lateral connections
        tau = 30/1000 % time constant for delta activity
        U_SE_L = 0.5 % synaptic efficacy parameters for lateral connections
        U_SE_I = 0.5 % synaptic efficacy parameters for feedforward connections
        tau_rec_L = 100/1000 % time constant of recovery for lateral connections
        tau_rec_I = 50/1000 % time constant of recovery for feedforward connections
        W_x_feedforward = [1.12, 0.7, 0.14] % function used for setting feedforward connections
        LateralConnections
        FeedforwardConnections
        BasalActivity
        Activity
        ActivityTimecourse
        DepressingEffectsOfLateral
        DepressingEffectsOfInputs
        TimePoint
    end
    
    methods(Static)
        function output = differenceOfGaussians(we, wi, sigma_e, sigma_i, x)
            output = we/(2*pi*sigma_e^2) * exp(-x.^2/(2*sigma_e^2)) - wi/(2*pi*sigma_i^2) * exp(-x.^2/(2*sigma_i^2));
        end
        
    end
    
    methods
        function obj = NeuralLayerClass(height, width, previous_layers)
            % Create an instance of this class
            % set previous_layers as [layer1, layer2, ...]
            % if this layer does not have previous layers, set as [].
            obj.Height = height;
            obj.Width = width;
            if isempty(previous_layers) == false
                for i = 1:length(previous_layers)
                    obj.PreviousLayers{i} = previous_layers(i);
                    obj.DepressingEffectsOfInputs{i} = zeros(previous_layers(i).Height, previous_layers(i).Width);
                end
            end
            obj.BasalActivity = 0;
            obj.Activity = zeros(height, width);
            obj.DepressingEffectsOfLateral = zeros(height, width);
            obj.TimePoint = 0;
        end
        
        function setLateralConnections(obj)
            H = obj.Height;
            W = obj.Width;
            % set the weight matrix of lateral connections
            obj.LateralConnections = zeros(H*2-1, W*2-1);
            for y = 1:H*2-1
                for x = 1:W*2-1
                    distance_temp = ((y-H)^2 + (x-W)^2)^0.5;
                    obj.LateralConnections(y,x) = obj.differenceOfGaussians(obj.W_e, obj.W_i, obj.Sigma_e, obj.Sigma_i, distance_temp);
                end
            end
        end
        
        function setLateralConnectionsWithRandomLoss(obj, fraction_of_loss)
            H = obj.Height;
            W = obj.Width;
            % set the weight matrix of lateral connections
            obj.LateralConnections = zeros(H*2-1, W*2-1);
            for y = 1:H*2-1
                for x = 1:W*2-1
                    distance_temp = ((y-H)^2 + (x-W)^2)^0.5;
                    if rand(1) > fraction_of_loss
                        obj.LateralConnections(y,x) = obj.differenceOfGaussians(obj.W_e, obj.W_i, obj.Sigma_e, obj.Sigma_i, distance_temp);
                    end
                end
            end
        end
        
        function visualizeLateralConnections(obj)
            L = obj.Width;
            figure, plot(0:L-1, obj.LateralConnections(L, L:end))
            hold on
            plot(0:L-1, zeros(1,L),'Color',[0.5 0.5 0.5])
            hold off
            set(gca,'FontSize',11);
            xlim([0 L-1]);
        end
        
        function setFeedforwardConnections(obj)
            H = obj.Height;
            W = obj.Width;
            obj.FeedforwardConnections = zeros(H*2-1, W*2-1);
            weight_vector = [flip(obj.W_x_feedforward(2:end)), obj.W_x_feedforward];  % e.g. [0.4 0.25 0.05] -> [0.05 0.25 0.4 0.25 0.05]
            obj.FeedforwardConnections(H-2:H+2,W-2:W+2) = weight_vector' * weight_vector;
        end
        
        function updateDepressingEffects(obj)
            delta_depressing_effects_lateral = - obj.U_SE_L * obj.Activity .* obj.DepressingEffectsOfLateral + (1 - obj.DepressingEffectsOfLateral)/obj.tau_rec_L;
            obj.DepressingEffectsOfLateral = obj.DepressingEffectsOfLateral + delta_depressing_effects_lateral / 1000;
            if isempty(obj.PreviousLayers) == false
                for i = 1:length(obj.PreviousLayers)
                    delta_depressing_effects_input = - obj.U_SE_I * obj.PreviousLayers{i}.Activity .* obj.DepressingEffectsOfInputs{i} + (1 - obj.DepressingEffectsOfInputs{i})/obj.tau_rec_I;
                    obj.DepressingEffectsOfInputs{i} = obj.DepressingEffectsOfInputs{i} + delta_depressing_effects_input / 1000;
                end
            end
        end
        
        function updateActivity(obj)
            if isempty(obj.PreviousLayers) == false
                signal = zeros(obj.Height, obj.Width);
                signal = signal + obj.U_SE_L * conv2(obj.DepressingEffectsOfLateral .* obj.Activity, obj.LateralConnections,'same');
                for i = 1:length(obj.PreviousLayers)
                    signal = signal + obj.U_SE_I * conv2(obj.DepressingEffectsOfInputs{i} .* obj.PreviousLayers{i}.Activity, obj.FeedforwardConnections, 'same');
                end
                delta_activity = (1/obj.tau) * (- obj.Activity + obj.BasalActivity + 0.5 * max(0, signal));
                obj.Activity = obj.Activity + delta_activity / 1000;
            end
        end
        
    end
end

