function acquireIntanOptotag()
%Brief protocol that controls optotagging LED
%   run at beginning and end of experiment.


%% Init DAQ
Fs = 20000;
s = daqSetup(Fs, 'opto');

%% parameters
stimulus = 'optotag';
sweepDuration = 10; % in s
interSweepInterval = 2; % in s
numSweeps = 10;


lightDur = 4; % in ms
lightDur_s = lightDur/1000; % convert to seconds
lightDur_samples = lightDur_s * Fs; % convert to samples
numFrequencies = 5;
optoFrequencies = [5, 10, 20, 40, 80];
squareWaveT = 0:1/Fs:(1/numFrequencies*sweepDuration) - 1/Fs;

for i = 1:length(optoFrequencies)
    dutyCycle = lightDur_samples/(Fs/optoFrequencies(i))*100;
    if i == 1
        squareWaveY = (square(2*pi*optoFrequencies(i)*squareWaveT,dutyCycle)+1)/2;
    else
        squareWaveY = [squareWaveY (square(2*pi*optoFrequencies(i)*squareWaveT,dutyCycle)+1)/2];
    end
end

squareWaveY = squareWaveY';

sweepDurationinSamples = Fs * sweepDuration;
interSweepSamples = interSweepInterval * Fs;
trigger = zeros(sweepDurationinSamples,1);
trigger(2:1:end-1) = 1;
fullTrigger = repmat([trigger;zeros(interSweepSamples,1)],numSweeps,1);
fullOpto = repmat([squareWaveY;zeros(interSweepSamples,1)],numSweeps,1);

s.queueOutputData(horzcat(fullTrigger, fullOpto));

[data, time] = s.startForeground();

% Save the fields of a structure as individual variables:
s1.stimulus = stimulus;
s1.Fs = Fs;
s1.data = data;
s1.time = time;
s1.trigger = fullTrigger;
s1.lightDur = lightDur;
path = 'E:\DATA\';
fullpath = strcat(path, stimulus, '_', datestr(now, 'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s \n', fullpath)
save(fullpath, '-struct', 's1');
            
        
    

end

