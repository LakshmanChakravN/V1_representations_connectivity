classdef projConstants
    %
    % LC April 06 2023
    %
    % DESCRIPTION: Project related constant variables
    % Data path: https://drive.google.com/drive/folders/1x8vVsvM0GAvfuMLwKo3bxOC-vjOjA1ej?usp=share_link
    properties( Constant = true )
        
        %% Folder Paths
        dataPath = ['..' filesep 'data'];
        rawDataPath = ['..' filesep 'data' filesep 'raw'];

        %%% Figure paths
        figPathBasicFit = ['..' filesep 'figures/basicFit'];

        %% File Names
        
        % raw
        epochInfoFileName = 'stim_epoch_info.csv';
        stimulusInfoFileName = 'stim_info.csv';
        spikeTimesFileName = 'matched_spike_times.csv';

        % binned
        binnedDataFileName = 'binnedData.mat';

        %% Data Info
        % Epoch related
        noOfEpochs = 3; % 3 epochs of drifting gratings
        
        % Spike times related
        noOfUnits = 75; % 75 units identified in VISp region
        
        % Stimulus related
        noOfOrientations = 8;
        orientationList = [0 45 90 135 180 225 270 315];
        orientationListNames = {'Degrees0','Degrees45','Degrees90',...
            'Degrees135','Degrees180','Degrees225','Degrees270',...
            'Degrees315'};
        nanColumnIdx = 9; % Separate col to store the nan-coded trials
        noOfTempFreq = 5;
        tempFreqList = [1 2 4 8 15];
        trialDuration = 2;

        % Analysis choices
        binSize = 0.05; % seconds
        paddingAroundEpochs = 10; % seconds
        psthBinSpan = -10:50; % 10 bins around stimulus presentation 
        noOfBases = 10;
        noOfCVfolds = 10;
    end
end