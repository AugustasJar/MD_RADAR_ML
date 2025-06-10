%% Take .mat SVD reduced spectrograms to perform feature extraction on
% Simply edit the fields of the "pipeline" struct

clear; clc;

% -- Import feature extraction functions
addpath('Feature extraction functions');

% --- Configuration of file paths ---
pipeline.filePattern = '*.mat';
pipeline.outputFolder = fullfile(pwd, 'generated_features');

% Load SVD .mat files instead of raw .dat file data
pipeline.parentFolderPath = '/home/teque/Documents/SystemsControlYear2/Object classification with RADAR/Dataset for project/Dataset_848_SVD';

% -- Features to be extracted. Remove names here to omit the
% features you don't want
featureFieldNames = {'mean', 'variance', 'skewness', 'kurtosis', ...
                     'torso_BW', 'limbs_BW', 'torso_BW_max', ...
                     'limbs_BW_max', 'CVD', 'energy_sym'};
pipeline.featureFieldNames = featureFieldNames;

% Singular vector components and amount to extract from
% Comment if you don't need them
SVD_featureTypes = {'mean', 'sigma', 'peaks_pos', 'peaks_neg'};
singular_vectors_no = 3;
newFeatureNames = {};
for i = 1:length(SVD_featureTypes)
    for j = 1:singular_vectors_no 
        newFeatureNames{end+1} = sprintf('%s_V%d', SVD_featureTypes{i}, j);
    end
end
pipeline.featureFieldNames = [featureFieldNames, newFeatureNames];

% Settings for the amount of time segments and the batch size
pipeline.numElementsPerFeature = 20;
pipeline.writeBatchSize = 100;
pipeline.trainingFiles = [];
pipeline.validationFiles = [];

% Enable/disable data augmentation
pipeline.augment = true;
pipeline.N_aug_rep = 2; % Amount of augmented versions per each augmentation type

% Name your output file
pipeline.outputCsvFile_train = fullfile(pipeline.outputFolder, 'n20_denoised_train_no_aug.csv');
pipeline.outputCsvFile_val = fullfile(pipeline.outputFolder, 'n20_denoised_val_no_aug.csv');

% Generate the feature dataset
generate_dataset(pipeline);
