clc; clear; close all;

% --- Параметры ---
invest_limit = 10^7;
popsize = 100;
maxGen = 600;      % Немного увеличим для лучшей сходимости
runs = 5;          % По заданию минимум 5
elitismCount = 3;
mutationRate = 0.1;

Space = [0, 0, 0, 0, 0;
         1e7, 1e7, 1e7, 1e7, 1e7];

% Список методов для тестирования
penalty_methods = {'mrtva', 'stupnovita', 'umerna'};
comparison_data = struct(); % Тут будем хранить лучшие прогоны для финального графика

for m = 1:length(penalty_methods)
    current_method = penalty_methods{m};
    fprintf('Тестирую метод: %s\n', current_method);
    
    all_runs_fitness = zeros(maxGen, runs);
    best_overall_fit = inf;
    best_overall_x = [];

    figure('Name', ['Метод: ' current_method]); hold on;
    
    for r = 1:runs
        % 1. Инициализация
        pop = genrpop(popsize, Space);
        best_in_gen = zeros(maxGen, 1);
        
        for gen = 1:maxGen
            % 2. Расчет фитнеса (передаем тип штрафа)
            fit_vals = fitness(pop, current_method);
            
            % Запоминаем лучшее в поколении
            [min_fit, idx] = min(fit_vals);
            best_in_gen(gen) = min_fit;
            
            % Сохраняем самое лучшее решение за все время
            if min_fit < best_overall_fit
                best_overall_fit = min_fit;
                best_overall_x = pop(idx, :);
            end
            
            % --- Генетические операторы (Genetic Toolbox) ---
            % Селекция
            best_indiv = selbest(pop, fit_vals, ones(1, elitismCount));
            parents = seltourn(pop, fit_vals, popsize - elitismCount);
            
            % Кроссовер (используем among или crossov)
            offspring = crossov(parents, 2, 0); 
            
            % Мутация (muta)
            amp = (Space(2,:) - Space(1,:)) * 0.1; % Амплитуда мутации 10% от диапазона
            offspring = muta(offspring, mutationRate, amp, Space);
            
            % Сборка новой популяции
            pop = [best_indiv; offspring];
            
            % Удаление дубликатов
            pop = change(pop, 2, Space);
        end
        
        all_runs_fitness(:, r) = best_in_gen;
        plot(best_in_gen, 'DisplayName', sprintf('Run %d (%.2f)', r, best_in_gen(end)));
    end
    
    % Оформление графика для текущего метода
    title(['Fitness convergence: ' current_method]);
    xlabel('Generácia'); ylabel('Fitness');
    legend('show'); grid on;
    
    % Сохраняем лучший прогон этого метода для финального сравнения
    [~, best_run_idx] = min(all_runs_fitness(end, :));
    comparison_data.(current_method) = all_runs_fitness(:, best_run_idx);
    
    % Вывод результатов в консоль
    fprintf('--- Результат для %s ---\n', current_method);
    disp('Лучшая аллокация (x1-x5):'); disp(best_overall_x);
    fprintf('Чистый доход: %.2f EUR\n', calc_yield(best_overall_x));
    fprintf('Нарушение ограничений (Violation): %.2f\n', v_sum(best_overall_x));
    fprintf('---------------------------\n');
end

% --- ФИНАЛЬНЫЙ СРАВНИТЕЛЬНЫЙ ГРАФИК ---
figure('Name', 'Porovnanie metod pokutovania'); hold on;
plot(comparison_data.mrtva, 'LineWidth', 2, 'DisplayName', 'Mŕtva');
plot(comparison_data.stupnovita, 'LineWidth', 2, 'DisplayName', 'Stupňovitá');
plot(comparison_data.umerna, 'LineWidth', 2, 'DisplayName', 'Úmerná');
title('Finálne porovnanie najlepších priebehov');
xlabel('Generácia'); ylabel('Fitness');
legend; grid on;