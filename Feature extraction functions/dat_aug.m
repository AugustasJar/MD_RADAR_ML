% function aug = dat_aug(Data_spec_MTI2, N)
%     if nargin < 2, N; end
%     if ~isreal(Data_spec_MTI2)
%         Data_spec_MTI2 = abs(Data_spec_MTI2);
%     end
% 
%     aug.orig = Data_spec_MTI2;
% 
%     % === Time Warp variants ===
%     for i = 1:N
%         scaleFactor = 0.8 + 0.4 * rand();
%         temp = imresize(Data_spec_MTI2, [size(Data_spec_MTI2,1), round(size(Data_spec_MTI2,2) * scaleFactor)]);
%         if size(temp, 2) >= size(Data_spec_MTI2,2)
%             aug.timeWarp{i} = temp(:, 1:size(Data_spec_MTI2,2));
%         else
%             padLength = size(Data_spec_MTI2,2) - size(temp,2);
%             aug.timeWarp{i} = padarray(temp, [0 padLength], 'replicate', 'post');
%         end
%     end
% 
%     % === Frequency Warp variants ===
%     for i = 1:N
%         shift = randi([-5, 5]);
%         aug.freqWarp{i} = circshift(Data_spec_MTI2, [shift, 0]);
%     end
% 
%     % === Gaussian Blur variants ===
%     for i = 1:N
%         kSize = 3 + 2*randi([0 2]);
%         sigma = 0.5 + 1.5*rand();
%         kernel = fspecial('gaussian', [kSize kSize], sigma);
%         aug.blur{i} = imfilter(Data_spec_MTI2, kernel, 'same');
%     end
% 
%     % === Noise variants ===
%     for i = 1:N
%         level = 0.005 + 0.02*rand();
%         aug.noise{i} = Data_spec_MTI2 + level * randn(size(Data_spec_MTI2));
%     end
% 
% end

function aug = dat_aug(Data_spec_MTI2, N_aug_rep)
    % RadarSpecAugment-based data augmentation for spectrograms
    % Input: Data_spec_MTI2 (spectrogram, complex or real)
    % Output: aug (struct with augmented spectrograms in cell arrays)

    % Convert to magnitude if complex
    if ~isreal(Data_spec_MTI2)
        Data_spec_MTI2 = abs(Data_spec_MTI2);
    end

    [nFreq, nTime] = size(Data_spec_MTI2);
    aug.orig = Data_spec_MTI2;

    %% === 1. Time Shift ===
    aug.timeShift = cell(1, N_aug_rep);
    for j = 1:N_aug_rep
        R1 = 150;
        D1 = randsample([-1, 1], 1); % shift left or right
        r1 = randi([0, R1]);
        
        if D1 == 1
            shifted = Data_spec_MTI2(:, 1:(end - r1));
            aug.timeShift{j} = padarray(shifted, [0 r1], 0, 'post');
        else
            shifted = Data_spec_MTI2(:, (1 + r1):end);
            aug.timeShift{j} = padarray(shifted, [0 r1], 0, 'pre');
        end
    end

    %% === 2. Frequency Disturbance ===
    aug.freqDisturb = cell(1, N_aug_rep);
    for j = 1:N_aug_rep
        disturbed = Data_spec_MTI2;
        R2 = 10;
        R1 = 5;
        r2 = randi([R1, R2]);
        p = 0.5;
        N = 10000;
        blob_size = 8;

        [~, idx] = maxk(Data_spec_MTI2(:), N);
        [f_idx, t_idx] = ind2sub(size(Data_spec_MTI2), idx);

        [X, Y] = meshgrid(-blob_size:blob_size, -blob_size:blob_size);
        sigma = blob_size / 2;
        gaussian_blob = exp(-(X.^2 + Y.^2) / (2 * sigma^2));
        gaussian_blob = gaussian_blob / max(gaussian_blob(:));

        for i = 1:N
            if rand() < p
                f0 = f_idx(i);
                t0 = t_idx(i);
                df = randsample([-r2, r2], 1);
                target_f = f0 + df;

                if target_f - blob_size >= 1 && target_f + blob_size <= nFreq && ...
                   t0 - blob_size >= 1 && t0 + blob_size <= nTime

                    blob_scaled = gaussian_blob * (Data_spec_MTI2(f0, t0) * 0.5);
                    disturbed(target_f - blob_size : target_f + blob_size, ...
                              t0 - blob_size : t0 + blob_size) = ...
                        disturbed(target_f - blob_size : target_f + blob_size, ...
                                  t0 - blob_size : t0 + blob_size) + blob_scaled;
                end
            end
        end
        aug.freqDisturb{j} = disturbed;
    end

    %% === 3. Frequency Shift ===
    % decided that this doesnt really make physiscal sense

    % aug.freqShift = cell(1, N_aug_rep);
    % for j = 1:N_aug_rep
    %     shifted = zeros(size(Data_spec_MTI2));
    %     R3 = 70;
    %     D3 = randsample([-1, 1], 1);
    %     r3 = randi([0, R3]);
    % 
    %     for t = 1:nTime
    %         for f = 1:nFreq
    %             new_f = f + D3 * r3;
    %             if new_f >= 1 && new_f <= nFreq
    %                 shifted(new_f, t) = shifted(new_f, t) + Data_spec_MTI2(f, t);
    %             elseif new_f < 1 && D3 == -1
    %                 shifted(1, t) = shifted(1, t) + Data_spec_MTI2(f, t);
    %             elseif new_f > nFreq && D3 == 1
    %                 shifted(nFreq, t) = shifted(nFreq, t) + Data_spec_MTI2(f, t);
    %             end
    %         end
    %     end
    %     aug.freqShift{j} = shifted;
    % end
end
