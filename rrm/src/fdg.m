clear; clc; close all;

%% Настройки путей (проверьте, что пути совпадают с C++ кодом)
joint_log_path = '/tmp/cv8_traj_joint_log.csv';
tool_log_path = '/tmp/cv8_traj_tool_log.csv';

%% 1. Визуализация данных сустава (Joint Log)
if exist(joint_log_path, 'file')
    joint_data = readtable(joint_log_path);
    
    figure('Name', 'Анализ движения сустава', 'Color', 'w');
    
    % График Позиции (q)
    subplot(3, 1, 1);
    plot(joint_data.t, joint_data.q, 'LineWidth', 1.5, 'Color', [0 0.4470 0.7410]);
    grid on; ylabel('Позиция [рад]'); title('Параметры выбранного сустава');
    
    % График Скорости (qd)
    subplot(3, 1, 2);
    plot(joint_data.t, joint_data.qd, 'LineWidth', 1.5, 'Color', [0.8500 0.3250 0.0980]);
    grid on; ylabel('Скорость [рад/с]');
    
    % График Ускорения (qdd)
    subplot(3, 1, 3);
    plot(joint_data.t, joint_data.qdd, 'LineWidth', 1.5, 'Color', [0.4660 0.6740 0.1880]);
    grid on; ylabel('Ускорение [рад/с^2]'); xlabel('Время [с]');
else
    fprintf('Файл лога суставов не найден: %s\n', joint_log_path);
end

%% 2. Визуализация траектории инструмента (Tool Log)
if exist(tool_log_path, 'file')
    tool_data = readtable(tool_log_path);
    
    % Преобразуем строковую колонку 'motion' в категории для удобства
    tool_data.motion = categorical(tool_data.motion);
    motions = categories(tool_data.motion);
    
    figure('Name', 'Траектория TCP (Инструмента)', 'Color', 'w');
    hold on; grid on; axis equal;
    
    % Цветовая карта для разных типов движения (согласно логике C++ кода)
    % ptp - синий, approach/retract - красный, machining - зеленый
    colors = struct('ptp', [0 0.4 1], ...
                    'approach', [1 0.1 0.1], ...
                    'machining', [0.1 1 0.1], ...
                    'retract', [1 0.5 0], ...
                    'transition', [0.5 0 0.8]);

    % Рисуем траекторию по сегментам, чтобы раскрасить их
    unique_motions = unique(tool_data.motion);
    for i = 1:length(unique_motions)
        m_type = unique_motions(i);
        mask = (tool_data.motion == m_type);
        
        % Находим индексы, чтобы рисовать точки (scatter) или линии
        % Для линий в MATLAB лучше использовать проверку смены типа движения
        plot3(tool_data.x(mask), tool_data.y(mask), tool_data.z(mask), ...
            '.', 'MarkerSize', 8, 'DisplayName', char(m_type));
    end
    
    xlabel('X [м]'); ylabel('Y [м]'); zlabel('Z [м]');
    title('3D Траектория кончика инструмента (TCP)');
    legend('Location', 'bestoutside');
    view(3); % Установить 3D вид
    
    % Дополнительно: график XYZ от времени
    figure('Name', 'Координаты инструмента от времени', 'Color', 'w');
    plot(tool_data.t, [tool_data.x, tool_data.y, tool_data.z], 'LineWidth', 1.5);
    grid on; legend('X', 'Y', 'Z');
    xlabel('Время [с]'); ylabel('Позиция [м]');
    title('Изменение декартовых координат');
else
    fprintf('Файл лога инструмента не найден: %s\n', tool_log_path);
end