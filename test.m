% Initialize joystick (usually ID 1 for the first connected joystick)
joy = vrjoystick(1);
player = rectangle('Position', [0 0 1 1]);
disp(-1 == true);

% Get the joystick capabilities
joyCaps = caps(joy);  % Returns a structure with fields for axes and buttons
numAxes = joyCaps.Axes;  % Number of axes
numButtons = joyCaps.Buttons;  % Number of buttons
disp(['Number of Axes: ', num2str(numAxes)]);
disp(['Number of Buttons: ', num2str(numButtons)]);

% Initial player position
playerPos = [0 0];

% Create a figure and assign a close request function to stop the loop
f = figure;
set(f, 'CloseRequestFcn', @(src, event) stopSimulation(src));
%hold on;
set(gca, 'XLim', [0 20], 'YLim', [0 20]);
axis off;

% Variable to control the loop
continueSimulation = true;

% Main loop to read inputs from the controller
while continueSimulation
    % Check if the figure is still open
    if ~isvalid(f)
        break;  % Exit the loop if the figure is closed
    end
    
    % Read axes values (e.g., left and right analog sticks)
    axes = getJoystickAxes(joy);
    disp(axes);
    
    % Read button presses
    buttons = button(joy);
    
    % Example: Check if the first button (e.g., A) is pressed
    if buttons(1)
        disp('Button 1 (A) pressed');
    end
    
    % Use the axes for movement (assuming first two axes are for X and Y movement)
    playerPos = playerPos + [axes(1) -axes(2)];  % Adjust based on your control scheme
    
    % Update the player position in your game
    set(player, 'Position', [playerPos 1 1]);
    
    pause(0.1);  % Slow down the loop
end

% Stop Simulation function
function stopSimulation(figHandle)
    % Function to stop the simulation when the figure is closed
    disp('Stopping simulation...');
    delete(figHandle);  % Close the figure window
    assignin('base', 'continueSimulation', false);  % Stop the loop
end

function joyAxes = getJoystickAxes(joy)
    joyAxes = axis(joy);  % Call the joystick's axis method
end
