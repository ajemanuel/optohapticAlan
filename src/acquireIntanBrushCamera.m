function acquireIntanBrushCamera(durationInSeconds)

% Init DAQ
Fs = 20000;
s = daqSetup(Fs, 'brushCamera');
cameraTriggerRate = 150;


cameraTriggerSamples = Fs/cameraTriggerRate;
durationInSamples = Fs * durationInSeconds;
maxCameraTriggers = durationInSamples/cameraTriggerSamples;

% Construct stimulus
stimulus = 'acquireIntanBrushCamera';

trigger = zeros(durationInSamples,1);
cameratrigger = zeros(durationInSamples,1);
trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end

for j = 10:maxCameraTriggers-10  % building a buffer into the loop
    cameratrigger(round(j * cameraTriggerSamples):1:round(j*cameraTriggerSamples)+20) = 1;
end

% Queue data

s.queueOutputData(horzcat(trigger, cameratrigger))
pause(3);
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
s1.cameratrigger = cameratrigger;
path = 'E:\DATA\';
fullpath = strcat(path, stimulus, '_', datestr(now, 'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s \n', fullpath)
save(fullpath, '-struct', 's1');