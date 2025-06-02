function [spectrogram_res, time_axis, vel_axis] = createSpectrogram_optimized(filename)
%createSpectrogram_optimized - Optimized version for speed by Gemini 2.5
%Pro
%   Detailed explanation of changes:
%   1. Removed unused outputs [h, f1] from freqz.
%   2. Vectorized MTI filtering loop.
%   3. Pre-allocated Data_spec_MTI2.
%   4. Removed calculation of Data_spec2 and Data_temp as they were not used.
%   5. Used fc variable in vel_axis calculation for robustness.
%   6. Added comments regarding potential further optimizations (win, range_axis).

    fileID = fopen(filename, 'r');
    if fileID == -1
        error('Could not open file: %s', filename);
    end
    dataArray = textscan(fileID, '%f');
    fclose(fileID);
    radarData = dataArray{1};
    clearvars dataArray; % fileID is already closed, ans is minor

    % Extract parameters
    fc = radarData(1); % Center frequency
    Tsweep = radarData(2)/1000; % Sweep time in sec (original was in ms)
    NTS = radarData(3); % Number of time samples per sweep
    Bw = radarData(4); % FMCW Bandwidth
    Data = radarData(5:end); % Raw data in I+j*Q format

    % Basic calculations
    fs = NTS / Tsweep; % Sampling frequency ADC
    % record_length = length(Data) / NTS * Tsweep; % Length of recording in s (not directly used later, can be removed if nc is calculated differently)
    nc = length(Data) / NTS; % Number of chirps, simpler calculation

    Data_time = reshape(Data, [NTS, nc]);

    % Windowing (win is ones, so Data_time.*win is Data_time.
    % If 'win' can be other windows, keep it. If always ones, consider removing '.*win')
    win = ones(NTS, size(Data_time,2));
    tmp = fftshift(fft(Data_time .* win), 1);

    % Select positive frequency components
    Data_range = tmp(NTS/2 + 1 : NTS, :);
    % Note: Original code had Data_range(1:NTS/2,:), assuming NTS/2 rows.
    % If NTS is odd, NTS/2 is not integer. fft output length is NTS.
    % tmp(NTS/2+1:NTS,:) takes roughly the second half. For even NTS, this is NTS/2 rows.
    % For odd NTS, e.g. NTS=5, NTS/2+1 = 3.5, this will error.
    % Assuming NTS is always even as is common for FFTs.
    % If NTS can be odd, use floor(NTS/2)+1:NTS or ceil(NTS/2)+1:NTS depending on needs.
    % For simplicity, assuming NTS is even based on NTS/2 usage.

    % MTI Filter (High-pass to remove static clutter)
    % ns = oddnumber(size(Data_range,2))-1;
    % Assuming 'oddnumber' is a user-defined function.
    % size(Data_range,2) is 'nc'. This line makes 'ns' an even number <= nc-1.
    % If 'oddnumber' is not available or its behavior is simple (e.g., make odd then subtract 1),
    % it could be: if rem(nc,2)==1, ns = nc-1; else ns = nc-2; end; or similar
    % For this optimization, we assume 'oddnumber' exists and is correct.
    if exist('oddnumber', 'file') ~= 2 && exist('oddnumber', 'var') ~= 1
        warning('The function "oddnumber" is not found. Using a placeholder logic for "ns". This might affect results.');
        % Placeholder: ensure ns is even and less than nc.
        % This is a guess; the actual behavior of 'oddnumber' is unknown.
        if rem(nc, 2) == 1 % nc is odd
            ns = nc - 1;
        else % nc is even
            if nc > 1
                ns = nc - 2; % or nc, depending on what oddnumber(even)-1 means
            else
                ns = 0; % handle nc=0 or nc=1 if they can occur
            end
        end
        if ns < 0, ns = 0; end % ensure ns is not negative
    else
        ns = oddnumber(size(Data_range,2)) - 1;
    end


    if ns <= 0 % If ns is zero or negative, cannot proceed with filtering/spectrogram
        warning('Calculated "ns" (%d) is too small. Skipping processing for file: %s', ns, filename);
        spectrogram_res = [];
        time_axis = [];
        vel_axis = [];
        return;
    end

    [b, a] = butter(4, 0.0075, 'high'); % Butterworth filter coefficients
    % [h, f1] = freqz(b, a, ns); % h and f1 were unused, removed.

    % Apply MTI filter (vectorized)
    % Ensure Data_range has enough columns (ns)
    if size(Data_range,2) < ns
       warning('Number of chirps nc (%d) is less than calculated ns (%d). Adjusting ns to %d.', size(Data_range,2), ns, size(Data_range,2));
       ns = size(Data_range,2);
       if ns == 0
            spectrogram_res = []; time_axis = []; vel_axis = []; return;
       end
    end
    
    % Preallocate Data_range_MTI with the correct number of columns 'ns'
    Data_range_MTI = zeros(size(Data_range,1), ns); 
    % Apply filter row-wise. filter operates on columns by default.
    % To filter rows, we can transpose, filter, then transpose back,
    % or use filter(b,a,X,[],2) if X's rows are to be filtered.
    % Original code filtered Data_range(k, 1:ns).
    Data_range_MTI = filter(b, a, Data_range(:, 1:ns), [], 2);


    % Frequency and Range Axis (range_axis is not returned, can be removed if not needed)
    % freq = (0:ns-1)*fs/(2*ns); % Not directly used in outputs
    % range_axis = (freq*3e8*Tsweep)/(2*Bw); % Not returned

    % Remove first bin (DC or near-DC component after FFT)
    % Ensure there's more than one row to remove the first.
    if size(Data_range_MTI,1) > 1
        Data_range_MTI = Data_range_MTI(2:end, :);
    end
    if size(Data_range,1) > 1
        Data_range = Data_range(2:end, :); % Data_range is used if Data_spec2 was needed
    end
    
    % If after removing the first row, Data_range_MTI becomes empty in rows
    if isempty(Data_range_MTI) || size(Data_range_MTI,1) == 0
        warning('Data_range_MTI is empty after removing the first row. Skipping spectrogram for file: %s', filename);
        spectrogram_res = [];
        time_axis = [];
        vel_axis = [];
        return;
    end


    % Spectrogram Parameters
    bin_indl = 10; % Lower bin index for range integration
    bin_indu = 30; % Upper bin index for range integration
    
    % Ensure bin_indu does not exceed the number of rows in Data_range_MTI
    if bin_indu > size(Data_range_MTI,1)
        bin_indu = size(Data_range_MTI,1);
    end
    if bin_indl > bin_indu % if lower bound is now greater (e.g. after adjustment or few rows)
        warning('Range bin indices (bin_indl=%d, bin_indu=%d) are invalid after adjustments for file: %s. Skipping spectrogram.',bin_indl, bin_indu, filename);
        spectrogram_res = []; time_axis = []; vel_axis = []; return;
    end


    MD.PRF = 1 / Tsweep;
    MD.TimeWindowLength = 200; % Samples for STFT window
    MD.OverlapFactor = 0.95;
    MD.OverlapLength = round(MD.TimeWindowLength * MD.OverlapFactor);
    MD.Pad_Factor = 4; % Padding factor for FFT
    MD.FFTPoints = MD.Pad_Factor * MD.TimeWindowLength;
    MD.DopplerBin = MD.PRF / MD.FFTPoints;
    MD.DopplerAxis = (-MD.PRF/2 : MD.DopplerBin : MD.PRF/2 - MD.DopplerBin);

    % Check if signal length `ns` is sufficient for at least one window
    if ns < MD.TimeWindowLength
        warning('Signal length ns (%d) is shorter than TimeWindowLength (%d) for file: %s. Skipping spectrogram.', ns, MD.TimeWindowLength, filename);
        spectrogram_res = [];
        time_axis = [];
        vel_axis = [];
        return;
    end
    
    MD.NumSegments = floor((ns - MD.OverlapLength) / (MD.TimeWindowLength - MD.OverlapLength));
    if MD.NumSegments <= 0
        warning('Number of segments for spectrogram is zero or negative for file: %s. Skipping.',filename);
        spectrogram_res = []; time_axis = []; vel_axis = []; return;
    end
    
    MD.WholeDuration = size(Data_range_MTI, 2) / MD.PRF; % Duration based on 'ns' samples

    % Pre-allocate for accumulated spectrogram
    % Size of spectrogram output: MD.FFTPoints rows, MD.NumSegments columns
    Data_spec_MTI2 = zeros(MD.FFTPoints, MD.NumSegments);

    % Calculate Spectrogram by integrating selected range bins
    for RBin = bin_indl : 1 : bin_indu
        % Ensure RBin is a valid index for Data_range_MTI's first dimension
        if RBin > 0 && RBin <= size(Data_range_MTI,1)
            % Spectrogram of the current range bin's time series
            % Data_range_MTI(RBin,:) has length 'ns'
            temp_spec = spectrogram(Data_range_MTI(RBin,:), MD.TimeWindowLength, MD.OverlapLength, MD.FFTPoints);
            Data_MTI_temp = fftshift(temp_spec, 1);
            Data_spec_MTI2 = Data_spec_MTI2 + abs(Data_MTI_temp);
        else
            warning('RBin index %d is out of bounds for Data_range_MTI with %d rows. Skipping this RBin.', RBin, size(Data_range_MTI,1));
        end
    end
    
    % Data_spec2 and related calculations were removed as Data_spec2 was not returned.

    MD.TimeAxis = linspace(0, MD.WholeDuration, size(Data_spec_MTI2, 2)); % Time axis for spectrogram

    Data_spec_MTI2 = flipud(Data_spec_MTI2); % Flip to have low velocities at bottom typically

    % Outputs
    % Use fc (center frequency from input) for vel_axis calculation
    if fc == 0 % Avoid division by zero if fc is not set or is zero
        warning('Center frequency fc is 0. Velocity axis cannot be computed correctly.');
        vel_axis = MD.DopplerAxis .* NaN; % Or handle error appropriately
    else
        vel_axis = MD.DopplerAxis .* (3e8 / (2 * fc));
    end
    time_axis = MD.TimeAxis;
    spectrogram_res = Data_spec_MTI2;

end