classdef PlayerObject < handle
    properties
        PlayerID; % Name of Player for reference
        IsAI; % If true, player is an AI agent. Otherwise player is human-controlled
        Position = [60 -30]; % Player's initial [x y] location on the map
        Head = [0 1]; % Player facing direction
        Rep;
        Size = 7;
        StepSize = 1;
        OldPositions; % Previous 5 positions (Queue) + Current Position
        OldHeads;
        Casualty = []; % Whether or not player is carrying a casualty
        RoomSpace;
        Room = 0;
        Jump = 0;
        Path;
        Target;
    end

    methods
        function obj = PlayerObject(Position, IsAI, RoomSpace)
            % Constructor to initialize the Player object
            obj.Position = Position;
            if ~IsAI
                color = 'b';
            else
                color = '#006F8F';
            end
            obj.Rep = StickmanSprite(obj.Position, obj.Size, color, false);
            obj.OldHeads = repmat(obj.Head, obj.Size, 1);
            obj.OldPositions = repmat(obj.Position, obj.Size, 1);
            obj.RoomSpace = RoomSpace;
            obj.IsAI = IsAI;
        end

        function draw(obj)
            obj.Rep.moveTo(obj.Position);
        end

        function controls(obj, axes)
            if ~obj.IsAI
                absX = abs(axes(1));
                absY = abs(axes(2));
                obj.Head = [(absX >= absY)*sign(axes(1)), (absY > absX)*sign(-axes(2))];
                % Update the player's position if it's not colliding
                obj.OldHeads = circshift(obj.OldHeads, [-1 0]);
                obj.OldHeads(obj.Size, :) = obj.Head;
                newPos = obj.Position + obj.Head;
                if ~isempty(obj.Casualty)
                    obj.Casualty.turn(obj.OldHeads(1, :));
                end
                if ~obj.isColliding(newPos)
                    obj.OldPositions = circshift(obj.OldPositions, [-1 0]);
                    obj.OldPositions(obj.Size, :) = obj.Position;
                    obj.Position = newPos;
                    if ~isempty(obj.Casualty)
                        obj.Casualty.goTo(obj.OldPositions(1, :));
                    end
                    obj.draw();
                end
            end
        end

        function follow(obj, casualty)
            obj.Path = [];
            obj.Position = casualty.OldPositions(1, :);
            obj.Head = casualty.OldHeads(1, :);
            obj.draw();
        end

        function pickUp(obj, casualty)
            global AIplayer1;
            if isempty(obj.Casualty) && ...
                    abs(AIplayer1.Position(1) - casualty.Position(1)) == obj.Size && ...
                    AIplayer1.Position(2) == casualty.Position(2)
                obj.Casualty = casualty;
                AIplayer1.Casualty = casualty;
                obj.Casualty.turn(obj.Head);
                shift = AIplayer1.Position(1) - casualty.Position(1);
                for i = 1:obj.Size-1
                    casualty.OldPositions(i, :) = casualty.OldPositions(obj.Size, :) + [(obj.Size-i)*sign(shift) 0];
                    casualty.OldHeads(i, :) = casualty.OldHeads(obj.Size, :);
                end
            end
        end

        function inRoom(obj, room)
            obj.Room = room;
        end

        function drop(obj)
            global rooms;
            global ambulance;
            if ~isempty(obj.Casualty)
                if obj.Room ~= 0
                    casPos = [rooms(obj.Room).CasualtyPos, rooms(obj.Room).CasualtyPos + [obj.Size obj.Size]];
                    if ~obj.collides(casPos, obj.Position) 
                        obj.Casualty.goTo(rooms(obj.Room).CasualtyPos);
                        obj.Casualty.turn([-1 0]);
                    end
                else
                    if obj.contains([ambulance.Position ambulance.Position+ambulance.Size], obj.Casualty.Position)
                        obj.Casualty.Rescued = true;
                    end
                    uistack(obj.Casualty.Rep.Rep, 'bottom');
                    obj.Casualty.die(480);
                end       
                obj.Casualty = [];
            end
        end

        function algLevel1(obj, ysig, dir)
            global wait;
            global gridBoundaries;
            % AI logic for determining and executing actions
            if ~obj.IsAI
                return;
            end
            if ysig && ~isempty(obj.Path)
                if ~wait
                    obj.Position = obj.Position + obj.Path(1, :);
                    obj.Path(1,:) = [0 0];
                    obj.Path = circshift(obj.Path, [-1 0]);
                end
            elseif ~isempty(obj.Casualty)
                obj.follow(obj.Casualty)
            else
                obj.Path = [];
                if ~obj.contains((gridBoundaries+[1 1 -1 -1]), obj.Position) ||...
                        obj.contains((gridBoundaries+[2 2 -2 -2]), obj.Position)
                    if ~wait
                        obj.ret();
                    end
                else
                    rotation = dir*[0 -1; 1 0];
        
                    if obj.isColliding(obj.Position + 2*obj.Head)
                        obj.Head = obj.Head * rotation;
                    else
                        obj.Position = obj.Position + obj.Head;
                    end
                end
            end
            % Update position and redraw
            if ~isempty(obj.Target) && obj.Position(1) == obj.Target(1) && obj.Position(2) == obj.Target(2)
                obj.Target = [];
            end
            obj.draw();
        end

        function dist = distance(obj, loc)
            delta = loc - obj.Position;
            dist = sqrt(dot(delta, delta));
        end

        function path = pathfinder(obj, loc, dir, casPos) 
            global len;
            global width
            global roomSize;
            global spacing;
            currentPos = obj.Position;
            steps = loc-currentPos;
            path = zeros((roomSize+spacing)*len*width, 2);
            if steps(1) < 0
                steps(1) = steps(1)+20;
            else
                steps(1) = steps(1)-19;
            end
            if obj.isColliding(currentPos+[2 1]) || obj.isColliding(currentPos+[-2 1]) || ...
                    obj.isColliding(currentPos+[2 -1]) || obj.isColliding(currentPos+[-2 -1])
                dir1 = 2;
                dir2 = 1;
            else
                dir1 = 1;
                dir2 = 2;
            end
            sgnMatrix = [(dir2>dir1), (dir1>dir2);(dir1>dir2), (dir2>dir1)];
            i = 1;
            counter = 1;
            if steps(dir1) ~= 0
                while counter <= abs(steps(dir1))
                    path(i, :) = [sign(steps(dir1)), 0]*sgnMatrix;
                    counter = counter + 1;
                    i = i + 1;
                end
            end
            currentPos = currentPos + [steps(dir1), 0]*sgnMatrix;
            counter = 1;
            if steps(dir2) ~= 0
                while counter <= abs(steps(dir2))
                    path(i, :) = [0, sign(steps(dir2))]*sgnMatrix;
                    counter = counter + 1;
                    i = i + 1;
                end
            end
            currentPos = currentPos + [0, steps(dir2)]*sgnMatrix;
            remaining = loc(1)-currentPos(1);
            counter = 1;
            while counter <= abs(remaining)
                path(i, :) = [sign(remaining), 0];
                counter = counter + 1;
                i = i + 1;
            end
            approach = obj.enterRoom(dir, casPos, loc);
            path(i:i+length(approach)-1, :) = approach;
        end

        function enter = enterRoom(obj, dir, casPos, loc)
            global roomSize
            enter = zeros(roomSize*roomSize, 2);
            i = 1;
            currentPos = loc;
            while currentPos(2) ~= casPos(2)-obj.Size
                enter(i, :) = [0, 1];
                currentPos = currentPos + [0 1];
                i = i + 1;
            end
            while currentPos(1) ~= casPos(1) + dir*obj.Size
                enter(i, :) = [dir, 0];
                currentPos = currentPos + [dir 0];
                i = i + 1;
            end
            while currentPos(2) ~= casPos(2)
                enter(i, :) = [0, 1];
                currentPos = currentPos + [0 1];
                i = i + 1;
            end
        end

        function ret(obj)
            global gridBoundaries;
            global entrances;
            global spacing;
            if ~obj.contains((gridBoundaries+[1 1 -1 -1]), obj.Position)
                if isempty(obj.Target)
                    obj.Head = [-1 0];
                    t1 = entrances(1, 1:2)+[1 spacing+obj.Size+1];
                    t2 = entrances(2, 1:2)+[1 spacing+obj.Size+1];
                    if obj.distance(t1) < obj.distance(t2)
                        obj.Target = t1;
                    else
                        obj.Target = t2;
                    end
                end
                vert = obj.Target(2) - obj.Position(2);
                hor = obj.Target(1) - obj.Position(1);
                
                if hor
                    obj.Position = obj.Position + [sign(hor), 0];
                else
                    obj.Position = obj.Position + [0, sign(vert)];
                end
            else
                if isempty(obj.Target)
                    targ1 = gridBoundaries(1)+1;
                    targ2 = gridBoundaries(2)+1;
                    targ3 = gridBoundaries(3)-spacing+1;
                    targ4 = gridBoundaries(4)-spacing+1;
                    x = obj.Position(1);
                    y = obj.Position(2);
                    dHor = min(abs(targ1-x), abs(targ3-x));
                    dVer = min(abs(targ2-y), abs(targ4-y));
                    if obj.isColliding(obj.Position+[2 1]) || obj.isColliding(obj.Position+[-2 1]) ||...
                            obj.isColliding(obj.Position+[2 -1]) || obj.isColliding(obj.Position+[-2 -1])
                        obj.Head = [1 0];
                        if dVer == targ4-y
                            obj.Target = [obj.Position(1), targ4];
                        else
                            obj.Target = [obj.Position(1), targ2];
                        end
                    else
                        obj.Head = [0 1];
                        if dHor == targ3-x
                            obj.Target = [targ3, obj.Position(2)];
                        else
                            obj.Target = [targ1, obj.Position(2)];
                        end
                    end
                end

                dist = obj.Target - obj.Position;
                disp(dist);
                obj.Position = obj.Position + [sign(dist(1)), sign(dist(2))];
            end
        end


        function cont = contains(obj, area, position)
            s = obj.Size;
            if position(1) >= area(1) && ...
                      position(1) <= area(3) - s && ...
                      position(2) >= area(2) && ...
                      position(2) <= area(4) - s
                cont = true;
            else
                cont = false;
            end
        end

        function coll = collides(obj, area, position)
            s = obj.Size;
            if position(1) > area(1) - s && ...
                      position(1) < area(3) && ...
                      position(2) > area(2) - s && ...
                      position(2) < area(4)
                coll = true;
            else
                coll = false;
            end
        end

        function collision = isColliding(obj, pos)
            global AIplayer1;
            global AIplayer3;
            global rooms;
            global len;
            global width;
            global roomSize
            global bounds;
            global gridBoundaries;
            global entrances;

            if ~obj.IsAI && isempty(obj.Casualty) && obj.collides([AIplayer1.Position, AIplayer1.Position + [obj.Size, obj.Size]], pos)
                collision = true;
                return;
            end

            if ~obj.IsAI && obj.collides([AIplayer3.Position, AIplayer3.Position + [obj.Size, obj.Size]], pos)
                collision = true;
                return;
            end

            % Early return if out of boundaries
            if ~obj.contains(gridBoundaries, pos)
                if obj.contains(bounds, pos) || ...
                   obj.contains(entrances(1, :), pos) || ...
                   obj.contains(entrances(2, :), pos)
                    collision = false;
                    return;
                else
                    collision = true;
                    return;
                end
            elseif obj.Room == 0
                cell = floor((pos+[9 9])/39);
                if cell(1) == len || cell(2) == width
                    collision = false;
                    return;
                end
                roomNumber = cell(1)*width + cell(2) + 1;
                area = [rooms(roomNumber).Position rooms(roomNumber).Position] + [0 0 roomSize roomSize];
                if obj.collides(area, pos)
                    collision = true;
                    return;
                end
            else
                % Check for collisions within a specific room
                r = obj.Room;
                room = rooms(r);
                
                if obj.contains(obj.RoomSpace(r+length(rooms), :), pos)
                    collision = false;
                    return;
                elseif obj.contains(obj.RoomSpace(r, :), pos)
                    % Check for collisions with casualties
                    if ~isempty(room.Casualty) && isempty(obj.Casualty)
                        casPos = [room.CasualtyPos, room.CasualtyPos + [obj.Size obj.Size]];
                        if obj.collides(casPos, pos)
                            collision = true;
                            return;
                        end
                    end
                else
                    if obj.collides([room.Position, room.Position+[roomSize roomSize]], pos)
                        collision = true;
                        return;
                    end
                    collision = false;
                    return;
                end
            end
            
            collision = false;
        end
    end
end