function acquireDualCamera()

% Init DAQ
Fs = 20000;
s = daqSetup(Fs, 'recordDualCamera');

[data, time] = s.startForeground();



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