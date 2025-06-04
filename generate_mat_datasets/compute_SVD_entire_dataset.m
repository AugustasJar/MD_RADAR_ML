clear; clc;

% --- Configuration ---
filePattern = '*.dat'; % Define the pattern for files to process (e.g., '*.dat', '*.bin', or your specific radar file extension)
sigma_truncate = 5; %Amount of singular vectors to take!(Make sure the SVD is done on a dB scale spectrogram!)
writeBatchSize = 10;

% addpath('Attention features/');
addpath("generate_mat_datasets/");

% parentFolderPath = 'C:\Users\augus\Desktop\DELFT\obj_detection\Dataset_848';
parentFolderPath = '/home/teque/Documents/SystemsControlYear2/Object classification with RADAR/Dataset for project/Dataset_848';
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

%% Process each file

% --- Define Output Root Path ---
outputRootPath = [parentFolderPath, '_SVD'];
count = 0;

% --- Process Each File ---
fprintf('Starting SVD computation and file saving...\n');
for k = 1:numFiles
    currentFile = allMatchingFiles(k);
    currentFileName = currentFile.name;
    currentFileSubfolderPath = currentFile.folderpath;
    fullFilePath = fullfile(currentFileSubfolderPath, currentFileName);

    fprintf('Processing file %d/%d: %s\n', k, numFiles, currentFileName);

    try
        % --- Load and Compute SVD ---
        [spectrogram_example, MD] = createSpectrogram_optimized(fullFilePath);

        % Apply it on the dB scale spectrogram(already given by the command
        % above)
        [U, S, V] = svd(spectrogram_example);

        U = U(:,1:sigma_truncate);
        S = S(1:sigma_truncate,1:sigma_truncate);
        V = V(:,1:sigma_truncate);

        % --- Determine Output Path ---
        % Create equivalent output subfolder path
        relativeSubPath = strrep(currentFileSubfolderPath, parentFolderPath, '');
        targetSubfolderPath = fullfile(outputRootPath, relativeSubPath);

        % Create output folder if it doesn't exist
        if ~exist(targetSubfolderPath, 'dir')
            mkdir(targetSubfolderPath);
        end

        % Create output file name
        [~, baseFileName, ~] = fileparts(currentFileName);
        outputFileName = [baseFileName, '_SVD.mat'];
        outputFilePath = fullfile(targetSubfolderPath, outputFileName);

        % --- Save Results to .mat ---
        save(outputFilePath, 'U', 'S', 'V', 'MD', 'sigma_truncate');

    catch ME
        warning('Error processing file %s: %s', currentFileName, ME.message);
    end
end

fprintf('Processing complete. SVD data saved in: %s\n', outputRootPath);

