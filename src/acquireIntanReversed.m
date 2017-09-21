function acquireIntanReversed()

% Init DAQ
Fs = 20000;
s = daqSetup(Fs);

% Construct stimulus
stimulus = 'acquireIntanReversed';
edgeLength = 8000; %, 2236, 2000, 1789, 1600, 1431,1280, 1145, 1024, 916, 820, 733, 656, 587, 524, 469, 420, 376, 336, 300];        
offsetX = 0;
offsetY = 0;
numStim = 300;
maxISI = .02;
dwellTime = .0003;


rng(.08041961) % seed random number generator for reproducibility

[x1,y1,lz1,lz2] = randSquareWithOffset(edgeLength, offsetX, offsetY, numStim, dwellTime, maxISI, Fs);
lz2(1:1:5) = 0;
lz2(1:1:200) = 5; %possible to trigger with a single sample?
lz2(200:1:end) = 0;
queueOutputData(s, horzcat(flip(x1), flip(y1), flip(lz1), flip(lz2));
pause(2);
% Output stimulus
[data,time] = s.startForeground();



% Clean up and save congfiguration
s.release();

% Save the fields of a structure as individual variables:
s1.stimulus = stimulus;
s1.edgeLength = edgeLength;
s1.offsetX = offsetX;
s1.offsetY = offsetY;
s1.numStim = numStim;
s1.dwellTime = dwellTime;
s1.ISI = maxISI;
s1.x1 = x1;
s1.y1 = y1;
s1.lz1 = lz1;
s1.data = data;
s1.time = time;
save(strcat(stimulus,'_',datestr(now, 'yymmdd HHMM SS'),'.mat'), '-struct', 's1');