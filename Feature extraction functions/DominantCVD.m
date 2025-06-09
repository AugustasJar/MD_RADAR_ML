function [dominant_cadence] = DominantCVD(spectrogram, MD)
% Extracts Cadence-Velocity Diagram (CVD) from a given spectrogram
%
% Input:
%   spectrogram_data: matrix of size [time x velocity] (e.g. abs(STFT))
%   time_axis: vector in seconds (length = number of time samples)
%
% Output:
%   Dominant Cadence peak, a single value

% FFT along time axis (rows)
CVD = abs(fftshift(fft(spectrogram, [], 1), 1));  % result = [time_fft x velocity]
% === Normalize CVD matrix (each value between 0 and 1) ===
CVD = abs(CVD);

% Cadence axis
N_time = length(MD.TimeAxis);
cadence_axis = linspace(-MD.PRF/2, MD.PRF/2, N_time);  % in Hz

% Original (normalized) cadence profile
cvd_profile = mean(CVD, 2);

% Filter cadence axis: only allow |cadence| > f Hz
valid_mask = abs(cadence_axis) > 0.75;
cadence_axis_filt = cadence_axis(valid_mask);
cvd_profile_filt = cvd_profile(valid_mask);
if isempty(cvd_profile_filt)
    dominant_cadence = 0;  % or NaN or fallback
    return;
end

% First try: strict threshold
[peaks, locs] = findpeaks(cvd_profile_filt, cadence_axis_filt, 'MinPeakProminence', 0.1);

% Fallback 1: try lower threshold
if isempty(peaks)
    [peaks, locs] = findpeaks(cvd_profile_filt, cadence_axis_filt, 'MinPeakProminence', 0.05);
end

% Fallback 2: no prominence requirement, just take the maximum
if isempty(peaks)
    [~, idx_max] = max(cvd_profile_filt);
    if ~isempty(idx_max)
        dominant_cadence = cadence_axis_filt(idx_max);
    else
        dominant_cadence = 0;  % or small fallback like 0 Hz
    end
else
    [~, idx_max] = max(peaks);
    dominant_cadence = locs(idx_max);
end
