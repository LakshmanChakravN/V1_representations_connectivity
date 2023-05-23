function [normMeanObs,normMeanPredFull,...
    normMeanPredStim,normMeanPredIntr,FC] = analyze(binnedVarArrCell,...
                               binnedSpikesCell,tempFreqCell,generatePlots)
%
% LC April 20 2023
%
% DESCRIPTION:
%   (1) Create sinusoidal modulation of binned spikes
%   (2) Create bases functions for the stimuli
%   (3) Create design matrix and CV indices for group lasso GLM model
%   (4) Run group lasso GLM in R
%   (5) Generate and organize model predictions
%
% Data path: https://drive.google.com/drive/folders/1x8vVsvM0GAvfuMLwKo3bxOC-vjOjA1ej?usp=share_link

arguments
    binnedVarArrCell cell
    binnedSpikesCell cell
    tempFreqCell cell
    generatePlots logical = false
end

%% Reading in constant variables and binned data

generatePlots = false;

C = projConstants;

load(fullfile(C.dataPath, 'binnedData.mat'),'binnedVarArrCell',...
                    'binnedSpikesCell','tempFreqCell');
noOfUnits = size(binnedSpikesCell{1},2);

%% Create sinusoidal modulation of binned spikes

modBinnedVarArrCell = modulateSpikeCounts(binnedVarArrCell,tempFreqCell);

%% Create bases functions for the stimuli

%%% Create variable names list for stimulus variables and intrinsic 
%%% activity(other recorded cells as variables)

% Stimulus variables:
% One column each for baseline, sine modulation and cosine modulation for
% each orientation. Add a regressor-of-no-interest column for nan variable
stimVariablesList = {};
for orientation = 1:C.noOfOrientations
    stimVariablesList = [stimVariablesList ...
        [C.orientationListNames{orientation} '_bl'] ...
        [C.orientationListNames{orientation} '_sin'] ...
        [C.orientationListNames{orientation} '_cos']];
end
stimVariablesList = [stimVariablesList 'nan'];

% Intrinsic activity:
% One column for each unit unit
fullUnitList = {};
for unit=1:noOfUnits
    fullUnitList = [fullUnitList, ['Cell' num2str(unit)]];
end

%%% Basis parameters

for var = 1:length(stimVariablesList)

    basesParams(var).varName = stimVariablesList{var};
    basesParams(var).numBases = C.noOfBases;
    basesParams(var).binSize = C.binSize;
    basesParams(var).kernDur = C.trialDuration;
    basesParams(var).linearStretch = C.trialDuration;
    basesParams(var).basesType = 'POST';
    basesParams(var).truncate = true;
    basesParams(var).mask = [];

end

% Visualize the bases functions for a specific variable

if generatePlots
    varNum = 1; % (Zero degrees baseline)
    bases = createBasesFunctions(basesParams(varNum).numBases, ...
        basesParams(varNum).binSize, basesParams(varNum).kernDur, ...
        basesParams(varNum).linearStretch, basesParams(varNum).basesType, ...
        basesParams(varNum).truncate);
    
    figure; 
    plot(bases); 
    title([basesParams(varNum).varName ' Bases Functions']);
    xlabel('Number of bins');
end

%% Create design matrix and CV indices for group lasso GLM model

noOfPaddedBins = C.paddingAroundEpochs/C.binSize;
fullDesignMat = [];
fullBinnedVarArray = [];
for epoch = 1:C.noOfEpochs
    
    binnedVarArray = binnedVarArrCell{epoch};
    binnedSpikes = binnedSpikesCell{epoch};
    modBinnedVarArray = modBinnedVarArrCell{epoch};
    
    designMat = createDesignMatrix(modBinnedVarArray, binnedSpikes, ...
        basesParams, C.dataPath);

    % Truncate the previously padded regions around epochs 
    designMatTruncated = designMat(noOfPaddedBins+1:end-noOfPaddedBins,:);
    binnedVarArrTruncated = binnedVarArray(noOfPaddedBins+1:end-noOfPaddedBins,:); 
    fullDesignMat = [fullDesignMat;designMatTruncated];
    fullBinnedVarArray = [fullBinnedVarArray;binnedVarArrTruncated];

end

if generatePlots
    figure; 
    imagesc(table2array(fullDesignMat));
    title('Design Matrix');
end

