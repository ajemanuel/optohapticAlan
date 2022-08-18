function [laserCommand] = generateLightCommand_jg(modulationFreqHz, stimDur_s, rampDur_s, numSpots, StimRate, peakLaserVolt)
    % Function to create light command for photostimulation with
    % mutiple spots.
    
    % For multiple spots, the laser signal needs to
    % 1) have n times the frequency of the desired stimulation frequency per spot, as the mirrors
    % will move between spots between laserCommandCyclces
    % 2) be corrected for the movement time of the galvo mirrors (be 0
    % during mirror movement times)
    % 3) be advanced in time to compensate for the laser modulation delay

    mirrorMoveTimeSec = 0.002; % mirrors take 2ms to move (seems like a conservative estimate, step response time is 800 microsec max)
    laserModulationLagSec = 0.001; % 1ms from laser command to actual laser power change

    laserOffset = 1;

    % Create laser commands:
    rampDirection = 'on';
    if strcmp(rampDirection, 'on')
        onDur_s = stimDur_s - rampDur_s;
        onRamp_envelope = linspace(0, 1, round(rampDur_s*StimRate))';
        on_envelope = ones(round(StimRate*onDur_s), 1);
        envelope = cat(1, onRamp_envelope, on_envelope); % append a 0 to beginning of vector
    elseif strcmp(rampDirection, 'off')
        envelope = linspace(1, 0, round(rampDur_s*StimRate))';
    else
        disp('rampDirection must be either on or off.')
    end

    % Create sinusoid of correct duration:
%     numSpots = numel(gridX);
    nCycles = modulationFreqHz * stimDur_s;
    %t = linspace(0, nCycles*2*pi, numel(envelope))'; %creates evenly spaced vector of numel(envelope) points between 0 and nCycles*2*pi
    t = linspace(0, nCycles*pi*numSpots, numel(envelope))'; % stimulation sites not = 2, but length of gridX vector


    mirrorMoveTimeSamples = round(StimRate * mirrorMoveTimeSec); 
    laserModulationLagSamples = round(StimRate * laserModulationLagSec);

    sinusoid = sin(t); % Sin so it starts at the beginning of a cycle.
    squareWave = sinusoid>0; 
    % signal needs to stay low during mirror movement time, so goes from 0
    % to sine wave only after movement has completed
    
    laserOn = ~imdilate(diff([0; squareWave])~=0, ones(mirrorMoveTimeSamples, 1));
    
    % Only output light for one spot
    oneSpot = 1;
    if oneSpot
        t = 0:1/StimRate:stimDur_s - 1/StimRate;
        oneSpotOn = (square(2*pi*modulationFreqHz*t, 1/numSpots*100)+1)'/2;
        laserOn = laserOn .* oneSpotOn;
    end

    % turn square wave of laser command into sinusoidally modulated wave
%     laserCommand = envelope .* laserOn .* abs(sinusoid); % here frequency of signal is doubled by taking the absolute value (necessary for bilateral stimulation at X Hz)
    laserCommand = envelope .* laserOn;

    laserCommand = circshift(laserCommand, [-laserModulationLagSamples, 1]); % shifts the laser command signal forward to account for laser modulation lag
    

    % Scale laser:
    laserCommand = laserOffset + laserCommand .* (peakLaserVolt-laserOffset);
end

