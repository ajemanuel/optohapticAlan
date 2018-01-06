function [ s, ch, dch ] = daqSetup( Fs , config)
% This function sets up the daq for signal generation and acquisition, and
% should be called by each of the stimulus files. Fs is the sampling rate,
% and config is channel configuration. Possible values for config include
% 'brush' 'opto' 'laser' 'brushCamera' 'indenter'


%% DAQ and Channel Identities for Current Setup (20170629)

Device = 'Dev2';

% analog outputs for Aurora stimulator
AOlength = 0;
AOforce = 1;

% analog outputs for scan mirrors
AOxScan = 2;
AOyScan = 3;

% analog inputs for Aurora stimulator
AIlength = 0;
AIforce = 1;

% analog input for brush
AIbrush = 3;

% monitoring trigger signal (should move this to a DI)
AItrigger = 4;

% trigger for LED used for optotagging
DOopto = 'port0/line1';
% trigger for recording
DOtrigger = 'port0/line0';
% trigger for camera
DOcameraTrigger = 'port0/line6'; % connected to PFI1
% trigger for TTL laser
DOlaser = 'port0/line1';

% PI stage outputs (nidaq --> C-867 controller)
DOphysikInstrumente1 = 'port0/line2';
DOphysikInstrumente2 = 'port0/line3';
DOphysikInstrumente4 = 'port0/line4';

% PI stage inputs (C-867 --> nidaq)
DIphysikInstrumente3 = 'port0/line5';
%DIphysikInstrumente4 = 'port0/line6';



%% Initiating DAQ and Assigning Channels

s = daq.createSession('ni');
s.Rate = Fs;

switch config
    case 'brush'
        ch = addAnalogInputChannel(s,Device,[AItrigger, AIbrush],'Voltage');
        dch = addDigitalChannel(s,Device,DOtrigger,'OutputOnly');
        dch.Name = 'trigger';
    case {'opto', 'optotag'}
        ch = addAnalogInputChannel(s,Device,AItrigger,'Voltage');
        dch = addDigitalChannel(s,Device,{DOtrigger, DOopto},'OutputOnly');
        dch(1).Name = 'trigger';
        dch(2).Name = 'opto';                
    case {'laser'}
        addAnalogOutputChannel(s,Device,[AOxScan, AOyScan],'Voltage');
        ch = addAnalogInputChannel(s,Device,[AItrigger],'Voltage');
        dch = addDigitalChannel(s,Device,{DOtrigger, DOlaser},'OutputOnly');
        dch(1).Name = 'trigger';
        dch(2).Name = 'Laser';
    case 'brushCamera'
        ch = addAnalogInputChannel(s,Device,[AItrigger, AIbrush],'Voltage');
        dch = addDigitalChannel(s,Device,{DOtrigger, DOcameraTrigger},'OutputOnly');
        dch(1).Name = 'Trigger';
        dch(2).Name = 'CameraTrigger';
    case 'indenter'
        ch = addAnalogInputChannel(s,Device,[AItrigger, AIlength, AIforce],'Voltage');
        dch = addDigitalChannel(s,Device,DOtrigger,'OutputOnly');
        dch.Name = 'Trigger';
        addAnalogOutputChannel(s,Device,[AOlength, AOforce],'Voltage');
    case 'indenterCamera'
        fprintf('Adding analog input channels\n')
        ch = addAnalogInputChannel(s,Device,[AItrigger, AIlength, AIforce],'Voltage');
        fprintf('Adding digital output channels\n')
        dch = addDigitalChannel(s,Device,{DOtrigger, DOcameraTrigger},'OutputOnly');
        dch(1).Name = 'Trigger';
        dch(2).Name = 'CameraTrigger';
        fprintf('Adding analog output channels\n')
        addAnalogOutputChannel(s,Device,[AOlength, AOforce],'Voltage');
        
    otherwise
        error('config not correct')
end

%% Step through channels and configure as single ended
 
if exist('ch', 'var') == 1
    for n = 1:length(ch)
        ch(n).TerminalConfig = 'SingleEnded';
    end
else
    ch = 'none';
end

end