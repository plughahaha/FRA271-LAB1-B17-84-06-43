%% ========================================================================
%  plot_trend_dark_theme_individual.m
%  พล็อตกราฟแยกทีละรูป ในสไตล์ Dark Theme (พื้นหลังดำ ตัวอักษรขาว เส้นสว่าง)
% =========================================================================
clear; clc; close all;

% --- ตั้งค่าธีมสีดำ (Dark Theme) สำหรับทุก Figure ---
set(0, 'DefaultFigureWindowStyle', 'normal');
set(groot, 'defaultFigureColor', [0.08 0.08 0.08]);    % พื้นหลัง Figure สีดำเข้ม
set(groot, 'defaultAxesColor', [0.12 0.12 0.12]);      % พื้นหลังช่องกราฟสีดำเทา
set(groot, 'defaultAxesXColor', 'w');                  % แกน X สีขาว
set(groot, 'defaultAxesYColor', 'w');                  % แกน Y สีขาว
set(groot, 'defaultTextColor', 'w');                   % ตัวอักษรทั้งหมดสีขาว
set(groot, 'defaultAxesGridColor', [0.35 0.35 0.35]);  % เส้นตารางสีเทา
set(groot, 'defaultAxesGridAlpha', 0.6);
set(groot, 'defaultAxesFontName', 'Tahoma');
set(groot, 'defaultAxesFontSize', 11);

% --- ตั้งค่าโฟลเดอร์หลัก และรายการเซนเซอร์ ---
baseFolder = 'C:\RMX_V2';
sensorType = 'ro'; % เลือก 'ro' (Rotary 0-100) หรือ 'slide' (Slide 0-60)

if strcmpi(sensorType, 'ro')
    dialScale = 0:10:100; % สเกลหน้าปัด 0-100
    sensors = {
        'Potentiometer A', fullfile(baseFolder, 'กราฟpotenroA'), [0 0.75 1.0];   % สีฟ้าสว่าง (Cyan)
        'Potentiometer B', fullfile(baseFolder, 'กราฟpotenroB'), [1.0 0.5 0.1];   % สีส้มสว่าง (Orange)
        'Potentiometer C', fullfile(baseFolder, 'กราฟpotenroC'), [0.8 0.3 1.0];   % สีม่วงสว่าง (Magenta)
    };
else
    dialScale = 0:10:60;  % สเกลหน้าปัด 0-60
    sensors = {
        'Slide A', fullfile(baseFolder, 'กราฟpotenslideA'), [0 0.75 1.0];
        'Slide B', fullfile(baseFolder, 'กราฟpotenslideB'), [1.0 0.5 0.1];
    };
end

numSensors = size(sensors, 1);

%% อ่านข้อมูลและสร้างกราฟรูปเดี่ยวฉากหลังดำ
for s = 1:numSensors
    sName   = sensors{s, 1};
    sFolder = sensors{s, 2};
    sColor  = sensors{s, 3};
    
    fprintf('กำลังอ่านข้อมูลของ: %s...\n', sName);
    
    adcVal = nan(size(dialScale));
    volVal = nan(size(dialScale));
    
    for k = 1:numel(dialScale)
        val = dialScale(k);
        % อ่านค่า ADC
        adcVal(k) = readSmartValue(fullfile(sFolder, sprintf('A%d', val)), 'adc');
        % อ่านค่า Voltage
        volVal(k) = readSmartValue(fullfile(sFolder, sprintf('V%d', val)), 'voltage');
    end
    
    % --- 1. กราฟ ADC Count (รูปเดี่ยว - ฉากดำ) ---
    figADC = figure('Name', [sName ' - ADC Dark'], 'Color', [0.08 0.08 0.08], 'Position', [100 100 680 480]);
    plot(dialScale, adcVal, 'o-', ...
        'LineWidth', 2.2, 'MarkerSize', 7, ...
        'Color', sColor, 'MarkerFaceColor', sColor);
    
    xlabel('Position / Scale', 'FontWeight', 'bold', 'Color', 'w');
    ylabel('ADC Count', 'FontWeight', 'bold', 'Color', 'w');
    title(['ADC Response - ' sName], 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'w');
    grid on; box on;
    xticks(dialScale);
    ylim([0 4095]); % สเกล ADC (0 - 4095)
    drawnow;
    
    saveNameADC = sprintf('%s_ADC_Dark.png', strrep(sName, ' ', '_'));
    exportgraphics(figADC, fullfile(sFolder, saveNameADC), 'Resolution', 300);
    
    % --- 2. กราฟ Voltage (V) (รูปเดี่ยว - ฉากดำ) ---
    figVol = figure('Name', [sName ' - Voltage Dark'], 'Color', [0.08 0.08 0.08], 'Position', [150 150 680 480]);
    plot(dialScale, volVal, 's-', ...
        'LineWidth', 2.2, 'MarkerSize', 7, ...
        'Color', sColor, 'MarkerFaceColor', sColor);
    
    xlabel('Position / Scale', 'FontWeight', 'bold', 'Color', 'w');
    ylabel('Voltage (V)', 'FontWeight', 'bold', 'Color', 'w');
    title(['Voltage Response - ' sName], 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'w');
    grid on; box on;
    xticks(dialScale);
    ylim([0 3.3]); % สเกล Voltage (0 - 3.3 V)
    drawnow;
    
    saveNameVol = sprintf('%s_Voltage_Dark.png', strrep(sName, ' ', '_'));
    exportgraphics(figVol, fullfile(sFolder, saveNameVol), 'Resolution', 300);
end

fprintf('\nเสร็จสมบูรณ์! ได้กราฟรูปเดี่ยวในธีม Dark Theme เรียบร้อยแล้วครับ\n');

%% ======================= ฟังก์ชันอ่านค่าอัจฉริยะ ========================
function val = readSmartValue(folderPath, dataType)
    val = NaN;
    if ~isfolder(folderPath)
        warning('ไม่พบโฟลเดอร์: %s', folderPath);
        return;
    end
    
    files = [dir(fullfile(folderPath, '*.mat')); dir(fullfile(folderPath, '*.csv'))];
    if isempty(files)
        warning('ไม่พบไฟล์ข้อมูลใน: %s', folderPath);
        return;
    end
    
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
                        d = elem.Values.Data;
                        candidates(end+1) = double(d(end));
                    elseif isnumeric(elem.Values)
                        candidates(end+1) = double(elem.Values(end));
                    end
                end
            elseif isa(firstVar, 'timeseries')
                candidates = double(firstVar.Data(end));
            elseif isstruct(firstVar) && isfield(firstVar, 'signals')
                for idx = 1:numel(firstVar.signals)
                    d = firstVar.signals(idx).values;
                    candidates(end+1) = double(d(end));
                end
            elseif isnumeric(firstVar)
                candidates = double(firstVar(end));
            end
            
            % คัดเลือกค่าตามชนิดข้อมูล
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
    catch ME
        warning('อ่านไฟล์ %s ไม่ได้: %s', fp, ME.message);
    end
end