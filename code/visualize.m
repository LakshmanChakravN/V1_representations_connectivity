function visualize(meanObs,meanPredFull,meanPredStim,meanPredIntr,FC)
% 
% DESCRIPTION:
% Figure 1: Plot representative unit's model fit, depicting observed PSTH,
%           fit of PSTH, contribution of stimulus and intrnsic regressors
% Figure 2: Plot tuning curves for the units, clustered
% Figure 3: Plot comparison of stimulus and intrinsic contributions
% Figure 4: Plot functional connectivity vs. distance between preferred
%           orientation between pairs of units
%
% Data path: https://drive.google.com/drive/folders/1x8vVsvM0GAvfuMLwKo3bxOC-vjOjA1ej?usp=share_link

arguments
    meanObs double
    meanPredFull double
    meanPredStim double
    meanPredIntr double
    FC double 
end

%% Load in data

C = projConstants;

% For debugging
% load(fullfile(C.dataPath,'predictions.mat'))
% meanObs = allData(:,:,:,:,1);
% meanPredFull = allData(:,:,:,:,2);
% meanPredStim = allData(:,:,:,:,3);
% meanPredIntr = allData(:,:,:,:,4);

noOfUnits = size(meanObs,1);

%% %%%%%%% FIGURE 1 %%%%%%%%

% PSTH time range: from 1 sec prior to stim onset till 1 sec after stim
% offset
histTimes = -1/C.binSize:(C.trialDuration+1)/C.binSize;
stimIdx = 21:60; % Stim presented bins

%% Figure 1: Representatve cell's model fit

figDir = C.figPathBasicFit;

if ~exist(figDir, 'dir')
   mkdir(figDir);
end

% Calculate area under the curve
maxObs      = nan(noOfUnits,C.noOfOrientations,C.noOfTempFreq);
aucObs      = nan(noOfUnits,C.noOfOrientations,C.noOfTempFreq);
aucPredFull = nan(noOfUnits,C.noOfOrientations,C.noOfTempFreq);
aucPredStim = nan(noOfUnits,C.noOfOrientations,C.noOfTempFreq);
aucPredIntr = nan(noOfUnits,C.noOfOrientations,C.noOfTempFreq);

for unit = 1:noOfUnits    
    for orientIdx = 1:C.noOfOrientations
        for tempFreqIdx = 1:C.noOfTempFreq
            
            thisMeanObs = squeeze(meanObs(unit,orientIdx,tempFreqIdx,:));
            thisMeanPredFull = squeeze(meanPredFull(unit,orientIdx,tempFreqIdx,:));
            thisMeanPredStim = squeeze(meanPredStim(unit,orientIdx,tempFreqIdx,:));
            thisMeanPredIntr = squeeze(meanPredIntr(unit,orientIdx,tempFreqIdx,:));

            maxObs(unit,orientIdx,tempFreqIdx) = max(thisMeanObs); % only for common y lim value
            
            aucObs(unit,orientIdx,tempFreqIdx) = trapz(thisMeanObs(stimIdx));
            aucPredFull(unit,orientIdx,tempFreqIdx) = trapz(thisMeanPredFull(stimIdx));
            aucPredStim(unit,orientIdx,tempFreqIdx) = trapz(thisMeanPredStim(stimIdx));
            aucPredIntr(unit,orientIdx,tempFreqIdx) = trapz(thisMeanPredIntr(stimIdx));

        end
    end
end

% Representative unit: Unit #3 (45 deg pref orient)

unit = 3;
orientIdx = 2; % 45 deg
tempFreqIdx = 1;

figure;

thisMeanObs = squeeze(meanObs(unit,orientIdx,tempFreqIdx,:));
thisMeanPredFull = squeeze(meanPredFull(unit,orientIdx,tempFreqIdx,:));
thisMeanPredStim = squeeze(meanPredStim(unit,orientIdx,tempFreqIdx,:));
thisMeanPredIntr = squeeze(meanPredIntr(unit,orientIdx,tempFreqIdx,:));

