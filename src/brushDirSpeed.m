function [  ] = brushDirSpeed( )
%Apply indenter steps to points on a grid.
%   Points  are ordered randomly.

%% Set Parameters

min_x = 2; % mm
min_y = 2; % mm
max_x = 16; % mm
max_y = 16; % mm
spacing = 2; % mm
velocities = [8,16,32,64]; %mm/s
num_repetitions = 8; % # of times repeating entire grid
num_positions = length(min_x:spacing:max_x);
starts = horzcat([min_x:spacing:max_x]',repmat(min_y,num_positions,1));
starts = vertcat(starts,horzcat(repmat(min_x,num_positions,1),[min_y:spacing:max_y]'));
ends = horzcat([min_x:spacing:max_x]',repmat(max_y,num_positions,1));
ends = vertcat(ends,horzcat(repmat(max_x,num_positions,1),[min_y:spacing:max_y]'));


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
    PIdevice.VEL ( axis, velocities(1)); % set speed of axes
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


%%set up "in Motion" trigger mode
% Send the info about whether an axis is in motion or not from PIdevice to
% Intan.
% Make sure that you start PIMikroMove, click on the tab "C-867", choose
% "Configure Trigger Output" and Enable 3 and 4.
PIdevice.TRO (3, 1)%axis1
PIdevice.TRO (4, 1)%axis2

%indicates the axis to be moved
PIdevice.CTO (3,2,1)%axis1
PIdevice.CTO (4,2,2)%axis2
% % specifies the In Motion trigger mode
% PIdevice.CTO (3,3,6)
% PIdevice.CTO (4,3,6)
% 
% % specifies the On Target trigger mode
% PIdevice.CTO (3,3,2)
% PIdevice.CTO (4,3,2)


% specifies the Single Position =9 trigger mode
PIdevice.CTO (3,3,8)
PIdevice.CTO (4,3,8)
PIdevice.CTO (3,10,9)
PIdevice.CTO (4,10,9)



%% Move Stages


for repetition = 1:num_repetitions
    fprintf('on repetition %d of %d\n',repetition,num_repetitions)
for velocity = 1:size(velocities,2)
    %% set velocity
    for axes = 1:size(availableAxes,2)
        axis = availableAxes{axes};
        PIdevice.VEL ( axis, velocities(velocity)); % set speed of axes    
    end
    fprintf('Devices  moving at %d mm/s\n',velocities(velocity))
for position = 1:size(starts)

    %% move to start position
    PIdevice.MOV ( availableAxes{1}, starts(position,1));
    disp ( 'X axis stage is moving')
    % wait for motion to stop
    while(0 ~= PIdevice.IsMoving ( availableAxes{1} ) )
        pause ( 0.05 );
        fprintf('.');
    end
    fprintf('\n');
    PIdevice.MOV ( availableAxes{2}, starts(position,2));
    disp ( 'Y axis stage is moving')
    % wait for motion to stop
    while(0 ~= PIdevice.IsMoving ( availableAxes{2} ) )
        pause ( 0.05 );
        fprintf('.');
    end
    fprintf('\n');
    
    pause (1)
    %% move to end position
    
    PIdevice.MOV ( availableAxes{1}, ends(position,1));
    disp ( 'X axis stage is moving')
    % wait for motion to stop
    while(0 ~= PIdevice.IsMoving ( availableAxes{1} ) )
        pause ( 0.05 );
        fprintf('.');
    end
    fprintf('\n');
    PIdevice.MOV ( availableAxes{2}, ends(position,2));
    disp ( 'Y axis stage is moving')
    % wait for motion to stop
    while(0 ~= PIdevice.IsMoving ( availableAxes{2} ) )
        pause ( 0.05 );
        fprintf('.');
    end
    fprintf('\n');
    
    pause(1)
       
end
end
end

%% If you want to close the connection
PIdevice.CloseConnection ();

%% If you want to unload the dll and destroy the class object
Controller.Destroy ();
clear Controller;
clear PIdevice;


%% read codeFile

fid = fopen([mfilename('fullpath'), '.m'], 'rt');
experimentCodeFile = fread(fid, inf, '*char');
fclose(fid);
% to read this back in from saved codeFile, use dlmwrite('output.m',experimentCodeFile','')
%% Save structure with stimulus information
s1.stimulus = 'brushDirSpeed';
s1.min_x = min_x;
s1.max_x = max_x;
s1.min_y = min_y;
s1.max_y = max_y;
s1.spacing = spacing;
s1.velocities = velocities;
s1.num_repetitions = num_repetitions;
s1.num_positions = num_positions;
s1.starts = starts;
s1.ends = ends;
s1.experimentCodeFile = experimentCodeFile;

path = 'E:\DATA\';
fullpath = strcat(path,s1.stimulus,'_', datestr(now,'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s\n', fullpath)
save(fullpath, '-struct', 's1');


end

