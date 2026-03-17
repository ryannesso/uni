clc; clear; close all;

% Run Genetic Algorithm for Each Penalty Method
fprintf('\n=== Running GA with Death Penalty ===\n');
figure(1); % Assign a unique figure ID
main(@fitnessDeathPenalty, 'Death Penalty');

fprintf('\n=== Running GA with Step Penalty ===\n');
figure(2); % Assign another unique figure ID
main(@fitnessStepPenalty, 'Step Penalty');

fprintf('\n=== Running GA with Moderate Penalty ===\n');
figure(3); % Assign another unique figure ID
main(@fitnessModeratePenalty, 'Moderate Penalty');