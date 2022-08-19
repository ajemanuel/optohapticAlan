function [ d, ch, dch ] = daqSetup( Fs , config)
% This function sets up the daq for signal generation and acquisition, and
% should be called by each of the stimulus files. Fs is the sampling rate,
% and config is channel configuration. Possible values for config include
% 'brush' 'opto' 'laser' 'brushCamera' 'indenter'


%% DAQ and Channel Identities for Current Setup (20170629)

Device = 'Dev1';

% analog outputs for Aurora stimulator
AOlength = 0;
AOforce = 1;


USBDevice = 'Dev2'; % this controls the device with the scan mirrors/laser
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
% trigger for side and ventral view cameras
DOsideCamera = 'port0/line4'; % this is on DEV3
DOventralCamera = 'port0/line3'; % this is on DEV3
% monitor side and ventral view cameras
DOsideCamera_mon = 'port0/line4'; % this is on DEV3
DOventralCamera_mon = 'port0/line2'; % this is on DEV3


% behavior readouts

licks = 'port0/line7';
Tone = 'port0/line5';

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

d = daq('ni'); %% the data acquisition toolbox support package must be installed
d.Rate = Fs;

switch config
    case 'brush'
        ch = addinput(d,Device,[AItrigger, AIbrush],'Voltage');
        dch = addinput(d,Device,DOtrigger,'Digital');
        dch.Name = 'trigger';
        addclock(d,'ScanClock','External','Dev1/PFI0');
    case {'opto', 'optotag'}
        ch = addinput(d,Device,AItrigger,'Voltage');
        dch = addinput(d,Device,{DOtrigger, DOopto},'Digital');
        dch(1).Name = 'trigger';
        dch(2).Name = 'opto';
        addclock(d,'ScanClock','External','Dev1/PFI0');
    case {'laser'}
        addoutput(d,USBDevice,[AOxScan, AOyScan],'Voltage');
        %ch = addAnalogInputChannel(s,OldDevice,[AItrigger],'Voltage'); %
        %not currently monitoring
        dch = addinput(d,USBDevice,{DOtrigger, DOlaser},'Digital');
        dch(1).Name = 'trigger';
        dch(2).Name = 'Laser';
        addclock(d,'ScanClock','External','Dev2/PFI0');
    case 'brushCamera'
        ch = addinput(d,Device,[AItrigger, AIbrush],'Voltage');
        dch = addoutput(d,Device,{DOtrigger, DOcameraTrigger},'Digital');
        dch(1).Name = 'trigger';
        dch(2).Name = 'CameraTrigger';
        addclock(d,'ScanClock','External','Dev1/PFI0');
    case 'camera'
        ch = addinput(d,Device,[AItrigger],'Voltage');
        dch = addoutput(d,Device,{DOtrigger, DOcameraTrigger},'Digital');
        dch(1).Name = 'trigger';
        dch(2).Name = 'CameraTrigger';
        addclock(d,'ScanClock','External','Dev1/PFI0');
    case 'dualCamera'
        ch = addinput(d,USBDevice,[AItrigger],'Voltage');
        dch = addoutput(d,USBDevice,{DOtrigger, DOventralCamera, DOsideCamera},'Digital');
        dch(1).Name = 'trigger';
        dch(2).Name = 'ventralCamera';
        dch(3).Name = 'sideCamera';
        addclock(d,'ScanClock','External','Dev2/PFI0');
    case 'recordDualCamera'
        dch = addinput(d,USBDevice,{DOventralCamera_mon, DOsideCamera_mon},'Digital');
        dch(1).Name = 'ventralCamera';
        dch(2).Name = 'sideCamera';
        addclock(d,'ScanClock','External','Dev2/PFI0');
    case 'indenter'
        ch = addinput(d,Device,[AItrigger, AIlength, AIforce],'Voltage');
        dch = addoutput(d,Device,DOtrigger,'Digital');
        dch.Name = 'trigger';
        addoutput(d,Device,[AOlength, AOforce],'Voltage');
        addclock(d,'ScanClock','External','Dev1/PFI0');
    case 'indenterCamera'
        ch = addinput(d,Device,[AItrigger, AIlength, AIforce],'Voltage');
        dch = addoutput(d,Device,{DOtrigger, DOcameraTrigger},'Digital');
        dch(1).Name = 'trigger';
        dch(2).Name = 'CameraTrigger';
        addoutput(d,Device,[AOlength, AOforce],'Voltage');
        addclock(d,'ScanClock','External','Dev1/PFI0');
    case 'indenterOpto'
        ch = addinput(d,Device,[AItrigger, AIlength, AIforce],'Voltage');
        dch = addoutput(d,Device,{DOtrigger, DOopto},'Digital');
        dch(1).Name = 'trigger';
        dch(2).Name = 'opto';
        addoutput(d,Device,[AOlength, AOforce],'Voltage');
        addclock(d,'ScanClock','External','Dev1/PFI0');
    case 'behaviorIndenter'
        ch = addinput(d,Device,[AItrigger, AIlength, AIforce],'Voltage');
        dch = addoutput(d,Device,[DOtrigger,Tone],'Digital');
        dch_i = addinput(d,Device,licks,'Digital');
        dch(1).Name = 'trigger';
        dch(2).Name = 'tone';
        addoutput(d,Device,[AOlength, AOforce],'Voltage');
        addclock(d,'ScanClock','External','Dev1/PFI0');
    case 'printHead'
        
        ch = addinput(d,USBDevice,AItrigger,'Voltage'); %
        dch = addoutput(d,USBDevice,{DOtrigger,...
                                pos1, pos2, pos3, pos4,...
                                pos5, pos6, pos7, pos8,...
                                pos9, pos10, pos11, pos12,...
                                pos13, pos14,pos15, pos16,...
                                pos17, pos18, pos19, pos20,...
                                pos21, pos22, pos23, pos24},...
                            'Digital');
        addclock(d,'ScanClock','External','Dev2/PFI0');
        
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