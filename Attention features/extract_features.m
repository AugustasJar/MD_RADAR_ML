function features = extract_features(spectrogram_data, doppler_axis, threshold_dB_below_peak)
% This function is used to generate a feature structure from a spectrogram
% (or a part of spectrogram). Feel free to copy this file and generate
% different feature vectors for testing.
%
% INPUTS:
%   spectrogram_data: 2D matrix [num_doppler_bins, num_time_segments]
%                     containing the spectrogram (e.g., magnitude or
%                     power)
%                     It's assumed that spectrogram_data(k,t) corresponds
%                     to doppler_axis(k) at time_axis(t).
%                     IMPORTANT: Bandwidth requires non dB scale input for
%                     it to work properly! CONVERT TO linear scale FIRST
%
%
%   doppler_axis:     Vector [num_doppler_bins, 1] or [1, num_doppler_bins]
%                     containing the Doppler frequency values for the rows
%                     of spectrogram_data.
%   threshold_dB_below_peak: Scalar, threshold in dB below the global peak
%                            of spectrogram_data to calculate envelopes (e.g., 40).
%
% OUTPUTS:
% feature vector: the features arranged in a struct as per desired format.

    if isempty(spectrogram_data)
        warning('Spectrogram data is empty. Returning empty features.');
        features.time_vector = [];
        features.mean = [];
        features.variance = [];
        features.skewness = [];
        features.kurtosis = [];
        features.envelopes.power_threshold_dB_below_peak = threshold_dB_below_peak;
        features.envelopes.power_threshold_value = NaN;
        features.envelopes.bottom_doppler = [];
        features.envelopes.top_doppler = [];
        features.pseudo_zernike_moments.description = 'Input spectrogram data was empty.';
        features.pseudo_zernike_moments.values = [];
        return;
    end

    [num_doppler_bins, num_time_segments] = size(spectrogram_data);

    mean_doppler = zeros(1, num_time_segments);
    variance_doppler = zeros(1, num_time_segments);
    skewness_doppler = zeros(1, num_time_segments);
    kurtosis_doppler = zeros(1, num_time_segments);

    bottom_envelope = zeros(1, num_time_segments);
    top_envelope = zeros(1, num_time_segments);

    doppler_axis = doppler_axis(:);

    % 1. Doppler Frequency Moments
    for t = 1:num_time_segments
        current_slice = spectrogram_data(:, t);
        total_intensity = sum(current_slice);

            normalized_slice = current_slice / total_intensity;

            % Mean
            current_mean = sum(doppler_axis .* normalized_slice);
            mean_doppler(t) = current_mean;

            % Variance
            current_variance = sum(((doppler_axis - current_mean).^2) .* normalized_slice);
            variance_doppler(t) = current_variance;

            if current_variance > 1e-12 % Std dev is non-zero
                std_dev = sqrt(current_variance);
                % Skewness
                skewness_doppler(t) = sum((((doppler_axis - current_mean)./std_dev).^3) .* normalized_slice);
                % Kurtosis
                kurtosis_doppler(t) = sum((((doppler_axis - current_mean)./std_dev).^4) .* normalized_slice);
            else  
                skewness_doppler(t) = 0; 
                kurtosis_doppler(t) = 0; 
            end
    end
<<<<<<< HEAD:extract_features.m
    %% 2. envelopes
=======
    
    % 2. envelopes
>>>>>>> e26fb21fd2434c91f10edeb7ff1e0321b04185d1:Attention features/extract_features.m
    % not currently used as features. finds the frequencies at RCS 16dB
    % lower than peak dB.
    % CONVERT TO LINEAR SCALE FIRST
    [torso_env_top,torso_env_bttm] = envelope_at_db(10.^(spectrogram_data/ 20),doppler_axis,16);
    % 3. Pseudo-Zernike Moments to-do
   
    % 4. torso BW - might need to be adjusted
    % the mean power concentrated in frequencies that are below 16dB of
    % peak
<<<<<<< HEAD:extract_features.m
    
        envelope_diff = abs(torso_env_top-torso_env_bttm);
        torso_BW = mean(envelope_diff,"omitnan");
=======
>>>>>>> e26fb21fd2434c91f10edeb7ff1e0321b04185d1:Attention features/extract_features.m
    
    envelope_diff = abs(torso_env_top-torso_env_bttm);
    torso_BW = mean(envelope_diff,"omitnan");
    
    % 5. total BW - might need to be adjusted
    % the mean power concentrated in frequencies that are below 36dB of
    % peak.
    % CONVERT TO LINEAR SCALE FIRST
    [MD_env_top,MD_env_btm] = envelope_at_db(10.^(spectrogram_data/ 20),doppler_axis,36);
    total_BW = mean(abs(MD_env_top-MD_env_btm),"omitnan");
     
    % 6. total BW offset
    % how much the BW is offset from mean.
    total_BW_offset = mean(MD_env_top - MD_env_btm,"omitnan");
    %% 7. torso BW offset
    torso_BW_offset = mean(torso_env_top - torso_env_bttm,"omitnan");
    % 8. limb oscillation period - TODO
    % Store features in a struct
%     features.time_vector = time_axis(:)'; % Ensure row vector

    % the means are for frequency.
    features.doppler_moments.mean = mean_doppler; % legacy
    
    features.mean = mean(mean_doppler,"omitnan");
    features.variance = mean(variance_doppler,"omitnan");
    features.skewness = mean(skewness_doppler,"omitnan");
    features.kurtosis = mean(kurtosis_doppler,"omitnan");
    
    features.torso_BW = torso_BW;
    features.total_BW = total_BW;
    
    features.total_BW_offset = total_BW_offset;
    features.total_torso_BW_offset = torso_BW_offset;
    
    % not sure where and how to use these.
    features.envelopes.bottom_doppler = torso_env_bttm;
    features.envelopes.top_doppler = torso_env_top;
    
%   features.pseudo_zernike_moments = pseudo_zernike_moments;

end
