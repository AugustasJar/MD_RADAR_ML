addpath('generate_mat_datasets');

addpath('Attention features');

[filename,pathname] = uigetfile('*.dat');
fullpath = fullfile(pathname, filename);
%%
[spectrogram_example, MD] = createSpectrogram_optimized(fullpath);

% [spectrogram_example, MD] = create_spectrogram_wrong(fullpath);

%% Plot the spectrogram

figure(1)
colormap(jet)
% imagesc(MD.TimeAxis,MD.DopplerAxis.*3e8/2/5.8e9,20*log10(abs(spectrogram_example))); colormap('jet'); axis xy
% imagesc(MD.TimeAxis,MD.VelocityAxis,spectrogram_example); colormap('jet'); axis xy
imagesc(MD.TimeAxis,MD.VelocityAxis, 20*log10(abs(spectrogram_example))); colormap('jet'); axis xy
ylim([-6 6]); colorbar
colormap; %xlim([1 9])
clim = get(gca,'CLim');
set(gca, 'CLim', clim(2)+[-40,0]);
xlabel('Time[s]', 'FontSize',16);
ylabel('Velocity [m/s]','FontSize',16)
set(gca, 'FontSize',16)
title(filename)

%% Try the SVD of the spectrogram

% Apply on the dB version!
[U, S, V] = svd(20*log10(abs(spectrogram_example)));
singular_value_cutoff = 25;
figure(2);  % Create a new figure
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
imagesc(MD.TimeAxis,MD.VelocityAxis,spectrogram_example); colormap('jet'); axis xy
ylim([-6 6]); colorbar
colormap; %xlim([1 9])
clim = get(gca,'CLim');
set(gca, 'CLim', clim(2)+[-40,0]);
xlabel('Time[s]', 'FontSize',16);
ylabel('Velocity [m/s]','FontSize',16)
set(gca, 'FontSize',16)
title(filename)

%% Compare denoised reconstruction to original full data SVD

singular_value_cutoff = 5;
spectrogram_denoised = U(:,1:singular_value_cutoff)*S(1:singular_value_cutoff, 1:singular_value_cutoff)*V(:,1:singular_value_cutoff)';

figure(2)
subplot(1,2,1);
colormap(jet)
imagesc(MD.TimeAxis,MD.VelocityAxis,20*log10(abs(spectrogram_example))); colormap('jet'); axis xy
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
imagesc(MD.TimeAxis,MD.DopplerAxis.*3e8/2/5.8e9,spectrogram_denoised); colormap('jet'); axis xy
ylim([-6 6]); colorbar
colormap; %xlim([1 9])
clim = get(gca,'CLim');
set(gca, 'CLim', clim(2)+[-40,0]);
xlabel('Time[s]', 'FontSize',16);
ylabel('Velocity [m/s]','FontSize',16)
set(gca, 'FontSize',16)
title(filename)

%% Check out the envelopes

