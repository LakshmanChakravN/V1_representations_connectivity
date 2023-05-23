% Master Script
clearvars

epochInfoFileName = 'stim_epoch_info.csv';
stimulusInfoFileName = 'stim_info.csv';
spikeTimesFileName = 'matched_spike_times.csv';

%%
[binnedVarArrCell,binnedSpikesCell,...
    tempFreqCell] = readAndBin(epochInfoFileName,stimulusInfoFileName,...
                        spikeTimesFileName);

%%
[meanObs,meanPredFull,...
    meanPredStim,meanPredIntr,FC] = analyze(binnedVarArrCell,...
                                            binnedSpikesCell,tempFreqCell);

%%
visualize(meanObs,meanPredFull,meanPredStim,meanPredIntr,FC)