% If you do not want a randomly generated cross validation vector, create 
% your own and save it as a .csv file in the same path where the design
% matrix is saved. Note the cross validation vector should have the same
% length as the number of rows in designMat
cvInd = sort(repelem(1:C.noOfCVfolds,ceil(size(fullDesignMat,1)/C.noOfCVfolds)));
cvInd = cvInd(1:size(fullDesignMat,1));
writematrix(cvInd', fullfile(C.dataPath, 'cvInd.csv'))

% Save design matrix
writetable(fullDesignMat, fullfile(C.dataPath, 'DesignMatrixWithCells.txt'))

%% Run group lasso GLM in R

% Make sure to download and install grpreg package 
% (https://cran.r-project.org/web/packages/grpreg/index.html)
% before running GroupLassoGLM_Rscript.R

% system('R CMD BATCH GroupLassoGLM_Rscript.R')

% Could not solve path issue for running it from MATLAB

%% Generate and organize model predictions

FC = [];
histTimes = -20:60; % 1 sec before the trial till 3 sec into it


meanPredStim = nan(noOfUnits,C.noOfOrientations,length(C.tempFreqList),length(histTimes));
meanPredIntr = nan(noOfUnits,C.noOfOrientations,length(C.tempFreqList),length(histTimes));
meanPredFull = nan(noOfUnits,C.noOfOrientations,length(C.tempFreqList),length(histTimes));
meanObs = nan(noOfUnits,C.noOfOrientations,length(C.tempFreqList),length(histTimes));

for unit = 1:noOfUnits

    % List of cells used in the design matrix (All cells except current one)
    selectUnitList = fullUnitList(1:end ~= unit);    
    allRegressors = [stimVariablesList selectUnitList];

    modelData = loadModelDataWithCells(C.dataPath, unit);
    
    % Store betas from the unit predictors for FC matrix
    selectBetas = modelData.betas(:,modelData.lambdas==modelData.minlambda);
    noOfColsPrecedingUnits = length(stimVariablesList)*C.noOfBases+1; % +1 for offset
    selBetasCells = (selectBetas(1+noOfColsPrecedingUnits:end))';
    FC = [FC;[selBetasCells(1:unit-1) 1 selBetasCells(unit:end)]];

    % Plot cross-validation error
    if generatePlots
        figure; 
        plot(modelData.cve, 'k');
        hold on; 
        plot(modelData.cve+modelData(1).cvse, 'k', 'LineStyle', '--');
        plot(modelData.cve-modelData(1).cvse, 'k', 'LineStyle', '--');
        legend({'Cross-validation error' 'Cross-validation standard error'});
        xlabel('Lambda Index');
        ylabel('CVE');
        title(['Unit' num2str(unit)])
    end
    
    % Predict firing rate using the GLM
    stimPredSpikes = modelPredictWithCells(modelData, ['Offset', stimVariablesList]);
    intrinsicPredSpikes = modelPredictWithCells(modelData, ['Offset', selectUnitList]);
    fullPredSpikes = modelPredictWithCells(modelData, ['Offset', allRegressors]);


    for thisOrientationIdx = 1:C.noOfOrientations
    
        stimTimes = find(diff(fullBinnedVarArray(:,thisOrientationIdx))>0);
    
        correspondingTempFreq = [];
        for epoch = 1:C.noOfEpochs
            tempFreqArr = tempFreqCell{epoch};
            correspondingTempFreq = [correspondingTempFreq; ...
                                     tempFreqArr(tempFreqArr(:,2) ...
                                     == C.orientationList(thisOrientationIdx),3)];
        end
        correspondingTempFreq = correspondingTempFreq(1:length(stimTimes));
    
        for tfIdx = 1:length(C.tempFreqList)
        
            thisTfTimes = stimTimes(correspondingTempFreq ...
                                                == C.tempFreqList(tfIdx));
            
            sampInds = thisTfTimes(1:end-1) + histTimes;
            
            % mean response across trials
            meanPredStim = mean(stimPredSpikes(sampInds),1); % model of stim
            meanPredIntr = mean(intrinsicPredSpikes(sampInds),1); % model of intrinsic activity
            meanObs = mean(fullDesignMat.(['Cell' num2str(unit) ...
                '_' num2str(1+length(stimVariablesList)) '_' num2str(unit)])(sampInds),1);
            meanPredFull = mean(fullPredSpikes(sampInds),1);

            % normalizing based on mean of 1 sec each around the stimulus,
            % to capture some units that have decreased response upon presentation

            preIdx = 1:20; % 1 sec pre stimulus
            postIdx = 61:81; % 1 sec post stimulus

            normMeanPredStim(unit,thisOrientationIdx,tfIdx,:) = meanPredStim - mean([meanPredStim(preIdx) meanPredStim(postIdx)]);
            normMeanPredIntr(unit,thisOrientationIdx,tfIdx,:) = meanPredIntr - mean([meanPredIntr(preIdx) meanPredIntr(postIdx)]);
            normMeanPredFull(unit,thisOrientationIdx,tfIdx,:) = meanPredFull - mean([meanPredFull(preIdx) meanPredFull(postIdx)]);
            normMeanObs(unit,thisOrientationIdx,tfIdx,:)      = meanObs - mean([meanObs(preIdx) meanObs(postIdx)]);

        end
    end
end

allData = cat(5,normMeanObs,normMeanPredFull,normMeanPredStim,normMeanPredIntr);

save(fullfile(C.dataPath,'predictions.mat'), "allData","FC");

end
    
