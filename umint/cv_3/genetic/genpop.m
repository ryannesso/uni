% -------- vlastne funkcie --------
function pop = genpop(popsize, gensize)
    pop = zeros(popsize, gensize);
    for i = 1:popsize
        mid = randperm(gensize - 2) + 1; % 2..gensize-1
        pop(i, :) = [1, mid, gensize];   % 1 a gensize
    end
end