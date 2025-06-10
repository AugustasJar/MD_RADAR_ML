% this function generates a feature vector from the data. it splits the
% spectrogram into N chunks and applies "extract_features.m" to each chunk
% generating a time series of chunks.

% edit this function if changes are made to extract features.

function features = generate_feature_vectors(spectrogram_data,doppler_axis,N)

    %split data the spectrogram into N slices.
    [num_doppler_bins, num_time_segments] = size(spectrogram_data);
    
    chunk_size = ceil(num_time_segments / N);
    paddedNumTimeFrames = chunk_size * N; % Total time frames after padding
    paddingAmount = paddedNumTimeFrames - num_time_segments;
    padding = zeros(num_doppler_bins,paddingAmount);
    spectrogram_padded = [spectrogram_data padding];
    features.mean = [];
    features.variance = [];
    features.skewness = [];
    features.kurtosis = [];
    
    features.torso_BW = [];
    features.total_BW = [];
    
    features.total_BW_offset = [];
    features.total_torso_BW_offset = [];
   disp("Calling extract_features...");
    for i=1:N
       chunk_start = (i-1)*chunk_size+1;
       chunk_end = i*chunk_size;
       
       chunk = spectrogram_padded(:,chunk_start:chunk_end);

       features_i = extract_features(chunk, doppler_axis, 36);
       
       features.mean = [features.mean features_i.mean];
       features.variance = [features.variance features_i.variance];
       features.skewness = [features.skewness features_i.skewness];
       features.kurtosis = [features.kurtosis features_i.kurtosis];
       features.torso_BW = [features.torso_BW features_i.torso_BW];
       features.total_BW = [features.total_BW features_i.total_BW];
    
       features.total_BW_offset = [features.total_BW_offset features_i.total_BW_offset];
       features.total_torso_BW_offset = [features.total_torso_BW_offset features_i.total_torso_BW_offset];
       
    end
end