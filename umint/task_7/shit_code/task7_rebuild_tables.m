function exports = task7_rebuild_tables(outDir)
%TASK7_REBUILD_TABLES Re-export all CSV tables from saved .mat results.
%   exports = task7_rebuild_tables(outDir)
% Loads mlp_results.mat and cnn_results.mat in outDir and rewrites the same
% CSV tables (Table 1-13 + per-model run tables) without any retraining.

if nargin < 1 || isempty(outDir)
    error('outDir is required');
end
outDir = char(outDir);

mlpMat = fullfile(outDir, 'mlp_results.mat');
cnnMat = fullfile(outDir, 'cnn_results.mat');

if exist(mlpMat, 'file') ~= 2
    error('Missing %s', mlpMat);
end
if exist(cnnMat, 'file') ~= 2
    error('Missing %s', cnnMat);
end

S = load(mlpMat, 'mlp_results');
mlp_results = S.mlp_results;
S = load(cnnMat, 'cnn_results');
cnn_results = S.cnn_results;

exports = struct();
exports.outDir = outDir;

% ---------- MLP ----------
mlpModelsCsv = fullfile(outDir, 'table1_mlp_models_hyperparams.csv');
t1_mlp = mlp_results.hyperparamModels;
t1_mlp.Properties.VariableNames = {'Model','Skryte_vrstvy','Neurony','Epochy','LR','Batch'};
writetable(t1_mlp, mlpModelsCsv);

mlpCsv = fullfile(outDir, 'table4_mlp_summary.csv');
t4_mlp = mlp_results.structureSummary;
t4_mlp.Properties.VariableNames = {'Model','Min_test_acc_pct','Max_test_acc_pct','Priemer_test_acc_pct','Priemer_test_loss'};
writetable(t4_mlp, mlpCsv);

mlpRunsCsv = fullfile(outDir, 'mlp_run_results_all_models.csv');
writetable(mlp_results.runResults, mlpRunsCsv);

mlpModels = unique(mlp_results.runResults.Model);
for i = 1:numel(mlpModels)
    m = mlpModels(i);
    t = mlp_results.runResults(mlp_results.runResults.Model == m, :);
    t = t(:, {'Run','TrainLoss','TestLoss','TrainAccPct','TestAccPct'});
    t.Properties.VariableNames = {'Beh','Train_loss','Test_loss','Train_acc_pct','Test_acc_pct'};
    safeName = matlab.lang.makeValidName(char(m));
    perModelCsv = fullfile(outDir, sprintf('table2_3_mlp_runs_%s.csv', safeName));
    writetable(t, perModelCsv);
end

mlpHpCsv = fullfile(outDir, 'mlp_hyperparams_runtime.csv');
writetable(mlp_results.hyperparams, mlpHpCsv);

mlpTimingCsv = fullfile(outDir, 'mlp_timing.csv');
writetable(struct2table(mlp_results.timing), mlpTimingCsv);

% ---------- CNN ----------
cnnModelsCsv = fullfile(outDir, 'table5_cnn_models_hyperparams.csv');
t5_cnn = cnn_results.archHyperparams;
t5_cnn.Properties.VariableNames = {'Model','Conv_vrstvy','Filtre','FC_vrstvy','Epochy','Batch'};
writetable(t5_cnn, cnnModelsCsv);

cnnArchCsv = fullfile(outDir, 'table9_cnn_summary.csv');
t9_cnn = cnn_results.archSummary;
t9_cnn.Properties.VariableNames = {'Model','Min_test_acc_pct','Max_test_acc_pct','Priemer_test_acc_pct','Priemer_test_loss'};
writetable(t9_cnn, cnnArchCsv);

cnnArchRunsCsv = fullfile(outDir, 'cnn_architecture_run_results_all_models.csv');
writetable(cnn_results.archRunResults, cnnArchRunsCsv);

cnnModels = unique(cnn_results.archRunResults.Model);
for i = 1:numel(cnnModels)
    m = cnnModels(i);
    t = cnn_results.archRunResults(cnn_results.archRunResults.Model == m, :);
    t = t(:, {'Run','TrainLoss','TestLoss','TrainAccPct','TestAccPct'});
    t.Properties.VariableNames = {'Beh','Train_loss','Test_loss','Train_acc_pct','Test_acc_pct'};
    safeName = matlab.lang.makeValidName(char(m));
    perModelCsv = fullfile(outDir, sprintf('table6_8_cnn_runs_%s.csv', safeName));
    writetable(t, perModelCsv);
