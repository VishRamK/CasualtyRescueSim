classdef Room < handle
    properties
        RoomID; % Name of the Room
        Position; % [x y] location of the room
        WallThickness = 3;
        Color = '#7F7F7F'; % Default color of the room
        Size; % Size of the room
        Players = []; % Players in the Room
        Casualty; % List of casualty objects in the room
        Colliding = 0;
        IsOpen = false; % Whether the room is open
        Thickness = 3;
        DoorSize;
        DoorPos;
        Door;
        RoomBox
        CasualtySize = 7
        CasualtyPos;
    end

    methods
        function obj = Room(id, position, size, casualties)
            obj.RoomID = id;
            obj.Position = position;
            obj.Size = size;
            obj.Casualty = casualties;
            obj.DoorSize = [12 obj.Thickness];
            obj.DoorPos = [(obj.Position(1) + (obj.Size(1) - obj.DoorSize(1))*0.5), obj.Position(2)];
            obj.CasualtyPos = position + [12, 13];
            obj.RoomBox = rectangle('Position', [obj.Position obj.Size(1) obj.Size(2)], 'FaceColor', obj.Color, 'EdgeColor', 'none');
            obj.Door = rectangle('Position', [obj.DoorPos, obj.DoorSize], 'FaceColor', '#CCADDB', 'EdgeColor', 'none');
        end
        
        function draw(obj)            
            % Draw the door
            uistack(obj.Door, 'top');
        end
        
        function drawInterior(obj)
            global player;
            global AIplayer1;
            % Draw the room's interior
            intSize = obj.Size - 2*[obj.Thickness obj.Thickness];
            intPos = obj.Position + [obj.Thickness obj.Thickness];
            rectangle('Position', [intPos, intSize], 'FaceColor', 'w', 'EdgeColor', 'none');
            % Draws whitespace on the previous door
            rectangle('Position', [obj.DoorPos, obj.DoorSize], 'FaceColor', '#FFFFFF', 'EdgeColor', 'none');
            % Draws an open door
            uistack(obj.Door, 'bottom');
            
            if ~isempty(obj.Casualty)
                uistack(obj.Casualty(1).Rep.Rep, 'top');
            end
            uistack(player.Rep.Rep, 'top');
            uistack(AIplayer1.Rep.Rep, 'top');
        end
        
        function isColliding = detectCollision(obj, player)
            % Collision detection between player and room
            % Check if player is within the room bounds (inside or at the door)
            isColliding = player.Position(1) >= obj.Position(1) - player.Size && ...
                          player.Position(1) <= obj.Position(1) + obj.Size(1) && ...
                          player.Position(2) >= obj.Position(2) - player.Size && ...
                          player.Position(2) <= obj.Position(2) + obj.Size(2);
        end

        function open(obj, player)
            if ~obj.IsOpen && obj.detectCollision(player)
                if (player.Position(2) == obj.DoorPos(2) - player.Size) &&...
                    (player.Position(1) >= obj.DoorPos(1)) &&...
                    (player.Position(1) <= obj.DoorPos(1) + obj.DoorSize(1) - player.Size)
                    obj.drawInterior();
                    obj.Players = [obj.Players, player];
                    obj.IsOpen = true;   
                end
            end
        end

        function close(obj)
            if obj.IsOpen 
                obj.Players = [];
                obj.draw();
                obj.IsOpen = false;
            end
        end
        
        function insideRoom = inRoom(obj, player)
            % Check if the player is inside the room
            insideRoom = obj.detectCollision(player);
        end
        
        function isFull = checkFull(obj)
            % Check if the room is full (based on some criteria, not implemented)
            isFull = false; % Placeholder implementation
        end
        
        function removeCasualty(obj)
            % Remove a casualty by ID
            if ~isempty(obj.Casualty)
                obj.Casualty = [];
            end
        end
        
        function obj = addCasualty(obj, casualtyID)
            % Add a casualty to the room
            if isempty(obj.Casualty)
                obj.Casualty = [obj.Casualty, casualtyID];
            end
        end
    end
end
