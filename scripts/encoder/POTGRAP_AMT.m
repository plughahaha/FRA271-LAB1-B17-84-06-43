%% ========================================================================
%  POTGRAP_AMT.m - ประมวลผล AMT103 (แยกโฟลเดอร์รูปใน OUTPUT_GRAPHS)
% =========================================================================
clear; clc; close all;
% ตั้งค่าธีมสีดำ (Dark Theme)
set(0, 'DefaultFigureWindowStyle', 'normal');
set(groot, 'defaultFigureColor', [0.08 0.08 0.08]);
set(groot, 'defaultAxesColor', [0.12 0.12 0.12]);
set(groot, 'defaultAxesXColor', 'w');
set(groot, 'defaultAxesYColor', 'w');
set(groot, 'defaultTextColor', 'w');
set(groot, 'defaultAxesGridColor', [0.35 0.35 0.35]);
set(groot, 'defaultAxesGridAlpha', 0.6);
set(groot, 'defaultAxesFontName', 'Tahoma');
set(groot, 'defaultAxesFontSize', 11);

% โฟลเดอร์ข้อมูล AMT103 และ โฟลเดอร์หลักบันทึกรูป OUTPUT_GRAPHS
baseFolder   = 'C:\RMX_V2\sensor_data\labencoder\AMT103';
outputFolder = 'C:\RMX_V2\sensor_data\labencoder\OUTPUT_GRAPHS';

colors = [0.0 0.8 1.0; 0.2 1.0 0.4; 1.0 0.4 0.4];
fprintf('🔍 กำลังประมวลผลข้อมูล Encoder รุ่น: AMT103...\n');

dirItems = dir(baseFolder);
condFolders = dirItems([dirItems.isdir] & ~startsWith({dirItems.name}, '.'));

for c = 1:numel(condFolders)
    condName = condFolders(c).name;
    condPath = fullfile(baseFolder, condName);
    matFiles = dir(fullfile(condPath, '*.mat'));
    if isempty(matFiles), continue; end
    
    figTitle = sprintf('AMT103 - %s', condName);
    fig = figure('Name', figTitle, 'Color', [0.08 0.08 0.08], 'Position', [100 100 800 500]);
    hold on; legendEntries = {};
    
    for f = 1:numel(matFiles)
        filePath = fullfile(condPath, matFiles(f).name);
        [~, fileBaseName] = fileparts(matFiles(f).name);
        [tData, yData] = readEncoderSignal(filePath);
        if ~isempty(yData)
            colorIdx = mod(f - 1, size(colors, 1)) + 1;
            plot(tData, yData, 'LineWidth', 1.8, 'Color', colors(colorIdx, :));
            legendEntries{end+1} = fileBaseName; %#ok<SAGROW>
        end
    end
    
    hold off;
    xlabel('Time (s)', 'FontWeight', 'bold', 'Color', 'w');
    ylabel('Encoder Count', 'FontWeight', 'bold', 'Color', 'w');
    title(figTitle, 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'w', 'Interpreter', 'none');
    grid on; box on;
    if ~isempty(legendEntries)
        legend(legendEntries, 'TextColor', 'w', 'Color', [0.15 0.15 0.15], 'EdgeColor', [0.4 0.4 0.4]);
    end
    drawnow;
    
    % สร้างโฟลเดอร์แยกตามรุ่น/เงื่อนไขย่อย เช่น OUTPUT_GRAPHS\AMT103\<condName>\
    subOutFolder = fullfile(outputFolder, 'AMT103', condName);
    if ~exist(subOutFolder, 'dir')
        mkdir(subOutFolder);
    end
    
    % บันทึกรูปกราฟลงโฟลเดอร์ย่อย
    saveName = sprintf('AMT103_%s_Dark.png', condName);
    exportgraphics(fig, fullfile(subOutFolder, saveName), 'Resolution', 300);
    fprintf('   ✅ บันทึกกราฟ: OUTPUT_GRAPHS\\AMT103\\%s\\%s\n', condName, saveName);
end

fprintf('\n🎉 เสร็จเรียบร้อย! รูป AMT103 ถูกแยกเซฟลงโฟลเดอร์ตามเงื่อนไขเรียบร้อยครับ\n');

function [t, y] = readEncoderSignal(filePath)
    t = []; y = [];
    try
        S = load(filePath); fn = fieldnames(S);
        if isempty(fn), return; end
        firstVar = S.(fn{1});
        if isa(firstVar, 'timeseries')
            t = firstVar.Time; y = firstVar.Data;
        elseif isa(firstVar, 'Simulink.SimulationData.Dataset')
            elem = firstVar.getElement(1);
            if isa(elem.Values, 'timeseries')
                t = elem.Values.Time; y = elem.Values.Data;
            end
        elseif isstruct(firstVar) && isfield(firstVar, 'signals')
            if isfield(firstVar, 'time') && ~isempty(firstVar.time), t = firstVar.time;
            else, t = (0:length(firstVar.signals(1).values)-1)'; end
            y = firstVar.signals(1).values;
        elseif isnumeric(firstVar)
            y = double(firstVar(:)); t = (0:length(y)-1)';
        end
    catch; end
end