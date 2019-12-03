function acquireIntanIndenterOpto_MWS_v2(protocol)

% Init DAQ
Fs = 20000;
s = daqSetup(Fs, 'indenterOpto');
optoTriggerRate = 1; % in Hz
optoTriggerSamples = Fs/optoTriggerRate;

switch protocol
    case 'forceSteps'
        %% parameters
        stimulus = 'IndenterOptoIncSteps';
        sweepDuration = 22.5; % in s  (change to 10)
        sweepDurationinSamples = Fs * sweepDuration;
        
        interSweepInterval = 2.5; % in s
        numSweeps = 60;
        len_off = 0; % below platform for moving stage, best to be 0 so no sudden oscillation at beginning of stimulus
        len_on = 8; % so that the maximum len will be at least 1 mm above platform
        %intensities = [0.025, 0.05, 0.1, 0.2, 0.4, 0.8, 1.0, 2];
        intensities = [0, 0, 0.025, 0.025, 0.05, 0.05, 0.1, 0.1, 0.2, 0.2, 0.4, 0.4, 0.8, 0.8, 1.0, 1.0, 1.5, 1.5];
        %intensities = [0, 0.025, 0.05, 0.1, 0.2, 0.4, 0.8, 1.0, 1.5, 0, 0.025, 0.05, 0.1, 0.2, 0.4, 0.8, 1.0, 1.5];
        %intensities = [0.2, 0.4, 0.2, 0.4];
        %stepFrequency = 0.5; %(for 1s long steps if sweep duration is 10s)
        stepFrequency = 1;
        
        optoDuration = 600; % in ms between 0 - 1000
        delay=-.05;
        optoFrequency=20;
        PulseWidth=10;
        
        %% Build stimuli #1
        
        if optoFrequency > optoDuration / PulseWidth
            optoFrequency = 1000 / PulseWidth
            'Warning: Opto Frequency Adjusted'
        end
        
        
        squareWaveT = 0:1/Fs:(.8*sweepDuration)-1/Fs; %builds steps (time)
        squareWaveY = (square(2*pi*stepFrequency*squareWaveT,50)+1)/2; %Builds square wav
        squareWaveZ = (square(2*pi*stepFrequency*squareWaveT,50*(optoDuration/500))+1)/2; %Builds square wave
        
        if PulseWidth >= optoDuration
            
            duty_cycle = (optoDuration / PulseWidth)*100
            squareWaveO = (square(2*pi*(optoFrequency*2)*squareWaveT,duty_cycle)+1)/2;
        else
            duty_cycle = (optoFrequency*(PulseWidth/1000) / (optoDuration/1000))*100;
            squareWaveO = (square(2*pi*optoFrequency*squareWaveT,duty_cycle)+1)/2;
        end
        
        
        squareWaveZ = squareWaveO .* squareWaveZ;
        
        delay_matrix = zeros(1,(abs(delay)*Fs));
        delay_matrix2 = zeros(1,(abs(delay)*Fs+20000));
        
        
        for i = 1:length(squareWaveZ)/20000/2;
            if i ==1
                squareWaveZ(1:(optoDuration-delay)/1000*20000+1)=0;
                
            else
                squareWaveZ((2*i-2)*20000:(2*i-(1+(1-optoDuration/1000)))*20000+1)=0;
            end
        end
        
        
        if delay > 0
            squareWaveOpto = [delay_matrix,squareWaveZ(1:end-length(delay_matrix))];
            'Opto after tactile stim'
            
            squareWaveOpto2 = [delay_matrix2,squareWaveZ(1:end-length(delay_matrix2))];
            'Opto after tactile stim'
        else
            squareWaveOpto=[squareWaveZ(abs(delay)*Fs+1:end),delay_matrix];
            'Opto before tactile stim'
            
            squareWaveOpto2 = [squareWaveZ(abs(delay)*Fs+20001:end),delay_matrix2];
            'Opto before tactile stim'
        end
        
        
        
        squareWaveY = squareWaveY'; %transposes it
        squareWaveOpto = squareWaveOpto';
        squareWaveOpto2 = squareWaveOpto2';
        
        for i = 1:size(intensities,2)
            if i == 1
                squareWaveY(1:i*Fs/stepFrequency) = intensities(i) * squareWaveY(1:i*Fs/stepFrequency);
            else
                squareWaveY((i-1)*Fs/stepFrequency:i*Fs/stepFrequency) = intensities(i) *...
                    squareWaveY((i-1)*Fs/stepFrequency:i*Fs/stepFrequency);
            end
        end
        
        clear squareWaveT
        
        
        %% Build Stimuli #2
        
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(1:1:end) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
        displacement = ones(sweepDurationinSamples,1) * len_on;
        blankTenth = zeros(sweepDurationinSamples*.1,1);
        force = [blankTenth; squareWaveY; blankTenth];
        
        %% applying filter to force
        windowSize = .015; % in s
        windowSizeSamples = round(windowSize * Fs);
        b = (1/windowSizeSamples)*ones(1,windowSizeSamples);
        a = 1;
        
        filteredForce = filter(b,a,force);
        %%
        
        if delay <0
            optoTrigger = [blankTenth(1:end-delay*-Fs);squareWaveOpto(1:delay*-Fs); squareWaveOpto; blankTenth];
            optoTrigger2 = [blankTenth(1:end-delay*-Fs);squareWaveOpto2(1:delay*-Fs); squareWaveOpto2; blankTenth];
        else
            optoTrigger = [blankTenth;squareWaveOpto; blankTenth];
            optoTrigger2 = [blankTenth(1:end-delay*-Fs);squareWaveOpto2(1:delay*-Fs); squareWaveOpto2; blankTenth];
        end
        
        %For more complicated sweep patterns
        %optoTriggerModule = [zeros(size(optoTrigger)); optoTrigger; optoTrigger];
        %forceModule = [force; force; zeros(size(force))];
        %lengthModule = [displacement; displacement; zeros(size(displacement))];
        %triggerModule = [trigger; trigger; trigger];
        
        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullTrigger(1)=0;
        
        fullLength = repmat([displacement; ones(interSweepSamples,1)*len_on],numSweeps,1);
        
        %ramping length up and down for first and last second in stimulus
        fullLength(1:2e4) = len_off:(len_on-len_off)/2e4:len_on-1/2e4;
        fullLength(end-2e4:end) = len_on:(len_off-len_on)/2e4:len_off-1/2e4;
        
        fullForce = repmat([filteredForce; zeros(interSweepSamples,1)],numSweeps,1);
        fullOptoTrigger = repmat([optoTrigger; zeros(interSweepSamples,1); optoTrigger2; zeros(interSweepSamples,1)],numSweeps/2,1);
        
