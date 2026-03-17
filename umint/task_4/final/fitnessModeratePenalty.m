function Fit = fitnessModeratePenalty(Pop)
    % Constants
    c = 10^3; % Scaling factor
    b = 1;    % Exponent

    popSize = size(Pop, 1);
    
    Fit = zeros(popSize, 1);

    for i = 1:popSize
        x = Pop(i, :); 

        J = 0.04*x(1) + 0.07*x(2) + 0.11*x(3) + 0.06*x(4) + 0.05*x(5);

        penalty = 0;

        violation = (x(1) + x(2) + x(3) + x(4) + x(5)) - 10000000;
        if violation > 0
            penalty = penalty + c * (violation^b);
        end

        violation = (x(1) + x(2)) - 2500000;
        if violation > 0
            penalty = penalty + c * (violation^b);
        end

        violation = (-x(4) + x(5));
        if violation > 0
            penalty = penalty + c * (violation^b);
        end

        violation = (-0.5*x(1) - 0.5*x(2) + 0.5*x(3) + 0.5*x(4) - 0.5*x(5));
        if violation > 0
            penalty = penalty + c * (violation^b);
        end

        Fit(i) = -J + penalty;
    end
end
