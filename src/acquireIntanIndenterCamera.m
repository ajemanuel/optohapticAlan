function acquireIntanIndenterCamera(protocol)

% Init DAQ
Fs = 20000;
s = daqSetup(Fs, 'indenterCamera');
cameraTriggerRate = 10; % in Hz
cameraTriggerSamples = Fs/cameraTriggerRate;

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
        
        %% build stimuli        
        
        % square wave for force
        squareWaveT = 0:1/Fs:(.9*sweepDuration)-1/Fs;
        squareWaveY = (square(2*pi*stepFrequency*squareWaveT,50)+1)/2*stepIntensity;
        squareWaveY = squareWaveY';
        clear squareWaveT
             

        
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        % build trigger
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
        % build camera trigger
        cameraTrigger = zeros(sweepDurationinSamples,1);
        maxCameraTriggers = sweepDurationinSamples/cameraTriggerSamples;
        for j = 10:maxCameraTriggers-10
            cameraTrigger(round(j * cameraTriggerSamples):1:round(j*cameraTriggerSamples)+20) = 1;
        end
        % build length      
        length = ones(sweepDurationinSamples,1) * len_on;
        blankTwentieth = zeros(sweepDurationinSamples*.05,1);
        % build force
        force = [blankTwentieth; squareWaveY; blankTwentieth];
        
        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullCameraTrigger = repmat([cameraTrigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_on],numSweeps,1);
        
        %ramping length up and down for first and last second in stimulus
        fullLength(1:Fs) = len_off:(len_on-len_off)/2e4:len_on-1/2e4;
        fullLength(end-Fs:end) = len_on:(len_off-len_on)/2e4:len_off-1/2e4;
        
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        boxcarWindow = 15; % in ms
        boxcarWindow_samples = boxcarWindow/1000*Fs;
        fullForce = movmean(fullForce,boxcarWindow_samples);
        
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullCameraTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
        
    case 'forceIncreasingSteps'
        %% parameters
        stimulus = 'IndenterForceSteps';
        sweepDuration = 20; % in s
        sweepDurationinSamples = Fs * sweepDuration;
        
        interSweepInterval = .5; % in s
        numSweeps = 30;
        len_off = 0; % below platform for moving stage, best to be 0 so no sudden oscillation at beginning of stimulus
        len_on = 9; % so that the maximum len will be at least 1 mm above platform
        intensities = [0.025, 0.05, 0.1, 0.2, 0.4, 0.8, 1.0, 1.5, 0.025, 0.05, 0.1, 0.2, 0.4, 0.8, 1.0, 1.5];
        %intensities = [0.025, 0.05, 0.1, 0.2, 0.4, 0.8, 1.0, 1.5];
        stepFrequency = 1;
        squareWaveT = 0:1/Fs:(.8*sweepDuration)-1/Fs;
        squareWaveY = (square(2*pi*stepFrequency*squareWaveT,50)+1)/2;
        squareWaveY = squareWaveY';
        
        % build camera trigger
        cameraTrigger = zeros(sweepDurationinSamples,1);
        maxCameraTriggers = sweepDurationinSamples/cameraTriggerSamples;
        for j = 10:maxCameraTriggers-10
            cameraTrigger(round(j * cameraTriggerSamples):1:round(j*cameraTriggerSamples)+20) = 1;
        end
        
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
        
        
        fullCameraTrigger = repmat([cameraTrigger; zeros(interSweepSamples,1)],numSweeps,1);        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_on],numSweeps,1);
        
        %ramping length up and down for first and last second in stimulus
        fullLength(1:2e4) = len_off:(len_on-len_off)/2e4:len_on-1/2e4;
        fullLength(end-2e4:end) = len_on:(len_off-len_on)/2e4:len_off-1/2e4;
        
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        boxcarWindow = 15; % in ms
        boxcarWindow_samples = boxcarWindow/1000*Fs;
        fullForce = movmean(fullForce,boxcarWindow_samples);
        
        
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullCameraTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
        

    case 'forceTwoSteps'
        %% parameters
        stimulus = 'IndenterForceSteps';
        sweepDuration = 20; % in s
        sweepDurationinSamples = Fs * sweepDuration;
        
        interSweepInterval = 0; % in s
        numSweeps = 1;
        len_off = 0; % below platform for moving stage, best to be 0 so no sudden oscillation at beginning of stimulus
        len_on = 10; % so that the maximum len will be at least 1 mm above platform
        intensities = zeros(16,1);
        intensities(1:2:end) = .04; % 2 mN
        intensities(2:2:end) = .2; % 10 mN
        stepFrequency = 1;
        squareWaveT = 0:1/Fs:(.8*sweepDuration)-1/Fs;
        squareWaveY = (square(2*pi*stepFrequency*squareWaveT,50)+1)/2;
        squareWaveY = squareWaveY';
        
        % build camera trigger
        cameraTrigger = zeros(sweepDurationinSamples,1);
        maxCameraTriggers = sweepDurationinSamples/cameraTriggerSamples;
        for j = 10:maxCameraTriggers-10
            cameraTrigger(round(j * cameraTriggerSamples):1:round(j*cameraTriggerSamples)+20) = 1;
        end
        
        for i = 1:size(intensities,1)
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
        
        
        fullCameraTrigger = repmat([cameraTrigger; zeros(interSweepSamples,1)],numSweeps,1);        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_on],numSweeps,1);
        
        %ramping length up and down for first and last second in stimulus
        fullLength(1:2e4) = len_off:(len_on-len_off)/2e4:len_on-1/2e4;
        fullLength(end-2e4:end) = len_on:(len_off-len_on)/2e4:len_off-1/2e4;
        
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        boxcarWindow = 15; % in ms
        boxcarWindow_samples = boxcarWindow/1000*Fs;
        fullForce = movmean(fullForce,boxcarWindow_samples);
        
        
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullCameraTrigger, fullLength, fullForce))
        
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
        sweepDuration = 2; % in s
        sweepDurationinSamples = sweepDuration * Fs;
        interSweepInterval = 0.5; % in s
        numSweeps = 500;
        len_off = 0;
        len_on = 9; % so that the maximum len will be ~ 1 mm above platform
        forceRange = [1,40];
        %forceRange = [0,75];
        frequencies = [2, 5, 10, 20, 40, 50, 60, 80, 100, 120];
        %frequencies = [2];
        voltageConversion = 53.869; % mN/V calibrated 1/23/18
            
        
        %build stimuli
        sineWaveT = 0:1/Fs:(.5*sweepDuration)-1/Fs;
        sineWaveY = zeros(size(sineWaveT,2),numSweeps);
        sineAmplitude = zeros(numSweeps,1);
        sineFrequency = zeros(numSweeps,1);
        for i = 1:numSweeps
            
            sineAmplitude(i) = rand*((forceRange(2)-forceRange(1))/voltageConversion)+forceRange(1)/voltageConversion; % in V
            
            sineFrequency(i) = frequencies(randi(size(frequencies),1)); % in Hz
            sineWaveY(:,i) = (sin(2*pi*sineFrequency(i)*sineWaveT - pi/2 )+1)/2*sineAmplitude(i);
            
        end
        s1.sineAmplitude = sineAmplitude*voltageConversion; % in mN
        s1.sineFrequency = sineFrequency;
        % build camera trigger
        cameraTrigger = zeros(sweepDurationinSamples,1);
        maxCameraTriggers = sweepDurationinSamples/cameraTriggerSamples;
        for j = 2:maxCameraTriggers-2
            cameraTrigger(round(j * cameraTriggerSamples):1:round(j*cameraTriggerSamples)+20) = 1;
        end        
        
        %% Build Stimuli
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
                
        blankQuarter = zeros(sweepDurationinSamples*.25,1);
        
        length = ones(sweepDurationinSamples,1) * len_on;
        fullForce = [];
        for i=1:numSweeps
            fullForce = [fullForce; blankQuarter; sineWaveY(:,i); blankQuarter;zeros(interSweepSamples,1)];
        end
        fullCameraTrigger = repmat([cameraTrigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_on],numSweeps,1);
        %ramping length up and down for first and last half second in stimulus
        fullLength(1:1e4) = len_off:(len_on-len_off)/1e4:len_on-1/1e4;
        fullLength(end-1e4:end) = len_on:(len_off-len_on)/1e4:len_off-1/1e4;
        
                
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullCameraTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();

