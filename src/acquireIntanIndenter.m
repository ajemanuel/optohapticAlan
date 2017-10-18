function acquireIntanIndenter(protocol)

% Init DAQ
Fs = 20000;
s = daqSetup(Fs, 'indenter');

switch protocol
    case 'forceSteps'  %% this protocol gives a train of force steps for the specified duration
        %% parameters
        stimulus = 'IndenterForceSteps';
        sweepDuration = 20; % in s
        interSweepInterval = 1; % in s
        numSweeps = 1;
        len_off = 0; % below platform for moving stage, best to be 0 so no sudden oscillation at beginning o stimulus
        len_on = 8; % so that the maximum len will be above platform
        stepIntensityMilliNewtons = 10; % in mN
        forceConversion = 50; % mN/V
        stepIntensity = stepIntensityMilliNewtons / forceConversion; % in V
        stepFrequency = 1; % 1 s steps
        squareWaveT = 0:1/Fs:(.9*sweepDuration)-1/Fs;
        squareWaveY = (square(2*pi*stepFrequency*squareWaveT,50)+1)/2*stepIntensity;
        squareWaveY = squareWaveY';
        clear squareWaveT
        
        %% build stimuli
        
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
        length = ones(sweepDurationinSamples,1) * len_on;
        blankTwentieth = zeros(sweepDurationinSamples*.05,1);
        force = [blankTwentieth; squareWaveY; blankTwentieth];
        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_on],numSweeps,1);
        
        %ramping length up and down for first and last second in stimulus
        fullLength(1:Fs) = len_off:(len_on-len_off)/2e4:len_on-1/2e4;
        fullLength(end-Fs:end) = len_on:(len_off-len_on)/2e4:len_off-1/2e4;
        
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
        
    case 'forceIncreasingSteps'
        %% parameters
        stimulus = 'IndenterForceSteps';
        sweepDuration = 10; % in s
        interSweepInterval = 1; % in s
        numSweeps = 1;
        len_off = 0; % below platform for moving stage, best to be 0 so no sudden oscillation at beginning of stimulus
        len_on = 8; % so that the maximum len will be at least 1 mm above platform
        intensities = [0.1, 0.2, 0.4, 0.8];
        stepFrequency = 0.5;
        squareWaveT = 0:1/Fs:(.8*sweepDuration)-1/Fs;
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
        length = ones(sweepDurationinSamples,1) * len_on;
        blankTenth = zeros(sweepDurationinSamples*.1,1);
        force = [blankTenth; squareWaveY; blankTenth];
        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_on],numSweeps,1);
        
        %ramping length up and down for first and last second in stimulus
        fullLength(1:2e4) = len_off:(len_on-len_off)/2e4:len_on-1/2e4;
        fullLength(end-2e4:end) = len_on:(len_off-len_on)/2e4:len_off-1/2e4;
        
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
        
        
    case 'forceLengthIncreasingSteps'
        %% parameters
        stimulus = 'IndenterForceLengthSteps';
        sweepDuration = 10; % in s
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepInterval = 3; % in s
        numSweeps = 5;
        len_off = -1; % so that len is below platform
        len_on = 2; % so that the maximum len will be ~ 1 mm above platform
        intensities = [0.1, 0.2, 0.4, 0.8];
        stepFrequency = 0.5;
        if size(intensities,2) ~= (.8*sweepDuration)*stepFrequency
            error('# of force intensities incompatible with sweep duration')
        end
        squareWaveT = 0:1/Fs:(.8*sweepDuration)-1/Fs;
        squareWaveY = (square(2*pi*stepFrequency*squareWaveT,50)+1)/2;
        squareWaveY = squareWaveY';
        
        for i = 1:size(squareWaveY,1)
            if squareWaveY(i) == 0
                squareWaveY(i) = len_off;
            elseif squareWaveY(i) == 1
                squareWaveY(i) = len_on;
            end
        end
        
        % filter length signal to prevent oscillations
        windowSize = 0.2*Fs;
        b = (1/windowSize)*ones(1,windowSize);
        a = 1;
        
        squareWaveY = filter(b, a, squareWaveY);
        
        forceWave = ones(sweepDurationinSamples*.8,1);
        
        forceWave(1:Fs*1.5) = forceWave(1:Fs*1.5) * intensities(1);
        forceWave(Fs*1.5+1:Fs*3.5) = forceWave(Fs*1.5+1:Fs*3.5) * intensities(2);
        forceWave(Fs*3.5+1:Fs*5.5) = forceWave(Fs*3.5+1:Fs*5.5) * intensities(3);
        forceWave(Fs*5.5+1:end) = forceWave(Fs*5.5+1:end) * intensities(4);
     
        
        clear squareWaveT
        
        %% build stimuli
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
        
        forceTenth = ones(sweepDurationinSamples*.1,1) * intensities(1);
        force = [forceTenth; forceWave; forceTenth];
            
        lengthTenth = ones(sweepDurationinSamples*.1,1) * len_off;
        length = [lengthTenth; squareWaveY; lengthTenth];

        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_off],numSweeps,1);
        fullForce = repmat([force; ones(interSweepSamples,1)*intensities(1)],numSweeps,1);
        
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