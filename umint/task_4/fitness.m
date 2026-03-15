function fits = fitness(pop, method)
    [pop_size, ~] = size(pop);
    fits = zeros(pop_size, 1);
    
    for i = 1:pop_size
        x = pop(i, :);
        
        % 1. Доходность
        yield = 0.04*x(1) + 0.07*x(2) + 0.11*x(3) + 0.06*x(4) + 0.05*x(5);
        
        % 2. Нарушения
        s = sum(x);
        v(1) = max(0, s - 10000000);                      % Бюджет
        v(2) = max(0, (x(1)+x(2)) - 2500000);              % Акции
        v(3) = max(0, x(5) - x(4));                        % Облигации vs Банк
        v(4) = max(0, (x(3) + x(4)) - 0.5 * s);            % Доля облигаций
        v(5) = sum(max(0, -x));                            % Неотрицательность
        
        total_v = sum(v);
        num_v = sum(v > 0);
        
        % 3. Выбор штрафа
        switch method
            case 'mrtva'
                penalty = (total_v > 0) * 10e6;
            case 'stupnovita'
                penalty = num_v * 10e6;
            case 'umerna'
                penalty = total_v * 20; % Коэффициент 20
        end
        
        fits(i) = -yield + penalty;
    end
end

% Доп. функция для вывода чистого дохода


% Доп. функция для проверки нарушений
