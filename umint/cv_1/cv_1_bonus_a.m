f = @testfn3c;
d = 5;
best_min = inf;
best_x = 0;

fplot(f, [-1000, 1000], 'k'); 
hold on; grid on;

current_x = -1000 + 2000 * rand();

for step = 1:1000
    current_y = f(current_x);
    plot(current_x, current_y, 'r.');
    drawnow limitrate;

    y_l = f(max(-1000, current_x - d));
    y_r = f(min(1000, current_x + d));

    if y_l < current_y && y_l <= y_r
        current_x = max(-1000, current_x - d);
    elseif y_r < current_y
        current_x = min(1000, current_x + d);
    else
        if current_y < best_min
            best_min = current_y;
            best_x = current_x;
        end
        current_x = -1000 + 2000 * rand();
    end
end

plot(best_x, best_min, 'go', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'LineWidth', 2);

fprintf("minimum y: %.2f \n", best_min);
fprintf("best x: %.2f \n", best_x);
fprintf("total steps: %d \n", step);