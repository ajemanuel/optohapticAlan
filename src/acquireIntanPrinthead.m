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
numSweeps = 2;

switch protocol
    case 'test'
        sweepDuration = 4.5; % in s
        sweepDurationinSamples = Fs * sweepDuration;
        indentDur = 250; % in ms
        indentDur_s = indentDur/1000; % convert to seconds
        indentDur_samples = indentDur_s * Fs; % convert to samples
        squareWaveT = 0:1/Fs:sweepDuration - 1/Fs;
        
        numPositions = 24;
        indentFrequency = sweepDuration/numPositions;
        dutyCycle = indentDur_s/(sweepDuration/numPositions)*100;
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
        fullTrigger = repmat([trigger;zeros(interSweep_samples,1)],numSweeps,1);
        fullStim = repmat([squareWaveY;zeros(interSweep_samples,numPositions)],numSweeps,1);
    
        
s.queueOutputData(horzcat(fullTrigger, fullStim));

[data, time] = s.startForeground();

% Save the fields of a structure as individual variables:
s1.stimulus = stimulus;
s1.Fs = Fs;
s1.data = data;
s1.time = time;
s1.stim = fullStim;
s1.trigger = fullTrigger;
s1.indentDur = indentDur;
path = 'E:\DATA\';
fullpath = strcat(path, stimulus, '_', datestr(now, 'yymmdd HHMM SS'), '.mat');
fprintf('saved as %s \n', fullpath)
save(fullpath, '-struct', 's1');
            
        
    

end