hold on
plot(histTimes*C.binSize, thisMeanObs);
plot(histTimes*C.binSize, thisMeanPredFull);
plot(histTimes*C.binSize, thisMeanPredStim);
plot(histTimes*C.binSize, thisMeanPredIntr);
title([C.orientationListNames{orientIdx} ' ' num2str(C.tempFreqList(tempFreqIdx)) ' Hz'])
legend('Observed','Predicted','StimulusContribution','IntrinsicContribution')
set(gca,'FontSize',16)
xlabel('Time from onset (s)')
ylabel('Firing rate (spikes/50-ms)')

%% %%%%%%% FIGURE 2 %%%%%%%%

% wrapping index function
wrapN = @(x, n) (1 + mod(x-1, n));

% Averaging across temporal freq

meanAUCObs = mean(aucObs,3);
meanAUCpredFull = mean(aucPredFull,3);
meanAUCpredStim = mean(aucPredStim,3);
meanAUCpredIntr = mean(aucPredIntr,3);

% Calculating pref orientation, max of PredFullValue
for unit = 1:noOfUnits

    thisMeanAUCpredStim = meanAUCpredStim(unit,:);
    [maxValue,prefOrientIdx] = max(thisMeanAUCpredStim);
    
    maxAUCpredStimValue(unit) =  maxValue;
    maxAUCpredFullValue(unit) = meanAUCpredFull(unit,prefOrientIdx);
    prefOrientIdxArr(unit) = prefOrientIdx;
    orthOrientIdxArr(unit) = wrapN(prefOrientIdx+2,8); % 90 deg away

end

% Aligning the tuning curves by pref orientation
prefIdx = 3;
orthIdx = 5;
for unit = 1:noOfUnits

    tempidx = wrapN((prefOrientIdxArr(unit):prefOrientIdxArr(unit)+7),8);
    alignedIdx= [tempidx(7) tempidx(8) tempidx(1:6)];

    meanAUCObs(unit,:)      = meanAUCObs(unit,alignedIdx);
    meanAUCpredFull(unit,:) = meanAUCpredFull(unit,alignedIdx);
    meanAUCpredStim(unit,:) = meanAUCpredStim(unit,alignedIdx);
    meanAUCpredIntr(unit,:) = meanAUCpredIntr(unit,alignedIdx);

end

%% Performing PCA on observed activity to identify putative clusters of cells

nPCs = 3;
[components,projections,~,~,explainedVariance] = pca(meanAUCObs);

% Supplementary Figure 1
figure('Position', get(0, 'Screensize'));
for pc = 1:nPCs
    subplot(1,nPCs,pc)
    
    hold on
    plot(components(:,pc),'b','LineWidth',1)
    title(['PC ' num2str(pc)])
    subtitle(['Explained Variance: ' num2str(explainedVariance(pc)) ' percent'])
    set(gca,'XTick',1:8)
    set(gca,'XTickLabel',-90:45:225)
    set(gca,'FontSize',16)
    xlabel('Distance from Preferred Orientation')
    ylabel('a.u.')  
end

%% Running k-means clustering on PC projections

nClust = 3;

% Since result changes everytime kmeans clustering is run, the optimal
% clustering scheme obtained from the command below was saved and loaded

%clustIdx = kmeans(projections(:,1:nPCs),nClust);

load(fullfile(C.dataPath,"clustIdx.mat"))
% Cluster 1: High activity, strongly tuned units
% Cluster 2: Low activity, weakly tuned units
% Cluster 3: High activity, weakly tuned units

nUnitsClust = [];
for clust = 1:nClust
    nUnitsClust = [nUnitsClust length(find(clustIdx==clust))];
end

% Projections in the space of Top 2 PCs

% Supplementary Figure 2
figure;
c = ['r','b','g'];
hold on
for clust = 1:nClust
    scatter(projections((clustIdx==clust),1),projections((clustIdx==clust),2),80,c(clust),'filled')
end
xlabel 'Projection onto Component #1'
ylabel 'Projection onto Component #2'
title('Clusters in space of 3 PCs')
subtitle('Only two PCs shown for visualization')
set(gca,'FontSize',16)

%% Figure 2: Tuning curve by cluster