case 'forceSineRamp'
        %% parameters
        stimulus = 'IndenterSine';
        sweepDuration = 10; % in s
        sweepDurationinSamples = sweepDuration * Fs;
        interSweepInterval = .5; % in s
        len_off = 0;
        len_on = 6; % so that the maximum len will be ~ 1 mm above platform
        forceRange = [0,25];
        frequencies = [2; 5; 10; 20; 40; 50; 60; 80; 100; 120];
        repetitions = 2;
        numSweeps = size(frequencies,1)*repetitions;
        voltageConversion = 53.869; % mN/V calibrated 1/23/18
        for i = 1:repetitions
            tempIndex = randperm(size(frequencies,1));
            if i == 1
                sineFrequency = frequencies(tempIndex);
            else
                sineFrequency = [sineFrequency; frequencies(tempIndex)];
            end
        end
        %build stimuli
        sineWaveT = 0:1/Fs:(.5*sweepDuration)-1/Fs;
        sineWaveY = zeros(size(sineWaveT,2),numSweeps);
        for i = 1:numSweeps
            amplitudeRamp = (sineWaveT*((forceRange(2)-forceRange(1))/(.5*sweepDuration)) + forceRange(1))/voltageConversion;
            sineWaveY(:,i) = (sin(2*pi*sineFrequency(i)*sineWaveT - pi/2 )+1)/2.*amplitudeRamp;
        end
        s1.forceRange = forceRange;
        s1.sineFrequency = sineFrequency;
        % build camera trigger
        cameraTrigger = zeros(sweepDurationinSamples,1);
        maxCameraTriggers = sweepDurationinSamples/cameraTriggerSamples;
        for j = 2:maxCameraTriggers-2
            cameraTrigger(round(j * cameraTriggerSamples):1:round(j*cameraTriggerSamples)+20) = 1;
        end        
        
        %% Build Stimuli
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
                
        blankQuarter = zeros(sweepDurationinSamples*.25,1);
        
        length = ones(sweepDurationinSamples,1) * len_on;
        fullForce = [];
        for i=1:numSweeps
            fullForce = [fullForce; blankQuarter; sineWaveY(:,i); blankQuarter;zeros(interSweepSamples,1)];
        end
        fullCameraTrigger = repmat([cameraTrigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_on],numSweeps,1);
        %ramping length up and down for first and last half second in stimulus
        fullLength(1:1e4) = len_off:(len_on-len_off)/1e4:len_on-1/1e4;
        fullLength(end-1e4:end) = len_on:(len_off-len_on)/1e4:len_off-1/1e4;
        
                
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullCameraTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();

    case 'forceSineBump'
        %% parameters
        stimulus = 'IndenterSine';
        sweepDuration = 3; % in s
        sweepDurationinSamples = sweepDuration * Fs;
        interSweepInterval = 0.5; % in s
        numSweeps = 250;
        len_off = 0;
        len_on = 9; % so that the maximum len will be ~ 1 mm above platform
        forceRange = [1,50];
        frequencies = [2];
        voltageConversion = 53.869; % mN/V calibrated 1/23/18
            
        
        %build stimuli
        sineWaveT = 0:1/Fs:.25-1/Fs; % quarter second sine bump
        sineWaveY = zeros(size(sineWaveT,2),numSweeps);
        sineAmplitude = zeros(numSweeps,1);
        sineFrequency = zeros(numSweeps,1);
        for i = 1:numSweeps
            
            if i > 150 && mod(i, 10) == 0
                sineAmplitude(i) = 75/voltageConversion; % 75 mN in V
            else
                sineAmplitude(i) = rand*((forceRange(2)-forceRange(1))/voltageConversion)+forceRange(1)/voltageConversion; % in V
            end
            sineFrequency(i) = frequencies(randi(size(frequencies),1)); % in Hz
            sineWaveY(:,i) = (sin(2*pi*sineFrequency(i)*sineWaveT))*sineAmplitude(i);
            
        end
        s1.sineAmplitude = sineAmplitude*voltageConversion; % in mN
        s1.sineFrequency = sineFrequency;
        % build camera trigger
        cameraTrigger = zeros(sweepDurationinSamples,1);
        maxCameraTriggers = sweepDurationinSamples/cameraTriggerSamples;
        for j = 2:maxCameraTriggers-2
            cameraTrigger(round(j * cameraTriggerSamples):1:round(j*cameraTriggerSamples)+20) = 1;
        end        
        
        %% Build Stimuli
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
                
        blankHalfSecond = zeros(Fs*.5,1);
        blankEnd = zeros(sweepDurationinSamples - size(blankHalfSecond,1) - 0.25 * Fs,1);
        
        length = ones(sweepDurationinSamples,1) * len_on;
        fullForce = [];
        for i=1:numSweeps
            fullForce = [fullForce; blankHalfSecond; sineWaveY(:,i); blankEnd;zeros(interSweepSamples,1)];
        end
        fullCameraTrigger = repmat([cameraTrigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_on],numSweeps,1);
        %ramping length up and down for first and last half second in stimulus
        fullLength(1:1e4) = len_off:(len_on-len_off)/1e4:len_on-1/1e4;
        fullLength(end-1e4:end) = len_on:(len_off-len_on)/1e4:len_off-1/1e4;
        
                
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullCameraTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();    
end



% Save variables as fields of a structure:
s1.cameraTriggerRate = cameraTriggerRate;
s1.stimulus = stimulus;
s1.Fs = Fs;
s1.data = data;
s1.time = time;
s1.trigger = fullTrigger;
s1.cameraTrigger = fullCameraTrigger;
path = 'E:\DATA\';
fullpath = strcat(path, stimulus, '_', datestr(now, 'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s \n', fullpath)
save(fullpath, '-struct', 's1');

end