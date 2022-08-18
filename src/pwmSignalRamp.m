function ramp = pwmSignalRamp(rampDurationSamples, pwmPeriod)
    ramp = zeros(rampDurationSamples, 1);
    periodsPerStep = round(rampDurationSamples / pwmPeriod / pwmPeriod);
    startInd = 1;
    for on_samples = 1:pwmPeriod
        on_fraction = on_samples / pwmPeriod;
        endInd = min([startInd+periodsPerStep*pwmPeriod-1 rampDurationSamples]);
        stepSignal = repmat(pwmSignal1period(on_fraction, pwmPeriod), 1, periodsPerStep);
        ramp(startInd:endInd) = stepSignal(1:endInd-startInd+1);
        startInd = endInd + 1;
    end
end

function signal = pwmSignal1period(on_fraction, period)
    % Generate one period of a pulse width modulated signal
    on_samples = round(period * on_fraction);
    off_samples = period - on_samples;
    signal = [ones(1, on_samples) zeros(1, off_samples)];
end

