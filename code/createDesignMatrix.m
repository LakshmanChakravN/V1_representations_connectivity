function designMat = createDesignMatrix(binnedVarArray, binnedSpikes, basesParams, varargin)

% Examples: designMat = createDesignMatrix(x, y, dataStructure)
%           designMat = createDesignMatrix(x, y, dataStructure, 'FORCEDGROUPS', {'Stim1 'Stim2'; 'Behavior1' 'Behavior2'})
%
% INPUTS:
% binnedVarArray = an nxm numeric array with n time bins and m variables
% representing the occurrence of each variable
% binnedSpikes = an nxm numeric array with n time bins and m cells
% basesParams = a structure array containing the following parameters:
%       basesParams(1).varName = 'Stim1'
%       basesParams(1).numBases = 10
%       basesParams(1).binSize = 0.05
%       basesParams(1).kernDur = 5
%       basesParams(1).linearStretch = 10
%       basesParams(1).basesType = 'POST'
%       basesParams(1).truncate = ''
%       The values in parenthesis represent the variable number in the order
%       listed in binnedVarArray columns.
% varargin = 'FORCEDGROUPS', groups
%       where groups is a cell array of cell arrays where each row
%       represents a new group of variables (i.e. {'Stim1' 'Stim2';'Behavior1' 'Behavior2'}
%
% OUTPUTS:
% designMat = a table of variables and binned spikes; each variable has as
%       many columns as numBases;


for i = 1:size(basesParams,2)
    varLabels{1,i} = basesParams(i).varName;
end


% Check that variable names are not repeated in varLabels
if length(unique(varLabels)) < length(varLabels)
    error('varNames should not have repeated variables');
end

% Check that variable names are strings and not numbers
if ~iscellstr(varLabels)
    error('varNames should be strings');
end

% Check that binnedSpikes does not contain labels
if ~isnumeric(binnedSpikes)
    error('binnedSpikes should be a numeric array');
end

% Check that the basesTypes are the same length as varLabels and columns of
% binnedVarArray
if length(basesParams) ~= length(varLabels) || length(basesParams) ~= size(binnedVarArray,2)
    error('Each column in binnedVarArray should have a corresponding entry in basesParams')
end

% Check if user has indicated FORCEDGROUPS
if any(strcmp('FORCEDGROUPS', varargin))
    forcedGroups = true;
    groupingNums = zeros(size(varargin{find(strcmp('FORCEDGROUPS',varargin))+1},1),1);
    groupNames = varargin{find(strcmp('FORCEDGROUPS',varargin))+1};
    if length(unique(groupNames)) < length(groupNames(:))
        error('Variables can only belong to one group')
    end
else
    forcedGroups = false;
end

designMat = {};
varNum = 1;
usedGroupNums = [];

for i = 1:length(basesParams)
    
    % Check if the varName belongs to one of the groupings
    if forcedGroups
        idx = strcmp(groupNames, basesParams(i).varName);
        idxExists = sum(idx(:));
        groupRowValue = groupingNums(logical(sum(idx,2)),1);
        if idxExists > 0 && groupRowValue < 1
            groupingNums(logical(sum(idx,2)),1) = varNum;
        elseif idxExists > 0 && groupRowValue > 0
            varNum = groupRowValue;
        elseif ~isempty(usedGroupNums)
            varNum = max(usedGroupNums)+1;
        end
        
        usedGroupNums(i) = varNum;
    end
    
    % Check that the basesType entered is one of 4 valid options
    if any(strcmp(basesParams(i).basesType, {'PRE' 'POST' 'SYM' 'NONE'}))
        if ~strcmp(basesParams(i).basesType, 'NONE')
            bases = createBasesFunctions(basesParams(i).numBases, basesParams(i).binSize, basesParams(i).kernDur, ...
                basesParams(i).linearStretch, basesParams(i).basesType, basesParams(i).truncate);
        end
    else
        error(['Invalid basesType entered at entry number ' num2str(i) '. Enter one of 4 options: PRE, POST, SYM, NONE']);
    end
    
    switch basesParams(i).basesType
        case 'PRE'
            clear varNames designMatTemp concatNamesMat
            onsets = [0; diff(binnedVarArray(:,i))>0];
            for k = 1:size(bases,2)
                designMatTemp(:,k) = conv(onsets,bases(:,k),'same');
                varNames(1,k) = strcat(varLabels(i), '_', num2str(varNum), '_', num2str(k));
            end
            if ~isempty(basesParams(i).mask)
                if ischar(basesParams(i).mask)
                    varIDs = struct2cell(basesParams');
                    varIDs = varIDs(1,:)';
                    if any(strcmp(varIDs, basesParams(i).mask))
                        varIdx = (strcmp(varIDs, basesParams(i).mask));
                        maskVar = binnedVarArray(:,varIdx);
                        designMatTemp = designMatTemp.*maskVar;
                    else
                        error('The masking variable you entered does not match any of the independent variables in basesParams');
                    end
                elseif size(basesParams(i).mask,1) == size(binnedVarArray,1)
                    maskVar = basesParams(i).mask;
                    designMatTemp = designMatTemp.*maskVar;
                else
                    error('The masking variable must have the same number of rows as binnedVarArray');
                end
            end                
            concatNamesMat = [varNames; num2cell(designMatTemp)];
            designMat = [designMat concatNamesMat];
            
        case 'POST'
            clear varNames designMatTemp concatNamesMat
            onsets = [0; diff(binnedVarArray(:,i))>0];
            for k = 1:size(bases,2)
                designMatTemp(:,k) = conv(onsets,bases(:,k),'same');
                varNames(1,k) = strcat(varLabels(i), '_', num2str(varNum), '_', num2str(k));
            end
            if ~isempty(basesParams(i).mask)
                if ischar(basesParams(i).mask)
                    varIDs = struct2cell(basesParams');
                    varIDs = varIDs(1,:)';
                    if any(strcmp(varIDs, basesParams(i).mask))
                        varIdx = (strcmp(varIDs, basesParams(i).mask));
                        maskVar = binnedVarArray(:,varIdx);
                        designMatTemp = designMatTemp.*maskVar;
                    else
                        error('The masking variable you entered does not match any of the independent variables in basesParams');
                    end
                elseif size(basesParams(i).mask,1) == size(binnedVarArray,1)
                    maskVar = basesParams(i).mask;
                    designMatTemp = designMatTemp.*maskVar;
                else
                    error('The masking variable must have the same number of rows as binnedVarArray');
                end
            end    
            concatNamesMat = [varNames; num2cell(designMatTemp)];
            designMat = [designMat concatNamesMat];
        case 'SYM'
            clear varNames designMatTemp concatNamesMat
            for k = 1:size(bases,2)
                designMatTemp(:,k)= conv(binnedVarArray(:,i),bases(:,k),'same');
                varNames(1,k) = strcat(varLabels(i), '_', num2str(varNum), '_', num2str(k));
            end
            if ~isempty(basesParams(i).mask)
                if ischar(basesParams(i).mask)
                    varIDs = struct2cell(basesParams');
                    varIDs = varIDs(1,:)';
                    if any(strcmp(varIDs, basesParams(i).mask))
                        varIdx = (strcmp(varIDs, basesParams(i).mask));
                        maskVar = binnedVarArray(:,varIdx);
                        designMatTemp = designMatTemp.*maskVar;
                    else
                        error('The masking variable you entered does not match any of the independent variables in basesParams');
                    end
                elseif size(basesParams(i).mask,1) == size(binnedVarArray,1)
                    maskVar = basesParams(i).mask;
                    designMatTemp = designMatTemp.*maskVar;
                else
                    error('The masking variable must have the same number of rows as binnedVarArray');
                end
            end    
            concatNamesMat = [varNames; num2cell(designMatTemp)];
            designMat = [designMat concatNamesMat];
        case 'NONE'
            clear varNames designMatTemp concatNamesMat
            concatNamesMat = [strcat(varLabels(i), '_', num2str(varNum), '_1'); num2cell(binnedVarArray(:,i))];
            designMat = [designMat concatNamesMat];
    end
    varNum = varNum+1;
end

% Create labels for the binned spikes and append to designMat
for j = 1:size(binnedSpikes,2)
    cellNames(1,j) = strcat({'Cell'}, num2str(j), '_', num2str(varNum), '_', num2str(j));
end
concatCellNames = [cellNames; num2cell(binnedSpikes)];
designMat = [designMat concatCellNames];



% Convert designMat to a table
designMat = cell2table(designMat(2:end,:), 'VariableNames', designMat(1,:));
