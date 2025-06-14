% In this script one can test the SVD spectrogram creation to see how much
% to truncate before computing an SVD version of the whole dataset
% addpath('generate_mat_datasets');
% addpath('../Feature exctraction functions');
addpath('generate_mat_datasets');

[filename,pathname] = uigetfile('*.dat');
fullpath = fullfile(pathname, filename);

% Already returns in dB scale
[spectrogram_example, MD] = createSpectrogram_optimized(fullpath);
%% Apply on the dB version!
[U, S, V] = svd(spectrogram_example);
%
% Check out the singular values per each activity
n = 3;  % Number of right singular vectors

V_peaks_pos = zeros(1, n);  % Positive peak counts
V_peaks_neg = zeros(1, n);  % Negative peak counts

figure(2);
for j = 1:n
    subplot(n, 1, j);

    % === LOW PASS FILTER ===
    alpha = 0.05;
    for i = 2:length(V(:, j))
        V(i, j) = alpha * V(i, j) + (1 - alpha) * V(i-1, j);
    end

    plot(MD.TimeAxis, V(:, j), 'r'); hold on;

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

    % === Plot peaks ===
    if ~isempty(pos_peak_locs)
        plot(MD.TimeAxis(pos_peak_locs), V(pos_peak_locs, j), 'k*', 'DisplayName', 'Positive Peaks');
    end
    if ~isempty(neg_peak_locs)
        plot(MD.TimeAxis(neg_peak_locs), V(neg_peak_locs, j), 'bo', 'DisplayName', 'Negative Peaks');
    end

    title(sprintf('Right Singular Vector %d — %d+ / %d- Peaks', ...
        j, V_peaks_pos(j), V_peaks_neg(j)));
    xlabel('Time (s)');
    ylabel('Value');
    legend('show');
    hold off;
end

sgtitle(filename, 'Interpreter', 'none');

% Optional: combine total peak counts
V_peaks_total = V_peaks_pos + V_peaks_neg;

%% Plot the spectrogram

figure(1)
colormap(jet)
imagesc(MD.TimeAxis,MD.VelocityAxis,spectrogram_example); colormap('jet'); axis xy
ylim([-6 6]); colorbar
colormap; %xlim([1 9])
clim = get(gca,'CLim');
set(gca, 'CLim', clim(2)+[-40,0]);
xlabel('Time[s]', 'FontSize',16);
ylabel('Velocity [m/s]','FontSize',16)
set(gca, 'FontSize',16)
title(filename)

%% Try the SVD of the spectrogram

singular_value_cutoff = 5;
figure(2);  % Create a new figure
% % Subplot 1
% subplot(2,2,1);  % 2 rows, 2 columns, position 1
% plot(MD.VelocityAxis,U(:,1));
% title('First left singular vector');
% xlabel('Velocity (m/s)');
% ylabel('Value');
% 
% % Subplot 2
% subplot(2,2,2);  % position 2
% plot(MD.TimeAxis, V(:,1));
% title('First right singular vector');
% xlabel('Time (s)');
% ylabel('Value');
% 
% % Subplot 3
% subplot(2,2,3);  % position 3
plot(diag(S(1:singular_value_cutoff, 1:singular_value_cutoff)));
% plot(diag(S));
title('Singular values');
xlabel('Component index k');
ylabel('Singular value');

% % Subplot 4
% subplot(2,2,4);  % position 4
% colormap(jet)
% imagesc(MD.TimeAxis,MD.VelocityAxis,spectrogram_example); colormap('jet'); axis xy
% ylim([-6 6]); colorbar
% colormap; %xlim([1 9])
% clim = get(gca,'CLim');
% set(gca, 'CLim', clim(2)+[-40,0]);
% xlabel('Time[s]', 'FontSize',16);
% ylabel('Velocity [m/s]','FontSize',16)
% set(gca, 'FontSize',16)
title(filename)

%% Compare denoised reconstruction to original full data SVD

singular_value_cutoff = 7;
spectrogram_denoised = U(:,1:singular_value_cutoff)*S(1:singular_value_cutoff, 1:singular_value_cutoff)*V(:,1:singular_value_cutoff)';

figure(2)
subplot(1,2,1);
colormap(jet)
imagesc(MD.TimeAxis,MD.VelocityAxis,spectrogram_example); colormap('jet'); axis xy
ylim([-6 6]); colorbar
colormap; %xlim([1 9])
clim = get(gca,'CLim');
set(gca, 'CLim', clim(2)+[-40,0]);
xlabel('Time[s]', 'FontSize',16);
ylabel('Velocity [m/s]','FontSize',16)
set(gca, 'FontSize',16)
title(filename)

subplot(1,2,2);
colormap(jet)
imagesc(MD.TimeAxis,MD.VelocityAxis,spectrogram_denoised); colormap('jet'); axis xy
ylim([-6 6]); colorbar
colormap; %xlim([1 9])
clim = get(gca,'CLim');
set(gca, 'CLim', clim(2)+[-40,0]);
xlabel('Time[s]', 'FontSize',16);
ylabel('Velocity [m/s]','FontSize',16)
set(gca, 'FontSize',16)
title("Reconstruction of spectrogram")

%% Quality of the truncated reconstruction

figure(4);  % Create a new figure
% Subplot 1
subplot(2,2,1);  % 2 rows, 2 columns, position 1
plot(MD.VelocityAxis,U(:,1));
title('First left singular vector');
xlabel('Velocity (m/s)');
ylabel('Value');

% Subplot 2
subplot(2,2,2);  % position 2
plot(MD.TimeAxis, V(:,1));
title('First right singular vector');
xlabel('Time (s)');
ylabel('Value');

% Subplot 3
subplot(2,2,3);  % position 3
plot(MD.VelocityAxis,U(:,2));
title('Second right singular vector');
xlabel('Index k');
ylabel('Singular value');

% Subplot 4
subplot(2,2,4);  % position 4
colormap(jet)
plot(MD.TimeAxis, V(:,2));
% ylim([-6 6]); colorbar
% colormap; %xlim([1 9])
% clim = get(gca,'CLim');
% set(gca, 'CLim', clim(2)+[-40,0]);
% xlabel('Time[s]', 'FontSize',16);
% ylabel('Velocity [m/s]','FontSize',16)
% set(gca, 'FontSize',16)
title(filename)

%%
figure(5);  % Create a new figure
% Subplot 1
subplot(2,2,1);  % 2 rows, 2 columns, position 1
plot(MD.VelocityAxis,U(:,1));
title('First left singular vector');
xlabel('Velocity (m/s)');
ylabel('Value');

% Subplot 2
subplot(2,2,2);  % position 2
plot(MD.TimeAxis, V(:,1));
title('First right singular vector');
xlabel('Time (s)');
ylabel('Value');

% Subplot 3
subplot(2,2,3);  % position 3
plot(diag(S(1:singular_value_cutoff, 1:singular_value_cutoff)));
title('Singular values');
xlabel('Index k');
ylabel('Singular value');

% Subplot 4
subplot(2,2,4);  % position 4
colormap(jet)
imagesc(MD.TimeAxis,MD.VelocityAxis,spectrogram_denoised); colormap('jet'); axis xy
ylim([-6 6]); colorbar
colormap; %xlim([1 9])
clim = get(gca,'CLim');
set(gca, 'CLim', clim(2)+[-40,0]);
xlabel('Time[s]', 'FontSize',16);
ylabel('Velocity [m/s]','FontSize',16)
set(gca, 'FontSize',16)
title(filename)
