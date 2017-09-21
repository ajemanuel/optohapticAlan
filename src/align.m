function align( offsetX, offsetY, time)
%% Low power alignment of the laser to the foot %%

%% outdated setup alignment settings. 20170622
% Left hindpaw at (10000,8000)
% Right hindpaw at (-25000, 8600)
% Left forepaw at (5000, -28000)
% Right forepaw at (-18000, -28000)


% Init DAQ
Fs = 20000;
s = daqSetupLaser(Fs);
voltageToDegrees = 1.25; % degrees/volt, thorlabs galvos
degreesToDistance = 3075; % microns/degrees, FTH100-1064 mounted in thorlabs cage mirror mount
voltageToDistance = voltageToDegrees * degreesToDistance; % volts/microns

% Construct stimulus
t = 0:1/Fs:time;
lz1 = 0.5 * (square(2*pi*30*t,.11)+1);
%lz2 = zeros(1,length(lz1));
x1 = zeros(1,length(lz1));
x1(1:end) = offsetX/voltageToDistance;
y1 = zeros(1,length(lz1));
y1(1:end) = offsetY/voltageToDistance;
lz1(end) = 0;

queueOutputData(s, [x1', y1', lz1'])

% Output stimulus
s.startForeground();
s.release()