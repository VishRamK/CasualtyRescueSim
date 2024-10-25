classdef CasualtyObject < handle
    properties
        Room = []; % Room containing the casualty
        SeverityLevel % Severity level of the casualty
        Rescued = false % Whether the casualty is rescued
        Alive = true % Whether the casualty is alive
        Position % [x y] location of the casualty
        Size = 7
        OldPositions; % Previous 7 positions (Queue) + Current Position
        OldHeads;
        Points % Points awarded for rescuing this casualty
        Head = [0 1];
        Rep; % Handle to the sprite image object
    end

    methods
        function obj = CasualtyObject(SeverityLevel, Position, Room)
            % Constructor to initialize the Casualty object
            colors = ["#02BC2A", "#E1BB01", "#D87C04", "#BD1313"];
            obj.Room = Room;
            obj.SeverityLevel = SeverityLevel;
            obj.Points = SeverityLevel * 100;
            obj.Position = Position;
            obj.OldHeads = repmat(obj.Head, obj.Size, 1);
            obj.OldPositions = repmat(obj.Position, obj.Size, 1);
            obj.Rep = StickmanSprite(Position, obj.Size, colors(SeverityLevel), true);
            set(obj.Rep.Text, 'String', SeverityLevel);
            uistack(obj.Rep.Text, 'top');
        end

        function draw(obj)
            % Draw the casualty sprite at the current position
            obj.Rep.moveTo(obj.Position);
            %set(obj.hImage, 'XData', [obj.Position(1), obj.Position(1) + obj.Size], 'YData', [obj.Position(2), obj.Position(2) + obj.Size]);
        end

        function die(obj, time)
            % Check if the casualty dies based on time and severity
            global totalPoints;
            global pointsDisplay;
            if floor(time) > (480 / obj.SeverityLevel)
                obj.Alive = false;
                if ~obj.Rescued
                    totalPoints = totalPoints - obj.Points;
                    set(pointsDisplay, 'String', totalPoints);
                end
                obj.Rep.changeColor('k')
                set(obj.Rep.Text, 'String', 'x');
                if obj.Head(1) ~= 0
                    offset = 0.1*obj.Size;
                else
                    offset = 0;
                end
                new = obj.Head + [0 offset];
                set(obj.Rep.Text, 'Position', obj.Rep.Text.Position+[0.4*new, 0]);
            end
        end

        function turn(obj, newHead)
            if obj.Head(1) == -newHead(1) && obj.Head(2) == -newHead(2)
                obj.Rep.rotateStickman(1);
                obj.Rep.rotateStickman(1);
            elseif obj.Head ~= newHead
                if obj.Head(1) ~= 0 && newHead(2) ~= 0
                    if obj.Head(1) ~= newHead(2)
                        obj.Rep.rotateStickman(1);
                    else
                        obj.Rep.rotateStickman(-1);
                    end
                elseif obj.Head(2) ~= 0 && newHead(1) ~= 0
                    if obj.Head(2) == newHead(1)
                        obj.Rep.rotateStickman(1);
                    else
                        obj.Rep.rotateStickman(-1);
                    end
                end
            end
            obj.Head = newHead;
            if ~obj.Alive
                if obj.Head(1) ~= 0
                    offset = 0.1*obj.Size;
                else
                    offset = 0;
                end
                new = [0 offset];
                set(obj.Rep.Text, 'Position', obj.Rep.Text.Position+[new, 0]);
            end
            obj.OldHeads = circshift(obj.OldHeads, [-1 0]);
            obj.OldHeads(obj.Size, :) = obj.Head;
        end


        function goTo(obj, pos)
            obj.OldPositions = circshift(obj.OldPositions, [-1 0]);
            obj.OldPositions(obj.Size, :) = obj.Position;
            obj.Position = pos;
            obj.draw();
        end
    end
end
