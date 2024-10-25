main();
function main()
    % Set up game parameters
    gameDuration = 480; % 30-second game

    % Initialize start time
    global startTime;
    startTime = tic;
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
    roomSize = 30;
    playerSize = 7;
    stepSize = 1;
    spacing = 9;
    global totalPoints;
    totalPoints = 0;
    global pointsDisplay;
    global ambulance;
    global player;
    global AIplayer;
    global openRoom;
    global casualty;
    global timeDisplay;

    % Calculate the positions of the 9 Rooms in a 3x3 grid
    len = 7;
    width = 2;
    global positions;
    positions = zeros(len*width, 2);
    for i = 0:len-1
        for j = 0:width-1
            positions((width*i)+(j+1), :) = [i j];
        end
    end
    positions = positions * (roomSize + spacing);
    global rooms;
    rooms = Room.empty(0, length(positions));
    global casualties;
    casualties = CasualtyObject.empty(0, length(positions));
    global grid;
    grid = zeros(length(positions), 4);
    global adjacents;
    adjacents = zeros(length(positions)+1, 5);
    
    % Draw the Rooms and populate casualties
    for i = 1:length(positions)
        grid(i, :) = [positions(i, :) - [spacing spacing], positions(i, :) + [roomSize roomSize]];
        left = max(0, i-width);
        right = (i+width) * (i+width <= length(positions));
        up = (i+1) * (mod(i, width) > 0);
        down = (i-1) * (mod(i-1, width) > 0);
        adjacents(i, :) = [i left right up down];
        if positions(i, 1) == positions(length(positions), 1)
            grid(i, :) = grid(i, :) + [0 0 spacing 0];
        end
        if positions(i, 2) == positions(length(positions), 2)
            grid(i, :) = grid(i, :) + [0 0 0 spacing];
        end
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
    adjacents(length(adjacents), :) = [width+1 len*width 0 0 0];

    % Draw the walls around
    blocks = zeros(6+length(rooms), 4);
    start1 = positions(1, :);
    start2 = positions(length(positions)-(width-1), :);
    verticalWalls = [start1 + [-(2*spacing), -(2*spacing)]; start2 + [(roomSize+spacing), -(2*spacing)]];
    hWallLength = verticalWalls(2, 1) - verticalWalls(1, 1) - spacing;
    vWallLength = positions(width, 2) - positions(1, 2) + roomSize + (4*spacing);
    for i = 1:2
        rectangle('Position', [verticalWalls(i, :) spacing vWallLength], 'FaceColor', '#7F7F7F', 'EdgeColor', 'none');
        blocks(i, :) = [verticalWalls(i, :)+[1 1], verticalWalls(i, :)+[spacing-1 vWallLength-1]];
    end
    horizontalWall = rectangle('Position', [positions(width, :) + [-(spacing), (roomSize+spacing)], hWallLength, spacing], 'FaceColor', '#7F7F7F', 'EdgeColor', 'none');
    blocks(3, :) = horizontalWall.Position + [1, 1, horizontalWall.Position(1:2)-[1 1]];
    % Make the Entrances
    currentLoc = positions(1, :) - [spacing (2*spacing)];
    for i = 1:3
        if i ~= 2
            rectangle('Position', [currentLoc, roomSize + spacing, spacing], 'FaceColor', '#7F7F7F', 'EdgeColor', 'none');
            blocks(i+3, :) = [currentLoc+[1 1], currentLoc+[roomSize+spacing-1, spacing-1]];
            currentLoc = currentLoc + [(roomSize + spacing) 0];
        else
            newLength = hWallLength-2*(roomSize+2*spacing);
            rectangle('Position', [currentLoc, newLength, spacing], 'FaceColor', '#7F7F7F', 'EdgeColor', 'none');
            blocks(i+3, :) = [currentLoc+[1 1], currentLoc+[newLength-1, spacing-1]];
            currentLoc = currentLoc + [newLength 0];
        end
        if i < 3
            currentLoc = currentLoc + [spacing 0];
        end
    end
    ambulance = Ambulance([(hWallLength/2)-(55+spacing), -70], [110 30]);
    ambulance.draw();
    
    scorePos = verticalWalls(2, :) + [-2, vWallLength + spacing];
    pointsDisplay = text(scorePos(1), scorePos(2), ['Score: ', int2str(totalPoints)], 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    uistack(pointsDisplay, "top");

    % Rooms
    for i = 1:length(rooms)
        blocks(i+6, :) = [rooms(i).Position + [1 1], rooms(i).Position + [roomSize-1 roomSize-1]];
    end

    roomSpace = zeros(2*length(rooms), 4);
    t = ambulance.Thickness;
    for i = 1:length(rooms)
        intSize = rooms(i).Size - 2*[t t];
        startVertex = rooms(i).Position + [t t];
        endVertex = startVertex + intSize;
        doorStart = rooms(i).DoorPos + [t, -playerSize-1];
        doorEnd = doorStart + rooms(i).DoorSize + [- t, t + 2*playerSize];
        roomSpace(i, :) = [startVertex endVertex];
        roomSpace(i+length(rooms), :) = [doorStart doorEnd];
    end

    % Draw the Player
    player = PlayerObject([60 -30], false, blocks, roomSpace);
    player.draw();
    AIplayer = PlayerObject(positions(1, :)-[spacing-1 spacing-1], true, blocks, roomSpace);
    AIplayer.draw();
    openRoom = 0;
    casualty = 0;
    
    timeDisplayPos = horizontalWall.Position(1:2) + [-2, 2*spacing];
    timeDisplay = text(timeDisplayPos(1), timeDisplayPos(2), ['Time: 480'], 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'k');
    uistack(timeDisplay, "top");

    % Create and start the game timer
    gameTimer = timer('ExecutionMode', 'fixedRate', ...
                      'Period', 0.1, ...   % Update every 0.1 seconds
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
        AIplayer.algLevel1();
        tolerance = 1;
        if abs(mod(elapsedTime, 120)) < tolerance
            for j = 1:length(casualties)
                casualties(j).die(elapsedTime);
            end
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

    function keyPress(~, event)
        % This function will be called when a key is pressed
        switch event.Key            
            case {'uparrow', 'downarrow', 'rightarrow', 'leftarrow'}
                player.controls(event.Key); % Update player position based on key pressed
            case 'a'
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
            case 's'
                for j = 1:length(casualties)                    
                    if casualties(j).Position - (playerSize*player.Head) == player.Position
                        player.pickUp(casualties(j));
                        casualty = j;
                        break;
                    end
                end
            case 'd'
                if casualty ~= 0
                    casualties(casualty) = player.Casualty;
                    player.drop();
                    casualty = 0;
                end
        end
        if openRoom ~= 0
            if rooms(openRoom).IsOpen && ~rooms(openRoom).detectCollision(player)
                rooms(openRoom).close();
                openRoom = 0;
                player.inRoom(0);
            end
        end
        uistack(player.Rep.Rep, 'top');
    end
end
