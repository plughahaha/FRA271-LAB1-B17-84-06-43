%% ========================================================================
%  plot_schmitt_trigger_dark.m
%  แสดงการทำงานของ Schmitt Trigger (ADC vs Digital Output) ในธีม Dark
% =========================================================================
clear; clc; close all;

% --- ตั้งค่าธีมสีดำ (Dark Theme) ---
set(0, 'DefaultFigureWindowStyle', 'normal');
set(groot, 'defaultFigureColor', [0.08 0.08 0.08]);    % พื้นหลัง Figure สีดำเข้ม
set(groot, 'defaultAxesColor', [0.12 0.12 0.12]);      % พื้นหลังช่องกราฟสีดำเทา
set(groot, 'defaultAxesXColor', 'w');                  % แกน X สีขาว
set(groot, 'defaultAxesYColor', 'w');                  % แกน Y สีขาว
set(groot, 'defaultTextColor', 'w');                   % ตัวอักษรสีขาว
set(groot, 'defaultAxesGridColor', [0.35 0.35 0.35]);  % เส้นตารางสีเทา
set(groot, 'defaultAxesGridAlpha', 0.6);
set(groot, 'defaultAxesFontName', 'Tahoma');
set(groot, 'defaultAxesFontSize', 11);

% --- ตั้งค่าโฟลเดอร์หลัก และค่า Threshold ---
possibleBaseFolder = {'C:\RMX_V2\sensor_data\labpo', 'C:\RMX_V2'};
baseFolder = '';
for b = 1:numel(possibleBaseFolder)
    if isfolder(possibleBaseFolder{b})
        baseFolder = possibleBaseFolder{b};
        break;
    end
end
if isempty(baseFolder), baseFolder = 'C:\RMX_V2'; end

UT = 2200; % Upper Threshold
LT = 1800; % Lower Threshold

triggerFolders = {'triggerA', 'triggerB', 'triggerC', 'กราฟtriggerA', 'กราฟtriggerB', 'กราฟtriggerC'};

