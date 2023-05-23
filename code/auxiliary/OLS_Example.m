% analysis
clearvars

githubDataPath = '/Users/lakshmannc/Documents/GitHub/project-LakshmanChakravN/data';
load(fullfile(githubDataPath, 'binnedData.mat'))

binnedVarArray = binnedVarArrCell{1};
binnedSpikes = binnedSpikesCell{1};
modBinnedVarArr = modBinnedVarArrCell{1};

examplePath='/Users/lakshmannc/Documents/SharedFolder_10Jan2023/data/'; % Enter the path where example data is saved

varList = {'0','45','90','135','180','225','270','315','nan'};

varNamesCell = {};
for var=1:8
   varNamesCell = [varNamesCell, [varList{var} '_1'], [varList{var} '_2']];
end

varNamesCell = [varNamesCell, varList{9}];

for unit = 1:75
    varNamesCell = [varNamesCell, ['Cell' num2str(unit)]];
end

designMat = array2table([modBinnedVarArr binnedSpikes],'VariableNames',varNamesCell);
writetable(designMat, fullfile(examplePath, 'ModDesignMatrixTest.txt'))

cvInd = sort(repelem(1:10,ceil(size(designMat,1)/10)));
cvInd = cvInd(1:size(designMat,1));
writematrix(cvInd', fullfile(examplePath, 'cvInd.csv'))

%% R

%%

X = modBinnedVarArr;
y = binnedSpikes(:,3);

b = regress(y,X);

y_pred = X*b;

for thisOrientationIdx = 1:8

%thisOrientationIdx = 2;
stimOnsetIdx = find(diff(binnedVarArray(:,thisOrientationIdx))>0);
histTimes = -20:60; % 1 sec before the trial till 3 sec into it
sampInds = stimOnsetIdx(1:(end-1))+histTimes;

meanPred = mean(y_pred(sampInds),1);
meanObs = mean(y(sampInds),1);

%figure; 

subplot(2,4,thisOrientationIdx)
hold on
plot(histTimes*0.05,meanPred);
plot(histTimes*0.05,meanObs);
title(varList{thisOrientationIdx})
ylim([-0.5 3])

end

%% Load in Data from R
cellNum = 1; % load specific cells or remove the 'CHOOSECELLS' argument to load all cells
modelData = loadModelData(examplePath, 'CHOOSECELLS', cellNum);

% Plot cross-validation error
figure; plot(modelData.cve, 'k'); % The lambda with the minimum validation error is the lambda used for fitting
hold on; plot(modelData.cve+modelData(1).cvse, 'k', 'LineStyle', '--');
hold on; plot(modelData.cve-modelData(1).cvse, 'k', 'LineStyle', '--');
legend({'Cross-validation error' 'Cross-validation standard error'});
xlabel('Lambda Index');
ylabel('CVE');

%% Predict firing rate using the GLM
LW1_predSpikes = modelPredict(modelData, {'Offset' 'x90'});
full_predSpikes = modelPredict(modelData, {'Offset' 'x0' 'x45' 'x90' 'x135' 'x180' 'x225' 'x270' 'x315' 'nan'});

% get LW1 trial times
lw1Times = find(diff(binnedVarArray(:,1)>0));
histTimes = -20:60; % 1 sec before the trial till 3 sec into it
sampInds = lw1Times(1:(end-1))+histTimes;

% mean response across trials
% note: the model will be a bit off in some cases because we only included
% a few task covariates, so we are systematically misestimating the
% response in some cases (e.g. LW2 trials).
meanPredS = mean(LW1_predSpikes(sampInds),1); % model of stim
meanPredFull = mean(full_predSpikes(sampInds),1); % model of stim/beh
meanObs = mean(designMat.(['Cell' num2str(cellNum)])(sampInds),1);
figure; 
%plot(histTimes*0.05, meanPredS);
hold on
plot(histTimes*0.05,meanPredFull);
plot(histTimes*0.05,meanObs);