function Pop = population(n, B)
    
    numCities = size(B, 1);
    Pop = zeros(n, numCities);

    fixedStart = 1; 
    fixedEnd = numCities;
    
    for i = 1:n
        % Shuffle (2 to 19)
        permOrder = randperm(numCities - 2) + 1;
        
        % Assign the fixed start and end points
        Pop(i, :) = [fixedStart, permOrder, fixedEnd];
    end
end
