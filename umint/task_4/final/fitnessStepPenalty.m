function Fit = fitnessStepPenalty(Pop)
    % Penalty constant
    p = 10^4; 
    
    % Population size
    popSize = size(Pop, 1);
    
    % Fitness array
    Fit = zeros(popSize, 1);

    for i = 1:popSize
        x = Pop(i, :); 

        % Compute the objective function
        J = 0.04*x(1) + 0.07*x(2) + 0.11*x(3) + 0.06*x(4) + 0.05*x(5);

        % Initialize penalty counter (σ = number of violated constraints)
        sigma = 0;

        % Constraint Checks
        if (x(1) + x(2) + x(3) + x(4) + x(5) > 10000000)
            sigma = sigma + 1;
        end
        if (x(1) + x(2) > 2500000)
            sigma = sigma + 1;
        end
        if (-x(4) + x(5) > 0)
            sigma = sigma + 1;
        end
        if (-0.5*x(1) - 0.5*x(2) + 0.5*x(3) + 0.5*x(4) - 0.5*x(5) > 0)
            sigma = sigma + 1;
        end

        %penalty = sigma * p;  % Option 1: Linear step penalty
        penalty = p^sigma;  % Option 2: Exponential step penalty
        
        Fit(i) = -J + penalty;
    end
end
