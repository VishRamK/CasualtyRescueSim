movable();
function movable()
    f = figure('Name', 'KeyPress Background Example', 'KeyPressFcn', @handleKeyPressInBackground);

    % Hold on to the current axes
    hold on;

    % Set the axis to be equal for proper square dimensions
    axis equal;
    axis([0 10 0 10]);

    % Turn off the axis for a cleaner look
    axis off;

    % Set the background color to white
    set(gca, 'Color', 'w');
    playerPos = [1.5 1.5];
    squareSize = 1;

    % Draw the player square
    player = rectangle('Position', [playerPos squareSize squareSize], 'FaceColor', 'k', 'EdgeColor', 'r');

    function handleKeyPressInBackground(~, event)
        disp('Key detected. Processing in background...');
        
        % Start the background execution using backgroundPool
        future = parfeval(backgroundPool, @processKeyPress, 1, event);
        
        % Use afterEach to update the player position when the future completes
        afterEach(future, @updatePlayerPosition, 0);
    end

    function deltaPos = processKeyPress(event)
        % This function runs in the background, do not update UI here!
        switch event.Key
            case 'uparrow'
                deltaPos = [0 1];
            case 'downarrow'
                deltaPos = [0 -1];
            case 'rightarrow'
                deltaPos = [1 0];
            case 'leftarrow'
                deltaPos = [-1 0];
            otherwise
                deltaPos = [0 0];
        end
        
        % Simulate a computationally intensive task
        pause(1); % Simulate processing delay
        
        % Return the calculated position delta
        deltaPos = deltaPos;
    end

    function updatePlayerPosition(deltaPos)
        % Update the player position based on the calculated delta
        playerPos = playerPos + deltaPos;
        set(player, 'Position', [playerPos squareSize squareSize]);
    end
end
