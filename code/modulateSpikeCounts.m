function [modBinnedVarArrCell] = modulateSpikeCounts(binnedVarArrCell,tempFreqCell,generatePlots)
%
% LC April 16 2023
%
% DESCRIPTION:
% Read in binnedData.mat, create modulated spike counts: sinusoidal
% modulation to account for sinusoidal drifting grating presentation.
% Creating sinusoids of temporal frequency matched with that presented.
% Creating two modulated columns (one with sine and other with cosine to
% account for preferred phase of the unit) for each orientation. Including 
% offset baseline as third column (1 whenever stimulus is on).
%
% INPUT:
% One binnedData.mat containing
% # 1. Dummy-coded variable array for each epoch (binnedVarArrCell)
% # 2. Temporal frequency of the presented drifting gratings for each epoch
%      (tempFreqCell)
%
% OUTPUT: 
% One binnedData.mat to which modBinnedVarArrCell is appended

arguments
    binnedVarArrCell cell
    tempFreqCell cell
    generatePlots logical = false
end

%% Reading in required constant variables

C = projConstants;

%% read the inputs

% Bin edges during the timecourse of one stimulus presentation
stimTimeCourse = 0:C.binSize:C.trialDuration-C.binSize;
noOfStimBins = C.trialDuration/C.binSize;

for epoch = 1:C.noOfEpochs

    binnedVarArr = binnedVarArrCell{epoch};
    tempFreqArr = tempFreqCell{epoch};
    
    modBinnedVarArr = [];
    % Create a vector of zeros for each orientation and plug-in the 
    % sinusoidal trains
    for thisOrientationIdx = 1:length(C.orientationList)
    
        sineBinnedVarArr = zeros(length(binnedVarArr),1);
        cosineBinnedVarArr = zeros(length(binnedVarArr),1);
        
        % Find the stimulus onsets and corresponding temporal frequencies
        stimOnsetIdx = find(diff(binnedVarArr(:,thisOrientationIdx))>0);
        correspondingTempFreq = tempFreqArr(tempFreqArr(:,2) ...
                               == C.orientationList(thisOrientationIdx),3);
        
        % Create sine and cosine modulated trains based on temporal
        % frequency
        for stim = 1:length(stimOnsetIdx)
        
            thisStimTempFreq = correspondingTempFreq(stim);
        
            sineBinnedVarArr(stimOnsetIdx(stim):stimOnsetIdx(stim)+noOfStimBins-1) ...
                = sin(pi*thisStimTempFreq*stimTimeCourse);
            cosineBinnedVarArr(stimOnsetIdx(stim):stimOnsetIdx(stim)+noOfStimBins-1) ...
                = cos(pi*thisStimTempFreq*stimTimeCourse);
        
        end
        
        % Adding baseline offset in front of the modulated trains
        modBinnedVarArr = [modBinnedVarArr ...
            binnedVarArr(:,thisOrientationIdx) ...
            sineBinnedVarArr cosineBinnedVarArr];
    
    end

    % Adding baseline offset for NaN stimuli (regressor of no interest)
    modBinnedVarArrCell{epoch} = [modBinnedVarArr ...
                                    binnedVarArr(:,C.nanColumnIdx)];

end

save(fullfile(C.dataPath,'binnedData.mat'), ...
    "modBinnedVarArrCell", "-append");

if generatePlots
    imagesc(modBinnedVarArr)
end
