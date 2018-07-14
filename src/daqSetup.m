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


OldDevice = 'Dev3'; % this controls the device with the scan mirrors/laser
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
DOphysikInstrumente1 = 'port0/line2'; %black 
DOphysikInstrumente2 = 'port0/line3'; %white
DOphysikInstrumente4 = 'port0/line4'; %yellow

% PI stage inputs (C-867 --> nidaq)
DIphysikInstrumente3 = 'port0/line5'; %green
%DIphysikInstrumente4 = 'port0/line6'; %purple

%% Channels for printer head stimulator (on oldDevice)

pos1 = 'port0/line8';
pos2 = 'port0/line9';
pos3 = 'port0/line10';
pos4 = 'port0/line11';

pos5 = 'port0/line12';
pos6 = 'port0/line13';
pos8 = 'port0/line14';
pos7 = 'port0/line15';

pos11 = 'port0/line16';
pos10 = 'port0/line17';
pos9 = 'port0/line18';
pos12 = 'port0/line19';

pos13 = 'port0/line20';
pos14 = 'port0/line21';
pos15 = 'port0/line22';
pos16 = 'port0/line23';

pos17 = 'port0/line24';
pos18 = 'port0/line25';
pos19 = 'port0/line26';
pos20 = 'port0/line27';

pos21 = 'port0/line28';
pos22 = 'port0/line29';
pos23 = 'port0/line30';
pos24 = 'port0/line31';


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
        addAnalogOutputChannel(s,OldDevice,[AOxScan, AOyScan],'Voltage');
        %ch = addAnalogInputChannel(s,OldDevice,[AItrigger],'Voltage'); %
        %not currently monitoring
        dch = addDigitalChannel(s,OldDevice,{DOtrigger, DOlaser},'OutputOnly');
        dch(1).Name = 'trigger';
        dch(2).Name = 'Laser';
    case 'brushCamera'
        ch = addAnalogInputChannel(s,Device,[AItrigger, AIbrush],'Voltage');
        dch = addDigitalChannel(s,Device,{DOtrigger, DOcameraTrigger},'OutputOnly');
        dch(1).Name = 'trigger';
        dch(2).Name = 'CameraTrigger';
    case 'indenter'
        ch = addAnalogInputChannel(s,Device,[AItrigger, AIlength, AIforce],'Voltage');
        dch = addDigitalChannel(s,Device,DOtrigger,'OutputOnly');
        dch.Name = 'trigger';
        addAnalogOutputChannel(s,Device,[AOlength, AOforce],'Voltage');
    case 'indenterCamera'
        fprintf('Adding analog input channels\n')
        ch = addAnalogInputChannel(s,Device,[AItrigger, AIlength, AIforce],'Voltage');
        fprintf('Adding digital output channels\n')
        dch = addDigitalChannel(s,Device,{DOtrigger, DOcameraTrigger},'OutputOnly');
        dch(1).Name = 'trigger';
        dch(2).Name = 'CameraTrigger';
        fprintf('Adding analog output channels\n')
        addAnalogOutputChannel(s,Device,[AOlength, AOforce],'Voltage');
    case 'indenterOpto'
        ch = addAnalogInputChannel(s,Device,[AItrigger, AIlength, AIforce],'Voltage');
        dch = addDigitalChannel(s,Device,{DOtrigger, DOopto},'OutputOnly');
        dch(1).Name = 'trigger';
        dch(2).Name = 'opto';
        addAnalogOutputChannel(s,Device,[AOlength, AOforce],'Voltage');
    case 'printHead'
        
        ch = addAnalogInputChannel(s,OldDevice,[AItrigger],'Voltage'); %
        dch = addDigitalChannel(s,OldDevice,{DOtrigger,...
                                pos1, pos2, pos3, pos4,...
                                pos5, pos6, pos7, pos8,...
                                pos9, pos10, pos11, pos12,...
                                pos13, pos14,pos15, pos16,...
                                pos17, pos18, pos19, pos20,...
                                pos21, pos22, pos23, pos24},...
                            'OutputOnly');
        
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