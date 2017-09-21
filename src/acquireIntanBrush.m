function acquireIntanBrush(durationInSeconds)

% Init DAQ
Fs = 20000;
s = daqSetup(Fs, 'brush');
durationInSamples = Fs * durationInSeconds;

% Construct stimulus
stimulus = 'acquireIntanBrush';

trigger = zeros(durationInSamples,1);
blank = zeros(durationInSamples,1);
trigger(2:1:end-2) = 1; 
queueOutputData(s, trigger)
pause(2);
% Output stimulus
[data, time] = s.startForeground();



% Clean up and save configuration
s.release()

% Save the fields of a structure as individual variables:
s1.stimulus = stimulus;
s1.Fs = Fs;
s1.data = data;
s1.time = time;
s1.trigger = trigger;
path = 'E:\DATA\';
fullpath = strcat(path, stimulus, '_', datestr(now, 'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s \n', fullpath)
save(fullpath, '-struct', 's1');