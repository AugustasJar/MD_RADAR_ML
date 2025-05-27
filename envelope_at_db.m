%function to generate an envelope above some dB value from the maximum.
% it is used as a helper function to find features.
function [top,bottom] = envelope_at_db(spectrogram_data,axis,threshold)
    %% 2. Top and Bottom Envelopes
        [num_doppler_bins, num_time_segments] = size(spectrogram_data);
        top = zeros(1, num_time_segments);
        bottom = zeros(1, num_time_segments);
    
        global_peak_power = max(spectrogram_data(:));

        power_threshold_value = global_peak_power * 10^(-threshold / 20);

        for t = 1:num_time_segments
            current_slice = spectrogram_data(:, t);
            indices_above_threshold = find(current_slice > power_threshold_value);

            if ~isempty(indices_above_threshold)
                top(t) = axis(min(indices_above_threshold));
                bottom(t) = axis(max(indices_above_threshold));
            end
        end
end