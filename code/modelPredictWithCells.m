function predSpikes = modelPredictWithCells(modelData, selVars)

% EXAMPLES: predSpikes = modelPredict(modelData, {'Offset' 'Stim1' 'Behavior1'})
%           predSpikes = modelPredict(modelData, {'Offset' 'Stim1' 'Behavior1'}, 'SELECTLAMBDA', lamIdx)
%
% INPUTS:
% modelData = a structure array created by loadModelData.m that includes 
%       the cellID, betas, lambdas, minlambda, cve, cvse, nulldeviance, and
%       design matrix
% selVars = the variables to be included for predicting spiking
% 'SELECTLAMBDA', lamIdx = a user specified lambda index from the list of lambdas; 
%       default is the minimum lambda index
%
% OUTPUTS:
% predSpikes = the model-estimated spiking across the recording duration entered in designMatrix

arguments
    modelData struct
    selVars cell
end

% Load the design matrix
dMat = modelData.designMat;

% Separate design matrix
cellInds = startsWith(dMat.Properties.VariableNames, modelData.cellID);
desMat = dMat(:,~cellInds);

% Add a column of ones at the front of the design matrix to represent the
% offset produced by the model
offsetVar = [ones(size(desMat(:,1)))];
offsetVarTbl= table(offsetVar, 'VariableNames', {'Offset'});
desTbl = [offsetVarTbl desMat];

% Identify lambda idx

lamIdx = find(modelData.lambdas == modelData.minlambda);

coefMat = num2cell((modelData.betas(:,lamIdx))',1); 
coefTbl = cell2table(coefMat, 'VariableNames', desTbl.Properties.VariableNames);

% Remove the last two underscores from each variable name
underscoreInds = cellfun(@(x)strfind(x, '_'), desTbl.Properties.VariableNames, 'UniformOutput',false);
underscoreInds{1} = [7, 0];
varNames = cellfun(@(x,y)x(1:y(end-1)-1),desTbl.Properties.VariableNames, underscoreInds, 'UniformOutput',false);

% Reconstruct firing based on model with specified variables
validCols = cellfun(@(x)any(strcmp(x,selVars)),varNames);
scaledBases = (table2array(desTbl).*table2array(coefTbl)).*validCols;
predSpikes = exp(sum(scaledBases,2));
