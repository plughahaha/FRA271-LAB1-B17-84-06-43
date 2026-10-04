%% ========================================================================
%  plot_trend_linear_dark.m
%  พล็อตกราฟ Linear (Slide) Potentiometer A และ B 
%  ในสไตล์ Dark Theme (แยกรูปเดี่ยว 1 รูป ต่อ 1 เซนเซอร์)
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

% --- ตั้งค่าโฟลเดอร์หลัก และรายการ Linear Potentiometer ---
baseFolder = 'C:\RMX_V2';
slideScale = 0:10:60; % สเกลระยะของ Slide Potentiometer (0-60)

sensors = {
    'Linear Potentiometer A', fullfile(baseFolder, 'กราฟpotenslideA'), [0 0.75 1.0];   % สีฟ้าสว่าง (Cyan)
    'Linear Potentiometer B', fullfile(baseFolder, 'กราฟpotenslideB'), [1.0 0.5 0.1];   % สีส้มสว่าง (Orange)
};

numSensors = size(sensors, 1);

%% อ่านข้อมูลและสร้างกราฟรูปเดี่ยวฉากหลังดำ
for s = 1:numSensors
    sName   = sensors{s, 1};
    sFolder = sensors{s, 2};
    sColor  = sensors{s, 3};
    
    fprintf('กำลังอ่านข้อมูลของ: %s...\n', sName);
    
    adcVal = nan(size(slideScale));
    volVal = nan(size(slideScale));
    
    for k = 1:numel(slideScale)
        val = slideScale(k);
        % อ่านค่า ADC และ Voltage
        adcVal(k) = readSmartValue(fullfile(sFolder, sprintf('A%d', val)), 'adc');
        volVal(k) = readSmartValue(fullfile(sFolder, sprintf('V%d', val)), 'voltage');
    end
    
    % --- 1. กราฟ ADC Count (Linear Poten - ฉากดำ) ---
    figADC = figure('Name', [sName ' - ADC Dark'], 'Color', [0.08 0.08 0.08], 'Position', [100 100 680 480]);
    plot(slideScale, adcVal, 'o-', ...
        'LineWidth', 2.2, 'MarkerSize', 7, ...
        'Color', sColor, 'MarkerFaceColor', sColor);
    
    xlabel('Position / Scale (0 - 60)', 'FontWeight', 'bold', 'Color', 'w');
    ylabel('ADC Count', 'FontWeight', 'bold', 'Color', 'w');
    title(['ADC Response - ' sName], 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'w');
    grid on; box on;
    xticks(slideScale);
    ylim([0 4095]); % สเกล ADC (0 - 4095)
    drawnow;
    
    saveNameADC = sprintf('%s_ADC_Dark.png', strrep(sName, ' ', '_'));
    exportgraphics(figADC, fullfile(sFolder, saveNameADC), 'Resolution', 300);
    
    % --- 2. กราฟ Voltage (V) (Linear Poten - ฉากดำ) ---
    figVol = figure('Name', [sName ' - Voltage Dark'], 'Color', [0.08 0.08 0.08], 'Position', [150 150 680 480]);
    plot(slideScale, volVal, 's-', ...
        'LineWidth', 2.2, 'MarkerSize', 7, ...
        'Color', sColor, 'MarkerFaceColor', sColor);
    
    xlabel('Position / Scale (0 - 60)', 'FontWeight', 'bold', 'Color', 'w');
    ylabel('Voltage (V)', 'FontWeight', 'bold', 'Color', 'w');
    title(['Voltage Response - ' sName], 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'w');
    grid on; box on;
    xticks(slideScale);
    ylim([0 3.3]); % สเกล Voltage (0 - 3.3 V)
    drawnow;
    
    saveNameVol = sprintf('%s_Voltage_Dark.png', strrep(sName, ' ', '_'));
    exportgraphics(figVol, fullfile(sFolder, saveNameVol), 'Resolution', 300);
end

fprintf('\nเสร็จสมบูรณ์! บันทึกไฟล์รูปกราฟ Linear Potentiometer สไตล์ Dark Theme เรียบร้อยครับ\n');

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