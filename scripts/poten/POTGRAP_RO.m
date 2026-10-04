clear; clc; close all;

basePath = 'C:\RMX_V2\sensor_data\labpo';
scales   = 0:10:100;

% ดึงเฉพาะโฟลเดอร์ที่ขึ้นต้นด้วย 'potenro' (เช่น potenroA, potenroB, potenroC)
dirList = dir(basePath);
dirList = dirList([dirList.isdir] & startsWith({dirList.name}, 'potenro', 'IgnoreCase', true));

if isempty(dirList)
    error('ไม่พบโฟลเดอร์ potenro ใน %s ครับ', basePath);
end

for d = 1:length(dirList)
    folderName = dirList(d).name;
    potPath    = fullfile(basePath, folderName);
    
    fprintf('กำลังทำเซนเซอร์ Rotary: %s ...\n', folderName);
    
    adcMeans = nan(1, length(scales));
    volMeans = nan(1, length(scales));
    
    % 1. อ่านค่า ADC และ Voltage แต่ละสเกล (A0-A100 และ V0-V100)
    for i = 1:length(scales)
        s = scales(i);
        
        folderA = fullfile(potPath, sprintf('A%d', s));
        adcMeans(i) = readFolderMean(folderA);
        
        folderV = fullfile(potPath, sprintf('V%d', s));
        volMeans(i) = readFolderMean(folderV);
    end
    
    % 2. แก้ไขค่า Voltage หากข้อมูลโดดเพี้ยน/เป็น NaN (คำนวณแปลงจาก ADC)
    for i = 1:length(scales)
        if isnan(volMeans(i)) || volMeans(i) < 0 || volMeans(i) > 3.3
            if ~isnan(adcMeans(i))
                volMeans(i) = (adcMeans(i) / 4095) * 3.3;
            end
        end
    end
    if max(volMeans) >= 3.3 && volMeans(2) == 3.3 && volMeans(3) == 0
        volMeans = (adcMeans / 4095) * 3.3;
    end
    
    % ---------------------------------------------------------------------
    % Figure 1: ADC Response (จุดวงกลม -o)
    % ---------------------------------------------------------------------
    figADC = figure('Name', sprintf('ADC - %s', folderName), ...
        'Color', [0.08 0.08 0.08], 'Position', [100 100 800 600]);
    
    plot(scales, adcMeans, '-o', 'Color', [0 0.7 1], 'LineWidth', 3, ...
        'MarkerSize', 9, 'MarkerEdgeColor', [0 0.7 1], 'MarkerFaceColor', [0 0.7 1]);
    
    title(sprintf('ADC Response - %s', folderName), 'FontSize', 16, 'FontWeight', 'bold', 'Color', 'w');
    xlabel('Position / Scale', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
    ylabel('ADC Count', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
    set(gca, 'Color', [0.12 0.12 0.12], 'XColor', 'w', 'YColor', 'w', ...
        'GridColor', [0.35 0.35 0.35], 'GridAlpha', 0.6, 'FontSize', 12, 'FontName', 'Tahoma');
    grid on; box on; xlim([0 100]); xticks(0:10:100); ylim([0 4100]);
    ax1 = gca; ax1.TickDir = 'in'; ax1.TickLength = [0.015 0.015];
    drawnow;
    
    % บันทึกไฟล์ ADC.png เข้าโฟลเดอร์ของตัวเอง
    saveADC = fullfile(potPath, sprintf('%s_ADC_Dark.png', folderName));
    exportgraphics(figADC, saveADC, 'Resolution', 300);
    
    % ---------------------------------------------------------------------
    % Figure 2: Voltage Response (จุดสี่เหลี่ยม -s)
    % ---------------------------------------------------------------------
    figVOL = figure('Name', sprintf('Voltage - %s', folderName), ...
        'Color', [0.08 0.08 0.08], 'Position', [150 150 800 600]);
    
    plot(scales, volMeans, '-s', 'Color', [0 0.7 1], 'LineWidth', 3, ...
        'MarkerSize', 9, 'MarkerEdgeColor', [0 0.7 1], 'MarkerFaceColor', [0 0.7 1]);
    
    title(sprintf('Voltage Response - %s', folderName), 'FontSize', 16, 'FontWeight', 'bold', 'Color', 'w');
    xlabel('Position / Scale', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
    ylabel('Voltage (V)', 'FontSize', 14, 'FontWeight', 'bold', 'Color', 'w');
    set(gca, 'Color', [0.12 0.12 0.12], 'XColor', 'w', 'YColor', 'w', ...
        'GridColor', [0.35 0.35 0.35], 'GridAlpha', 0.6, 'FontSize', 12, 'FontName', 'Tahoma');
    grid on; box on; xlim([0 100]); xticks(0:10:100); ylim([0 3.3]);
    ax2 = gca; ax2.TickDir = 'in'; ax2.TickLength = [0.015 0.015];
    drawnow;
    
    % บันทึกไฟล์ Voltage.png เข้าโฟลเดอร์ของตัวเอง
    saveVOL = fullfile(potPath, sprintf('%s_Voltage_Dark.png', folderName));
    exportgraphics(figVOL, saveVOL, 'Resolution', 300);
end

fprintf('\nเสร็จเรียบร้อย! ทำเฉพาะ potenro และเซฟแยกตามโฟลเดอร์เรียบร้อยครับ\n');

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