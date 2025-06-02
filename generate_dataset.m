% processRadarDataToCsv.m
%
% This script reads all specified files from an input folder,
% extracts features using 'extractRadarFeatures.m', and saves
% the features along with filenames to a CSV file, writing every N files.

clear; clc;

% -- Import functions
addpath('Attention features');
addpath('SVD features');

% --- Configuration ---
filePattern = '*.mat';
numElementsPerFeature = 30;
num_time_segments = numElementsPerFeature;
writeBatchSize = 5;
numSingularVectors = 3;

outputFolder = fullfile(pwd, 'generated_features');
outputCsvFile = fullfile(outputFolder, 'attention_features_n30_denoised.csv');

parentFolderPath = '/home/teque/Documents/SystemsControlYear2/Object classification with RADAR/Dataset for project/Dataset_848_SVD';
% parentFolderPath = '/home/teque/Documents/SystemsControlYear2/Object classification with RADAR/Dataset for project/Dataset_848';
fprintf('Searching for subfolders in: %s\n', parentFolderPath);
allItems = dir(parentFolderPath);
allDirs = allItems([allItems.isdir]);
subFolders = allDirs(~ismember({allDirs.name}, {'.', '..'}));
fprintf('Found %d subfolder(s).\n', length(subFolders));

% --- Find all matching files
allMatchingFiles = [];
for i = 1:length(subFolders)
    currentSubFolderPath = fullfile(parentFolderPath, subFolders(i).name);
    filesInSubFolder = dir(fullfile(currentSubFolderPath, filePattern));
    for j = 1:length(filesInSubFolder)
        filesInSubFolder(j).folderpath = currentSubFolderPath;
    end
    allMatchingFiles = [allMatchingFiles; filesInSubFolder]; %#ok<AGROW>
end

numFiles = length(allMatchingFiles);
if numFiles == 0
    fprintf('No files found matching "%s"\n', filePattern);
    return;
end
fprintf('Found %d files to process.\n', numFiles);

% --- Prepare headers ---
featureFieldNames = {'mean', 'variance', 'skewness', 'kurtosis', ...
                     'torso_BW', 'total_BW', 'total_BW_offset', ...
                     'total_torso_BW_offset'};
numFeatureTypes = length(featureFieldNames);

header = {'SampleIndex', 'FileName'};
addSVDLabels = @(prefix) arrayfun(@(x) sprintf('%s%d', prefix, x), ...
                                   1:numSingularVectors, 'UniformOutput', false);

for i = 1:numFeatureTypes
    for j = 1:numElementsPerFeature
        header{end+1} = sprintf('%s_%d', featureFieldNames{i}, j);
    end
end

%% --- Initialize batching ---
batchData = cell(writeBatchSize, length(header));
filesInBatch = 0;
firstWriteDone = false;

% --- Process each file ---
fprintf('Starting feature extraction...\n');
for k = 1:numFiles
    currentFile = allMatchingFiles(k);
    fullFilePath = fullfile(currentFile.folderpath, currentFile.name);
    fprintf('Processing file %d/%d: %s\n', k, numFiles, currentFile.name);

    % --- Feature extraction ---
    data = load(fullFilePath);
    % SVD_features = extract_SVD_features(data, numSingularVectors);
    % [spectrogram,time_axis,vel_axis] = createSpectrogram_optimized(fullFilePath); % Assuming this function exists

    % Attention features using SVD denoised spectrogram
    featuresStruct = generate_feature_vectors(data.U * data.S * data.V', ...
                                              data.MD.VelocityAxis, numElementsPerFeature);
    % featuresStruct = generate_feature_vectors(spectrogram, ..
    %                                           vel_axis, numElementsPerFeature);

    % --- Store into batch ---
    filesInBatch = filesInBatch + 1;
    currentRow = filesInBatch;
    currentCellCol = 3;

    batchData{currentRow, 1} = k;
    batchData{currentRow, 2} = currentFile.name;

    % --- Process the attention featuresnum_time_segments
    for i = 1:numFeatureTypes
        fieldName = featureFieldNames{i};
        if isfield(featuresStruct, fieldName)
            vector = featuresStruct.(fieldName);
            if iscolumn(vector), vector = vector'; end
            if length(vector) == numElementsPerFeature
                batchData(currentRow, currentCellCol : currentCellCol + numElementsPerFeature - 1) = num2cell(vector);
            else
                batchData(currentRow, currentCellCol : currentCellCol + numElementsPerFeature - 1) = {NaN};
            end
        else
            batchData(currentRow, currentCellCol : currentCellCol + numElementsPerFeature - 1) = {NaN};
        end

        % --- Add SVD features ---
        % batchData(currentRow, currentCellCol : currentCellCol + len(SVD_features)) = num2cell(SVD_features);

        % currentCellCol = currentCellCol + numElementsPerFeature + len(SVD_features);
         currentCellCol = currentCellCol + numElementsPerFeature;
    end

    % --- Write batch if full or last file ---
    if filesInBatch == writeBatchSize || k == numFiles
        fprintf('Writing batch: rows %d to %d\n', k - filesInBatch + 1, k);
        T_batch = cell2table(batchData(1:filesInBatch, :), 'VariableNames', header);

        try
            if ~firstWriteDone
                writetable(T_batch, outputCsvFile);
                firstWriteDone = true;
                fprintf('Created file: %s\n', outputCsvFile);
            else
                writetable(T_batch, outputCsvFile, 'WriteMode', 'append', 'WriteVariableNames', false);
                fprintf('Appended to file: %s\n', outputCsvFile);
            end
        catch ME
            fprintf('Error writing CSV: %s\n', ME.message);
        end

        % Reset batch
        batchData = cell(writeBatchSize, length(header));
        filesInBatch = 0;
    end
end

fprintf('All files processed.\n');