function [x1,y1,lz1] = randSquareWithOffset(edgeLength, offsetX, offsetY, numStim, dwellTime, ISI, Fs)
%randSquare Random dot stimulation on a square of size edgeLength x edgeLength. 
%   edgeLength is specified in microns.
%   dwellTime is specified in seconds, recommended dwelltime is .0001 seconds
%   ISI is the time between successive mirror locations, specified in
%   seconds, recommended is .001 seconds.

    voltageToDegrees = 1.25; % degrees/volt, thorlabs small beam galvos
    degreesToDistance = 3075; % microns/degrees, FTH100-1064
    voltageToDistance = voltageToDegrees * degreesToDistance; % volts/microns
    
    
    ISISamples = round( ISI * Fs);
    dwellSamples = round(dwellTime * Fs);
    centerSamplePad = round((ISISamples - dwellSamples)/2);
    totalSamples = (numStim + 2)*ISISamples; %Number of total samples required, including returning to zero at beg and end.
    x1 = zeros(totalSamples,1);   
    y1 = zeros(totalSamples,1);  
    lz1 = zeros(totalSamples,1); 

    for n = 1:numStim
       x1(n * ISISamples : (n+1) * ISISamples) = (offsetX + unifrnd(-edgeLength/2, edgeLength/2))/voltageToDistance;
       y1(n * ISISamples : (n+1) * ISISamples) =(offsetY + unifrnd(-edgeLength/2, edgeLength/2))/voltageToDistance;
       lz1(n * ISISamples + centerSamplePad : (n+1) * ISISamples - centerSamplePad ) = 1; % set laser TTL to HIGH
    end

