%% ========================================================================
%  POTGRAP_LOAD.m - รันแลป Load Cell (labload) - Dark Theme
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

% --- กำหนดโฟลเดอร์หลักสำหรับ Load Cell ---
baseFolder = 'C:\RMX_V2\labload';

if ~isfolder(baseFolder)
    error('ไม่พบโฟลเดอร์: %s\nกรุณาตรวจสอบเส้นทางโฟลเดอร์ในเครื่องอีกครั้ง', baseFolder);
end

tColor = [1.0 0.75 0.0]; % สีทองสว่าง (Amber Gold)

fprintf('🔍 กำลังประมวลผลข้อมูลแลป Load Cell ในโฟลเดอร์: %s...\n', baseFolder);

% อ่านรายชื่อโฟลเดอร์น้ำหนัก (เช่น 1kg, 2kg, ..., 10kg)
dirItems = dir(baseFolder);
weightFolders = dirItems([dirItems.isdir] & ~startsWith({dirItems.name}, '.'));

weights = [];
validFolderNames = {};

for i = 1:numel(weightFolders)
    % ดึงเฉพาะตัวเลขจากชื่อโฟลเดอร์ (เช่น "1kg" -> 1)
    numStr = regexprep(weightFolders(i).name, '[^\d\.]', '');
    wVal = str2double(numStr);
    if ~isnan(wVal)
        weights(end+1) = wVal; %#ok<SAGROW>
        validFolderNames{end+1} = weightFolders(i).name; %#ok<SAGROW>
    end
end

% จัดเรียงน้ำหนักจากน้อยไปมาก (1kg -> 10kg)
[weights, sortIdx] = sort(weights);
validFolderNames = validFolderNames(sortIdx);

if isempty(weights)
    error('ไม่พบโฟลเดอร์น้ำหนักย่อยใน: %s', baseFolder);
end

adcVals = nan(size(weights));
volVals = nan(size(weights));

% วนลูปอ่านข้อมูลแต่ละน้ำหนัก (หาค่าเฉลี่ยจากรอบการทดลอง 1, 2, 3...)
for k = 1:numel(weights)
    wFolder = validFolderNames{k};
    wPath = fullfile(baseFolder, wFolder);
    
    subItems = dir(wPath);
    runDirs = subItems([subItems.isdir] & ~startsWith({subItems.name}, '.'));
    
    if isempty(runDirs)
        % กรณีไม่มีโฟลเดอร์ย่อย 1, 2, 3 ให้ใช้อ่านตรงจากโฟลเดอร์น้ำหนัก
        adcVals(k) = readSmartValue(wPath, 'adc');
        volVals(k) = readSmartValue(wPath, 'voltage');
    else
        % อ่านค่าจากทุกรอบทดลองแล้วนำมาหาค่าเฉลี่ย (Mean)
        runAdc = [];
        runVol = [];
        for r = 1:numel(runDirs)
            rPath = fullfile(wPath, runDirs(r).name);
            a = readSmartValue(rPath, 'adc');
            v = readSmartValue(rPath, 'voltage');
            if ~isnan(a), runAdc(end+1) = a; end %#ok<SAGROW>
            if ~isnan(v), runVol(end+1) = v; end %#ok<SAGROW>
        end
        
        if ~isempty(runAdc), adcVals(k) = mean(runAdc); end
        if ~isempty(runVol), volVals(k) = mean(runVol); end
    end
end

% --- 1. กราฟ ADC Count vs Load ---
figADC = figure('Name', 'Load Cell - ADC', 'Color', [0.08 0.08 0.08], 'Position', [100 100 700 480]);
plot(weights, adcVals, 'o-', ...
    'LineWidth', 2.2, 'MarkerSize', 7, ...
    'Color', tColor, 'MarkerFaceColor', tColor);

xlabel('Load (kg)', 'FontWeight', 'bold', 'Color', 'w');
ylabel('ADC Count', 'FontWeight', 'bold', 'Color', 'w');
title('Load Cell Sensor ADC vs Load', 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'w');
grid on; box on;
xticks(weights);
ylim([0 4095]);
drawnow;

exportgraphics(figADC, fullfile(baseFolder, 'LoadCell_ADC_Dark.png'), 'Resolution', 300);

% --- 2. กราฟ Voltage vs Load ---
figVol = figure('Name', 'Load Cell - Voltage', 'Color', [0.08 0.08 0.08], 'Position', [150 150 700 480]);
plot(weights, volVals, 's-', ...
    'LineWidth', 2.2, 'MarkerSize', 7, ...
    'Color', tColor, 'MarkerFaceColor', tColor);

xlabel('Load (kg)', 'FontWeight', 'bold', 'Color', 'w');
ylabel('Voltage (V)', 'FontWeight', 'bold', 'Color', 'w');
title('Load Cell Sensor Voltage vs Load', 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'w');
grid on; box on;
xticks(weights);
ylim([0 3.3]);
drawnow;

exportgraphics(figVol, fullfile(baseFolder, 'LoadCell_Voltage_Dark.png'), 'Resolution', 300);

fprintf('\n🎉 ประมวลผลแลป Load Cell เรียบร้อยแล้ว! บันทึกรูปกราฟไว้ที่:\n - %s\n', baseFolder);

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