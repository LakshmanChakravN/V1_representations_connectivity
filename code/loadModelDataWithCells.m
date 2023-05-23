function modelData = loadModelDataWithCells(fileDirectory, cellIDs)
%
% Examples: modelData = loadModelData('/home/Documents/Data/')
%           modelData = loadModelData('/home/Documents/Data/', 'CHOOSECELLS', [2:5 10 12 14])
% 
% INPUTS:
% fileDirectory = specifies the directory where the model output files and
%       design matrix are saved
% [cellIDs] = only reads in cells specified in cellIDs
%
% OUTPUT:
% modelData = a structure array containing the cell ID, betas, lambdas,
%       minimum lambda, cross validation error (cve), cross validation standard
%       error (cvse), and null deviance for each cell produced from the
%       model

arguments
    fileDirectory char
    cellIDs double
end

% Load the design matrix
dMat = readtable(fullfile(fileDirectory, 'DesignMatrixWithCells.txt'));

% Separate cells from design matrix
cellResponses = startsWith(dMat.Properties.VariableNames, 'Cell');
cellResponses = dMat(:,cellResponses);

    
for j = 1:length(cellIDs)
    modelData(j).cellID = char(cellResponses.Properties.VariableNames(cellIDs(j)));
    modelData(j).betas = csvread(fullfile(fileDirectory, 'RoutputFiles', string(['betas_' char(cellResponses.Properties.VariableNames(cellIDs(j)))])),1);
    modelData(j).lambdas = csvread(fullfile(fileDirectory, 'RoutputFiles', string(['lambdas_' char(cellResponses.Properties.VariableNames(cellIDs(j)))])),1);
    modelData(j).minlambda = csvread(fullfile(fileDirectory, 'RoutputFiles', string(['minlambda_' char(cellResponses.Properties.VariableNames(cellIDs(j)))])),1);
    modelData(j).cve = csvread(fullfile(fileDirectory, 'RoutputFiles', string(['cve_' char(cellResponses.Properties.VariableNames(cellIDs(j)))])),1);
    modelData(j).cvse = csvread(fullfile(fileDirectory, 'RoutputFiles', string(['cvse_' char(cellResponses.Properties.VariableNames(cellIDs(j)))])),1);
    modelData(j).nulldeviance = csvread(fullfile(fileDirectory, 'RoutputFiles', string(['nulldev_' char(cellResponses.Properties.VariableNames(cellIDs(j)))])),1);
    modelData(j).designMat = dMat;    
end

end


        