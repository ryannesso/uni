function fitness = calculate_fitness(pop, coords)
    [rows, ~] = size(pop);
    fitness = zeros(rows, 1);
    for i = 1:rows
        route = coords(pop(i, :), :);
        diffs = diff(route);
        dists = sqrt(sum(diffs.^2, 2));
        fitness(i) = sum(dists);
    end
end