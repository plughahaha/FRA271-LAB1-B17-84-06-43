%% ========================================================================
%  plot_schmitt_trigger_slider_dark.m
%  แสดงการทำงานของ Schmitt Trigger สำหรับ Slider Potentiometer (Dark Theme)
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

% --- ตั้งค่าโฟลเดอร์หลัก และค่า Threshold ---
baseFolder = 'C:\RMX_V2';
UT = 2200; % Upper Threshold
LT = 1800; % Lower Threshold

% ระบุชื่อโฟลเดอร์ตรงตามในรูปภาพ (มี r สองตัว: triggerslider)
triggerFolders = {'กราฟtriggersliderA', 'กราฟtriggersliderB'};

foundAny = false;

for tf = 1:numel(triggerFolders)
    tFolderName = triggerFolders{tf};
    tFolderPath = fullfile(baseFolder, tFolderName);
    
    if ~isfolder(tFolderPath)
        fprintf('❌ ไม่พบโฟลเดอร์: %s\n', tFolderPath);
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
        [adcSig, tADC]   = loadTimeSeries(pathA0);
        [trigSig, tTrig] = loadTimeSeries(pathTrigger);
        
        if isempty(adcSig) || isempty(trigSig)
            fprintf('⚠️ ข้อมูลไม่ครบใน: %s\n', runPath);
            continue;
        end
        
        foundAny = true;
        fprintf('✅ กำลังพล็อตกราฟ: %s / %s...\n', tFolderName, runName);
        
        % กำหนดแกน X (เวลา หรือ ตัวอย่างข้อมูล)
        xDataADC  = ifElse(~isempty(tADC), tADC, (1:numel(adcSig))');
        xDataTrig = ifElse(~isempty(tTrig), tTrig, (1:numel(trigSig))');
        xLabelStr = ifElse(~isempty(tADC), 'Time (s)', 'Sample Index');
        
        % --- สร้างกราฟแสดงผล (Dark Theme) ---
        figTitle = sprintf('Slider Schmitt Trigger - %s (Run %s)', tFolderName, runName);
        fig = figure('Name', figTitle, 'Color', [0.08 0.08 0.08], 'Position', [100 100 900 580]);
        
        % --- Subplot 1: สัญญาณ ADC ของ Slider + เส้น UT/LT ---
        ax1 = subplot(2, 1, 1);
        plot(xDataADC, adcSig, 'Color', [0 0.85 1], 'LineWidth', 1.8, 'DisplayName', 'Slider ADC');
        hold on;
        
        % เส้น Threshold UT และ LT
        yline(UT, '--', sprintf('UT = %d', UT), 'Color', [1 0.3 0.3], ...
            'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left', 'FontSize', 10);
        yline(LT, '--', sprintf('LT = %d', LT), 'Color', [0.3 1 0.4], ...
            'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left', 'FontSize', 10);
        
        ylabel('ADC Count', 'FontWeight', 'bold');
        title(figTitle, 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'w');
        grid on; box on;
        ylim([0 4095]);
        legend('Location', 'northeast', 'TextColor', 'w');
        
        % --- Subplot 2: สถานะ Digital Output (0/1) ---
        ax2 = subplot(2, 1, 2);
        stairs(xDataTrig, trigSig, 'Color', [1 0.5 0.1], 'LineWidth', 2, 'DisplayName', 'Trigger Output (y)');
        
        xlabel(xLabelStr, 'FontWeight', 'bold');
        ylabel('Output State (0/1)', 'FontWeight', 'bold');
        grid on; box on;
        ylim([-0.2 1.2]);
        yticks([0 1]);
        legend('Location', 'northeast', 'TextColor', 'w');
        
        % เชื่อมแกน X ให้ซูม/เลื่อนพร้อมกัน
        linkaxes([ax1, ax2], 'x');
        drawnow;
        
        % บันทึกรูปภาพ
        saveName = sprintf('%s_Run%s_Schmitt_Dark.png', tFolderName, runName);
        exportgraphics(fig, fullfile(tFolderPath, saveName), 'Resolution', 300);
    end
end

if ~foundAny
    fprintf('\n❌ ยังพล็อตกราฟไม่ได้ กรุณาตรวจสอบว่าในโฟลเดอร์ 1 หรือ 2 มีไฟล์ .mat อยู่ข้างในหรือไม่ครับ\n');
else
    fprintf('\n🎉 เสร็จสมบูรณ์! สร้างกราฟ Schmitt Trigger ของ Slider เรียบร้อยแล้วครับ\n');
end

%% ======================= ฟังก์ชันย่อยอ่านข้อมูล ========================
function [sig, t] = loadTimeSeries(folderPath)
    sig = []; t = [];
    if ~isfolder(folderPath), return; end
    
    % ค้นหาไฟล์ .mat หรือ .csv ทั้งในโฟลเดอร์นี้และโฟลเดอร์ย่อย
    files = [dir(fullfile(folderPath, '*.mat')); dir(fullfile(folderPath, '*.csv')); ...
             dir(fullfile(folderPath, '**', '*.mat')); dir(fullfile(folderPath, '**', '*.csv'))];
         
    if isempty(files), return; end
    
    fp = fullfile(files(1).folder, files(1).name);
    [~, ~, ext] = fileparts(fp);
    
    try
        if strcmpi(ext, '.mat')
            S = load(fp);
            fn = fieldnames(S);
            varData = S.(fn{1});
            
            if isa(varData, 'Simulink.SimulationData.Dataset')
                elem = varData.getElement(1);
                if isa(elem.Values, 'timeseries')
                    sig = double(elem.Values.Data(:));
                    t   = double(elem.Values.Time(:));
                end
            elseif isa(varData, 'timeseries')
                sig = double(varData.Data(:));
                t   = double(varData.Time(:));
            elseif isstruct(varData) && isfield(varData, 'signals')
                sig = double(varData.signals(1).values(:));
                if isfield(varData, 'time'), t = double(varData.time(:)); end
            elseif isnumeric(varData)
                sig = double(varData(:));
            end
        else % .csv
            T = readtable(fp);
            numData = T{:, vartype('numeric')};
            if size(numData, 2) >= 2
                t   = double(numData(:, 1));
                sig = double(numData(:, end));
            else
                sig = double(numData(:, end));
            end
        end
    catch
    end
end

function res = ifElse(cond, a, b)
    if cond, res = a; else, res = b; end
end