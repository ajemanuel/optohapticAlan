function acquireIntanDualCamera(durationInSeconds)

% Init DAQ
Fs = 20000;
s = daqSetup(Fs, 'dualCamera');
ventralTriggerRate = 200;
sideCameraRate = 200;

ventralTriggerSamples = Fs/ventralTriggerRate;
sideTriggerSamples = Fs/sideCameraRate;
durationInSamples = Fs * durationInSeconds;
maxVentralTriggers = durationInSamples/ventralTriggerSamples;
maxSideTriggers = durationInSamples/sideTriggerSamples;


% Construct stimulus
stimulus = 'acquireIntanDualCamera';

trigger = zeros(durationInSamples,1);
ventralcameratrigger = zeros(durationInSamples,1);
sidecameratrigger = zeros(durationInSamples,1);
trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end

for j = 2:maxVentralTriggers-1  % building a buffer into the loop
    ventralcameratrigger(round(j * ventralTriggerSamples):1:round(j*ventralTriggerSamples)+50) = 1;
end

for j = 2:maxSideTriggers-1  % building a buffer into the loop
    sidecameratrigger(round(j * sideTriggerSamples):1:round(j*sideTriggerSamples)+50) = 1;
end



% Queue data
fprintf('expect %i frames on ventral camera\n',sum(ventralcameratrigger(2:end) - ventralcameratrigger(1:end-1) > 0))
fprintf('expect %i frames on side camera\n',sum(sidecameratrigger(2:end) - sidecameratrigger(1:end-1) > 0))
s.queueOutputData(horzcat(trigger, ventralcameratrigger, sidecameratrigger))
pause(1);
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
s1.ventralcameratrigger = ventralcameratrigger;
s1.sidecameratrigger = sidecameratrigger;
path = 'E:\DATA\';
fullpath = strcat(path, stimulus, '_', datestr(now, 'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s \n', fullpath)
save(fullpath, '-struct', 's1');