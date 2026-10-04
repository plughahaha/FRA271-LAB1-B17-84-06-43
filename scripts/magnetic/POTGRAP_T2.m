%% ========================================================================
%  POTGRAP_T2.m - รันเฉพาะ template2 (Dark Theme)
% =========================================================================
clear; clc; close all;

% --- ตั้งค่าธีมสีดำ (Dark Theme) ---
set(0, 'DefaultFigureWindowStyle', 'normal');
set(groot, 'defaultFigureColor', [0.08 0.08 0.08]);    % พื้นหลัง Figure สีดำ
set(groot, 'defaultAxesColor', [0.12 0.12 0.12]);      % พื้นหลังช่องกราฟ
set(groot, 'defaultAxesXColor', 'w');                  % แกน X สีขาว
set(groot, 'defaultAxesYColor', 'w');                  % แกน Y สีขาว
set(groot, 'defaultTextColor', 'w');                   % ตัวอักษรสีขาว
set(groot, 'defaultAxesGridColor', [0.35 0.35 0.35]);  % เส้นตารางสีเทา
set(groot, 'defaultAxesGridAlpha', 0.6);
set(groot, 'defaultAxesFontName', 'Tahoma');
set(groot, 'defaultAxesFontSize', 11);

% --- กำหนดโฟลเดอร์หลัก และค้นหาโฟลเดอร์ template2 อัตโนมัติ ---
baseFolder = 'C:\RMX_V2\labmag';

% ค้นหาโฟลเดอร์ที่ขึ้นต้นด้วย template2
matchedDirs = dir(fullfile(baseFolder, 'template2*'));
matchedDirs = matchedDirs([matchedDirs.isdir]);

if isempty(matchedDirs)
    error('ไม่พบโฟลเดอร์ template2 ใน: %s\nกรุณาตรวจสอบชื่อโฟลเดอร์ใน C:\\RMX_V2\\labmag\\', baseFolder);
end

% ดึงชื่อโฟลเดอร์จริงที่พบในไดร์ฟ
tName  = matchedDirs(1).name;
tPath  = fullfile(baseFolder, tName);
tColor = [1.0 0.5 0.1]; % สีส้มสว่าง (Orange)

fprintf('🔍 กำลังประมวลผลข้อมูลในโฟลเดอร์: %s...\n', tPath);

% อ่านรายชื่อโฟลเดอร์ระยะทาง (เช่น 1.1, 1.3, ..., 4.3)
dirItems = dir(tPath);
distFolders = dirItems([dirItems.isdir] & ~startsWith({dirItems.name}, '.'));

distances = [];
validFolderNames = {};
for i = 1:numel(distFolders)
    dVal = str2double(distFolders(i).name);
    if ~isnan(dVal)
        distances(end+1) = dVal; %#ok<SAGROW>
        validFolderNames{end+1} = distFolders(i).name; %#ok<SAGROW>
    end
end

% จัดเรียงระยะทางจากน้อยไปมาก
[distances, sortIdx] = sort(distances);
validFolderNames = validFolderNames(sortIdx);

if isempty(distances)
    error('ไม่พบโฟลเดอร์ระยะทางย่อยใน: %s', tPath);
end

adcVals = nan(size(distances));
volVals = nan(size(distances));

% วนลูปอ่านข้อมูลในแต่ละระยะทาง
for k = 1:numel(distances)
    distName = validFolderNames{k};
    distPath = fullfile(tPath, distName);
    
    subItems = dir(distPath);
    runDirs = subItems([subItems.isdir] & ~startsWith({subItems.name}, '.'));
    
    if isempty(runDirs)
        targetFolder = distPath;
    else
        targetFolder = fullfile(distPath, runDirs(1).name);
    end
    
    % อ่านค่า ADC (A0) และ Voltage (v0)
    adcVals(k) = readSmartValue(targetFolder, 'adc');
    volVals(k) = readSmartValue(targetFolder, 'voltage');
end

% --- 1. กราฟ ADC Count vs Distance ---
figADC = figure('Name', [tName ' - ADC'], 'Color', [0.08 0.08 0.08], 'Position', [100 100 700 480]);
plot(distances, adcVals, 'o-', ...
    'LineWidth', 2.2, 'MarkerSize', 7, ...
    'Color', tColor, 'MarkerFaceColor', tColor);

