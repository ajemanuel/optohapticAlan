function acquireIntanIndenter(protocol)

% Init DAQ
Fs = 20000;
s = daqSetup(Fs, 'indenter');

switch protocol
    case 'forceSteps'
        %% parameters
        stimulus = 'IndenterForceSteps';
        sweepDuration = 20; % in s
        interSweepInterval = 2; % in s
        numSweeps = 5;
        len = 4; %so that the maximum len will be ~ 1 mm above platform
        stepIntensity = 1; % in V
        stepFrequency = 0.5;
        squareWaveT = 0:1/Fs:(.5*sweepDuration)-1/Fs;
        squareWaveY = (square(2*pi*stepFrequency*squareWaveT,50)+1)/2*stepIntensity;
        squareWaveY = squareWaveY';
        clear squareWaveT
        
        %% build stimuli
        
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
        length = ones(sweepDurationinSamples,1) * len;
        blankQuarter = zeros(sweepDurationinSamples*.25,1);
        force = [blankQuarter; squareWaveY; blankQuarter];
        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len],numSweeps,1);
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
        
    case 'forceIncreasingSteps'
        %% parameters
        stimulus = 'IndenterForceSteps';
        sweepDuration = 20; % in s
        interSweepInterval = 2; % in s
        numSweeps = 20;
        len = 4; % so that the maximum len will be ~ 1 mm above platform
        intensities = [0.1, 0.2, 0.4, 0.8, 1.6];
        stepFrequency = 0.5;
        squareWaveT = 0:1/Fs:(.5*sweepDuration)-1/Fs;
        squareWaveY = (square(2*pi*stepFrequency*squareWaveT,50)+1)/2;
        squareWaveY = squareWaveY';
        
        for i = 1:size(intensities,2)
            if i == 1
                squareWaveY(1:i*Fs/stepFrequency) = intensities(i) * squareWaveY(1:i*Fs/stepFrequency);
            else
                squareWaveY((i-1)*Fs/stepFrequency:i*Fs/stepFrequency) = intensities(i) *...
                    squareWaveY((i-1)*Fs/stepFrequency:i*Fs/stepFrequency);
            end
        end
        
        clear squareWaveT
        
        %% build stimuli
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
        length = ones(sweepDurationinSamples,1) * len;
        blankQuarter = zeros(sweepDurationinSamples*.25,1);
        force = [blankQuarter; squareWaveY; blankQuarter];
        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len],numSweeps,1);
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
        
    
    case 'forceSine'
        %% parameters
        stimulus = 'IndenterSine';
        sweepDuration = 20; % in s
        interSweepInterval = 2; % in s
        numSweeps = 5;
        len = 4; % so that the maximum len will be ~ 1 mm above platform
        sineAmplitude = 0.2; % in V
        sineFrequency = 40; % in Hz
        
        
        %% Build Stimuli
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
                
        sineWaveT = 0:1/Fs:(.5*sweepDuration)-1/Fs;
        sineWaveY = (sin(2*pi*sineFrequency*sineWaveT)+1)/2*sineAmplitude;
        sineWaveY = sineWaveY';
        
        blankQuarter = zeros(sweepDurationinSamples*.25,1);
        
        length = ones(sweepDurationinSamples,1) * len;
        force = [blankQuarter; sineWaveY; blankQuarter];
        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len],numSweeps,1);
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        
                
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
        
end



% Save the fields of a structure as individual variables:
s1.stimulus = stimulus;
s1.Fs = Fs;
s1.data = data;
s1.time = time;
s1.trigger = fullTrigger;
path = 'E:\DATA\';
fullpath = strcat(path, stimulus, '_', datestr(now, 'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s \n', fullpath)
save(fullpath, '-struct', 's1');

end