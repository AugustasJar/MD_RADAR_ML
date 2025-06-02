% Purpose of script
% Fuse attention features over time segments together with features over
% the entire duration

% It groups the time segment features into coherent time segments and in
% between time segments adds copies of features calculated over a whole
% spectrogram

% This format is then compatible with our time segment transformer while
% the dataset files can also be tested with other classifiers

addpath('generated_datasets');

T = readtable('attention_features_n25_denoised.csv');
data = table2array(T);  % Convert to numeric matrix
