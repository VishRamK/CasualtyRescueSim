classdef StickmanSprite < handle
    properties
        Position;    % Position of the stickman [x, y]
        Direction = [0 1];
        Size;        % Size of the stickman
        Color;       % Color of the stickman
        Head;        % Handle for the head
        Body;        % Handle for the body
        Text;
        Arms = gobjects(2,1);        % Handles for the arms
        Legs = gobjects(2,1);        % Handles for the legs
        Rep;
        Casualty;
    end
    
    methods
        % Constructor
        function obj = StickmanSprite(position, size, color, casualty)
            if nargin < 3
                color = 'k'; % Default color is black
            end
            if nargin < 2
                size = 10; % Default size
            end
            if nargin < 1
                position = [0, 0]; % Default position
            end
            obj.Rep = hggroup();
            obj.Position = position;
            obj.Size = size;
            obj.Color = color;
            obj.Casualty = casualty;
            obj.Text = text(obj.Position(1) + 0.3*obj.Size, obj.Position(2) + 0.45*obj.Size, 0, "", 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'w', 'Parent', obj.Rep);
            % Draw the stickman
            obj.draw();
        end
        
        % Draw the stickman
        function draw(obj)
            
            % Create the head, body, arms, and legs and assign them to the group     
            s = obj.Size;
            x = obj.Position(1) + 0.5*s;
            y = obj.Position(2) + 0.7*s;

            % Draw the head (circle)
            obj.Head = rectangle('Position', [x - 0.15*s, y, 0.3*s, 0.3*s], ...
                'Curvature', [1, 1], 'FaceColor', obj.Color, 'EdgeColor', 'none', 'Parent', obj.Rep);

            if obj.Casualty
                
                % Draw the body (rect)
                obj.Body = rectangle('Position', [x - 0.3*s, y - 0.6*s, 0.6*s, 0.6*s], 'FaceColor', obj.Color, 'EdgeColor', 'none', 'Parent', obj.Rep);
            
                % Draw the arms (lines)
                obj.Arms(1) = line('XData', [x - 0.5*s, x - 0.3*s], 'YData', [y - 0.2*s, y - 0.1*s], 'Color', obj.Color, 'LineWidth', 2, 'Parent', obj.Rep);
                obj.Arms(2) = line('XData', [x + 0.5*s, x + 0.3*s], 'YData', [y - 0.2*s, y - 0.1*s], 'Color', obj.Color, 'LineWidth', 2, 'Parent', obj.Rep);
                
                % Draw the legs (lines)
                obj.Legs(1) = line('XData', [x - 0.4*s, x - 0.2*s], 'YData', [y - 0.7*s, y - 0.6*s], 'Color', obj.Color, 'LineWidth', 2, 'Parent', obj.Rep);
                obj.Legs(2) = line('XData', [x + 0.4*s, x + 0.2*s], 'YData', [y - 0.7*s, y - 0.6*s], 'Color', obj.Color, 'LineWidth', 2, 'Parent', obj.Rep);
            else
            
                % Draw the body (line)
                obj.Body = line([x, x], [y - 0.4*s, y], 'Color', obj.Color, 'LineWidth', 2, 'Parent', obj.Rep);
                
                % Draw the arms (lines)
                obj.Arms(1) = line('XData', [x - 0.4*s, x], 'YData', [y - 0.2*s, y - 0.1*s], 'Color', obj.Color, 'LineWidth', 2, 'Parent', obj.Rep);
                obj.Arms(2) = line('XData', [x + 0.4*s, x], 'YData', [y - 0.2*s, y - 0.1*s], 'Color', obj.Color, 'LineWidth', 2, 'Parent', obj.Rep);
                
                % Draw the legs (lines)
                obj.Legs(1) = line('XData', [x - 0.4*s, x], 'YData', [y - 0.7*s, y - 0.4*s], 'Color', obj.Color, 'LineWidth', 2, 'Parent', obj.Rep);
                obj.Legs(2) = line('XData', [x + 0.4*s, x], 'YData', [y - 0.7*s, y - 0.4*s], 'Color', obj.Color, 'LineWidth', 2, 'Parent', obj.Rep);
            end
        end
        
        % Move the stickman
        function moveTo(obj, newPosition)
            dx = newPosition(1) - obj.Position(1);
            dy = newPosition(2) - obj.Position(2);
            
            % Update position
            obj.Position = newPosition;
            
            % Move head
            obj.Head.Position = obj.Head.Position + [dx, dy, 0, 0];
            
            % Move body
            if obj.Casualty
                obj.Body.Position = [obj.Body.Position(1) + dx, obj.Body.Position(2) + dy, 0.6*obj.Size, 0.6*obj.Size];
                obj.Text.Position = obj.Text.Position + [dx dy 0];
                uistack(obj.Text, 'top');
            else
                obj.Body.XData = obj.Body.XData + dx;
                obj.Body.YData = obj.Body.YData + dy;
            end
            
            % Move arms
            obj.Arms(1).XData = obj.Arms(1).XData + dx;
            obj.Arms(1).YData = obj.Arms(1).YData + dy;
            obj.Arms(2).XData = obj.Arms(2).XData + dx;
            obj.Arms(2).YData = obj.Arms(2).YData + dy;
            
            % Move legs
            obj.Legs(1).XData = obj.Legs(1).XData + dx;
            obj.Legs(1).YData = obj.Legs(1).YData + dy;
            obj.Legs(2).XData = obj.Legs(2).XData + dx;
            obj.Legs(2).YData = obj.Legs(2).YData + dy;
        end

        
        % Change the color of the stickman
        function changeColor(obj, newColor)
            obj.Color = newColor;
            obj.Head.FaceColor = newColor;
            obj.Head.EdgeColor = newColor;
            if obj.Casualty
                obj.Body.FaceColor = newColor;
            else
                obj.Body.Color = newColor;
            end
            obj.Arms(1).Color = newColor;
            obj.Arms(2).Color = newColor;
            obj.Legs(1).Color = newColor;
            obj.Legs(2).Color = newColor;
        end
        function rotateStickman(obj, dir)            
            % Rotation matrix for rotation
            s = obj.Size;
            R = dir * [0 1; -1 0];
            obj.Direction = obj.Direction * -R;
            % Calculate new relative position for the text based on the direction
            if obj.Direction(1) == 1
                newTxt = [0.2*s, 0.5*s];  % Text offset when facing right
            elseif obj.Direction(1) == -1
                newTxt = [0.4*s, 0.5*s];  % Text offset when facing left
            elseif obj.Direction(2) == 1
                newTxt = [0.45*s, 0.3*s];  % Text offset when facing up
            elseif obj.Direction(2) == -1
                newTxt = [0.3*s, 0.6*s];  % Text offset when facing down
            end
            newTxtPos = obj.Position + newTxt;
            % Calculate the centroid of the stickman
            allX = [];
            allY = [];
            
            for i = 1:length(obj.Rep.Children)
                h = obj.Rep.Children(i);
                if strcmp(h.Type, 'line')
                    allX = [allX, get(h, 'XData')];
                    allY = [allY, get(h, 'YData')];
                elseif strcmp(h.Type, 'rectangle')
                    pos = get(h, 'Position');
                    corners = [pos(1), pos(2); 
                               pos(1) + pos(3), pos(2); 
                               pos(1), pos(2) + pos(4); 
                               pos(1) + pos(3), pos(2) + pos(4)];
                    allX = [allX, corners(:, 1)'];
                    allY = [allY, corners(:, 2)'];
                elseif strcmp(h.Type, 'text')
                    % For text, just add the position directly
                    pos = get(h, 'Position');
                    allX = [allX, pos(1)];
                    allY = [allY, pos(2)];
                end
            end
            
            % Centroid of the stickman
            centerX = mean(allX);
            centerY = mean(allY);
            
            % Loop through all parts (children) of the stickman
            for i = 1:length(obj.Rep.Children)
                h = obj.Rep.Children(i);
                
                if strcmp(h.Type, 'line')
                    % Get line coordinates
                    xData = get(h, 'XData');
                    yData = get(h, 'YData');
                    
                    % Center the line coordinates around the origin
                    centeredCoords = [xData - centerX; yData - centerY];
                    
                    % Apply rotation
                    rotatedCoords = R * centeredCoords;
                    
                    % Translate back to the original center
                    set(h, 'XData', rotatedCoords(1, :) + centerX);
                    set(h, 'YData', rotatedCoords(2, :) + centerY);

                elseif strcmp(h.Type, 'text')
                    % Handle text movement without rotation
                    pos = get(h, 'Position');
                    
                    % Set the new position without altering rotation
                    set(h, 'Position', [newTxtPos, 0]);
                    
                elseif strcmp(h.Type, 'rectangle')
                    % Get rectangle position
                    pos = get(h, 'Position');
                    
                    % Calculate rectangle corners
                    corners = [pos(1), pos(2); 
                               pos(1) + pos(3), pos(2); 
                               pos(1), pos(2) + pos(4); 
                               pos(1) + pos(3), pos(2) + pos(4)];
                           
                    % Center the rectangle corners around the origin
                    centeredCorners = corners - [centerX, centerY];
                    
                    % Apply rotation
                    rotatedCorners = (R * centeredCorners')';
                    
                    % Translate back to the original center
                    rotatedCorners = rotatedCorners + [centerX, centerY];
                    
                    % Determine new position
                    minX = min(rotatedCorners(:, 1));
                    minY = min(rotatedCorners(:, 2));
                    maxX = max(rotatedCorners(:, 1));
                    maxY = max(rotatedCorners(:, 2));
                    newPos = [minX, minY, maxX - minX, maxY - minY];
                    
                    % Set the new position
                    set(h, 'Position', newPos);
                end
            end
        end
    end
end
