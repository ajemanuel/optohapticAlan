function acquireIntanOptotag_jg(protocol, peakVolt)
%Brief protocol that controls optotagging LED
%   run at beginning and end of experiment.


%% Init DAQ
Fs = 20000;
s = daqSetup_jg(Fs, 'optoMod');

%% parameters
stimulus = 'optotag';

interSweepInterval = 2.5; % in s
interSweep_samples = interSweepInterval * Fs;
numSweeps = 20;

switch protocol
    case 'pulse'
        
        sweepDuration = 10; % in s
        sweepDurationinSamples = Fs * sweepDuration;
        
        lightDur = 10; % in ms
        lightDur_s = lightDur/1000; % convert to seconds
        lightDur_samples = lightDur_s * Fs; % convert to samples
        
        %optoFrequencies = [0.2];
        optoFrequencies = [1, 2, 5, 10, 20];
        %optoFrequencies = [1, 1, 1, 1, 1];
        numFrequencies = length(optoFrequencies);
        squareWaveT = 0:1/Fs:(1/numFrequencies*sweepDuration) - 1/Fs;

        for i = 1:numFrequencies
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
    
    case 'pairedPulse'
        sweepDuration = 4; % in s
        sweepDurationinSamples = Fs * sweepDuration;
        lightDur = 10; % in ms
        lightDur_s = lightDur/1000; % convert to seconds
        lightDur_samples = lightDur_s * Fs; % convert to samples
        
        lags = [32, 64, 100, 128, 256, 500, 1000, 2000]; % in ms
        permutedLags = lags(randperm(size(lags,2)));
        
        numLags = length(lags);
        numRepetitions = 20;
        allLags = repmat(permutedLags,1,numRepetitions);
        allLags_samples = allLags * Fs/1000;
        numSweeps = numLags * numRepetitions;
        s1.allLags = allLags;
        s1.numSweeps = numSweeps;
        optos = zeros(sweepDurationinSamples,numSweeps);
        
        startFirstPulse = sweepDurationinSamples/4;
        endFirstPulse = startFirstPulse + lightDur_samples;
        optos(startFirstPulse:endFirstPulse,:) = 1;
        
        for i = 1:numSweeps
            startSecondPulse = startFirstPulse + allLags_samples(i);
            endSecondPulse = startSecondPulse + lightDur_samples;
            optos(startSecondPulse:endSecondPulse,i) = 1;
        end

      
        
        
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1;
        fullTrigger = repmat([trigger;zeros(interSweep_samples,1)],numSweeps,1);
        for i = 1:numSweeps
            if i == 1
                fullOpto = [optos(:,i);zeros(interSweep_samples,1)];
            else
                fullOpto = [fullOpto; optos(:,i); zeros(interSweep_samples,1)];
            end
        end
        
    case 'randomPulse'
        sweepDuration=60;
        sweepDurationinSamples=sweepDuration*Fs;
        lightDur = 10; % in ms
        lightDur_s = lightDur/1000; % convert to seconds
        lightDur_samples = lightDur_s * Fs; % convert to samples
        meanFrequency = 1;
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
        peakVolt = 5;
        sweepDuration = 4; % in s
        sweepDurationinSamples = Fs * sweepDuration;
        
        lightDur = 2; %s
        lightDur_samples = lightDur*Fs; % convert to samples
        lightOnset = 1; %s
        lightOnset_samples = lightOnset * Fs;
        lightOffset_samples = lightOnset_samples + lightDur_samples;
        
        opto = zeros(sweepDurationinSamples,1);
        opto(lightOnset_samples:lightOffset_samples) = 1;
        opto = opto .* peakVolt;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1;
        fullTrigger = repmat([trigger;zeros(interSweep_samples,1)],numSweeps,1);
        fullOpto = repmat([opto;zeros(interSweep_samples,1)],numSweeps,1);
        
    case 'sustained40Hz'
        sweepDuration = 4; % 6 in s
        sweepDurationinSamples = Fs * sweepDuration;
        
        lightDur = 2; %2 s
        lightDur_samples = lightDur*Fs; % convert to samples
        lightOnset = 1; %s
        lightOnset_samples = lightOnset * Fs;
        lightOffset_samples = lightOnset_samples + lightDur_samples;
        
        optoFreq = 40;
        dutyCycle = 50;
        t = 0:1/Fs:lightDur - 1/Fs;
        squareWave = (square(2*pi*optoFreq*t, dutyCycle)+1)/2;
        
        opto = zeros(sweepDurationinSamples,1);
        opto(lightOnset_samples:lightOffset_samples-1) = squareWave(:);
        opto = opto .* peakVolt;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1;
        fullTrigger = repmat([trigger;zeros(interSweep_samples,1)],numSweeps,1);
        fullOpto = repmat([opto;zeros(interSweep_samples,1)],numSweeps,1);
    
    case 'rampedSustained'
        sweepDuration = 4.5; % in s
        sweepDurationinSamples = Fs * sweepDuration;
        pwmPeriod_samples = 100; % pulse period, higher = more gradual
        
        rampOnset = 1; %s
        rampOnset_samples = rampOnset * Fs;
        rampDur = 0.5; %s
        rampDur_samples = rampDur * Fs;
        lightOnset_samples = rampOnset_samples + rampDur_samples;
        lightDur = 2; %s
        lightDur_samples = lightDur * Fs; % convert to samples
        lightOffset_samples = lightOnset_samples + lightDur_samples;
        
        opto = zeros(sweepDurationinSamples,1);
        opto(rampOnset_samples:lightOnset_samples-1) = pwmSignalRamp(rampDur_samples, pwmPeriod_samples);
        opto(lightOnset_samples:lightOffset_samples) = 1;
        
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1;
        fullTrigger = repmat([trigger;zeros(interSweep_samples,1)],numSweeps,1);
        fullOpto = repmat([opto;zeros(interSweep_samples,1)],numSweeps,1);
        
    case 'rampedSustained40Hz'
        optoFreq = 40;
        dutyCycle = 50;
        LEDOffset = 0.05;
        
        sweepDuration = 6.5; % 6.5 in s
        sweepDurationinSamples = Fs * sweepDuration;
        
        rampOnset = 2; %s
        rampOnset_samples = rampOnset * Fs;
        rampDur = 0.5; %s
        rampDur_samples = rampDur * Fs;
        steadyOnset_samples = rampOnset_samples + rampDur_samples;
        steadyDur = 2; %2 s
        steadyDur_samples = steadyDur * Fs; % convert to samples
        lightOffset_samples = steadyOnset_samples + steadyDur_samples;
        lightDur = rampDur + steadyDur;
        lightDur_samples = lightDur * Fs;
        
        
        nCycles = optoFreq * lightDur;
        t = 0:1/Fs:lightDur - 1/Fs;
        squareWave = (square(2*pi*optoFreq*t, dutyCycle)+1)/2;
        % Ramping did not seem linear so I made a two piece linear ramp to
        % make it more gradual
        envelope = cat(2, linspace(0, 0.25, rampDur_samples/2), linspace(0.25, 1, rampDur_samples/2), ones(1, steadyDur_samples));
        squareWave = squareWave .* envelope;
        squareWave = LEDOffset + squareWave .* (peakVolt-LEDOffset);
%         plot(t, squareWave);
        opto = zeros(sweepDurationinSamples,1);
        opto(rampOnset_samples:lightOffset_samples-1) = squareWave(:);
        
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1;
        fullTrigger = repmat([trigger;zeros(interSweep_samples,1)],numSweeps,1);
        fullOpto = repmat([opto;zeros(interSweep_samples,1)],numSweeps,1);                
    otherwise
        error('Protocol not found.')
            
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

