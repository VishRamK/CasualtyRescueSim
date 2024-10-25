main();
function main()
    % Set up game parameters
    gameDuration = 480; % 30-second game

    % Initialize start time
    global startTime;
    startTime = tic;

    % Controller Initialization
    joy = vrjoystick(1);

    % Create a figure window
    f = figure();%'KeyPressFcn', @keyPress);
    % Hold on to the current axes
    hold on;

    % Set the axis to be equal for proper square dimensions
    axis equal;

    % Turn off the axis for a cleaner look
    axis off;

    % Set the background color to white
    set(gca, 'Color', 'w');

    % Define the size of the squares and the spacing between them
    global roomSize;
    roomSize = 30;
    global playerSize;
    playerSize = 7;
    stepSize = 1;
    global spacing;
    spacing = 9;
    global totalPoints;
    totalPoints = 0;
    global pointsDisplay;
    global ambulance;
    global player;
    global AIplayer1;
    global AIplayer3;
    global openRoom;
    global casualty;
    global timeDisplay;

    % Calculate the positions of the 9 Rooms in a 3x3 grid
    global len;
    global width;
    len = 4;
    width = 4;
    global positions;
    positions = zeros(len*width, 2);
    
    for i = 0:len-1
        for j = 0:width-1
            positions((width*i)+(j+1), :) = [i j];
        end
    end
    positions = positions * (roomSize + spacing);

    global gridBoundaries;
    gridBoundaries = [positions(1) - [spacing spacing], positions(length(positions), :)+[roomSize+spacing, roomSize+spacing]];
    global rooms;
    rooms = Room.empty(0, length(positions));
    global casualties;
    casualties = CasualtyObject.empty(0, length(positions));
    
    % Draw the Rooms and populate casualties
    for i = 1:length(positions)
        roomName = ['room', int2str(i)];
        rooms(i) = Room(roomName, positions(i, :), [roomSize roomSize], []);
        rooms(i).draw();
        casualtyPosition = rooms(i).CasualtyPos;
        casualties(i) = CasualtyObject(randi(4), casualtyPosition, i);
        uistack(casualties(i).Rep.Rep, 'bottom');
        casualties(i).turn([-1 0]);
        rooms(i) = rooms(i).addCasualty(casualties(i));
        totalPoints = totalPoints + casualties(i).Points;
    end

    % Draw the walls around
    start1 = positions(1, :);
    start2 = positions(length(positions)-(width-1), :);
    verticalWalls = [start1 + [-(2*spacing), -(2*spacing)]; start2 + [(roomSize+spacing), -(2*spacing)]];
    hWallLength = verticalWalls(2, 1) - verticalWalls(1, 1) - spacing;
    vWallLength = positions(width, 2) - positions(1, 2) + roomSize + (4*spacing);
    for i = 1:2
        rectangle('Position', [verticalWalls(i, :) spacing vWallLength], 'FaceColor', '#7F7F7F', 'EdgeColor', 'none');
    end
    horizontalWall = rectangle('Position', [positions(width, :) + [-(spacing), (roomSize+spacing)], hWallLength, spacing], 'FaceColor', '#7F7F7F', 'EdgeColor', 'none');
    % Make the Entrances
    global entrances;
    entrances = zeros(2, 4);
    currentLoc = positions(1, :) - [spacing (2*spacing)];
    for i = 1:3
        if i ~= 2
            rectangle('Position', [currentLoc, roomSize + spacing, spacing], 'FaceColor', '#7F7F7F', 'EdgeColor', 'none');
            currentLoc = currentLoc + [(roomSize + spacing) 0];
        else
            newLength = hWallLength-2*(roomSize+2*spacing);
            rectangle('Position', [currentLoc, newLength, spacing], 'FaceColor', '#7F7F7F', 'EdgeColor', 'none');
            entrances(1, :) = [currentLoc-[spacing, playerSize], currentLoc+[0, spacing+playerSize]];
            entrances(2, :) = [currentLoc+[newLength, -playerSize], currentLoc+[newLength+spacing, spacing+playerSize]];
            currentLoc = currentLoc + [newLength 0];
        end
        if i < 3
            currentLoc = currentLoc + [spacing 0];
        end
    end
    ambulance = Ambulance([(hWallLength/2)-(55+spacing), -70], [110 30]);
    ambulance.draw();
    global bounds;
    bounds = [verticalWalls(1, 1), ambulance.Position(2), verticalWalls(2, 1)+spacing, verticalWalls(2, 2)];
    
    scorePos = verticalWalls(2, :) + [-2, vWallLength + spacing];
    pointsDisplay = text(scorePos(1), scorePos(2), ['Score: ', int2str(totalPoints)], 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    uistack(pointsDisplay, "top");

    roomSpace = zeros(2*length(rooms), 4);
    t = ambulance.Thickness;
    for i = 1:length(rooms)
        intSize = rooms(i).Size - 2*[t t];
        startVertex = rooms(i).Position + [t t];
        endVertex = startVertex + intSize;
        doorStart = rooms(i).DoorPos + [0, -playerSize];
        doorEnd = doorStart + rooms(i).DoorSize + [0, t + 2*playerSize];
        roomSpace(i, :) = [startVertex endVertex];
        roomSpace(i+length(rooms), :) = [doorStart doorEnd];
    end

    % Draw the Player
    player = PlayerObject([60 -30], false, roomSpace);
    player.draw();
    AIplayer1 = PlayerObject(positions(1, :)-[spacing-1 spacing-1], true, roomSpace);
    AIplayer1.draw();
    AIplayer3 = PlayerObject(positions(16, :)+[roomSize+1, roomSize+1], true, roomSpace);
    AIplayer3.draw();
    openRoom = 0;
    casualty = 0;
    
    timeDisplayPos = horizontalWall.Position(1:2) + [-2, 2*spacing];
    timeDisplay = text(timeDisplayPos(1), timeDisplayPos(2), 'Time: 480', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    uistack(timeDisplay, "top");

    global direction1;
    direction1 = 1;

    global direction2;
    direction2 = 1;

    %global ysig;
    ysig = 0;
    global wait;
    wait = 0;
    curSev = 4;

    % Create and start the game timer
    gameTimer = timer('ExecutionMode', 'fixedRate', ...
                      'Period', 0.05, ...   % Update every 0.1 seconds
                      'TasksToExecute', inf, ...
                      'TimerFcn', @gameLoop, ...
                      'StopFcn', @endGame);
    start(gameTimer);
    function gameLoop(~, ~)
        % Calculate remaining time
        elapsedTime = toc(startTime);
        remainingTime = max(0, gameDuration - elapsedTime);
        % Update time display
        set(timeDisplay, 'String', sprintf('Time: %.1f', remainingTime));
        
        % Add game logic here (e.g., moving objects, checking collisions, etc.
        playerArea = [player.Position, player.Position + [playerSize playerSize]];
        AI1Area = [AIplayer1.Position, AIplayer1.Position + [playerSize playerSize]];
        AI3Area = [AIplayer3.Position, AIplayer3.Position + [playerSize playerSize]];
        if AIplayer1.collides(playerArea, AIplayer1.Position+AIplayer1.Head) || AIplayer1.collides(AI3Area, AIplayer1.Position+AIplayer1.Head)
            AIplayer1.Head = -AIplayer1.Head;
            direction1 = -direction1;
            wait = 1;
        else
            wait = 0;
        end
        if AIplayer3.collides(playerArea, AIplayer3.Position+AIplayer3.Head) || AIplayer1.collides(AI1Area, AIplayer3.Position+AIplayer3.Head)
            AIplayer3.Head = -AIplayer3.Head;
            direction2 = -direction2;
        end
        AIplayer1.algLevel1(ysig, direction1);
        AIplayer3.algLevel1(0, direction2);
      
        % Player Logic
        error = 0.1;
        [axis_vals, button_vals, ~] = read(joy);
        if abs(axis_vals(1, 1)) > error || abs(axis_vals(1, 2)) > error
            player.controls(axis_vals(1, :));
            closeDoor();
        end

        if button_vals(2)
            openDoor();

        elseif button_vals(3)
            ysig = 0;
            dropCasualty();
            disp([AIplayer1.Path, AIplayer1.Target]);

        elseif button_vals(1)
            ysig = 0;
            pickCasualty();

        elseif button_vals(4)
            if player.Room > 0 && ysig == 0
                casPos = rooms(player.Room).CasualtyPos;
                if player.Position(1) + playerSize <= casPos(1) || ...
                        player.Position(1) - playerSize >= casPos(1)
                    player.Target = [];
                    dir = sign(player.Position(1)-casPos(1));
                    player.Position = casPos + [dir*playerSize, 0];
                    player.Head = [-dir 0];
                    player.OldPositions = repmat(player.Position, 7, 1);
                    player.OldHeads = repmat(player.Head, 7, 1);
                    player.OldPositions(1, :) = player.Position;
                    player.OldHeads(1, :) = player.Head;
                    loc = rooms(player.Room).Position + [11, -8];
                    AIplayer1.Path = AIplayer1.pathfinder(loc, -dir, casPos);
                    player.draw()
                    ysig=1;
                end
            end   
        end
        %tolerance = 1;
        if ~mod(floor(elapsedTime), 120)
            for j = 1:length(casualties)
                if casualties(j).Alive && casualties(j).SeverityLevel == curSev
                    casualties(j).die(elapsedTime);
                end
            end
            curSev = curSev-1;
        end
        if remainingTime <= 0
            stop(gameTimer); % Stop the game if time is up
        end
    end
    
    function endGame(~, ~)
        % Stop the timer
        stop(gameTimer);
        delete(gameTimer);
        
        % Display game over message or final score
        disp('Game Over');
        disp(['Final Score: ', num2str(totalPoints)]);
        close(gcf);
    end

    % Update player controls using the joystick
    function openDoor()
        for j = 1:length(rooms)
            rooms(j).open(player);
            if rooms(j).IsOpen
                player.inRoom(j);
                openRoom = j;
                break
            end
            % Bring the player to the top layer
            uistack(player.Rep.Rep, 'top');
        end
    end

    function closeDoor()
        if openRoom ~= 0
            if rooms(openRoom).IsOpen && ~rooms(openRoom).detectCollision(player)
                rooms(openRoom).close();
                openRoom = 0;
                player.inRoom(0);
            end
        end
        uistack(player.Rep.Rep, 'top');
    end

    function pickCasualty()
        for j = 1:length(casualties)                    
            if casualties(j).Position - (playerSize*player.Head) == player.Position
                player.pickUp(casualties(j));
                casualty = j;
                break;
            end
        end
    end

    function dropCasualty()
        if casualty ~= 0
            casualties(casualty) = player.Casualty;
            player.drop();
            AIplayer1.Casualty = [];
            casualty = 0;
        end
    end
end
