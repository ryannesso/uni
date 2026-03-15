f = @testfn3c;
d = 1;
x0 = -1000 + 2000 * rand(1, 2);

[X, Y] = meshgrid(linspace(-1000, 1000, 100), linspace(-1000, 1000, 100));
Z = zeros(size(X));
for i = 1:numel(X), Z(i) = f([X(i), Y(i)]); end

figure('Color', 'w');
contour(X, Y, Z, 20); 
colorbar;
hold on; grid on;
xlabel('x1'); ylabel('x2');
title('2D optimalizácia - Kontúrový graf');

path_x = x0(1); path_y = x0(2);
h_path = plot(path_x, path_y, 'k-', 'LineWidth', 1.5);
h_point = plot(x0(1), x0(2), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 6);

for step = 1:1000
    y_curr = f(x0);

    x_l = x0(1) - d; if x_l < -1000, x_l = -1000; end
    x_r = x0(1) + d; if x_r > 1000, x_r = 1000; end
    y_d = x0(2) - d; if y_d < -1000, y_d = -1000; end
    y_u = x0(2) + d; if y_u > 1000, y_u = 1000; end

    y_l = f([x_l, x0(2)]);
    y_r = f([x_r, x0(2)]);
    y_dn = f([x0(1), y_d]);
    y_up = f([x0(1), y_u]);

    best_y = y_curr;
    next_x = x0;

    if y_l < best_y, best_y = y_l; next_x = [x_l, x0(2)]; end
    if y_r < best_y, best_y = y_r; next_x = [x_r, x0(2)]; end
    if y_dn < best_y, best_y = y_dn; next_x = [x0(1), y_d]; end
    if y_up < best_y, best_y = y_up; next_x = [x0(1), y_u]; end

    if best_y < y_curr
        x0 = next_x;
        path_x = [path_x, x0(1)]; 
        path_y = [path_y, x0(2)]; 
        set(h_path, 'XData', path_x, 'YData', path_y);
        set(h_point, 'XData', x0(1), 'YData', x0(2));
        drawnow limitrate;
    else
        break;
    end
end

plot(x0(1), x0(2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
fprintf('Final x: %.2f, y: %.2f | f(x,y): %.2f\n', x0(1), x0(2), f(x0));