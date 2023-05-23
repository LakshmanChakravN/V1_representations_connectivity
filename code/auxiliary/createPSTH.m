function [] = createPSTH(unitNum)
%
% LC April 08 2023
%
% DESCRIPTION:
% Creates PSTH for each stimulus type (orientation x frequency) for example
% units
%
% INPUT:
%
% OUTPUT:
%

arguments
    unitNum {mustBeInRange(unitNum,1,75)} = 1;
end

%% Reading in required constant variables
clearvars
C = projConstants;

%% Read in binnedSpikes and binnedVarArray

load(fullfile(C.dataPath, C.binnedDataFileName), 'binnedVarArrCell');
load(fullfile(C.dataPath, C.binnedDataFileName), 'binnedSpikesCell');
load(fullfile(C.dataPath, C.binnedDataFileName), 'tempFreqCell');

%% Create raster heat map and PSTH for the example cell

for thisOrientationIdx = 1:8

    allUnitsStimLockedSpikes = cell(1,5);
    for unitNum = 1:75
    
        for epoch = 1:3
    
            binnedVarArr = binnedVarArrCell{epoch};
            binnedSpikes = binnedSpikesCell{epoch};
            tempFreqArr = tempFreqCell{epoch};
    
            
            
            stimOnsetIdx = find(diff(binnedVarArr(:,thisOrientationIdx))>0);
            correspondingTempFreq = tempFreqArr(tempFreqArr(:,2) ...
                                          == C.orientationList(thisOrientationIdx),3);
            
            for thisTempFreqIdx = 1:length(C.tempFreqList)
            
                thisTempFreq = C.tempFreqList(thisTempFreqIdx);
            
                thisStimOnsetIdx = stimOnsetIdx(correspondingTempFreq == thisTempFreq);
            
            
                stimArrayIdx = thisStimOnsetIdx + repmat(C.psthBinSpan,length(thisStimOnsetIdx),1);
                
                binnedSpikesThisUnit = binnedSpikes(:,unitNum);
                stimLockedSpikes = binnedSpikesThisUnit(stimArrayIdx);
                
                if length(thisStimOnsetIdx)==1
                    stimLockedSpikes = stimLockedSpikes';
                end
            
                allUnitsStimLockedSpikes{1,thisTempFreqIdx} = [allUnitsStimLockedSpikes{1,thisTempFreqIdx};stimLockedSpikes];
            
            end
    
        end
    end
    %%
    figure;
    for thisTempFreqIdx = 1:length(C.tempFreqList)
        
        thisTempFreq = C.tempFreqList(thisTempFreqIdx);
    
        hold on
        fig = subplot(2,5,thisTempFreqIdx);
        imagesc(allUnitsStimLockedSpikes{1,thisTempFreqIdx})
        title([num2str(C.orientationList(thisOrientationIdx)) ' deg ' num2str(thisTempFreq) ' Hz'])
    
        subplot(2,5,5+thisTempFreqIdx)
        histogram('BinEdges',1:62,'BinCounts',sum(allUnitsStimLockedSpikes{1,thisTempFreqIdx}))

    end
    saveas(fig,['PSTH_' num2str(C.orientationList(thisOrientationIdx)) 'deg ' num2str(thisTempFreq) 'Hz.png']);

end
%%

% Unit 3 codes for 45 degrees

varList = 0:45:315;
tempFreqList = [1 2 4 8 15];

thisUnit = 3;
thisVar = 2; % idx for 45 degrees

stimOnsetIdx = find(diff(binnedVarArr(:,thisVar))>0);
correspondingTempFreq = tempFreqArr(tempFreqArr(:,2)==varList(thisVar),3);

%%

for thisTempFreqIdx = 1:length(tempFreqList)

    thisTempFreq = tempFreqList(thisTempFreqIdx);

    thisStimOnsetIdx = stimOnsetIdx(correspondingTempFreq == thisTempFreq);


    stimArrayIdx = thisStimOnsetIdx + repmat(0:psthDuration,length(thisStimOnsetIdx),1);
    
    binnedSpikesThisUnit = binnedSpikes(:,thisUnit);
    stimLockedSpikes = binnedSpikesThisUnit(stimArrayIdx);
    
    if length(thisStimOnsetIdx)==1
        stimLockedSpikes = stimLockedSpikes';
    end

    normMeanStimLockedSpikes = mean(stimLockedSpikes,1)/max(mean(stimLockedSpikes));

    hold on
    subplot(2,5,thisTempFreqIdx)
    imagesc(stimLockedSpikes)
    title(num2str(thisTempFreq))

    subplot(2,5,5+thisTempFreqIdx)
    plot(normMeanStimLockedSpikes)

end
