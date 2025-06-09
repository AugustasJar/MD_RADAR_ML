function svd_features = extract_SVD_features(data, singular_vectors, N)
%EXTRACT_SVD_FEATURES Summary of this function goes here

    % data = load(fullpath);  % Assuming the file is a .mat file containing U and V matrices
    
    % U = data.U(:,1:singular_vectors);
    V = data.V(:,1:singular_vectors);
    
    % Mean(takes it along columns
    % mean_U = mean(U);
    mean_V = mean(V);
    
    % std along columns
    % sigma_U = std(U,0, 1);
    sigma_V = std(V,0, 1);
    
    % Centroid and bandwidth(in doppler Hz) of the first left singular
    % % vector
    % S = abs(U(:, 1)).^2;
    % f = data.MD.DopplerAxis;
    % freq_centroid = sum(f .* S') / sum(S);
    % freq_bandwidth = sqrt(sum((f - freq_centroid).^2 .* S') / sum(S));

    % U_peaks = [];
    % U_neg_peaks = [];
    % V_peaks = [];
    % V_neg_peaks = [];
    % for j=1:singular_vectors
    %     % Change peak-finding parameters for up to "singular_vectors" amount of
    %     % columns you want from U

        % Check out the singular values per each activity
n = 3;  % Number of right singular vectors

V_peaks_pos = zeros(1, n);  % Positive peak counts
V_peaks_neg = zeros(1, n);  % Negative peak counts

% figure(2);
for j = 1:n
    % subplot(n, 1, j);

    % === LOW PASS FILTER ===
    alpha = 0.05;
    for i = 2:length(V(:, j))
        V(i, j) = alpha * V(i, j) + (1 - alpha) * V(i-1, j);
    end

    % === Peak detection parameters ===
    if j == 1
        peak_prom     = 0.001;
        peak_dist     = 50;
        neg_peak_prom = 0.003;
        neg_peak_dist = 50;
    else
        peak_prom     = 0.01;
        peak_dist     = 20;
        neg_peak_prom = 0.02;
        neg_peak_dist = 20;
    end

    % === Detect positive peaks ===
    [~, pos_peak_locs] = findpeaks(V(:, j), ...
        'MinPeakProminence', peak_prom, ...
        'MinPeakDistance', peak_dist);
    V_peaks_pos(j) = numel(pos_peak_locs);

    % === Detect negative peaks ===
    [~, neg_peak_locs] = findpeaks(-V(:, j), ...
        'MinPeakProminence', neg_peak_prom, ...
        'MinPeakDistance', neg_peak_dist);
    V_peaks_neg(j) = numel(neg_peak_locs);




        % if j == 1
        %     peak_prom = 0.1;
        %     peak_dist = 80;
        %     neg_peak_prom = 0.0005;
        %     neg_peak_dist = 50;
        % else
        %     peak_prom = 0.01;
        %     peak_dist = 80;
        %     neg_peak_prom = 0.05;
        %     neg_peak_dist = 5;
        % end
        % 
        %     % Peak detection (positive)
        %     [~, peak_locs_idx] = findpeaks(U(:, j), ...
        %         'MinPeakProminence', peak_prom, ...
        %         'MinPeakDistance', peak_dist);
        %     U_peaks = [U_peaks, length(peak_locs_idx)];
        % 
        %     % Peak detection (negative)
        %     [~, neg_peak_locs_idx] = findpeaks(-U(:, j), ...
        %         'MinPeakProminence', neg_peak_prom, ...
        %         'MinPeakDistance', neg_peak_dist);
        %     U_neg_peaks = [U_neg_peaks, length(neg_peak_locs_idx)];
        % 
        % if j == 1
        %     peak_prom = 0.001;
        %     peak_dist = 50;
        %     neg_peak_prom = 0.003;
        %     neg_peak_dist = 50;
        % else
        %     peak_prom = 0.01;
        %     peak_dist = 50;
        %     neg_peak_prom = 0.02;
        %     neg_peak_dist = 50;
        % end
        % 
        % % Peak detection (positive)
        % [~, peak_locs_idx] = findpeaks(abs(V(:, j)), ...
        %     'MinPeakProminence', peak_prom, ...
        %     'MinPeakDistance', peak_dist);
        %  V_peaks = [V_peaks, length(peak_locs_idx)];
    
        % Peak detection (negative)
        % [~, neg_peak_locs_idx] = findpeaks(-V(:, j), ...
        %     'MinPeakProminence', neg_peak_prom, ...
        %     'MinPeakDistance', neg_peak_dist);
        %  V_neg_peaks = [V_neg_peaks, length(neg_peak_locs_idx)];
    end
    % disp(length(U_peaks));
    % disp(length(V_peaks));
    % disp(length(U_neg_peaks));
    % disp(length(V_neg_peaks));
    % 
    % disp(length(mean_U(1:singular_vectors)));
    % disp(length(mean_V(1:singular_vectors)));
    % disp(length(sigma_U(1:singular_vectors)));
    % disp(length(sigma_V(1:singular_vectors)));

    % disp(length(freq_centroid));
    % disp(length(freq_bandwidth));



    % svd_features = [mean_U(1:singular_vectors), sigma_U(1:singular_vectors), ...
    %     mean_V(1:singular_vectors), sigma_V(1:singular_vectors), ...
    %     freq_centroid, freq_bandwidth, ...
    %     U_peaks, U_neg_peaks, V_peaks, V_neg_peaks];

    svd_features = [mean_V(1:singular_vectors), sigma_V(1:singular_vectors), V_peaks_pos, V_peaks_neg];
    % Repeat for each time segment
    % svd_features = repmat(svd_features,1,N);
    % disp(size(svd_features));

end
