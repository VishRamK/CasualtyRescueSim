classdef Ambulance < Room % Inherit from Room
    properties
    end

    methods
        function obj = Ambulance(position, size)            
            % Call the Room constructor
            obj = obj@Room('Ambulance', position, size, []);
        end

        function draw(obj)
            % Draw the ambulance
            rectangle('Position', [obj.Position obj.Size(1) obj.Size(2)], 'FaceColor', obj.Color, 'EdgeColor', 'none');
            curIdx = obj.Position + [10 0];
            while curIdx(1) < obj.Position(1) + obj.Size(1)
                rectangle('Position', [curIdx, [10 obj.Size(2)]], 'FaceColor', 'r', 'EdgeColor', 'none');
                curIdx = curIdx + [20 0];
            end
        end
        
        function obj = addCasualty(obj, casualty)
            % Increment the number of rescued casualties
            obj.Casualties = [obj.Casualties casualty];
            casualty.Rescued = true;
        end
    end
end
