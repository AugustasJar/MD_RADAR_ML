function aug = dat_aug(Data_spec_MTI2, N)
    if nargin < 2, N; end
    if ~isreal(Data_spec_MTI2)
        Data_spec_MTI2 = abs(Data_spec_MTI2);
    end

    aug.orig = Data_spec_MTI2;

    % === Time Warp variants ===
    for i = 1:N
        scaleFactor = 0.8 + 0.4 * rand();
        temp = imresize(Data_spec_MTI2, [size(Data_spec_MTI2,1), round(size(Data_spec_MTI2,2) * scaleFactor)]);
        if size(temp, 2) >= size(Data_spec_MTI2,2)
            aug.timeWarp{i} = temp(:, 1:size(Data_spec_MTI2,2));
        else
            padLength = size(Data_spec_MTI2,2) - size(temp,2);
            aug.timeWarp{i} = padarray(temp, [0 padLength], 'replicate', 'post');
        end
    end

    % === Frequency Warp variants ===
    for i = 1:N
        shift = randi([-5, 5]);
        aug.freqWarp{i} = circshift(Data_spec_MTI2, [shift, 0]);
    end

    % === Gaussian Blur variants ===
    for i = 1:N
        kSize = 3 + 2*randi([0 2]);
        sigma = 0.5 + 1.5*rand();
        kernel = fspecial('gaussian', [kSize kSize], sigma);
        aug.blur{i} = imfilter(Data_spec_MTI2, kernel, 'same');
    end

    % === Noise variants ===
    for i = 1:N
        level = 0.005 + 0.02*rand();
        aug.noise{i} = Data_spec_MTI2 + level * randn(size(Data_spec_MTI2));
    end
    
end
