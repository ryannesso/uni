nVar = 100;
popSize = 50;  
maxGen = 1000;    
mutRate = 0.01; 
runs = 5;
Space = [repmat(-1000,1,nVar); repmat(1000,1,nVar)];

figure('Color', 'w');
hold on; grid on; 
colors = ['r', 'g', 'b', 'k', 'm'];

overallBestFit = inf;
overallBestX = [];

for run = 1:runs
    population = genrpop(popSize, Space);
    history = zeros(1, maxGen);
    
    fprintf('Spúšťam beh č. %d...\n', run);

    for gen = 1:maxGen
        fitness = testfn3c(population);
        [bestVal, bestIdx] = min(fitness);
        history(gen) = bestVal;
        
        if bestVal < overallBestFit
            overallBestFit = bestVal;
            overallBestX = population(bestIdx, :);
        end
    
        population = change(population, 2, Space);
    
        [~, sortIdx] = sort(fitness);
        elites = population(sortIdx(1:5), :);
    
        ParentsExtra = seltourn(population, fitness, popSize - 5);
    
        offSpring = crossov(ParentsExtra, 2, 0);
    
        ampVal = 500 * (1 - gen/maxGen)^3 + 0.5; 
        Amp = repmat(ampVal, 1, nVar);
    
        offSpring = mutx(offSpring, mutRate, Space);
        offSpring = muta(offSpring, mutRate, Amp, Space);
    
        population = [elites; offSpring];
    end
    
    plot(1:maxGen, history, colors(run), 'LineWidth', 1.2); 
end

title('100-D Schwefel (Optimized GA) - 5 Run Comparison');
xlabel('Generácie');
ylabel('Fitness');
legend('Beh 1', 'Beh 2', 'Beh 3', 'Beh 4', 'Beh 5');

fprintf('\n====================================================\n');
fprintf('VÝSLEDKY PRE SPRÁVU:\n');
fprintf('Najlepšie celkové fitness: %.4f\n', overallBestFit);
fprintf('Súradnice najlepšieho jedinca (prvých 5 génov): ');
disp(overallBestX(1:5));
fprintf('====================================================\n');