nVar = 10;
popSize = 50;
maxGen = 350;
mutRate = 0.01;

runs = 5;
figure;
hold on; grid on; 

colors = ['r', 'g', 'b', 'k', 'm']; 

for run = 1:runs 
    Space = [repmat(-1000,1,nVar); repmat(1000,1,nVar)];
    elitismCnt = 10;

    %init population
    population = genrpop(popSize, Space);
    bestFitness = zeros(1, maxGen);

    for gen = 1:maxGen
        fitness = testfn3c(population);
        [currentMin, minIdx] = min(fitness);
        bestFitness(gen) = currentMin;

        Nums = ones(1, elitismCnt);
        [ParentsBest, ~] = selbest(population, fitness, Nums);
        numExtra = size(population, 1) - elitismCnt;
        [ParentsExtra, ~] = seltourn(population, fitness, numExtra);
        population = change(population, 2, Space);

        offSpring = crossov(ParentsExtra, 2, 0);
        %offSpring = intmedx(ParentsExtra, 1.25);
        %offSpring = around(ParentsExtra, 0, 1.25, Space);
        Amp = repmat(1600 * 0.05, 1, nVar);

        offSpring = mutx(offSpring, mutRate, Space);
        offSpring = muta(offSpring, mutRate, Amp, Space);

        finalPopulation = [ParentsBest; offSpring];
        population = finalPopulation;
    end
    
    plot(1:maxGen, bestFitness, colors(run), 'LineWidth', 1.2); 
    fprintf('Beh %d: Najlepšie fitness = %.4f\n', run, bestFitness(end));
end

xlabel('generations');
ylabel('fitness value');
title('evolution of fitness over multiple runs');
legend('Run 1', 'Run 2', 'Run 3', 'Run 4', 'Run 5'); 
hold off;
