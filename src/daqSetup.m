function [ s, ch, dch ] = daqSetup( Fs , config)
% This function sets up the daq for signal generation and acquisition, and
% should be called by each of the stimulus files. Fs is the sampling rate,
% and config is channel configuration. Possible values for config include
% 'brush' 'opto' 'laser' 'brushCamera' 'indenter'


%% DAQ and Channel Identities for Current Setup (20170629)

Device = 'Dev3';

AOlength = 0;
AOforce = 1;
AOxScan = 2;
AOyScan = 3;

AIlength = 0;
AIforce = 1;
AIbrush = 3;
AItrigger = 4;

DOopto = 'port0/line11';

DOtrigger = 'port0/line8';
DOcameraTrigger = 'port0/line10';
DOlaser = 'port0/line9';

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