figure('Position', get(0, 'Screensize'));
for clust = 1:nClust
    
    subplot(2,nClust,clust)
    plot((meanAUCpredFull(clustIdx==clust,:))')
    set(gca,'XTick',1:8)
    set(gca,'XTickLabel',-90:45:225)
    set(gca,'FontSize',16)
    xlabel('Distance from Preferred Orientation')
    ylabel('Area under PSTH')
    title(['Cluster ' num2str(clust) ': All Units Tuning curve'])
    subtitle(['n = ' num2str(nUnitsClust(clust))])
    ylim([-30 100])

    subplot(2,nClust,nClust+clust)

    x = (1:C.noOfOrientations)';
    y = (mean(meanAUCpredFull(clustIdx==clust,:)))';
    dy = std(meanAUCpredFull(clustIdx==clust,:))/sqrt(nUnitsClust(clust));% Standard Error

    hold on
    fill([x;flipud(x)],[y-dy;flipud(y+dy)],[.9 .9 .9],'linestyle','none');
    plot(y,'b','LineWidth',1)
    
    set(gca,'XTick',1:C.noOfOrientations)
    set(gca,'XTickLabel',-90:45:225)
    set(gca,'FontSize',16)
    xlabel('Distance from Preferred Orientation')
    ylabel('Area under PSTH')  
    title(['Cluster ' num2str(clust) ': Average Tuning curve'])
    subtitle(['n = ' num2str(nUnitsClust(clust))])
    ylim([-10 60])
end

%% %%%%%%%% FIGURE 3 %%%%%%%%%%%%%

% Calculating and comparing stimulus and intrinsic contributions

%% Figure 3: Comparing stimulus and intrinsic contributions
figure('Position', get(0, 'Screensize'));
for clust = 1:nClust

    % converting back to log space for comparison. Shifting the set of curves
    % up to let min value be e to have 1 as min value after log transformation
    %logPredFull = log(meanAUCpredFull(clustIdx==clust,:) - min(meanAUCpredFull(clustIdx==clust,:)) + 1);
    logPredStim = log(meanAUCpredStim(clustIdx==clust,:) - min(meanAUCpredStim(clustIdx==clust,:),[],"all") + exp(1));
    logPredIntr = log(meanAUCpredIntr(clustIdx==clust,:) - min(meanAUCpredIntr(clustIdx==clust,:),[],"all") + exp(1));
    
    subplot(2,nClust,clust)
    hold on
    plot(logPredStim','r');
    plot(logPredIntr','b');
    set(gca,'XTick',1:8)
    set(gca,'XTickLabel',-90:45:225)
    set(gca,'FontSize',16)
    xlabel('Distance from Preferred Orientation')
    ylabel('log(AUPSTH)')
    title(['Cluster ' num2str(clust) ': Stim vs Intr contribution'])
    subtitle(['n = ' num2str(nUnitsClust(clust))])
    ylim([1 4.5])

    [diffStim,pStim] = permTest(logPredStim(:,prefIdx),logPredStim(:,orthIdx));
    [diffIntr,pIntr] = permTest(logPredIntr(:,prefIdx),logPredIntr(:,orthIdx));


    subplot(2,nClust,nClust+clust)
    hold on
    
    x = (1:C.noOfOrientations)';
    yStim = (mean(logPredStim))';
    yIntr = (mean(logPredIntr))';
    dyStim = std(logPredStim)/sqrt(nUnitsClust(clust));% Standard Error
    dyIntr = std(logPredIntr)/sqrt(nUnitsClust(clust));% Standard Error

    hold on
    fill([x;flipud(x)],[yStim-dyStim;flipud(yStim+dyStim)],[.9 .9 .9],'linestyle','none');
    fill([x;flipud(x)],[yIntr-dyIntr;flipud(yIntr+dyIntr)],[.9 .9 .9],'linestyle','none');

    b(1) = plot(mean(logPredStim),'r','LineWidth',1);
    b(2) = plot(mean(logPredIntr),'b','LineWidth',1);
        
    legend(b,'Stimulus','Intrinsic')
    set(gca,'XTick',1:C.noOfOrientations)
    set(gca,'XTickLabel',-90:45:225)
    set(gca,'FontSize',16)
    xlabel('Distance from Preferred Orientation')
    ylabel('log (AUPSTH)')
    title(['Cluster ' num2str(clust) ': Stim vs Intr contr. Mean'])
    subtitle(['n = ' num2str(nUnitsClust(clust))])
    ylim([1 4.5])

    text(0.1,4,0,['Pref-Ortho = ' num2str(round(diffStim*100)/100) ...
        ', p=' num2str(pStim)],'Color','r','FontSize',14)
    text(0.1,3.75,0,['Pref-Ortho = ' num2str(round(diffIntr*100)/100) ...
        ', p=' num2str(pIntr)],'Color','b','FontSize',14)

%     subplot(3,nClust,2*nClust+clust)
%     hold on
%     plot((logPredStim./logPredIntr)','m')
%     yline(1,'k--')
%     set(gca,'XTick',1:8)
%     set(gca,'XTickLabel',-90:45:225)
%     set(gca,'FontSize',16)
%     xlabel('Distance from Preferred Orientation')
%     ylabel('a.u.')
%     title(['Cluster ' num2str(clust) ': Stim/Intr contribution'])
%     subtitle(['n = ' num2str(nUnitsClust(clust))])
%     ylim([0 4])

end

% Inference: In Cluster 1, stimulus and intrinsic activity have similar
% profiles across the orientation (high at preferred, low at orthogonal 
% orientations). Comparitively, in Cluster 3, the intrinsic activity is
% lowest at preferred orientation compared to the orthogonal orientation.

%% %%%%%%%% FIGURE 4 %%%%%%%%%%%

% Comparing functional connectivity as a function of distance between
% preferred orientations

for i=1:noOfUnits
    FC(i,i) = nan;
end

figure;
for clust = 1:nClust

    clustUnits = find(clustIdx==clust);

    % ordering units by pref orientation
    prefOrient = C.orientationList(prefOrientIdxArr(clustUnits));
    [orientSorted,orientSortIdx] = sort(prefOrient);
    orientSortedBounds = [0 find(diff(orientSorted))]+1;

    clustFC = FC(clustUnits,clustUnits);
    
    subplot(4,nClust,[clust nClust+clust])
    ax = pcolor(clustFC(orientSortIdx,orientSortIdx));
    colorbar; clim([-1 1]);colormap(blueWhiteRedColormap());
    ax.LineStyle = 'none';
    axis square
    xline(orientSortedBounds,'LineWidth',1)
    yline(orientSortedBounds,'LineWidth',1)
    set(gca,'XTick',orientSortedBounds)
    set(gca,'XTickLabel',orientSorted(orientSortedBounds))
    set(gca,'YTick',orientSortedBounds(1:end-1))
    set(gca,'YTickLabel',orientSorted(orientSortedBounds))
    title(['Cluster ' num2str(clust) ' FC'])
    subtitle(['n = ' num2str(nUnitsClust(clust))])
    set(gca,'FontSize',16)
    xlabel('Preferred Orientation')
    ylabel('Preferred Orientation')

    % Correlating with distance b/w pref orient    
    FCarr = [];
    prefOrientDist = [];
    count = 0;
    for row = 1:length(clustUnits)
        for col = 1:length(clustUnits)
            if row==col
            else
                count = count+1;
                FCarr(count) = FC(clustUnits(row),clustUnits(col));
                prefOrientDist(count) = abs(prefOrient(row) - prefOrient(col));
            end
        end
    end
    
    for orientIdx = 1:8
        meanFC(orientIdx) = mean(FCarr(prefOrientDist==C.orientationList(orientIdx)));
    end
    
    
    subplot(4,nClust,2*nClust+clust)
    hold on
    scatter(prefOrientDist,FCarr,80,'red','filled')
    scatter(C.orientationList,meanFC,80,'blue','filled')
    set(gca,'XTick',0:45:315)
    xlim([-45 360])
    ylim([-1 1])
    xlabel('Dist b/w pref orient of pair')
    ylabel('Pair FC')
    set(gca,'FontSize',16)
    
    subplot(4,nClust,3*nClust+clust)
    scatter(C.orientationList,meanFC,80,'blue','filled')
    set(gca,'XTick',0:45:315)
    xlim([-45 360])
    ylim([-0.1 0.15])
    yline(0,'k--')
    xlabel('Dist b/w pref orient of pair')
    ylabel('Pair FC mean')
    set(gca,'FontSize',16)

end

% Inference: In the strongly tuned cells, the connectivty is in tune with
% the preferred orientation of the cells: the cells with similar preferred
% orientation have positive functional connectivty (trend) whereas the cells with
% preffered orientation separated by 90 degrees have negative functional
% connectivity (trend). Low (trend) FC strength for similarly tuned cells is seen in cells 
% of Cluster 3.  
end