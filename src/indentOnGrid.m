function [  ] = indentOnGrid( )
%Apply indenter steps to points on a grid.
%   Points  are ordered randomly.

%% Set Parameters

min_x = 8; % mm
min_y = 8; % mm
max_x = 10; % mm
max_y = 10; % mm
grid_spacing = .5; %mm
move_velocity = 20; %mm/s
num_repetitions = 2; % # of times repeating entire grid
grid_x = repmat([min_x:grid_spacing:max_x],(max_y-min_y)/grid_spacing+1,1);

grid_y = repmat([min_y:grid_spacing:max_y]',1,(max_x-min_x)/grid_spacing+1);

grid_positions = [grid_x(:) grid_y(:)];

rng(20170922) % set random seed for reproducibility

grid_positions_rand = grid_positions(randperm(size(grid_positions,1)),:);

grid_positions_actual = zeros([size(grid_positions_rand),num_repetitions]);

%% Load PI MATLAB Driver GCS2
%  (if not already loaded) should be already within saved path
% addpath ( 'C:\Users\Public\PI\PI_MATLAB_Driver_GCS2', 'C:\Users\Public\PI\C-867\Samples\MATLAB' ); % If you are still using XP, please look at the manual for the right path to include.

if ( ~exist ( 'Controller', 'var' ) || ~isa ( Controller, 'PI_GCS_Controller' ) )
    Controller = PI_GCS_Controller ();
end

%% Start connection
%(if not already connected)

boolPIdeviceConnected = false; if ( exist ( 'PIdevice', 'var' ) ), if ( PIdevice.IsConnected ), boolPIdeviceConnected = true; end; end;
if ( ~(boolPIdeviceConnected ) )

    % Please choose the connection type you need.    
    
%    % RS232
%    comPort = 1;          % Look at the Device Manager to get the rigth COM Port.
%    baudRate = 115200;    % Look at the manual to get the rigth bau rate for your controller.
%    PIdevice = Controller.ConnectRS232 ( comPort, baudRate );


     % USB
     controllerSerialNumber = '0117051110';    % Use "devicesUsb = Controller.EnumerateUSB('')" to get all PI controller connected to you PC.
                                                                                     % Or look at the label of the case of your controller
     PIdevice = Controller.ConnectUSB ( controllerSerialNumber );


%     % TCP/IP
%     ip = 'xxx.xxx.xx.xxx';  % Use "devicesTcpIp = Controller.EnumerateTCPIPDevices('')" to get all PI controller available on the network.
%     port = 50000;           % Is 50000 for almost all PI controllers
%     PIdevice = Controller.ConnectTCPIP ( ip, port ) ;

end

% Query controller identification string
connectedControllerName = PIdevice.qIDN()

% initialize PIdevice object for use in MATLAB
PIdevice = PIdevice.InitializeController ();

%% Show connected stages

% query names of all controller axes
availableAxes = PIdevice.qSAI_ALL


% get Name of the stage connected to axis 1
PIdevice.qCST ( '1' )


% Show for all axes: which stage is connected to which axis
for idx = 1 : length ( availableAxes )
    % qCST gets the name of the 
    stageName = PIdevice.qCST ( availableAxes { idx } );
    disp ( [ 'Axis ', availableAxes{idx}, ': ', stageName ] );
end

% if the stages listed are wrong use one of the following solutions:
% - PIMikroMove (recommended, but MS windows only)
% - PITerminal  (use VST, qCST, CST and WPA command as described in the Manual)
% - Use function "PI_ChangeConnectedStage"

%% Startup Stage

% This sections performs the startup commands valid for most but not all
% PI devices. Depending on you sepcific device you will need to remove some
% commands or add one of the following (list might be incomplete. Please
% look at the manual if necessary):
% - PIdevice.EAX ( axis, true );
% - PIdevice.ATZ ( ... )
% - You may need to interchange the order of FRF and SVO (this is the case for C-891)

for axes = 1:size(availableAxes,2)
    
	axis = availableAxes{axes};

    % switch servo on for axis
    switchOn    = 1;
    % switchOff   = 0;
    PIdevice.SVO ( axis, switchOn );
    PIdevice.VEL ( axis, move_velocity); % set speed of axes
    % reference axis
    PIdevice.FRF ( axis );  % find reference
    bReferencing = 1;                           
    disp ( ['Stage ' axis ' is referencing'] )
    % wait for referencing to finish
    while(0 ~= PIdevice.qFRF ( axis ) == 0 )                        
        pause(0.1);           
        fprintf('.');
    end       
    fprintf('\n');
end


%% Move Stages


for repetition = 1:num_repetitions
    fprintf('on repetition %d of %d\n',repetition,num_repetitions)
for gridLoc = 1:size(grid_positions_rand)
    PIdevice.MOV ( availableAxes{1}, grid_positions_rand(gridLoc,1));
    disp ( 'X axis stage is moving')
    % wait for motion to stop
    while(0 ~= PIdevice.IsMoving ( availableAxes{1} ) )
        pause ( 0.05 );
        fprintf('.');
    end
    fprintf('\n');
    
    PIdevice.MOV ( availableAxes{2}, grid_positions_rand(gridLoc,2));
    disp ( 'Y axis stage is moving')
    % wait for motion to stop
    while(0 ~= PIdevice.IsMoving ( availableAxes{2} ) )
        pause ( 0.05 );
        fprintf('.');
    end
    fprintf('\n');
    pause(1) %% rest of code will go here
    grid_positions_actual(gridLoc,1, repetition) = PIdevice.qPOS(availableAxes{1});
    grid_positions_actual(gridLoc,2, repetition) = PIdevice.qPOS(availableAxes{2});
    
    fprintf('Repetition %d of %d\n',repetition,num_repetitions)
    fprintf('Stimulating site %d of %d\n',gridLoc, size(grid_positions_rand))
    fprintf('X: %.2f, Y: %.2f\n',grid_positions_rand(gridLoc,1),grid_positions_rand(gridLoc,2))
    acquireIntanIndenterCamera('forceSteps')
    
end
end

%% If you want to close the connection
PIdevice.CloseConnection ();

%% If you want to unload the dll and destroy the class object
Controller.Destroy ();
clear Controller;
clear PIdevice;


%% Save structure with stimulus information
s1.stimulus = 'GridIndent';
s1.min_x = min_x;
s1.max_x = max_x;
s1.min_y = min_y;
s1.max_y = max_y;
s1.num_repetitions = num_repetitions;
s1.grid_spacing = grid_spacing;
s1.grid_positions = grid_positions;
s1.grid_positions_rand = grid_positions_rand;
s1.grid_positions_actual = grid_positions_actual;

path = 'E:\DATA\';
fullpath = strcat(path,s1.stimulus,'_', datestr(now,'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s\n', fullpath)
save(fullpath, '-struct', 's1');

%positonReached = PIdevice.qPOS(axis)
end

