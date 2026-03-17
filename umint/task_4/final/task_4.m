clc; clear; close all;

params.nVar = 5;
params.popSize = 50;
params.maxGen = 600;
params.mutRate = 0.2;
params.elitismCount = 5;
params.numRuns = 5;

penaltyMethods = {
    @fitnessDeathPenalty, 'Death Penalty';
    @fitnessStepPenalty, 'Step Penalty';
    @fitnessModeratePenalty, 'Moderate Penalty'
};

BestHistoryData = struct();

for i = 1:size(penaltyMethods, 1)
    figure(i); 
    hold on;
    bestHistory = main(penaltyMethods{i, 1}, penaltyMethods{i, 2}, params);
    BestHistoryData.(['m', num2str(i)]) = bestHistory; 
    hold off;
end

figure(4); hold on;
plot(1:params.maxGen, -BestHistoryData.m1, 'r', 'LineWidth', 1.5);
plot(1:params.maxGen, -BestHistoryData.m2, 'g', 'LineWidth', 1.5);
plot(1:params.maxGen, -BestHistoryData.m3, 'b', 'LineWidth', 1.5);
xlabel('Generation'); ylabel('Best Fitness (Profit)');
title('Comparison of Best Runs');
legend('Death Penalty', 'Step Penalty', 'Moderate Penalty');
grid on;

function [bestHistory] = main(fitnessFunction, methodName, p)
    Space = [zeros(1, p.nVar); repmat(2500000, 1, p.nVar)];
    
    globalBestFitness = Inf;
    globalBestSolution = [];
    bestHistory = zeros(1, p.maxGen);
    
    for run = 1:p.numRuns
        Pop = genrpop(p.popSize, Space);
        currentRunHistory = zeros(1, p.maxGen);
        
        for gen = 1:p.maxGen
            Fit = fitnessFunction(Pop);
            currentRunHistory(gen) = min(Fit);
            
            [ParentsBest, ~] = selbest(Pop, Fit, ones(1, p.elitismCount));
            [ParentsExtra, ~] = seltourn(Pop, Fit, p.popSize - p.elitismCount);
            
            Offspring = crossov(ParentsExtra, 2, 0);
            Offspring = mutx(Offspring, p.mutRate, Space);
            Offspring = muta(Offspring, p.mutRate, repmat(2500000 * 0.1, 1, p.nVar), Space);
            
            Pop = [ParentsBest; Offspring];
        end
        
        Fit = fitnessFunction(Pop);
        [runBestFitness, bestIdx] = min(Fit);
        
        if runBestFitness < globalBestFitness
            globalBestFitness = runBestFitness;
            globalBestSolution = Pop(bestIdx, :);
            bestHistory = currentRunHistory; 
        end
        
        plot(1:p.maxGen, -currentRunHistory, 'LineWidth', 1);
    end
    
    xlabel('Generation');
    ylabel('Best Fitness (Profit)');
    title(['Fitness Evolution - ', methodName]);
    grid on;
    
    fprintf('\n==================== FINAL RESULTS (%s) ====================\n', methodName);
    fprintf('Final Best Fitness (Profit): %.6f\n', -globalBestFitness);
    fprintf('Final Best Investment Allocation:\n');
    disp(globalBestSolution);
end