function [binnedVarArrCell,binnedSpikesCell,tempFreqCell] = readAndBin(epochInfoFileName,stimulusInfoFileName,spikeTimesFileName,generatePlots) 
%
% LC April 02 2023
%
% DESCRIPTION:
% Read in Allen Institute VisualCoding-Neuropixels select
% data (described in dataExtraction.ipynb), dummy code the variables into 
% bins and and bin the spike times. Drifing gratings were presented in
% three epochs. Considering 10 seconds around each epoch additionally
% prioir to convolution to minimize edge artifacts. Will truncate them post
% convolution.
% 
% Data path: https://drive.google.com/drive/folders/1x8vVsvM0GAvfuMLwKo3bxOC-vjOjA1ej?usp=share_link
%
% INPUT: 
% Three CSV files containing information about:
% # 1. epochs (stim_epoch_info.csv),
% # 2. stimuli (stim_info.csv), and 
% # 3. spikes (matched_spike_times.csv)
%
% OUTPUT:
% One binnedData.mat containing
% # 1. Dummy-coded variable array for each epoch (binnedVarArrCell)
% # 2. Binned Spikes for each epoch (binnedSpikesCell)
% # 3. Temporal frequency of the presented drifting gratings for each epoch
%      (tempFreqCell)

arguments
    epochInfoFileName char
    stimulusInfoFileName char
    spikeTimesFileName char
    generatePlots logical = false
end

%% Reading in required constant variables

C = projConstants;

%% Extract and Organize Spike times by unit and epoch

% Read Epoch info, Stimulus info, and Spike times files
stimEpochInfo = readtable(fullfile(C.rawDataPath, epochInfoFileName));
stimInfo = readtable(fullfile(C.rawDataPath, stimulusInfoFileName));
spikeTimes = readtable(fullfile(C.rawDataPath, spikeTimesFileName));

% Extract epoch relevant information
epochStartTime = stimEpochInfo.start_time;
epochStopTime = stimEpochInfo.stop_time;
epochDuration = epochStopTime - epochStartTime;

% Organize spikeTimes table by units

% # 1. Identify boundaries between units
unitBounds = [0 ; find(diff(spikeTimes.unit_id))];
noOfUnits = length(unitBounds);

selectSpikeTimes = cell(C.noOfEpochs,noOfUnits);
for unit = 1:noOfUnits

    % # 2. Extract thisUnit's spike times
    if unit == noOfUnits
        thisUnitIdxArr = 1+unitBounds(unit):height(spikeTimes);
    else
        thisUnitIdxArr = 1+unitBounds(unit):unitBounds(unit+1);
    end
    
    spikeTimesByUnit = spikeTimes.times(thisUnitIdxArr);

    % # 3. Extract spike times only during the epochs (plus padding)
    for epoch = 1:C.noOfEpochs
        selectIdx = (spikeTimesByUnit >= epochStartTime(epoch) ...
                                         - C.paddingAroundEpochs ...
                   & spikeTimesByUnit <= epochStopTime(epoch) ...
                                         +C.paddingAroundEpochs);
        selectSpikeTimes{epoch,unit} = spikeTimesByUnit(selectIdx);
    end

end

%% Binning

% Identify boundaries of stimulus blocks (identifiers for epochs)
stimBlockNum = stimInfo.stimulus_block;
stimBlockBounds = [0 ; find(diff(stimBlockNum))];

binnedVarArrCell = cell(1,C.noOfEpochs);
binnedSpikesCell = cell(1,C.noOfEpochs);
tempFreqCell = cell(1,C.noOfEpochs);

