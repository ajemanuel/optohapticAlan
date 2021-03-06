function acquireIntanIndenterOpto(protocol, optoOn)

% Init DAQ
Fs = 20000;
s = daqSetup(Fs, 'indenterOpto');
optoTriggerRate = 10; % in Hz
optoTriggerSamples = Fs/optoTriggerRate;
optoDuration = 15; % in ms
if nargin < 2
    optoOn = true;
end
    
switch protocol
    case 'forceSteps'  %% this protocol gives a train of force steps for the specified duration
        %% parameters
        stimulus = 'IndenterOptoForceSteps';
        sweepDuration = 20; % in s
        interSweepInterval = 1; % in s
        
        numSweeps = 1;
        len_off = 0; % below platform for moving stage, best to be 0 so no sudden oscillation at beginning o stimulus
        len_on = 6; % so that the maximum len will be above platform
        stepIntensityMilliNewtons = 20; % in mN
        forceConversion = 53.869; % mN/V
        stepIntensity = stepIntensityMilliNewtons / forceConversion; % in V
        stepFrequency = .5; % 1 s steps
        
        %% build stimuli        
        
        % square wave for force
        squareWaveT = 0:1/Fs:(.8*sweepDuration)-1/Fs;
        squareWaveY = (square(2*pi*stepFrequency*squareWaveT,50)+1)/2*stepIntensity;
        squareWaveY = squareWaveY';
        clear squareWaveT
             

        
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        % build trigger
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
        % build camera trigger
        optoTrigger = zeros(sweepDurationinSamples,1);
        if optoOn == true
            maxOptoTriggers = sweepDurationinSamples/optoTriggerSamples;
            for j = 10:maxOptoTriggers-10
                optoTrigger(round(j * optoTriggerSamples):1:round(j*optoTriggerSamples)+Fs/(optoDuration*1000)) = 1;
            end
        end
        % build length      
        length = ones(sweepDurationinSamples,1) * len_on;
        blankTenth = zeros(sweepDurationinSamples*.1,1);
        % build force
        force = [blankTenth; squareWaveY; blankTenth];
        
        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullOptoTrigger = repmat([optoTrigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_on],numSweeps,1);
        
        %ramping length up and down for first and last second in stimulus
        fullLength(1:Fs) = len_off:(len_on-len_off)/2e4:len_on-1/2e4;
        fullLength(end-Fs:end) = len_on:(len_off-len_on)/2e4:len_off-1/2e4;
        
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        boxcarWindow = 15; % in ms
        boxcarWindow_samples = boxcarWindow/1000*Fs;
        fullForce = movmean(fullForce,boxcarWindow_samples);
        
        
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullOptoTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
        
    case 'forceStepsOptoOdd'  %% this protocol gives a train of force steps for the specified duration
        %% parameters
        stimulus = 'IndenterOptoForceSteps';
        sweepDuration = 20; % in s
        interSweepInterval = .25; % in s
        
        numSweeps = 15;
        len_off = 0; % below platform for moving stage, best to be 0 so no sudden oscillation at beginning o stimulus
        len_on = 6; % so that the maximum len will be above platform
        stepIntensityMilliNewtons = 40; % in mN
        forceConversion = 53.869; % mN/V
        stepIntensity = stepIntensityMilliNewtons / forceConversion; % in V
        stepFrequency = .5; % 1 s steps
        optoLag = -0.25; % in seconds
        
        %% build stimuli        
        
        % square wave for force
        squareWaveT = 0:1/Fs:(.8*sweepDuration)-1/Fs;
        squareWaveY = (square(2*pi*stepFrequency*squareWaveT,50)+1)/2*stepIntensity;
        squareWaveY = squareWaveY';
        clear squareWaveT
             

        
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        % build trigger
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
        % build opto trigger
        optoTrigger = zeros(sweepDurationinSamples,1);
        if optoOn == true
            stepStarts = [0:40000:300000] + 40000; % only true for 0.5 s sampling
            stepEnds = [20000:40000:300000] + 40000;
            optoStarts = optoLag*Fs:Fs/optoTriggerRate:(stepEnds(1) - stepStarts(1))-optoLag*Fs;
            for i = 1:2:size(stepStarts,2) % every other step
                for j = 1:size(optoStarts,2)
                    optoTrigger(stepStarts(i)+optoStarts(j):stepStarts(i)+optoStarts(j)+optoDuration/1000*Fs) = 1;
                end
            end
        end
        % build length      
        length = ones(sweepDurationinSamples,1) * len_on;
        blankTenth = zeros(sweepDurationinSamples*.1,1);
        % build force
        force = [blankTenth; squareWaveY; blankTenth];
        
        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullOptoTrigger = repmat([optoTrigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_on],numSweeps,1);
        
        %ramping length up and down for first and last second in stimulus
        fullLength(1:Fs) = len_off:(len_on-len_off)/2e4:len_on-1/2e4;
        fullLength(end-Fs:end) = len_on:(len_off-len_on)/2e4:len_off-1/2e4;
        
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        boxcarWindow = 15; % in ms
        boxcarWindow_samples = boxcarWindow/1000*Fs;
        fullForce = movmean(fullForce,boxcarWindow_samples);
        
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullOptoTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
    case 'forceStepsOptoOdd_constant'
        %% parameters
        stimulus = 'IndenterOptoForceSteps';
        sweepDuration = 20; % in s
        interSweepInterval = .25; % in s
        
        numSweeps = 10;
        len_off = 0; % below platform for moving stage, best to be 0 so no sudden oscillation at beginning o stimulus
        len_on = 6; % so that the maximum len will be above platform
        stepIntensityMilliNewtons = 75; % in mN
        forceConversion = 53.869; % mN/V
        stepIntensity = stepIntensityMilliNewtons / forceConversion; % in V
        stepFrequency = .5; % 1 s steps
        optoLag = -0.25; % in seconds
        
        %% build stimuli        
        
        % square wave for force
        squareWaveT = 0:1/Fs:(.8*sweepDuration)-1/Fs;
        squareWaveY = (square(2*pi*stepFrequency*squareWaveT,50)+1)/2*stepIntensity;
        squareWaveY = squareWaveY';
        clear squareWaveT
             

        
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        % build trigger
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
        % build opto trigger
        optoTrigger = zeros(sweepDurationinSamples,1);
        if optoOn == true
            stepStarts = [0:40000:300000] + 40000; % only true for 0.5 Hz sampling
            stepEnds = [20000:40000:300000] + 40000;
            optoStarts = stepStarts(1:2:end)+optoLag*Fs;
            optoEnds = stepEnds(1:2:end) - optoLag*Fs;
            for j = 1:size(optoStarts,2)
                optoTrigger(optoStarts(j):optoEnds(j)) = 1;
            end
        end
        % build length      
        length = ones(sweepDurationinSamples,1) * len_on;
        blankTenth = zeros(sweepDurationinSamples*.1,1);
        % build force
        force = [blankTenth; squareWaveY; blankTenth];
        
        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullOptoTrigger = repmat([optoTrigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_on],numSweeps,1);
        
        %ramping length up and down for first and last second in stimulus
        fullLength(1:Fs) = len_off:(len_on-len_off)/2e4:len_on-1/2e4;
        fullLength(end-Fs:end) = len_on:(len_off-len_on)/2e4:len_off-1/2e4;
        
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        boxcarWindow = 15; % in ms
        boxcarWindow_samples = boxcarWindow/1000*Fs;
        fullForce = movmean(fullForce,boxcarWindow_samples);
        
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullOptoTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();    
        
        
    case 'forceIncreasingSteps'
        %% parameters
        stimulus = 'IndenterOptoIncSteps';
        sweepDuration = 20; % in s
        sweepDurationinSamples = Fs * sweepDuration;
        
        interSweepInterval = 3; % in s
        numSweeps = 1;
        len_off = 0; % below platform for moving stage, best to be 0 so no sudden oscillation at beginning of stimulus
        len_on = 6; % so that the maximum len will be at least 1 mm above platform
        intensities = [0.025, 0.05, 0.1, 0.2, 0.4, 0.8, 1.0, 1.5, 0.025, 0.05, 0.1, 0.2, 0.4, 0.8, 1.0, 1.5];
        stepFrequency = 1;
        squareWaveT = 0:1/Fs:(.8*sweepDuration)-1/Fs;
        squareWaveY = (square(2*pi*stepFrequency*squareWaveT,50)+1)/2;
        squareWaveY = squareWaveY';
        
        % build led trigger
        optoTrigger = zeros(sweepDurationinSamples,1);
        if optoOn == true
            maxOptoTriggers = sweepDurationinSamples/optoTriggerSamples;
            for j = 10:maxOptoTriggers-10
                optoTrigger(round(j * optoTriggerSamples):1:round(j*optoTriggerSamples)+20) = 1;
            end
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
        
        
        fullOptoTrigger = repmat([optoTrigger; zeros(interSweepSamples,1)],numSweeps,1);        
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
        
        s.queueOutputData(horzcat(fullTrigger, fullOptoTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
        
        
 
    case 'varLag'
        %% parameters
        stimulus = 'IndenterOpto';
        sweepDuration = 2; % in s
        sweepDurationinSamples = sweepDuration * Fs;
        interSweepInterval = 0.5; % in s
        len = 8; % so that the maximum len will be ~ 1 mm above platform
        
        lags = [-.45,-.25,-.2,-.1,-.05,-0.025, -0.01, 0, 0.25, 0.45];
        numLags = size(lags,2);
        lagsPermuted = lags(randperm(numLags));
        numRepetitions = 20;
        forceIntensity = 75; % mN
        numSweeps = numLags * numRepetitions; % currently 340
        
        s1.lagsPermuted = lagsPermuted;
        s1.numRepetitions = numRepetitions;
        s1.forceIntensity = forceIntensity;
        s1.numSweeps = numSweeps;
        
        % build led trigger
        opto = zeros(numSweeps,sweepDurationinSamples);
        for i = 1:numSweeps
            lag = lagsPermuted(mod(i,numLags)+1) * Fs + sweepDurationinSamples*(3/4);
            if lag == 0
                lag = 1;
            end
            optoEnd = int32(lag+optoDuration/1000*Fs);
            opto(i,lag:optoEnd) = 1;
        end
        
        %% Build Stimuli
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
                
        onHalf = ones(sweepDurationinSamples*.5,1);
        forceIntensity_V = forceIntensity / 53.869; % converting to Voltage
        
        
        blankQuarter = zeros(sweepDurationinSamples*.25,1);
        
        length = ones(sweepDurationinSamples,1) * len;
        force = [blankQuarter; onHalf*forceIntensity_V; blankQuarter];
        for i = 1:numSweeps
            if i == 1
                fullOptoTrigger = [opto(i,:)'; zeros(interSweepSamples,1)];
            else
                fullOptoTrigger = [fullOptoTrigger; opto(i,:)'; zeros(interSweepSamples,1)];
            end
        end
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len],numSweeps,1);
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        % filtering force
        boxcarWindow = 15; % in ms
        boxcarWindow_samples = boxcarWindow/1000*Fs;
        fullForce = movmean(fullForce,boxcarWindow_samples);
        %ramping length up and down for first and last second in stimulus
        fullLength(1:2e4) = 0:(len-0)/2e4:len-1/2e4;
        fullLength(end-2e4:end) = len:(0-len)/2e4:0-1/2e4;
                
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullOptoTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
    case 'varLagMultiDur'
        %% parameters
        stimulus = 'IndenterOpto';
        sweepDuration = 2; % in s
        sweepDurationinSamples = sweepDuration * Fs;
        interSweepInterval = 0.5; % in s
        len = 8; % so that the maximum len will be ~ 1 mm above platform
        
        numSweeps = 200;
        
        % will randomly draw from these options when generating stimulus
        lags = [-0.5,0.5]; % location of light pulse relative to onset of step in s
        durs = [0, 10, 1, 5]; % duration of LED pulse in ms
        
        numLags = size(lags,2);
        numDurs = size(durs,2);
        
        lagsPermuted = zeros(numSweeps,1);
        dursPermuted = zeros(numSweeps,1);
        
        forceIntensity = 75; % mN
        
        
        s1.forceIntensity = forceIntensity;
        s1.numSweeps = numSweeps;
        
        % build led trigger
        opto = zeros(numSweeps,sweepDurationinSamples);
        for i = 1:numSweeps
            lag = lags(randi(numLags))* Fs + sweepDurationinSamples*(1/4);
            dur = durs(randi(numDurs));
            if lag == 0
                lag = 1;
            end
            optoEnd = int32(lag+dur/1000*Fs);
            opto(i,lag:optoEnd) = 1;
            
            lagsPermuted(i) = lag;
            dursPermuted(i) = dur;
        end
        s1.dursPermuted = dursPermuted;
        s1.lagsPermuted = lagsPermuted;
        
        %% Build Stimuli
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
                
        onHalf = ones(sweepDurationinSamples*.5,1);
        forceIntensity_V = forceIntensity / 53.869; % converting to Voltage
        
        
        blankQuarter = zeros(sweepDurationinSamples*.25,1);
        
        length = ones(sweepDurationinSamples,1) * len;
        force = [blankQuarter; onHalf*forceIntensity_V; blankQuarter];
        for i = 1:numSweeps
            if i == 1
                fullOptoTrigger = [opto(i,:)'; zeros(interSweepSamples,1)];
            else
                fullOptoTrigger = [fullOptoTrigger; opto(i,:)'; zeros(interSweepSamples,1)];
            end
        end
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len],numSweeps,1);
        fullForce = repmat([force; zeros(interSweepSamples,1)],numSweeps,1);
        % filtering force
        boxcarWindow = 15; % in ms
        boxcarWindow_samples = boxcarWindow/1000*Fs;
        fullForce = movmean(fullForce,boxcarWindow_samples);
        %ramping length up and down for first and last second in stimulus
        fullLength(1:2e4) = 0:(len-0)/2e4:len-1/2e4;
        fullLength(end-2e4:end) = len:(0-len)/2e4:0-1/2e4;
                
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullOptoTrigger, fullLength, fullForce))
        
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
        % build opto trigger
        optoTrigger = zeros(sweepDurationinSamples,1);
        optoTrigger(floor(sweepDuration*Fs/6):floor(sweepDuration*Fs*5/6)) = 1;     
        
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
        fullOptoTrigger = repmat([optoTrigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length; ones(interSweepSamples,1)*len_on],numSweeps,1);
        %ramping length up and down for first and last half second in stimulus
        fullLength(1:1e4) = len_off:(len_on-len_off)/1e4:len_on-1/1e4;
        fullLength(end-1e4:end) = len_on:(len_off-len_on)/1e4:len_off-1/1e4;
        
                
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullOptoTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
end

% Save variables as fields of a structure:
s1.cameraTriggerRate = optoTriggerRate;
s1.stimulus = stimulus;
s1.Fs = Fs;
s1.data = data;
s1.time = time;
s1.trigger = fullTrigger;
s1.cameraTrigger = fullOptoTrigger;
s1.optoOn = optoOn;
s1.optoDuration = optoDuration;
path = 'E:\DATA\';
fullpath = strcat(path, stimulus, '_', datestr(now, 'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s \n', fullpath)
save(fullpath, '-struct', 's1');

end