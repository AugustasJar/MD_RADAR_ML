function [] = generate_dataset(pipeline)

    fprintf('Searching for subfolders in: %s\n', pipeline.parentFolderPath);
    allItems = dir(pipeline.parentFolderPath);
    allDirs = allItems([allItems.isdir]);
    subFolders = allDirs(~ismember({allDirs.name}, {'.', '..'}));
    numSubFolders = length(subFolders);
    fprintf('Found %d subfolder(s).\n', numSubFolders);
    
    % --- Find all matching files ---
    allMatchingFiles = [];
    for i = 1:numSubFolders
        currentSubFolderPath = fullfile(pipeline.parentFolderPath, subFolders(i).name);
        filesInSubFolder = dir(fullfile(currentSubFolderPath, pipeline.filePattern));
        for j = 1:length(filesInSubFolder)
            filesInSubFolder(j).folderpath = currentSubFolderPath;
        end
        allMatchingFiles = [allMatchingFiles; filesInSubFolder]; %#ok<AGROW>
    end
    
    numFiles = length(allMatchingFiles);
    if numFiles == 0
        fprintf('No files found matching "%s"\n', pipeline.filePattern);
        return;
    end
    fprintf('Found %d files to process.\n', numFiles);
    
    % Initialize file lists
    trainingFiles = [];
    validationFiles = [];
    
    % Go through all files and folders to group and split files
    for i = 1:numSubFolders
        currentSubFolderPath = fullfile(pipeline.parentFolderPath, subFolders(i).name);
        
        filesInSubFolder = dir(fullfile(currentSubFolderPath, pipeline.filePattern));
        
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
    if pipeline.augment
        process_and_write_files(trainingFiles, pipeline.outputCsvFile_train, ...
                                  pipeline.numElementsPerFeature, pipeline.writeBatchSize, pipeline.featureFieldNames, pipeline.N_aug_rep);
    
        process_and_write_files(validationFiles, pipeline.outputCsvFile_val, ...
                                  pipeline.numElementsPerFeature, pipeline.writeBatchSize, pipeline.featureFieldNames, pipeline.N_aug_rep);
    else
        process_and_write_files_no_aug(trainingFiles, pipeline.outputCsvFile_train, ...
                                      pipeline.numElementsPerFeature, pipeline.writeBatchSize, pipeline.featureFieldNames);
        
        process_and_write_files_no_aug(validationFiles, pipeline.outputCsvFile_val, ...
                                      pipeline.numElementsPerFeature, pipeline.writeBatchSize, pipeline.featureFieldNames);
    end

    fprintf('All files processed.\n');
end

