function bases = createBasesFunctions(numBases, binSize, kernDur, linearStretch, basesType, truncate)
%
% Examples: bases = createBasesFunctions(10, 0.05, 5, 10, 'POST', false)
%           bases = createBasesFunctions(10, 0.05, 5, 10, 'POST', true)
% 
% INPUTS:
% numBases = number of bases functions for PRE and POST functions; for SYM
%      the numBases entered will correspond to half of the output bases since
%      they are mirrored along the center (i.e. if you want a total of 14 bases,
%      (7 spanning the pre-event period, 7 spanning the post-event period), then
%      you enter numBases=7 and the program will create all 14.
% binSize = size of bins used for binning the data (in seconds)
% kernDur = the length of a trial (in seconds)
% linearStretch = indicates how stretched the cosine functions will be; the larger the value, the wider the functions.
% basesType = a string indicating if the bases should be pre, post or symmetric (i.e. 'PRE', 'POST', or 'SYM')
% varargin = indicates whether to truncate the bases when they reach the kernDur
% 
% OUTPUTS:
% bases = the bases functions 
% 
% Based on Park, et al. (2014). Encoding and decoding in parietal cortex during sensorimotor decision-making. Nat. Neurosci. 17, 1395–1403.

arguments
    numBases double = 10
    binSize double = 0.05
    kernDur double = 5
    linearStretch double = 10
    basesType char = 'POST'
    truncate logical = true
end

% Send an error if the linear stretch value is not greater than 0
if linearStretch <= 0
    error('linearStretch should be greater than 0');
end

% Check that the bin size is smaller than the trial duration
if binSize >= kernDur
    error('binSize must be smaller than trialDur')
end


% Define the first and last peak based on trial duration and bin size
peakPts = [0 round(kernDur/binSize)];

nonlinfunc = @(x)(log(x + 1e-20)); % non-linear stretch function
rangeVals = nonlinfunc(peakPts + linearStretch); % min and max values for cosine peaks
peakSpacing = diff(rangeVals)/(numBases-1); % spacing between raised cosine peaks
peakVals = rangeVals(1):peakSpacing:rangeVals(2); % peak values for basis vectors

invnonlinfunc = @(x)(exp(x) - 1e-20);
maximumTime = invnonlinfunc(rangeVals(2)+2*peakSpacing) - linearStretch;
timeBins = (0:1:maximumTime); % define the time bins for the range of bases functions
diffCoef = repmat(nonlinfunc(timeBins' + linearStretch), 1, numBases) - repmat(peakVals, numel(timeBins), 1);
diffCoefNorm = (diffCoef*pi)/(2*peakSpacing);
basesRaw = (cos(max(-pi, min(pi, diffCoefNorm))) + 1)/2; % calculate the bases functions

% Normalize the bases; ensures peak is always at 1
maxVals = max(basesRaw);
basesNorm = basesRaw./(repmat(maxVals, size(basesRaw,1), 1));

if truncate
    basesTemp = basesNorm(1:round(kernDur/binSize),:);
    if strcmp(basesType, 'PRE')
        bases = flipud([zeros(size(basesTemp)); basesTemp]);
    elseif strcmp(basesType, 'POST')
        bases = [zeros(size(basesTemp)); basesTemp];
    elseif strcmp(basesType, 'SYM')
        bases = flipud([[fliplr(flipud(basesTemp)); zeros(size(basesTemp,1), size(basesTemp,2))] ...
        [zeros(size(basesTemp,1), size(basesTemp,2)); basesTemp]]);
    end

else
    basesTemp = basesNorm;
    if strcmp(basesType, 'PRE')
        bases = flipud([zeros(size(basesTemp)); basesTemp]);
    elseif strcmp(basesType, 'POST')
        bases = [zeros(size(basesTemp)); basesTemp];
    elseif strcmp(basesType, 'SYM')
        bases = flipud([[fliplr(flipud(basesTemp)); zeros(size(basesTemp,1), size(basesTemp,2))] ...
            [zeros(size(basesTemp,1), size(basesTemp,2)); basesTemp]]);
    end
end
   


