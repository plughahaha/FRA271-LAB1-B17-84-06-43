clear; clc; close all;

basePath = 'C:\RMX_V2\sensor_data\labpo';

% ดึงเฉพาะโฟลเดอร์ Slide/Linear Potentiometer (เช่น potenslideA, potenslideB, potenliA ฯลฯ)
dirList = dir(basePath);
dirList = dirList([dirList.isdir] & ~startsWith({dirList.name}, '.'));

validFolders = {};
for k = 1:length(dirList)
    name = dirList(k).name;
    if startsWith(name, 'potenslide', 'IgnoreCase', true) || startsWith(name, 'potenli', 'IgnoreCase', true)
        validFolders{end+1} = name; %#ok<AGROW>
    end
end

if isempty(validFolders)
    error('ไม่พบโฟลเดอร์ potenslide หรือ potenli ใน %s ครับ', basePath);
end

for d = 1:length(validFolders)
    folderName = validFolders{d};
    potPath    = fullfile(basePath, folderName);
    
    % ดึงระยะสเกล A ที่มีจริงในโฟลเดอร์ย่อยอัตโนมัติ (เช่น A0, A10, A20 ... A50)
    aFolders = dir(fullfile(potPath, 'A*'));
    aFolders = aFolders([aFolders.isdir]);
    
    scales = [];
    for k = 1:length(aFolders)
        val = sscanf(aFolders(k).name, 'A%d');
        if ~isempty(val)
            scales(end+1) = val; %#ok<AGROW>
        end
    end
    scales = sort(unique(scales));
    
    if isempty(scales)
        fprintf('ข้าม %s (ไม่พบโฟลเดอร์ A0, A10...)\n', folderName);
        continue;
    end
    
    maxDisp = max(scales);
    fprintf('กำลังทำ Slide/Linear Potentiometer: %s (ระยะ 0 - %d mm) ...\n', folderName, maxDisp);
    
    adcMeans = nan(1, length(scales));
    volMeans = nan(1, length(scales));
    
    % 1. อ่านค่า ADC และ Voltage ตามระยะที่มี
    for i = 1:length(scales)
        s = scales(i);
        
        folderA = fullfile(potPath, sprintf('A%d', s));
        adcMeans(i) = readFolderMean(folderA);
        
        folderV = fullfile(potPath, sprintf('V%d', s));
        volMeans(i) = readFolderMean(folderV);
    end
    
    % 2. แก้ไขค่า Voltage หากข้อมูลโดดเพี้ยน/เป็น NaN
    for i = 1:length(scales)
        if isnan(volMeans(i)) || volMeans(i) < 0 || volMeans(i) > 3.3
            if ~isnan(adcMeans(i))
                volMeans(i) = (adcMeans(i) / 4095) * 3.3;
            end
        end
    end
    if max(volMeans) >= 3.3 && length(volMeans) >= 3 && volMeans(2) == 3.3 && volMeans(3) == 0
        volMeans = (adcMeans / 4095) * 3.3;
    end
    
    % ---------------------------------------------------------------------
    % Figure 1: ADC Response (แกน X เป็น Displacement (mm))
    % ---------------------------------------------------------------------
    figADC = figure('Name', sprintf('ADC - %s', folderName), ...
        'Color', [0.08 0.08 0.08], 'Position', [100 100 800 600]);
    
    plot(scales, adcMeans, '-o', 'Color', [0 0.7 1], 'LineWidth', 3, ...
        'MarkerSize', 9, 'MarkerEdgeColor', [0 0.7 1], 'MarkerFaceColor', [0 0.7 1]);
    
    title(sprintf('ADC Response - Linear Potentiometer (%s)', folderName), 'FontSize', 16, 'FontWeight', 'bold', 'Color', 'w');
    xlabel('Displacement (mm)', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
    ylabel('ADC Count', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
    set(gca, 'Color', [0.12 0.12 0.12], 'XColor', 'w', 'YColor', 'w', ...
        'GridColor', [0.35 0.35 0.35], 'GridAlpha', 0.6, 'FontSize', 12, 'FontName', 'Tahoma');
    grid on; box on; xlim([0 maxDisp]); xticks(0:10:maxDisp); ylim([0 4100]);
    ax1 = gca; ax1.TickDir = 'in'; ax1.TickLength = [0.015 0.015];
    drawnow;
    
    % บันทึกไฟล์รูป ADC ลงโฟลเดอร์ของตัวเอง
    saveADC = fullfile(potPath, sprintf('%s_ADC_Dark.png', folderName));
    exportgraphics(figADC, saveADC, 'Resolution', 300);
    
    % ---------------------------------------------------------------------
    % Figure 2: Voltage Response (แกน X เป็น Displacement (mm))
    % ---------------------------------------------------------------------
    figVOL = figure('Name', sprintf('Voltage - %s', folderName), ...
        'Color', [0.08 0.08 0.08], 'Position', [150 150 800 600]);
    
    plot(scales, volMeans, '-s', 'Color', [0 0.7 1], 'LineWidth', 3, ...
        'MarkerSize', 9, 'MarkerEdgeColor', [0 0.7 1], 'MarkerFaceColor', [0 0.7 1]);
    
    title(sprintf('Voltage Response - Linear Potentiometer (%s)', folderName), 'FontSize', 16, 'FontWeight', 'bold', 'Color', 'w');
    xlabel('Displacement (mm)', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
    ylabel('Voltage (V)', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
    set(gca, 'Color', [0.12 0.12 0.12], 'XColor', 'w', 'YColor', 'w', ...
        'GridColor', [0.35 0.35 0.35], 'GridAlpha', 0.6, 'FontSize', 12, 'FontName', 'Tahoma');
    grid on; box on; xlim([0 maxDisp]); xticks(0:10:maxDisp); ylim([0 3.3]);
    ax2 = gca; ax2.TickDir = 'in'; ax2.TickLength = [0.015 0.015];
    drawnow;
    
    % บันทึกไฟล์รูป Voltage ลงโฟลเดอร์ของตัวเอง
    saveVOL = fullfile(potPath, sprintf('%s_Voltage_Dark.png', folderName));
    exportgraphics(figVOL, saveVOL, 'Resolution', 300);
end

fprintf('\nเสร็จเรียบร้อย! ประมวลผล Slide/Linear Potentiometer และเซฟรูปเข้าโฟลเดอร์แล้วครับ\n');

% =========================================================================
% ฟังก์ชันอ่านข้อมูลไฟล์ในโฟลเดอร์
% =========================================================================
function avgFolder = readFolderMean(folderPath)
    avgFolder = NaN;
    if ~isfolder(folderPath), return; end
    
    files = dir(folderPath);
    files = files(~[files.isdir] & ~startsWith({files.name}, '.'));
    
    fileMeans = [];
    for k = 1:length(files)
        filePath = fullfile(folderPath, files(k).name);
        val = readFileData(filePath);
        if ~isnan(val)
            fileMeans(end+1) = val; %#ok<AGROW>
        end
    end
    
    if ~isempty(fileMeans)
        avgFolder = mean(fileMeans, 'omitnan');
    end
end

function val = readFileData(filePath)
    val = NaN;
    try
        S = load(filePath, '-mat');
        numData = extractDataFromStruct(S);
        if ~isempty(numData), val = mean(numData, 'omitnan'); return; end
    catch
    end
    
    try
        S = load(filePath);
        if isstruct(S)
            numData = extractDataFromStruct(S);
        else
            numData = double(S(:));
        end
        if ~isempty(numData), val = mean(numData, 'omitnan'); return; end
    catch
    end
    
    try
        data = readmatrix(filePath);
        if ~isempty(data)
            numData = double(data(~isnan(data)));
            if ~isempty(numData), val = mean(numData, 'omitnan'); return; end
        end
    catch
    end
end

function numArr = extractDataFromStruct(S)
    numArr = [];
    if ~isstruct(S), return; end
    fn = fieldnames(S);
    
    for i = 1:length(fn)
        if strcmpi(fn{i}, 'time') || strcmpi(fn{i}, 'tout')
            continue;
        end
        
        v = S.(fn{i});
        if isa(v, 'Simulink.SimulationData.Dataset')
            try v = v.getElement(1).Values.Data; catch; end
        elseif isa(v, 'timeseries')
            try v = v.Data; catch; end
        elseif isstruct(v) && isfield(v, 'signals')
            try v = v.signals(1).values; catch; end
        elseif istable(v)
            try v = table2array(v); catch; end
        end
        
        if isnumeric(v) || islogical(v)
            arr = double(v(:));
            arr = arr(~isnan(arr) & ~isinf(arr));
            if ~isempty(arr)
                numArr = arr;
                return;
            end
        end
    end
end