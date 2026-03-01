nVar = 10;
popSize = 50;
maxGen = 1000;
mutRate = 0.02;

runs = 5;
figure;
hold on;

for run = 1:runs 
    Space = [repmat(-500,1,nVar); repmat(500,1,nVar)];
    elitismCnt = 2;

    %init population
    population = genrpop(popSize, Space);
    bestFitness = zeros(1, maxGen);

    for gen = 1:maxGen
        fitness = eggholder(population);
        bestFitness(gen) = min(fitness);

        Nums = ones(1, elitismCnt);
        [ParentsBest, ~] = selbest(population, fitness, Nums);
        numExtra = size(population, 1) - elitismCnt;
        [ParentsExtra, ~] = seltourn(population, fitness, numExtra);

        offSpring = crossov(ParentsExtra, 2, 0);

        Amp = repmat(1600 * 0.05, 1, nVar);

        offSpring = mutx(offSpring, mutRate, Space);
        offSpring = muta(offSpring, mutRate, Amp, Space);

        finalPopulation = [ParentsBest; offSpring];
        population = finalPopulation;
    end
    fitness = eggholder(population);
    [~, bestIdx] = min(fitness);
    bestSolution = population(bestIdx, :);
    plot(1:maxGen, bestFitness, 'r');
end

xlabel('generations');
ylabel('fitnes value');
title('evolution of fitness over multiple runs');
hold off;
