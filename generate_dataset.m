% processRadarDataToCsv.m
%
% This script reads all specified files from an input folder,
% extracts features using 'extractRadarFeatures.m', and saves
% the features along with filenames to a CSV file, writing every 50 files.

clear; clc;

% --- Configuration ---
filePattern = '*.dat'; % Define the pattern for files to process (e.g., '*.dat', '*.bin', or your specific radar file extension)
outputCsvFile = 'radar_features_output_n20.csv';
numElementsPerFeature = 20;
writeBatchSize = 100; % Number of files to process before writing to CSV

parentFolderPath = 'C:\Users\augus\Desktop\DELFT\obj_detection\Dataset_848';
fprintf('Searching for subfolders in: %s\n', parentFolderPath);
allItems = dir(parentFolderPath);
allDirs = allItems([allItems.isdir]); % Keep only directories
subFolders = allDirs(~ismember({allDirs.name}, {'.', '..'})); % Exclude '.' and '..'
numSubFolders = length(subFolders);
fprintf('Found %d potential subfolder(s) to scan for files.\n', numSubFolders);

allMatchingFiles = [];
for i=1:numSubFolders
    currentSubFolderPath = fullfile(parentFolderPath, subFolders(i).name);
    fprintf('  Scanning folder: %s\n', currentSubFolderPath);
    filesInSubFolder = dir(fullfile(currentSubFolderPath, filePattern));
    for j = 1:length(filesInSubFolder)
        filesInSubFolder(j).folderpath = currentSubFolderPath; % Store full path to the folder
    end
    allMatchingFiles = [allMatchingFiles; filesInSubFolder]; %#ok<AGROW>
end

numFiles = length(allMatchingFiles);
if numFiles == 0
    fprintf('No files found matching the pattern "%s" in the specified parent folder and its subfolders.\n', filePattern);
    return;
end
fprintf('Found %d files to process.\n', numFiles);

% --- Define feature field names in the order they should appear ---
featureFieldNames = {'mean', 'variance', 'skewness', 'kurtosis', ...
                     'torso_BW', 'total_BW', 'total_BW_offset', ...
                     'total_torso_BW_offset'};
numFeatureTypes = length(featureFieldNames);

% --- Prepare headers for the CSV file ---
header = {'SampleIndex', 'FileName'};
for i = 1:numFeatureTypes
    fieldName = featureFieldNames{i};
    for j = 1:numElementsPerFeature
        header{end+1} = sprintf('%s_%d', fieldName, j);
    end
end

% --- Initialize a cell array to store data for the current batch ---
batchData = cell(writeBatchSize, 2 + numFeatureTypes * numElementsPerFeature);
filesInBatch = 0; % Counter for files in the current batch
firstWriteDone = false; % Flag to track if the header has been written

% --- Process each file ---
fprintf('Starting feature extraction...\n');
for k = 1:numFiles
    currentFile = allMatchingFiles(k);
    currentFileName = currentFile.name;
    currentFileSubfolderPath = currentFile.folderpath;
    fullFilePath = fullfile(currentFileSubfolderPath, currentFileName);

    fprintf('Processing file %d/%d: %s\n', k, numFiles, currentFileName);

    % Call your feature extraction function
    % This function should return a structure as described
    [spectrogram,time_axis,vel_axis] = createSpectrogram_optimized(fullFilePath); % Assuming this function exists
    featuresStruct = generate_feature_vectors(spectrogram,vel_axis,numElementsPerFeature); % Assuming this function exists

    filesInBatch = filesInBatch + 1; % Increment file counter for the batch

    % Store sample index and filename
    batchData{filesInBatch, 1} = k; % Overall Sample Index
    batchData{filesInBatch, 2} = currentFileName; % FileName

    % Flatten the features structure into the cell array row
    currentCellCol = 3;
    for i = 1:numFeatureTypes
        fieldName = featureFieldNames{i};
        if isfield(featuresStruct, fieldName)
            featureVector = featuresStruct.(fieldName);
            if ~isrow(featureVector) && iscolumn(featureVector)
                featureVector = featureVector';
            end
            if length(featureVector) == numElementsPerFeature
                batchData(filesInBatch, currentCellCol : currentCellCol + numElementsPerFeature - 1) = num2cell(featureVector);
            else
                warning('Feature "%s" for file "%s" has %d elements, expected %d. Filling with NaNs.', ...
                        fieldName, currentFileName, length(featureVector), numElementsPerFeature);
                batchData(filesInBatch, currentCellCol : currentCellCol + numElementsPerFeature - 1) = {NaN}; % Pad with NaN
            end
        else
            warning('Feature field "%s" not found in output for file "%s". Filling with NaNs.', fieldName, currentFileName);
            batchData(filesInBatch, currentCellCol : currentCellCol + numElementsPerFeature - 1) = {NaN}; % Fill with NaNs if field missing
        end
        currentCellCol = currentCellCol + numElementsPerFeature;
    end

    % Check if it's time to write the batch to CSV
    if filesInBatch == writeBatchSize || k == numFiles
        fprintf('Writing batch to CSV (Files %d to %d)...\n', k - filesInBatch + 1, k);
        % Convert current batch data to a table
        T_batch = cell2table(batchData(1:filesInBatch, :), 'VariableNames', header);

        try
            if ~firstWriteDone
                % First write: create the file with headers
                writetable(T_batch, outputCsvFile);
                firstWriteDone = true;
                fprintf('Successfully created %s and wrote initial batch.\n', outputCsvFile);
            else
                % Subsequent writes: append to the existing file without headers
                writetable(T_batch, outputCsvFile, 'WriteMode', 'append', 'WriteVariableNames', false);
                fprintf('Successfully appended batch to %s.\n', outputCsvFile);
            end
        catch ME_write
            fprintf('ERROR writing CSV file: %s\n', ME_write.message);
            fprintf('Please check file permissions and path.\n');
            % Optionally, decide if you want to stop or continue if a write fails
        end

        % Reset for the next batch
        batchData = cell(writeBatchSize, 2 + numFeatureTypes * numElementsPerFeature); % Re-initialize
        filesInBatch = 0;
    end
end

fprintf('Processing complete.\n');