xlabel('Distance (cm)', 'FontWeight', 'bold', 'Color', 'w');
ylabel('ADC Count', 'FontWeight', 'bold', 'Color', 'w');
title(sprintf('Magnetic Sensor ADC - %s', tName), 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'w');
grid on; box on;
xticks(distances);
ylim([0 4095]);
drawnow;

exportgraphics(figADC, fullfile(tPath, sprintf('%s_ADC_Dark.png', tName)), 'Resolution', 300);

% --- 2. กราฟ Voltage vs Distance ---
figVol = figure('Name', [tName ' - Voltage'], 'Color', [0.08 0.08 0.08], 'Position', [150 150 700 480]);
plot(distances, volVals, 's-', ...
    'LineWidth', 2.2, 'MarkerSize', 7, ...
    'Color', tColor, 'MarkerFaceColor', tColor);

xlabel('Distance (cm)', 'FontWeight', 'bold', 'Color', 'w');
ylabel('Voltage (V)', 'FontWeight', 'bold', 'Color', 'w');
title(sprintf('Magnetic Sensor Voltage - %s', tName), 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'w');
grid on; box on;
xticks(distances);
ylim([0 3.3]);
drawnow;

exportgraphics(figVol, fullfile(tPath, sprintf('%s_Voltage_Dark.png', tName)), 'Resolution', 300);

fprintf('\n🎉 เสร็จสมบูรณ์! บันทึกรูปกราฟ ADC และ Voltage ของ %s เรียบร้อยแล้วครับ\n', tName);

%% ======================= ฟังก์ชันย่อยอ่านค่า ========================
function val = readSmartValue(folderPath, dataType)
    val = NaN;
    if ~isfolder(folderPath), return; end
    
    if strcmpi(dataType, 'adc')
        subSearch = 'A0';
    else
        subSearch = 'v0';
    end
    
    targetPath = fullfile(folderPath, subSearch);
    if isfolder(targetPath)
        searchPath = targetPath;
    else
        searchPath = folderPath;
    end
    
    files = [dir(fullfile(searchPath, '*.mat')); dir(fullfile(searchPath, '*.csv')); ...
             dir(fullfile(searchPath, '**', '*.mat')); dir(fullfile(searchPath, '**', '*.csv'))];
         
    if isempty(files), return; end
    
    fp = fullfile(files(1).folder, files(1).name);
    [~, ~, ext] = fileparts(fp);
    
    try
        if strcmpi(ext, '.mat')
            S = load(fp);
            fn = fieldnames(S);
            firstVar = S.(fn{1});
            
            candidates = [];
            if isa(firstVar, 'Simulink.SimulationData.Dataset')
                for idx = 1:firstVar.numElements
                    elem = firstVar.getElement(idx);
                    if isa(elem.Values, 'timeseries')
                        candidates(end+1) = double(elem.Values.Data(end));
                    elseif isnumeric(elem.Values)
                        candidates(end+1) = double(elem.Values(end));
                    end
                end
            elseif isa(firstVar, 'timeseries')
                candidates = double(firstVar.Data(end));
            elseif isstruct(firstVar) && isfield(firstVar, 'signals')
                for idx = 1:numel(firstVar.signals)
                    candidates(end+1) = double(firstVar.signals(idx).values(end));
                end
            elseif isnumeric(firstVar)
                candidates = double(firstVar(end));
            end
            
            if strcmpi(dataType, 'voltage')
                v_match = candidates(candidates <= 3.35);
                if ~isempty(v_match)
                    val = v_match(end);
                else
                    val = (candidates(end) / 4095) * 3.3;
                end
            else
                a_match = candidates(candidates > 3.35);
                if ~isempty(a_match)
                    val = a_match(end);
                else
                    val = candidates(1);
                end
            end
        else % .csv
            T = readtable(fp);
            numData = T{:, vartype('numeric')};
            if ~isempty(numData)
                rawVal = double(numData(end, end));
                if strcmpi(dataType, 'voltage') && rawVal > 3.35
                    val = (rawVal / 4095) * 3.3;
                else
                    val = rawVal;
                end
            end
        end
    catch
    end
end

