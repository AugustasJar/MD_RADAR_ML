function process_and_write_files(fileList, outputCsvFile, numElementsPerFeature, writeBatchSize, featureFieldNames)
    numFeatureTypes = length(featureFieldNames);

    % --- Prepare headers for the CSV file ---
    header = {'SampleIndex', 'FileName'};
    for i = 1:numFeatureTypes
        fieldName = featureFieldNames{i};
        for j = 1:numElementsPerFeature
            header{end+1} = sprintf('%s_%d', fieldName, j);
        end
    end

    batchData = cell(writeBatchSize, 2 + numFeatureTypes * numElementsPerFeature);
    filesInBatch = 0;
    firstWriteDone = false;

    numFiles = length(fileList);
    fprintf('Starting feature extraction for %s...\n', outputCsvFile);
    

    for k = 1:numFiles
        currentFile = fileList(k);
        currentFileName = currentFile.name;
        fullFilePath = fullfile(currentFile.folderpath, currentFileName);

        fprintf('Processing file %d/%d: %s\n', k, numFiles, currentFileName);

        % disp(k);

        % CHANGE THIS TO SVD DENOISED VERSION!
        % [spectrogram, time_axis, vel_axis] = createSpectrogram_optimized(fullFilePath);
        data = load(fullFilePath);
        N_aug_rep = 1;

        % DATA AUGMENTATION CALLED HERE on reconstructed SVD spectrogram
        aug = dat_aug(data.U*data.S*data.V', N_aug_rep);

        spectrogramVariants = {aug.orig};
        variantLabels = {'orig'};
        warpTypes = {'timeWarp', 'freqWarp', 'blur', 'noise'};

        for t = 1:length(warpTypes)
            type = warpTypes{t};
            for i = 1:N_aug_rep
                spectrogramVariants{end+1} = aug.(type){i};
                variantLabels{end+1} = sprintf('%s_%d', type, i);
            end
        end

        for v = 1:length(spectrogramVariants)
            spec_v = spectrogramVariants{v};
            label_v = variantLabels{v};

            % featuresStruct = generate_feature_vectors(spec_v, data.MD, numElementsPerFeature, fullFilePath);
            featuresStruct = generate_feature_vectors(spec_v, data.MD, numElementsPerFeature);
            filesInBatch = filesInBatch + 1;

            batchData{filesInBatch, 1} = sprintf('%d_%s', k, label_v);
            batchData{filesInBatch, 2} = [currentFileName '_' label_v];
            currentCellCol = 3;

            for i = 1:numFeatureTypes
                fieldName = featureFieldNames{i};
                if isfield(featuresStruct, fieldName)
                    featureVector = featuresStruct.(fieldName);
                    if ~isrow(featureVector), featureVector = featureVector'; end
                    if length(featureVector) == numElementsPerFeature
                        batchData(filesInBatch, currentCellCol : currentCellCol + numElementsPerFeature - 1) = num2cell(featureVector);
                    else
                        batchData(filesInBatch, currentCellCol : currentCellCol + numElementsPerFeature - 1) = {NaN};
                    end
                else
                    batchData(filesInBatch, currentCellCol : currentCellCol + numElementsPerFeature - 1) = {NaN};
                end
                currentCellCol = currentCellCol + numElementsPerFeature;
            end
        end
        % disp(filesInBatch);
        
        % Divide filesInBatch by the amount of augmented variants
        % Small fix so the files are actually saved when writebatchsize is
        % equal to 100. filesInBatch increases with
        % length(spectrogramVariants) per file instead of once per file

        if filesInBatch/length(spectrogramVariants) == writeBatchSize || k == numFiles
            fprintf('Writing batch to CSV (Files %d to %d)...\n', k - filesInBatch + 1, k);
            T_batch = cell2table(batchData(1:filesInBatch, :), 'VariableNames', header);

            try
                if ~firstWriteDone
                    writetable(T_batch, outputCsvFile);
                    firstWriteDone = true;
                else
                    writetable(T_batch, outputCsvFile, 'WriteMode', 'append', 'WriteVariableNames', false);
                end
            catch ME_write
                fprintf('ERROR writing to %s: %s\n', outputCsvFile, ME_write.message);
            end

            batchData = cell(writeBatchSize, 2 + numFeatureTypes * numElementsPerFeature);
            filesInBatch = 0;
        end
    end

    fprintf('Finished writing to %s\n', outputCsvFile);
end