%         figure
%         plot(fullForce(1:1500000))
%         hold on
%         plot(fullOptoTrigger(1:1500000))
        
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullOptoTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
        
        
    case 'forceSine'
        %% parameters
        stimulus = 'IndenterSine';
        sweepDuration = 2; % in s
        sweepDurationinSamples = sweepDuration * Fs;
        interSweepInterval = .5; % in s
        repetitions = 10;
        
   
        len_off = 0;
        len_on = 6; % so that the maximum len will be ~ 1 mm above platform
        forceRange = [5,10,20,40];
        frequencies = [2, 5, 10, 20, 40, 60, 80, 100];
        numSweeps = size(frequencies,2)*size(forceRange,2)*repetitions*2;
        voltageConversion = 50; % mN/V calibrated 1/23/18
        
        optoDuration = 1300; % in ms between 0 - 1000
        delay=0;
        optoFrequency=30;
        PulseWidth=10;
        
        if optoFrequency > optoDuration / PulseWidth
            optoFrequency = 1000 / PulseWidth
            'Warning: Opto Frequency Adjusted'
        end
        
        
        %%build stimuli
        sineWaveT = 0:1/Fs:(.5*sweepDuration)-1/Fs;
        sineWaveY = zeros(size(sineWaveT,2),numSweeps);
        sineAmplitude = zeros(numSweeps,1);
        sineFrequency = zeros(numSweeps,1);
        
        squareWaveT=0:1/Fs:(.65*sweepDuration)-1/Fs;
        squareWaveZ = (square(2*pi*squareWaveT,50*(optoDuration/500))+1)/2; %Builds square wave
        
        if PulseWidth >= optoDuration
            
            duty_cycle = (optoDuration / PulseWidth)*100;
            squareWaveO = (square(2*pi*(optoFrequency*2)*squareWaveT,duty_cycle)+1)/2;
        else
            duty_cycle = (optoFrequency*(PulseWidth/1000) / (optoDuration/1000))*100;
            squareWaveO = (square(2*pi*optoFrequency*squareWaveT,duty_cycle)+1)/2;
        end
        
        
        squareWaveZ = squareWaveO .* squareWaveZ;
        
        delay_matrix = zeros(1,(abs(delay)*Fs));
        delay_matrix2 = zeros(1,(abs(delay)*Fs+20000));
        
        
        for i = 1:length(squareWaveZ)/20000/2;
            if i ==1
                squareWaveZ(1:(optoDuration-delay)/1000*20000+1)=0;
                
            else
                squareWaveZ((2*i-2)*20000:(2*i-(1+(1-optoDuration/1000)))*20000+1)=0;
            end
        end
        
        
        if delay > 0
            squareWaveOpto = [delay_matrix,squareWaveZ(1:end-length(delay_matrix))];
            'Opto after tactile stim'
            
        else
            squareWaveOpto=[squareWaveZ(abs(delay)*Fs+1:end),delay_matrix];
            'Opto before tactile stim'
            
        end
        
        %transposes it
        squareWaveOpto = squareWaveOpto';
        
        for i = 1:numSweeps
            
            sineAmplitude(i) = rand*((forceRange(2)-forceRange(1))/voltageConversion)+forceRange(1)/voltageConversion; % in V
            
            sineFrequency(i) = frequencies(randi(size(frequencies),1)); % in Hz
            sineWaveY(:,i) = (sin(2*pi*sineFrequency(i)*sineWaveT - pi/2 )+1)/2*sineAmplitude(i);
            
        end
        s1.sineAmplitude = sineAmplitude*voltageConversion; % in mN
        s1.sineFrequency = sineFrequency;
        
        %% Build Stimuli

        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
        
        blankQuarter = zeros(sweepDurationinSamples*.25,1);
        blank15 = zeros(sweepDurationinSamples*.175,1);
        
        if delay <0
            optoTrigger = [blank15(1:end-delay*-Fs);squareWaveOpto(1:delay*-Fs); squareWaveOpto; blank15];
        else
            optoTrigger = [blank15;squareWaveOpto; blank15];
        end
        
        
        length1 = ones(sweepDurationinSamples,1) * len_on;
        fullForce = [];
        for i=1:numSweeps
            fullForce = [fullForce; blankQuarter; sineWaveY(:,i); blankQuarter;zeros(interSweepSamples,1)];
        end
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length1; ones(interSweepSamples,1)*len_on],numSweeps,1);
        %ramping length up and down for first and last half second in stimulus
        fullLength(1:1e4) = len_off:(len_on-len_off)/1e4:len_on-1/1e4;
        fullLength(end-1e4:end) = len_on:(len_off-len_on)/1e4:len_off-1/1e4;
        
        fullOptoTrigger = repmat([optoTrigger; zeros(interSweepSamples,1);zeros(length(optoTrigger),1);zeros(interSweepSamples,1)],round(numSweeps/2),1);
        
        figure
        plot(fullForce)
        hold on
        plot(fullOptoTrigger)
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
        frequencies = [2, 5, 10, 20, 40, 60, 80, 100];
        repetitions = 10;
        numSweeps = size(frequencies,2)*repetitions;

        voltageConversion = 50; % mN/V calibrated 1/23/18
        
        optoDuration = 5000; % in ms between 0 - 1000
        delay=0;
        optoFrequency=30;
        PulseWidth=10;
        
        squareWaveT=0:1/Fs:(.50*sweepDuration)-1/Fs;
        squareWaveZ = (square(2*pi*squareWaveT,50*(optoDuration/500))+1)/2; %Builds square wave
        
        duty_cycle = (optoFrequency*(PulseWidth/1000) / (optoDuration/1000))*100;
        squareWaveO = (square(2*pi*optoFrequency*squareWaveT,duty_cycle)+1)/2;

        
        squareWaveZ = squareWaveO .* squareWaveZ;
        
        delay_matrix = zeros(1,(abs(delay)*Fs));
        delay_matrix2 = zeros(1,(abs(delay)*Fs+20000));
        
