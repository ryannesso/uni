function Fit = fitnessDeathPenalty(Pop)

    penalty = 1e10;
    
    popSize = size(Pop, 1);
    
    Fit = zeros(popSize, 1);

    for i = 1:popSize
        x = Pop(i, :); 

        J = 0.04*x(1) + 0.07*x(2) + 0.11*x(3) + 0.06*x(4) + 0.05*x(5);
        
        % Convert to minimization
        Fit(i) = -J; 

        if (x(1) + x(2) + x(3) + x(4) + x(5) > 10000000) || ...
           (x(1) + x(2) > 2500000) || ...
           (-x(4) + x(5) > 0) || ...
           (-0.5*x(1) - 0.5*x(2) + 0.5*x(3) + 0.5*x(4) - 0.5*x(5) > 0)
            
            Fit(i) = penalty;
        end
    end
end