for tf = 1:numel(triggerFolders)
    tFolderName = triggerFolders{tf};
    tFolderPath = fullfile(baseFolder, tFolderName);
    
    if ~isfolder(tFolderPath)
        continue;
    end
    
    % ค้นหาโฟลเดอร์ย่อยข้างใน (เช่น โฟลเดอร์ 1, 2)
    subDirs = dir(tFolderPath);
    subDirs = subDirs([subDirs.isdir] & ~startsWith({subDirs.name}, '.'));
    
    for sd = 1:numel(subDirs)
        runName = subDirs(sd).name;
        runPath = fullfile(tFolderPath, runName);
        
        pathA0      = fullfile(runPath, 'A0');
        pathTrigger = fullfile(runPath, 'trigger');
        
        % อ่านข้อมูลอนุกรมเวลา (Time Series)
        [adcSig, tADC] = loadTimeSeries(pathA0);
        [trigSig, tTrig] = loadTimeSeries(pathTrigger);
        
        if isempty(adcSig) || isempty(trigSig)
            warning('ไม่พบข้อมูลสมบูรณ์ใน: %s', runPath);
            continue;
        end
        
        % สร้างแกน X (ใช้เวลาจริง หรือใช้อินเด็กซ์ของข้อมูล)
        xDataADC  = ifElse(~isempty(tADC), tADC, 1:numel(adcSig));
        xDataTrig = ifElse(~isempty(tTrig), tTrig, 1:numel(trigSig));
        xLabelStr = ifElse(~isempty(tADC), 'Time (s)', 'Sample Index');
        
        % --- จัดรูปแบบชื่อกราฟให้ตรงเป้าหมาย ---
        displayFolderName = tFolderName;
        if ~startsWith(displayFolderName, 'กราฟ')
            displayFolderName = ['กราฟ' displayFolderName];
        end
        figTitle = sprintf('Schmitt Trigger Response - %s (Run %s)', displayFolderName, runName);
        fig = figure('Name', figTitle, 'Color', [0.08 0.08 0.08], 'Position', [100 100 900 620]);
        
        % --- Subplot 1: สัญญาณ ADC + เส้น UT/LT ---
        ax1 = subplot(2, 1, 1);
        hADC = plot(xDataADC, adcSig, 'Color', [0 0.85 1], 'LineWidth', 1.8);
        hold on;
        
        % วาดเส้น Upper Threshold (UT) และ Lower Threshold (LT)
        hUT = yline(UT, '--', 'Color', [1 0.3 0.3], 'LineWidth', 1.5);
        hLT = yline(LT, '--', 'Color', [0.3 1 0.4], 'LineWidth', 1.5);
        
        % ตัวหนังสือ UT = 2200 และ LT = 1800 ด้านซ้ายบนเส้น
        xMin = min(xDataADC);
        text(xMin, UT + 120, sprintf('UT = %d', UT), 'Color', [1 0.35 0.35], ...
            'FontSize', 11, 'FontWeight', 'bold', 'VerticalAlignment', 'bottom');
        text(xMin, LT - 120, sprintf('LT = %d', LT), 'Color', [0.35 1 0.4], ...
            'FontSize', 11, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
        
        ylabel('ADC Count', 'FontWeight', 'bold');
        title(figTitle, 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'w');
        grid on; box on;
        ylim([0 4100]);
        
        % Legend ตรงตามรูปเป้าหมาย: ADC Signal, data1, data2
        legend([hADC, hUT, hLT], {'ADC Signal', 'data1', 'data2'}, ...
            'Location', 'northeast', 'TextColor', 'w', 'Color', [0.12 0.12 0.12], 'EdgeColor', [0.5 0.5 0.5]);
        
        % --- Subplot 2: สถานะ Digital Output (0/1) ---
        ax2 = subplot(2, 1, 2);
        hTrig = plot(xDataTrig, trigSig, 'Color', [1 0.8 0.1], 'LineWidth', 2);
        
        xlabel(xLabelStr, 'FontWeight', 'bold');
        ylabel('Output State (0/1)', 'FontWeight', 'bold');
        grid on; box on;
        ylim([-0.2 1.2]);
        yticks([0 1]);
        legend(hTrig, {'Trigger Output (y)'}, ...
            'Location', 'northeast', 'TextColor', 'w', 'Color', [0.12 0.12 0.12], 'EdgeColor', [0.5 0.5 0.5]);
        
        % ล็อกแกน X ของทั้งสองกราฟให้เลื่อน/ซูมพร้อมกัน
        linkaxes([ax1, ax2], 'x');
        drawnow;
        
        % บันทึกรูปภาพ
        saveName = sprintf('%s_Run%s_Schmitt_Dark.png', tFolderName, runName);
        exportgraphics(fig, fullfile(tFolderPath, saveName), 'Resolution', 300);
    end
end

fprintf('\nสร้างกราฟ Schmitt Trigger สไตล์ Dark Theme เรียบร้อยแล้วครับ!\n');

%% ======================= ฟังก์ชันย่อยอ่านข้อมูล ========================
function [sig, t] = loadTimeSeries(folderPath)
    sig = []; t = [];
    if ~isfolder(folderPath)
        if isfile(folderPath)
            fp = folderPath;
        elseif isfile([folderPath '.mat'])
            fp = [folderPath '.mat'];
        else
            return;
        end
    else
        % อ่านไฟล์ทั้งหมดในโฟลเดอร์โดยไม่จำกัดนามสกุล
        files = dir(fullfile(folderPath, '*'));
        files = files(~[files.isdir] & ~startsWith({files.name}, '.'));
        
        validFiles = [];
        for k = 1:numel(files)
            [~, ~, ext] = fileparts(files(k).name);
            if ~strcmpi(ext, '.png') && ~strcmpi(ext, '.jpg') && ~strcmpi(ext, '.fig')
                validFiles = [validFiles; files(k)];
            end
        end
        if isempty(validFiles), return; end
        fp = fullfile(validFiles(1).folder, validFiles(1).name);
    end
    
    % 1. โหลดแบบ MAT-file
    try
        S = load(fp);
        fn = fieldnames(S);
        if ~isempty(fn)
            varData = S.(fn{1});
            if isa(varData, 'Simulink.SimulationData.Dataset')
                elem = varData.getElement(1);
                if isa(elem.Values, 'timeseries')
                    sig = double(elem.Values.Data(:));
                    t   = double(elem.Values.Time(:));
                    return;
                end
            elseif isa(varData, 'timeseries')
                sig = double(varData.Data(:));
                t   = double(varData.Time(:));
                return;
            elseif isstruct(varData) && isfield(varData, 'signals')
                sig = double(varData.signals(1).values(:));
                if isfield(varData, 'time'), t = double(varData.time(:)); end
                return;
            elseif isnumeric(varData)
                if size(varData, 2) >= 2
                    t   = double(varData(:, 1));
                    sig = double(varData(:, end));
                else
                    sig = double(varData(:));
                end
                return;
            end
        end
    catch
    end
    
    % 2. อ่านแบบ Text/Matrix สำรองสำหรับไฟล์ไร้นามสกุล
    try
        data = readmatrix(fp);
        if ~isempty(data)
            if size(data, 2) >= 2
                t   = double(data(:, 1));
                sig = double(data(:, end));
            else
                sig = double(data(:, 1));
            end
            return;
        end
    catch
    end
end

function res = ifElse(cond, a, b)
    if cond, res = a; else, res = b; end
end