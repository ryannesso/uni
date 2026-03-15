f = @testfn3c;
d = 1;
x0 = -1000 + 2000 * rand(1, 3);

y_history = []; 

for step = 1:1000
    y_curr = f(x0);
    y_history = [y_history, y_curr];

    x_l = x0(1)-d; if x_l < -1000, x_l = -1000; end
    x_r = x0(1)+d; if x_r > 1000, x_r = 1000; end
    y_d = x0(2)-d; if y_d < -1000, y_d = -1000; end
    y_u = x0(2)+d; if y_u > 1000, y_u = 1000; end
    z_b = x0(3)-d; if z_b < -1000, z_b = -1000; end
    z_f = x0(3)+d; if z_f > 1000, z_f = 1000; end

    y_nb = [
        f([x_l, x0(2), x0(3)]);
        f([x_r, x0(2), x0(3)]);
        f([x0(1), y_d, x0(3)]);
        f([x0(1), y_u, x0(3)]);
        f([x0(1), x0(2), z_b]);
        f([x0(1), x0(2), z_f])
    ];
    
    nb_coords = [
        x_l, x0(2), x0(3);
        x_r, x0(2), x0(3);
        x0(1), y_d, x0(3);
        x0(1), y_u, x0(3);
        x0(1), x0(2), z_b;
        x0(1), x0(2), z_f
    ];

    best_y = y_curr;
    best_idx = 0;

    for i = 1:6
        if y_nb(i) < best_y
            best_y = y_nb(i);
            best_idx = i;
        end
    end

    if best_idx > 0
        x0 = nb_coords(best_idx, :);
    else
        break;
    end
end

figure('Color', 'w');
plot(y_history, 'LineWidth', 2, 'Color', 'b');
grid on;
xlabel('Iterácia (krok)');
ylabel('Hodnota funkcie F(x,y,z)');
title('Priebeh hodnoty funkcie v iteráciách (3D optimalizácia)');

fprintf('Final X: %.2f, Y: %.2f, Z: %.2f | f(x,y,z): %.2f\n', x0(1), x0(2), x0(3), f(x0));