%         
%         for i = 1:length(squareWaveZ)/20000/2;
%             if i ==1
%                 squareWaveZ(1:(optoDuration-delay)/1000*20000+1)=0;
%                 
%             else
%                 squareWaveZ(((2*i-2)*20000):(2*i-(1+(1-optoDuration/1000)))*20000+1)=0;
%             end
%         end
%         
%         
%         if delay > 0
%             squareWaveOpto = [delay_matrix,squareWaveZ(1:end-length(delay_matrix))];
%             'Opto after tactile stim'
%             
%         else
%             squareWaveOpto=[squareWaveZ(abs(delay)*Fs+1:end),delay_matrix];
%             'Opto before tactile stim'
%             
%         end
        
           squareWaveOpto = [delay_matrix,squareWaveZ(1:end-length(delay_matrix))];        

%transposes it
        squareWaveOpto = squareWaveOpto';
        
        
        
        for i = 1:repetitions
            tempIndex = randperm(size(frequencies,2));
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
        
        %% Build Stimuli
        sweepDurationinSamples = Fs * sweepDuration;
        interSweepSamples = interSweepInterval * Fs;
        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1; % trigger determines length of intan recording, which will have buffer at beg and end
        
        blankQuarter = zeros(sweepDurationinSamples*.25,1);
        blankQuarter1 = zeros(sweepDurationinSamples*.245,1);
        blankQuarter2 = zeros(sweepDurationinSamples*.255,1);
        %blank15 = zeros(sweepDurationinSamples*.175,1);
        
        if delay <0
            optoTrigger = [blankQuarter1(1:end-delay*-Fs);squareWaveOpto(1:delay*-Fs); squareWaveOpto; blankQuarter2];
        else
            optoTrigger = [blankQuarter1;squareWaveOpto; blankQuarter2];
        end
        
        length1 = ones(sweepDurationinSamples,1) * len_on;
        fullForce = [];
        
        for i=1:numSweeps
            fullForce = [fullForce; blankQuarter; sineWaveY(:,i); blankQuarter;zeros(interSweepSamples,1)];
        end
        
        fullTrigger = repmat([trigger; zeros(interSweepSamples,1)],numSweeps,1);
        fullLength = repmat([length1; ones(interSweepSamples,1)*len_on],numSweeps,1);
        %ramping length up and down for first and last half second in stimulus
        fullLength(1:1e4) = len_off:(len_on-len_off)/1e4:len_on-1/1e4;
        fullLength(end-1e4:end) = len_on:(len_off-len_on)/1e4:len_off-1/1e4;
        
        fullOptoTrigger = repmat([optoTrigger; zeros(interSweepSamples,1);zeros(length(optoTrigger),1);zeros(interSweepSamples,1)],round(numSweeps/2),1);
        
%         figure
%         plot(fullForce)
%         hold on
%         plot(fullOptoTrigger)
        %% Queue data
        
        s.queueOutputData(horzcat(fullTrigger, fullCameraTrigger, fullLength, fullForce))
        
        [data, time] = s.startForeground();
        
end
%% Save variables as fields of a structure:
s1.stimulus = stimulus;
s1.Fs = Fs;
s1.data = data;
s1.time = time;
s1.trigger = fullTrigger;
s1.optoTrigger = fullOptoTrigger;
s1.optoOn = true;
s1.optoDuration = optoDuration;
s1.optoTriggerRate = optoTriggerRate;
path = 'E:\DATA\MWS\';
fullpath = strcat(path,s1.stimulus,'_', datestr(now,'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s \n', fullpath)
save(fullpath, '-struct', 's1');


end


