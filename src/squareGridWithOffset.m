function [x1,y1,lz1] = squareGridWithOffset(edgeLength, offsetX, offsetY, spacing, numRepetitions, dwellTime, ISI, Fs)
%randSquare Random dot stimulation on a square of size edgeLength x edgeLength. 
%   edgeLength is specified in microns.
%   dwellTime is specified in seconds, recommended dwelltime is .0001 seconds
%   ISI is the time between successive mirror locations, specified in
%   seconds, recommended is .001 seconds.

    voltageToDegrees = 1.25; % degrees/volt, thorlabs small beam galvos
    degreesToDistance = 3075; % microns/degrees, FTH100-1064
    voltageToDistance = voltageToDegrees * degreesToDistance; % volts/microns
    
    rng(.08041961)
    ISISamples = round( ISI * Fs);
    dwellSamples = round(dwellTime * Fs);
    centerSamplePad = round((ISISamples - dwellSamples)/2);
    
    numStim = (edgeLength/spacing)^2 * numRepetitions;
    
    min_x = offsetX - edgeLength/2;
    min_y = offsetY - edgeLength/2;
    max_x = offsetX + edgeLength/2;
    max_y = offsetY + edgeLength/2;
    
    
    %% make grid
    grid_x = repmat([min_x:spacing:max_x],(max_y-min_y)/spacing+1,1);
    grid_y = repmat([min_y:spacing:max_y]',1,(max_x-min_x)/spacing+1);
    grid_positions = [grid_x(:) grid_y(:)];
    grid_positions_voltage = grid_positions / voltageToDistance;
    grid_positions_rand = grid_positions_voltage(randperm(size(grid_positions_voltage,1)),:);
    
    
    
    totalSamples = (numStim + 2)*(ISISamples+dwellSamples); %Number of total samples required, including returning to zero at beg and end.
    x1 = zeros(totalSamples,1);   
    y1 = zeros(totalSamples,1);  
    lz1 = zeros(totalSamples,1); 
    size(lz1)
    for repetition = 1:numRepetitions
       for gridLoc = 1:size(grid_positions_rand) % for each grid
           n = gridLoc + size(grid_positions_rand)*(repetition-1);
           x1(n * ISISamples : (n+1) * ISISamples) = grid_positions_rand(gridLoc,1);
           y1(n * ISISamples : (n+1) * ISISamples) = grid_positions_rand(gridLoc,2);
           lz1(n * ISISamples + centerSamplePad : (n+1) * ISISamples - centerSamplePad ) = 1; % set laser TTL to HIGH
       end

    end
    size(lz1)
end
