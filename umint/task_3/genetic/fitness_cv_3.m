function fitness = fitness(P, B)
    
    [numChromosomes, numCities] = size(P); 
    fitness = zeros(numChromosomes, 1);

    for i = 1:numChromosomes
        chromosome = P(i, :);
        totalDist = 0;
        
        for j = 1:numCities-1
            point1 = B(chromosome(j), :);  % Get coordinates of point j
            point2 = B(chromosome(j+1), :); % Get coordinates of next point
            totalDist = totalDist + sqrt(sum((point1 - point2).^2)); % Euclidean distance
        end
        
        fitness(i) = totalDist; % Fitness is inverse of total distance (minimize distance)
    end
end
