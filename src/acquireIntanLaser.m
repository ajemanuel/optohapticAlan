function acquireIntanLaser(protocol)
    % Init DAQ
    Fs = 80000;
    s = daqSetup(Fs,'laser');

    
    % Construct stimulus
    switch protocol
        case 'randSquareWithOffset'
            stimulus = 'randSquareWithOffset';
            edgeLength = 6000; % in microns      
            offsetX = 0; % in microns  [-26000, , -24000, 26000 ]  empirical range [-x, +x, -y, +y]
            offsetY = 22000; % in microns
            numStim = 1000; 
            dwellTime = 0.0005;  %.001 singes FST ruler
            ISI = .1;  %empirical min is .001 seconds (thorlabs mirrors confined to 1cm^2)

            rng(.08041961) % seed random number generator for reproducibility
            [x1,y1,lz1] = randSquareWithOffset(edgeLength, offsetX, offsetY, numStim, dwellTime, ISI, Fs);
            trigger = zeros(1,length(x1));
            trigger(2:end-2) = 1;
            %lz2(1:round(Fs/acqFPS):end) = 9; %possible to trigger with a single sample?
    end



     s.queueOutputData(horzcat(x1, y1, trigger', lz1))
     pause(2);
     data = s.startForeground();



    % Clean up and save congfiguration
    s.release()

    % Save the fields of a structure as individual variables:
    s1.stimulus = stimulus;
    s1.edgeLength = edgeLength;
    s1.offsetX = offsetX;
    s1.offsetY = offsetY;
    s1.numStim = numStim;
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
