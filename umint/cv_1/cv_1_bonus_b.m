f = @testfn3c;
d = 10;
x0 = -1000 + 2000 * rand(1, 2);

[X, Y] = meshgrid(linspace(-1000, 1000, 150), linspace(-1000, 1000, 150));
Z = zeros(size(X));
for i = 1:numel(X), Z(i) = f([X(i), Y(i)]); end

figure('Color', 'w');
s = surfc(X, Y, Z);
s(1).EdgeColor = 'none';
s(1).FaceAlpha = 0.6; 
shading interp; 
colormap jet; 
hold on; 
view(-30, 45);
camlight; 
lighting gouraud;

path_x = x0(1); path_y = x0(2); path_z = f(x0);
h_path = plot3(path_x, path_y, path_z + 20, 'k-', 'LineWidth', 2);
h_point = plot3(x0(1), x0(2), path_z + 20, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

for step = 1:1000
    y_curr = f(x0);
    nb = [x0(1)-d, x0(2); x0(1)+d, x0(2); x0(1), x0(2)-d; x0(1), x0(2)+d];
    y_nb = [f(nb(1,:)); f(nb(2,:)); f(nb(3,:)); f(nb(4,:))];
    [b_min, idx] = min(y_nb);

    if b_min < y_curr
        x0 = nb(idx, :);
        path_x = [path_x, x0(1)];
        path_y = [path_y, x0(2)];
        path_z = [path_z, f(x0)];
        set(h_path, 'XData', path_x, 'YData', path_y, 'ZData', path_z + 20);
        set(h_point, 'XData', x0(1), 'YData', x0(2), 'ZData', f(x0) + 20);
        drawnow limitrate;
    else
        break;
    end
end

plot3(x0(1), x0(2), f(x0) + 20, 'go', 'MarkerSize', 12, 'MarkerFaceColor', 'g');