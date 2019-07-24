function acquireIntanLaser(protocol)
    % Init DAQ
    Fs = 20000;
    s = daqSetup(Fs,'laser');

    
    % Construct stimulus
    switch protocol
        case 'randSquareWithOffset'
            stimulus = 'randSquareWithOffset';
            edgeLength = 12000; % in microns      
            offsetX = -26000; % in microns  [-26000, , -24000, 26000 ]  empirical range [-x, +x, -y, +y]
            offsetY = 0; % in microns
            numStim = 8000; 
            dwellTime = 0.0003;  %.001 singes FST ruler
            ISI = .1;  %empirical min is .001 seconds (thorlabs mirrors confined to 1cm^2)

            rng(.08041961) % seed random number generator for reproducibility
            [x1,y1,lz1] = randSquareWithOffset(edgeLength, offsetX, offsetY, numStim, dwellTime, ISI, Fs);
            trigger = zeros(1,length(x1));
            trigger(2:end-2) = 1;
            s1.edgeLength = edgeLength;
            %lz2(1:round(Fs/acqFPS):end) = 9; %possible to trigger with a single sample?
        case 'squareGridWithOffset'
            stimulus = 'squareGridWithOffset';
            edgeLength = 4000;
            offsetX = -15000;
            offsetY = -20000;
            spacing = 100;
            numRepetitions = 10;
            dwellTime = 0.0001;
            ISI = 0.1;
            
            [x1,y1,lz1] = squareGridWithOffset(edgeLength, offsetX, offsetY, spacing, numRepetitions, dwellTime, ISI, Fs);
            trigger = zeros(1,length(x1));
            trigger(2:end-2) = 1;
            s1.edgeLength = edgeLength;
        case 'rastGridWithOffset'
            stimulus = 'rastGridWithOffset';
            edgeLength = 6000;
            offsetX = 0;
            offsetY = 0;
            spacing = 100;
            numRepetitions = 50;
            dwellTime = 0.00001;
            ISI = 0.001;
            direction = 'left';
            [x1,y1,lz1] = rastGridWithOffset(edgeLength, offsetX, offsetY, spacing, numRepetitions, dwellTime, ISI, Fs, direction);
            trigger = zeros(1,length(x1));
            trigger(2:end-2) = 1;
            s1.direction = direction;
            s1.edgeLength = edgeLength;
        case 'pulseSinglePoint'
            stimulus = 'singlePoint';
            offsetX = -26500;
            offsetY = 0;
            stimFrequency = 20; % in Hz
            dwellTime = 0.0003; % in s
            duration = 2; % in s
            numTrials = 30;
            ISI = 6; % in s
            
            % construct stimulus
            squareWaveT = 0:1/Fs:duration;
            duty = dwellTime/(1/stimFrequency) * 100;
            squareWaveY = (square(2*pi*stimFrequency*squareWaveT,duty)+1)/2;
            squareWaveY = squareWaveY';
            interStim = zeros(ISI*Fs,1);
            
            lz1 = repmat([interStim; squareWaveY], numTrials, 1);
            lz1 = [lz1; interStim]; % end with another intertrial interval
            trigger = zeros(length(lz1),1);
            trigger(2:end-2) = 1;
            trigger = trigger';
            x1 = ones(length(lz1),1) * offsetX;
            y1 = ones(length(lz1),1) * offsetY;
            voltageToDegrees = 1.25; % degrees/volt, thorlabs small beam galvos
            degreesToDistance = 3075; % microns/degrees, FTH100-1064
            voltageToDistance = voltageToDegrees * degreesToDistance; % microns/volt
            x1 = x1 / voltageToDistance;
            y1 = y1 / voltageToDistance;
            
            
            s1.stimFrequency = stimFrequency;
            s1.stimDuration = duration;
            s1.interTrialTime = ISI;
            s1.numTrials = numTrials;
        
            
    end


    s.queueOutputData(horzcat(x1, y1, trigger', lz1))
    pause(1);
    data = s.startForeground();



    % Clean up and save congfiguration
    s.release()

    % Save the fields of a structure as individual variables:
    s1.stimulus = stimulus;
    
    s1.offsetX = offsetX;
    s1.offsetY = offsetY;
    %s1.numStim = numStim;
    s1.dwellTime = dwellTime;
    s1.ISI = ISI;
    s1.x = x1;
    s1.y = y1;
    s1.laser = lz1;
    s1.trigger = trigger';
    s1.Fs = Fs;
    s1.data = data;
    path = 'E:\DATA\';
    fullpath = strcat(path, stimulus, '_', datestr(now, 'yymmdd HHMM SS'), '.mat');
    fprintf('saved as %s \n', fullpath)
    save(fullpath, '-struct', 's1');
end
