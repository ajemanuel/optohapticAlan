function acquireIntanOptotag(protocol)
%Brief protocol that controls optotagging LED
%   run at beginning and end of experiment.


%% Init DAQ
Fs = 20000;
s = daqSetup(Fs, 'opto');

%% parameters
stimulus = 'optotag';
sweepDuration = 5; % in s
sweepDurationinSamples = Fs * sweepDuration;
interSweepInterval = 2; % in s
interSweep_samples = interSweepInterval * Fs;
numSweeps = 60;

switch protocol
    case 'pulse'
        lightDur = 1; % in ms
        lightDur_s = lightDur/1000; % convert to seconds
        lightDur_samples = lightDur_s * Fs; % convert to samples
        numFrequencies = 5;
        optoFrequencies = [1, 2, 5, 10, 20];
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

        
        
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1;
        fullTrigger = repmat([trigger;zeros(interSweep_samples,1)],numSweeps,1);
        fullOpto = repmat([squareWaveY;zeros(interSweep_samples,1)],numSweeps,1);
    
    case 'randomPulse'
        
        lightDur = 50; % in ms
        lightDur_s = lightDur/1000; % convert to seconds
        lightDur_samples = lightDur_s * Fs; % convert to samples
        meanFrequency = 0.5;
        numStim = sweepDuration/meanFrequency;
        rng(20180615)
        starts = int32(rand(numStim,1) * sweepDuration * Fs);
        
        opto = zeros(sweepDurationinSamples,1);
        
        for i = 1:length(starts)
            opto(starts(i):starts(i)+lightDur_samples) = 1;
        end
        
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1;
        fullTrigger = repmat([trigger;zeros(interSweep_samples,1)],numSweeps,1);
        fullOpto = repmat([opto;zeros(interSweep_samples,1)],numSweeps,1);
        
    case 'sustained'
        lightDur = 2; %s
        lightDur_samples = lightDur*Fs; % convert to samples
        lightOnset = 1.5; %s
        lightOnset_samples = lightOnset * Fs;
        lightOffset_samples = lightOnset_samples + lightDur_samples;
        
        opto = zeros(sweepDurationinSamples,1);
        opto(lightOnset_samples:lightOffset_samples) = 1;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1;
        fullTrigger = repmat([trigger;zeros(interSweep_samples,1)],numSweeps,1);
        fullOpto = repmat([opto;zeros(interSweep_samples,1)],numSweeps,1);
    end
        
s.queueOutputData(horzcat(fullTrigger, fullOpto));

[data, time] = s.startForeground();

% Save the fields of a structure as individual variables:
s1.stimulus = stimulus;
s1.Fs = Fs;
s1.data = data;
s1.time = time;
s1.opto = fullOpto;
s1.trigger = fullTrigger;
s1.lightDur = lightDur;
path = 'E:\DATA\';
fullpath = strcat(path, stimulus, '_', datestr(now, 'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s \n', fullpath)
save(fullpath, '-struct', 's1');
            
        
    

end

