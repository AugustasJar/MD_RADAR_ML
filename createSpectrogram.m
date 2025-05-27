function [spectrogram_res,time_axis,vel_axis] = createSpectrogram(filename)
%created from DataProcessingExample.m 
    fileID = fopen(filename, 'r');
    dataArray = textscan(fileID, '%f');
    fclose(fileID);
    radarData = dataArray{1};
    clearvars fileID dataArray ans;
    fc = radarData(1); % Center frequency
    Tsweep = radarData(2); % Sweep time in ms
    Tsweep=Tsweep/1000; %then in sec
    NTS = radarData(3); % Number of time samples per sweep
    Bw = radarData(4); % FMCW Bandwidth. For FSK, it is frequency step;
    % For CW, it is 0.
    Data = radarData(5:end); % raw data in I+j*Q format
    fs=NTS/Tsweep; % sampling frequency ADC
    record_length=length(Data)/NTS*Tsweep; % length of recording in s
    nc=record_length/Tsweep; % number of chirps

    
    Data_time=reshape(Data, [NTS nc]);
    win = ones(NTS,size(Data_time,2));
    %Part taken from Ancortek code for FFT and IIR filtering
    tmp = fftshift(fft(Data_time.*win),1);
    Data_range(1:NTS/2,:) = tmp(NTS/2+1:NTS,:);
    ns = oddnumber(size(Data_range,2))-1;
    Data_range_MTI = zeros(size(Data_range,1),ns);
    [b,a] = butter(4, 0.0075, 'high');
    [h, f1] = freqz(b, a, ns);
    for k=1:size(Data_range,1)
      Data_range_MTI(k,1:ns) = filter(b,a,Data_range(k,1:ns));
    end
    freq =(0:ns-1)*fs/(2*ns); 
    range_axis=(freq*3e8*Tsweep)/(2*Bw);
    Data_range_MTI=Data_range_MTI(2:size(Data_range_MTI,1),:);
    Data_range=Data_range(2:size(Data_range,1),:);
    
    
    bin_indl = 10;
    bin_indu = 30;

    MD.PRF=1/Tsweep;
    MD.TimeWindowLength = 200;
    MD.OverlapFactor = 0.95;
    MD.OverlapLength = round(MD.TimeWindowLength*MD.OverlapFactor);
    MD.Pad_Factor = 4;
    MD.FFTPoints = MD.Pad_Factor*MD.TimeWindowLength;
    MD.DopplerBin=MD.PRF/(MD.FFTPoints);
    MD.DopplerAxis=-MD.PRF/2:MD.DopplerBin:MD.PRF/2-MD.DopplerBin;
    MD.WholeDuration=size(Data_range_MTI,2)/MD.PRF;
    MD.NumSegments=floor((size(Data_range_MTI,2)-MD.TimeWindowLength)/floor(MD.TimeWindowLength*(1-MD.OverlapFactor)));

    Data_spec_MTI2=0;
    Data_spec2=0;
    for RBin=bin_indl:1:bin_indu
        Data_MTI_temp = fftshift(spectrogram(Data_range_MTI(RBin,:),MD.TimeWindowLength,MD.OverlapLength,MD.FFTPoints),1);
        Data_spec_MTI2=Data_spec_MTI2+abs(Data_MTI_temp);                                
        Data_temp = fftshift(spectrogram(Data_range(RBin,:),MD.TimeWindowLength,MD.OverlapLength,MD.FFTPoints),1);
        Data_spec2=Data_spec2+abs(Data_temp);
    end
    MD.TimeAxis=linspace(0,MD.WholeDuration,size(Data_spec_MTI2,2));

    Data_spec_MTI2=flipud(Data_spec_MTI2);
    
    % returns
    vel_axis = MD.DopplerAxis.*3e8/2/5.8e9;
    time_axis = MD.TimeAxis;
    spectrogram_res = Data_spec_MTI2;
end