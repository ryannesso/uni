clc; clear; close all;

B = [
    0, 0;   17, 100; 51, 15; 70, 62; 42, 25; 
    32, 17; 51, 64;  39, 45; 68, 89; 20, 19; 
    12, 87; 80, 37;  35, 82; 2, 15;  38, 95; 
    33, 50; 85, 52;  97, 27; 99, 10; 37, 67; 
    20, 82; 49, 0;   62, 14; 7, 60;  0, 0
];

popSize = 100;      
elitismCount = 5; 
mutationRate = 0.1;
numGenerations = 1500;
numRuns = 10;

allRunsFitness = zeros(numGenerations, numRuns);
globalBestFitness = inf;
globalBestRoute = [];

fprintf('starting calculations (10 runs)...\n');

for runs = 1:numRuns
    Pop = population(popSize, B);
    
    for gen = 1:numGenerations
        fitnessValues = fitness_cv_3(Pop, B);
    
        [currentMin, bestIdx] = min(fitnessValues);
        allRunsFitness(gen, runs) = currentMin;
        
        if currentMin < globalBestFitness
            globalBestFitness = currentMin;
            globalBestRoute = Pop(bestIdx, :);
        end
    
        Nums = ones(1, elitismCount);
        [BestPop, BestFit] = selbest(Pop, fitnessValues, Nums);
        BestFit = BestFit(:);
    
        remainingCount = popSize - elitismCount;
        [SelectedPop, ~] = seltourn(Pop, fitnessValues, remainingCount);
    
        NewPop = crosord(SelectedPop, 0); 
        NewPop(:, 2:end-1) = swappart(NewPop(:, 2:end-1), mutationRate);
        NewPop(:, 2:end-1) = swapgen(NewPop(:, 2:end-1), 0.01);
        NewPop(:, 2:end-1) = invord(NewPop(:, 2:end-1), 0.3);

        NewFit = fitness_cv_3(NewPop, B);
    
        Pop = [BestPop; NewPop];
    end
    fprintf('run %d finished. best fitness: %.4f\n', runs, allRunsFitness(end, runs));
end

fprintf('\n==================== results ====================\n');
fprintf('absolute best route length: %.6f\n', globalBestFitness);

successRuns = sum(allRunsFitness(end, :) <= 480);
fprintf('number of successful runs (<= 480): %d of %d\n', successRuns, numRuns);

fprintf('\nbest route sequence (point indices):\n');
fprintf('%d ', globalBestRoute);
fprintf('\n');

fprintf('\nbest route coordinates:\n');
disp(B(globalBestRoute, :));

figure('Color', 'w');
hold on;
avgFitness = mean(allRunsFitness, 2);
hRuns = plot(allRunsFitness, 'Color', [0.7 0.7 0.7], 'LineWidth', 1.8);
hAvg = plot(avgFitness, 'r', 'LineWidth', 3);
xlabel('generation');
ylabel('best fitness (length)');
title('fitness vs generation (all runs and average)');
legend([hRuns(1), hAvg], {'individual runs', 'average convergence'}, 'location', 'northeast');
grid on;

figure('Color', 'w');
hold on;
scatter(B(:,1), B(:,2), 40, 'blue', 'filled'); 
text(B(:,1) + 1, B(:,2) + 1, string(1:size(B,1)), 'FontSize', 9);

orderedCoords = B(globalBestRoute, :);
plot(orderedCoords(:,1), orderedCoords(:,2), 'g-', 'LineWidth', 2);

scatter(B(1,1), B(1,2), 100, 'red', 'square', 'LineWidth', 2);

title(['best route found (length: ' num2str(globalBestFitness) ')']);
xlabel('x'); 
ylabel('y');
grid on;
hold off;