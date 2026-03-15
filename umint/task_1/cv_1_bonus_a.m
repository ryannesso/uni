f = @testfn3c;
d = 10;
best_min = inf;
best_x = 0;

fplot(f, [-1000, 1000], 'k'); 
hold on; grid on;

current_x = -1000 + 2000 * rand();

for step = 1:1000
    current_y = f(current_x);
    
    plot(current_x, current_y, 'r.', 'MarkerSize', 10);
    drawnow limitrate;
    x_l = current_x - d;
    if x_l < -1000
        x_l = -1000;
    end
    x_r = current_x + d;
    if x_r > 1000 
        x_r = 1000;
    end
    
    y_l = f(x_l);
    y_r = f(x_r);

    if y_l < current_y && y_l <= y_r
        current_x = x_l;
    elseif y_r < current_y
        current_x = x_r;
    else
        if best_min > current_y
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
fprintf("d: %d \n", d);