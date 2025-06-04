%% This script takes the .mat files of the SVD and computes the features we want from spectrograms of reduced dimensionality

clear; clc;
% -- Import feature extraction functions
addpath('Feature extraction functions');

% --- Configuration ---
filePattern = '*.mat';
numElementsPerFeature = 10;
num_time_segments = numElementsPerFeature;
writeBatchSize = 100;

outputFolder = fullfile(pwd, 'generated_features');
outputCsvFile_train = fullfile(outputFolder, 'features_n10_denoised_train.csv');
outputCsvFile_val = fullfile(outputFolder, 'features_n10_denoised_val.csv');

parentFolderPath = '/home/teque/Documents/SystemsControlYear2/Object classification with RADAR/Dataset for project/Dataset_848_SVD';

fprintf('Searching for subfolders in: %s\n', parentFolderPath);
allItems = dir(parentFolderPath);
allDirs = allItems([allItems.isdir]);
subFolders = allDirs(~ismember({allDirs.name}, {'.', '..'}));
numSubFolders = length(subFolders);
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

featureFieldNames = {'mean', 'variance', 'skewness', 'kurtosis', ...
                     'torso_BW', 'limbs_BW', 'torso_BW_max', ...
                     'limbs_BW_max', 'CVD'};

trainingFiles = [];
validationFiles = [];

% Go through all files and folders to group and split files
for i = 1:numSubFolders
    currentSubFolderPath = fullfile(parentFolderPath, subFolders(i).name);
    % fprintf('Scanning folder: %s\n', currentSubFolderPath);
    
    filesInSubFolder = dir(fullfile(currentSubFolderPath, filePattern));
    
    % Add full path info
    for k = 1:length(filesInSubFolder)
        filesInSubFolder(k).folderpath = currentSubFolderPath;
    end

    % --- Group by activity type (first digit of filename) ---
    activityMap = containers.Map();

    for k = 1:length(filesInSubFolder)
        fname = filesInSubFolder(k).name;
        if ~isempty(fname)
            activityType = fname(1);  % First character = activity
            if ~isKey(activityMap, activityType)
                activityMap(activityType) = [];
            end
            activityMap(activityType) = [activityMap(activityType), k];
        end
    end

    % --- For each activity, split and assign files ---
    activityKeys = keys(activityMap);
    for a = 1:length(activityKeys)
        indices = activityMap(activityKeys{a});
        indices = indices(randperm(length(indices)));  % Shuffle
        nTrain = round(0.8 * length(indices));
        trainIdx = indices(1:nTrain);
        valIdx = indices(nTrain+1:end);

        trainingFiles = [trainingFiles; filesInSubFolder(trainIdx)];
        validationFiles = [validationFiles; filesInSubFolder(valIdx)];
    end
end
fprintf('Finished splitting files \n');

% Compute the features for the training and the validation datasets
process_and_write_files(trainingFiles, outputCsvFile_train, numElementsPerFeature, writeBatchSize, featureFieldNames);
process_and_write_files(validationFiles, outputCsvFile_val, numElementsPerFeature, writeBatchSize, featureFieldNames);

fprintf('All files processed.\n');