for epoch = 1:C.noOfEpochs

    % Identify number of bins and bin edges (in real time)
    noOfBins = round(epochDuration(epoch)/C.binSize);
    binnedTime = 0:C.binSize:epochDuration(epoch);

    %% Create Binned Variable Array

    % Extract indices for stimuli in thisEpoch
    if epoch == C.noOfEpochs
        thisEpochIdxArr = 1+stimBlockBounds(epoch):length(stimBlockNum);
    else
        thisEpochIdxArr = 1+stimBlockBounds(epoch):stimBlockBounds(epoch+1);
    end
    
    % Calculate relative start and stop time w.r.t. start of the epoch
    relativeStartTime = stimInfo.start_time(thisEpochIdxArr) ...
                        - epochStartTime(epoch);
    relativeStopTime = stimInfo.stop_time(thisEpochIdxArr) ...
                        - epochStartTime(epoch);

    % Extract presented orientation and temporal frequency values, store
    % temporal frequency information in a separate array
    varArr = stimInfo.orientation(thisEpochIdxArr);
    tempFreq = stimInfo.temporal_frequency(thisEpochIdxArr);

    tempFreqCell{epoch} = [relativeStartTime varArr tempFreq];

    % Dummy coding structure  for variables array: 
    % * As many columns as there are variables (8 orientations + one column
    %   for nan values)
    % * 1's in the bins where the stimulus occured, 0's everywhere else
    binnedVarArr = zeros(noOfBins,length(C.orientationList)+1);
    for thisStimIdx = 1:length(thisEpochIdxArr)
        
        % Identify bin indices of thisStim
        thisStimBinIdxArr = find(binnedTime >= relativeStartTime(thisStimIdx)...
                               & binnedTime <= relativeStopTime(thisStimIdx));
        
        % Place 1's in the bin indices for corresponding orientation in
        % separate columns
        for varListIdx = 1:length(C.orientationList)
            if varArr(thisStimIdx) == C.orientationList(varListIdx)
                binnedVarArr(thisStimBinIdxArr,varListIdx) = 1;
            end

            if isnan(varArr(thisStimIdx))
                binnedVarArr(thisStimBinIdxArr,C.nanColumnIdx) = 1;
            end
        end

    end

    %%% Padding with zeros to cover the 10 seconds around each epoch
    
    % Calculate number of padded zero bins
    noOfZeroBins = C.paddingAroundEpochs/C.binSize;

    % Padding around the variable array
    binnedVarArr = [zeros(noOfZeroBins,length(C.orientationList)+1); ...
                    binnedVarArr; ...
                    zeros(noOfZeroBins,length(C.orientationList)+1)];

    binnedVarArrCell{epoch} = binnedVarArr;

    %% Create Binned Spikes Array

    % Calculate padded binned time for later slicing
    paddedBinnedTime = 0:C.binSize:...
        (epochDuration(epoch)+C.binSize+2*C.paddingAroundEpochs);
    paddedNoOfBins = noOfBins + 2*C.paddingAroundEpochs/C.binSize;

    binnedSpikes = [];
    for unit = 1:noOfUnits
    
        % Calculate relative spike times from start of epoch + padding
        thisSpikeTimes = selectSpikeTimes{epoch,unit};
        thisSpikeTimesRelative = thisSpikeTimes - epochStartTime(epoch) ...
                                + C.paddingAroundEpochs;

        % Bin the spike times to get binned spike counts
        thisUnitBinnedSpikes = histcounts(thisSpikeTimesRelative, ...
                                          paddedBinnedTime);
        binnedSpikes = [binnedSpikes thisUnitBinnedSpikes'];

    end

    binnedSpikesCell{epoch} = binnedSpikes;

end

%% Save data and generate plots
% Write data into .mat files
save(fullfile(C.dataPath,'binnedData.mat'), ...
    "binnedVarArrCell","binnedSpikesCell","tempFreqCell")

% Generate Plots
if generatePlots
    
    % Variable Arrays
    figure;
    clf;
    hold on
    for epoch = 1:C.noOfEpochs
        subplot(1,C.noOfEpochs,epoch)
        imagesc(binnedVarArrCell{epoch});
        set(gca,'XTickLabel',[C.orientationList nan]);
        xlabel('Orientation');
        ylabel('Bin number');
        title(['Epoch #' num2str(epoch)])
    end

    % Spike Counts
    figure;
    clf;
    hold on
    for epoch = 1:C.noOfEpochs
        subplot(1,C.noOfEpochs,epoch)
        imagesc(binnedSpikesCell{epoch});
        set(gca,'XTick',1:5:noOfUnits)
        set(gca,'XTickLabel',1:5:noOfUnits);
        xlabel('Unit number');
        ylabel('Bin number');
        title(['Epoch #' num2str(epoch)])
    end

end

end