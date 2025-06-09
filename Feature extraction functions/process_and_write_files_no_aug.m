function process_and_write_files_no_aug(fileList, outputCsvFile, numElementsPerFeature, writeBatchSize, featureFieldNames)
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
        data = load(fullFilePath);

        % featuresStruct = generate_feature_vectors(spec_v, data.MD, numElementsPerFeature);
        featuresStruct = generate_feature_vectors(data, numElementsPerFeature);
        SVD_features = extract_SVD_features(data, 3, numElementsPerFeature);

        % Bit of extra work to add SVD features
        numSVD = length(SVD_features);
        startIndex = length(featureFieldNames) - numSVD + 1;
        for i = 1:numSVD
            fieldName = featureFieldNames{startIndex + i - 1};
            featuresStruct.(fieldName) = repmat(SVD_features(i),1,numElementsPerFeature);
        end
        
        % % Bit of extra work to add SVD features
        filesInBatch = filesInBatch + 1;

        batchData{filesInBatch, 1} = k; % Overall Sample Index
        batchData{filesInBatch, 2} = currentFileName; % FileName
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
        % end
        % disp(filesInBatch);
        
        % Divide filesInBatch by the amount of augmented variants
        % Small fix so the files are actually saved when writebatchsize is
        % equal to 100. filesInBatch increases with
        % length(spectrogramVariants) per file instead of once per file

        if filesInBatch == writeBatchSize || k == numFiles
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
