function features = extract_features(spectrogram_data, doppler_axis)
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

% OUTPUTS:
% feature vector: the features arranged in a struct as per desired format.

    if isempty(spectrogram_data)
        warning('Spectrogram data is empty. Returning empty features.');
        features.time_vector = [];
        features.mean = [];
        features.variance = [];
        features.skewness = [];

        features.kurtosis = [];
        features.torso_BW = [];
        features.limbs_BW = [];

        features.torso_BW_max = [];
        features.limbs_BW_max = [];
        
        features.pseudo_zernike_moments.description = 'Input spectrogram data was empty.';
        features.pseudo_zernike_moments.values = [];
        return;

        end

    [~, num_time_segments] = size(spectrogram_data);

    mean_doppler = zeros(1, num_time_segments);
    variance_doppler = zeros(1, num_time_segments);
    skewness_doppler = zeros(1, num_time_segments);
    kurtosis_doppler = zeros(1, num_time_segments);

    
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

    threshold_dB_T = 25;
    % CONVERT TO LINEAR SCALE FIRST
    [torso_env_top,torso_env_btm] = envelope_at_db(10.^(spectrogram_data/ 20),doppler_axis,threshold_dB_T);
    envelope_diff = abs(torso_env_top-torso_env_btm);
    torso_BW = mean(envelope_diff,"omitnan");
    
    % 5. BW of limbs swinging: the mean power concentrated in frequencies that are below 47dB of
    % peak.

    % Convert to linear scale first!
    threshold_dB_L = 47;
    [Limbs_env_top,Limbs_env_btm] = envelope_at_db(10.^(spectrogram_data/ 20),doppler_axis,threshold_dB_L);
    limbs_unacc_BW = mean(abs(Limbs_env_top-Limbs_env_btm),"omitnan");
    limbs_acc_BW = limbs_unacc_BW - torso_BW;

    % 6. torso BW maximum: The 2% highest maximum bandwidth, to prevent anomalies in the data. 
    torso_BW_Max = max(torso_env_top - torso_env_btm);
    torso_BW_Max_robust = prctile(torso_BW_Max,98);

    % 7. limbs BW maximum
    limbs_BW_max = max(Limbs_env_top - Limbs_env_btm);
    limbs_BW_max_robust = prctile(limbs_BW_max,98);
    limbs_acc_max_robust = limbs_BW_max_robust- torso_BW_Max_robust;


% the means are for frequency.
    features.doppler_moments.mean = mean_doppler; % legacy
    
    features.mean = mean(mean_doppler,"omitnan");
    features.variance = mean(variance_doppler,"omitnan");
    features.skewness = mean(skewness_doppler,"omitnan");
    features.kurtosis = mean(kurtosis_doppler,"omitnan");
    
    features.torso_BW = torso_BW;
    features.limbs_BW = limbs_acc_BW;
    
    features.torso_BW_max = torso_BW_Max_robust;
    features.limbs_BW_max = limbs_acc_max_robust;
    % Cadence Velocity Diagram (CVD): Implemented in generate_feature_vectors.m


%   features.pseudo_zernike_moments = pseudo_zernike_moments;


end


%% Old/unused stuff

    % CONVERT TO LINEAR SCALE FIRST
    % [MD_env_top,MD_env_btm] = envelope_at_db(10.^(spectrogram_data/ 20),doppler_axis,36);
    % total_BW = mean(abs(MD_env_top-MD_env_btm),"omitnan");


    % 6. total BW offset: how much the BW is offset from mean.
    % total_BW_offset = mean(MD_env_top - MD_env_btm,"omitnan");
    % 7. torso BW offset
    % torso_BW_offset = mean(torso_env_top - torso_env_bttm,"omitnan");
    
    % 8. limb oscillation period - TODO
    % Store features in a struct
%     features.time_vector = time_axis(:)'; % Ensure row vector

   

    
    % 2. envelopes: Finds the frequencies at RCS 16dB lower than peak dB.
    % 3. Pseudo-Zernike Moments to-do
   
    % 4. torso BW: the mean power concentrated in frequencies that are below 16dB of
    % peak