end

cnnDropCsv = fullfile(outDir, 'table11_dropout_mean_summary.csv');
t11 = cnn_results.dropoutMeanSummary;
t11.Properties.VariableNames = {'Dropout','Pocet_behov','Priemer_train_acc_pct','Priemer_test_acc_pct','Priemer_test_loss'};
writetable(t11, cnnDropCsv);

cnnDropOverfitCsv = fullfile(outDir, 'table10_dropout_overfit.csv');
t10 = cnn_results.dropoutOverfitSummary;
t10.Properties.VariableNames = {'Model','Dropout','Pocet_behov','Priemer_epochy_zaciatku_pretrenovania','Priemer_val_loss'};
writetable(t10, cnnDropOverfitCsv);

cnnDropRunsCsv = fullfile(outDir, 'cnn_dropout_run_results_all.csv');
writetable(cnn_results.dropoutRunResults, cnnDropRunsCsv);

cnnHpCsv = fullfile(outDir, 'cnn_hyperparams_runtime.csv');
writetable(cnn_results.hyperparams, cnnHpCsv);

cnnTimingCsv = fullfile(outDir, 'cnn_timing.csv');
writetable(struct2table(cnn_results.timing), cnnTimingCsv);

% ---------- Combined ----------
combined = table(
    {char(mlp_results.best.name)}, mlp_results.best.meanTestAcc * 100, ...
    {char(cnn_results.best.name)}, cnn_results.best.meanTestAcc * 100, ...
    'VariableNames', {'BestMLP','BestMLP_MeanTestAccPct','BestCNN','BestCNN_MeanTestAccPct'});
combinedCsv = fullfile(outDir, 'combined_best_summary.csv');
writetable(combined, combinedCsv);

% Table 12
table12 = table(
    {'MLP'; 'CNN'}, ...
    [height(mlp_results.structureSummary); height(cnn_results.archSummary)], ...
    [mean(mlp_results.structureSummary.MeanTestAccPct); mean(cnn_results.archSummary.MeanTestAccPct)], ...
    [mean(mlp_results.structureSummary.MeanTestLoss); mean(cnn_results.archSummary.MeanTestLoss)], ...
    'VariableNames', {'Pristup','Pocet_modelov','Priemer_test_acc_pct','Priemer_test_loss'});

table12Csv = fullfile(outDir, 'table12_mlp_vs_cnn.csv');
writetable(table12, table12Csv);

% Table 13
mlpCPU = mlp_results.timing.cpuSeconds;
mlpGPU = mlp_results.timing.gpuSeconds;
cnnCPU = cnn_results.timing.cpuSeconds;
cnnGPU = cnn_results.timing.gpuSeconds;

speedup = @(cpu,gpu) cpu ./ gpu;

avgCPU = mean([mlpCPU; cnnCPU], 'omitnan');
avgGPU = mean([mlpGPU; cnnGPU], 'omitnan');

table13 = table(
    {char(mlp_results.best.name); char(cnn_results.best.name); 'Priemer'}, ...
    [mlpCPU; cnnCPU; avgCPU], ...
    [mlpGPU; cnnGPU; avgGPU], ...
    [speedup(mlpCPU, mlpGPU); speedup(cnnCPU, cnnGPU); speedup(avgCPU, avgGPU)], ...
    'VariableNames', {'Model','CPU_cas_s','GPU_cas_s','Zrychlenie'});

table13Csv = fullfile(outDir, 'table13_cpu_vs_gpu.csv');
writetable(table13, table13Csv);

exports.tables = struct(
    'table1', mlpModelsCsv, ...
    'table2_3_all', mlpRunsCsv, ...
    'table4', mlpCsv, ...
    'table5', cnnModelsCsv, ...
    'table6_8_all', cnnArchRunsCsv, ...
    'table9', cnnArchCsv, ...
    'table10', cnnDropOverfitCsv, ...
    'table11', cnnDropCsv, ...
    'table12', table12Csv, ...
    'table13', table13Csv);

fprintf('Rebuilt CSV tables in %s\n', outDir);
end
