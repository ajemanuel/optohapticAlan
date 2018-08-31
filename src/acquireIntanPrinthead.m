function acquireIntanPrinthead(protocol)
%Brief protocol that controls optotagging LED
%   run at beginning and end of experiment.


%% Init DAQ
Fs = 20000;
s = daqSetup(Fs, 'printHead');

%% parameters
stimulus = 'printHead';
interSweepInterval = 3; % in s
interSweep_samples = interSweepInterval * Fs;
num_sweeps = 2;

switch protocol
    case 'test'
        sweepDuration = 4.5; % in s
        sweepDurationinSamples = Fs * sweepDuration;
        time_pin = 0.25; % in s
        indentDur_samples = time_pin * Fs; % convert to samples
        squareWaveT = 0:1/Fs:sweepDuration - 1/Fs;
        
        numPositions = 24;
        indentFrequency = sweepDuration/numPositions;
        dutyCycle = time_pin/(sweepDuration/numPositions)*100;
        squareWaveY = zeros(numPositions,sweepDurationinSamples);%(square(2*pi*indentFrequency*squareWaveT,dutyCycle)+1)/2;
        
        for i = 1:numPositions
            fprintf('%i\n',i)
            if i == 1
                indentStart = 1;
            else
            %    indentStart = (i-1) * indentFrequency * Fs;
                indentStart = (i-1) * (sweepDuration/numPositions) * Fs;
            end
            
            indentEnd = indentStart + indentDur_samples;
            if indentEnd > sweepDurationinSamples
                indentEnd = sweepDurationinSamples-1;
            end
            fprintf('%i %i\n',indentStart,indentEnd)
            squareWaveY(i,floor(indentStart):floor(indentEnd)) = 1;
        end
        squareWaveY = squareWaveY';

        trigger = zeros(sweepDurationinSamples,1);
        trigger(2:1:end-1) = 1;
        fullTrigger = repmat([trigger;zeros(interSweep_samples,1)],num_sweeps,1);
        fullStim = repmat([squareWaveY;zeros(interSweep_samples,numPositions)],num_sweeps,1);
    
    case 'directional'
        num_sweeps = 30;
        speed = 64; % in mm/s
        fprintf('speed %i mm/s\n',speed)
        time_stim = 4/speed; % the length of the pin array is 4mm (width is ~1mm)
        time_isi = 3; % in s
        time_isi_samples = time_isi * Fs;
        overlap = 6; % # of pins to have activated at once
        pinOrder = [1 13 2 14 3 15 4 16 5 17 6 18 7 19 8 20 9 21 10 22 11 23 12 24];
        time_pin = (overlap*time_stim)/ (24 + overlap-1);
        time_pin_samples = floor(time_pin * Fs);
        stim = zeros(int32(time_stim*Fs),24);
        for i = 1:24 % for each pin
            if i ==  1
                indentStart = 1;
            else
                indentStart = floor((i-1)/(24+overlap-1) * time_stim * Fs);
            end
            indentEnd = indentStart + time_pin_samples;
            if indentEnd > time_stim * Fs
                indentEnd = floor(time_stim * Fs - 1);
            end
            stim(indentStart:indentEnd,pinOrder(i)) = 1;
        end
        stim_isi = zeros(time_isi_samples,24);
        half_stim_isi = zeros(time_isi_samples/2,24);
        revStim = flip(stim);
        fullStim = repmat([half_stim_isi;stim;stim_isi;revStim;half_stim_isi],num_sweeps,1);
        fullTrigger = zeros(length(fullStim),1);
        fullTrigger(2:1:end-1) = 1;
        s1.speed = speed;
        s1.num_sweeps = num_sweeps;
        s1.time_isi = time_isi;
        s1.overlap = overlap;
    case 'randSingle'
        time_pin = 0.025; % in s
        time_pin_samples = floor(time_pin * Fs);
        frequency = 10; % in Hz
        num_stim = 2000;
        sweep_dur_samples = num_stim/frequency * Fs;
        num_sweeps = 1;
        stim = zeros(sweep_dur_samples,24);
        time_isi = 2; % in s
        time_isi_samples = time_isi * Fs; % in samples
        rng(20180716)
        locs = zeros(num_stim,1);
        for i = 1:num_stim
            if i == 1
                indentStart = 1;
            else
                indentStart = floor((i-1)/num_stim * sweep_dur_samples);
            end
            indentEnd = floor(indentStart + time_pin_samples);
            pin = randi(24);
            locs(i) = pin;
            stim(indentStart:indentEnd,pin) = 1;
        end
        s1.stimFrequency = frequency;
        s1.locs = locs;
        s1.num_sweeps = num_sweeps;
        stim_isi = zeros(time_isi_samples,24);
        revStim = flip(stim);
        fullStim = repmat([stim_isi;stim;stim_isi;revStim;stim_isi],num_sweeps,1);
        fullTrigger = zeros(length(fullStim),1);
        fullTrigger(2:1:end-1) = 1;
    case 'randPair'
        time_pin = 0.025; % in s
        time_pin_samples = floor(time_pin * Fs);
        frequency = 10; % in Hz
        num_stim = 2000;
        sweep_dur_samples = num_stim/frequency * Fs;
        num_sweeps = 1;
        stim = zeros(sweep_dur_samples,24);
        time_isi = 2; % in s
        time_isi_samples = time_isi * Fs; % in samples
        rng(20180716)
        locs = zeros(num_stim,2);
        for i = 1:num_stim
            if i == 1
                indentStart = 1;
            else
                indentStart = floor((i-1)/num_stim * sweep_dur_samples);
            end
            indentEnd = floor(indentStart + time_pin_samples);
            pin1 = randi(24);
            pin2 = randi(24);
            locs(i,1) = pin1;
            locs(i,2) = pin2;
            stim(indentStart:indentEnd,pin1) = 1;
            stim(indentStart:indentEnd,pin2) = 1;
        end
        
        stim_isi = zeros(time_isi_samples,24);
        revStim = flip(stim);
        fullStim = repmat([stim_isi;stim;stim_isi;revStim;stim_isi],num_sweeps,1);
        fullTrigger = zeros(length(fullStim),1);
        fullTrigger(2:1:end-1) = 1;
        
        
        s1.stimFrequency = frequency;
        s1.locs = locs;
        s1.num_sweeps = num_sweeps;
end
s.queueOutputData(horzcat(fullTrigger, fullStim));

[data, time] = s.startForeground();

% Save the fields of a structure as individual variables:
s1.stimulus = stimulus;
s1.protocol = protocol;
s1.Fs = Fs;
s1.data = data;
s1.time = time;
s1.stim = fullStim;
s1.trigger = fullTrigger;
s1.time_pin = time_pin;
path = 'E:\DATA\';
fullpath = strcat(path, stimulus, '_', datestr(now, 'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s \n', fullpath)
save(fullpath, '-struct', 's1');
            
        
    

end

