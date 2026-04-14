clc; close all;

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

% =========================================================
% Task 7 (UMINT): Run ALL (MLP + CNN) and export tables
% =========================================================

stamp = datestr(now, 'yyyymmdd_HHMMSS');
outDir = fullfile('results', ['task7_' stamp]);
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

fprintf('Output folder: %s\n', outDir);

% Reproducibility (different runs still differ, but the whole experiment is repeatable)
rng(42, 'twister');

% -----------------
% Run MLP
% -----------------
mlp_opts = struct();
mlp_opts.numRuns = 5;
mlp_opts.structures = {[128], [256 128]};
mlp_opts.names = {'MLP1', 'MLP2'};
mlp_opts.epochs = 20;
mlp_opts.initialLearnRate = 1e-3;
mlp_opts.miniBatchSize = 64;
mlp_opts.regularization = 1e-4;
mlp_opts.validationPatience = 5;
mlp_opts.useGPU = true;
mlp_opts.doTiming = true;
mlp_opts.timingEpochs = 5;
mlp_opts.outDir = outDir;
mlp_opts.saveFigures = true;
mlp_opts.closeFiguresAfterSave = true;
mlp_opts.figureResolution = 300;
mlp_opts.saveBestArtifacts = true;

mlp_results = task7mlp_run(mlp_opts);

% Export MLP tables
mlpModelsCsv = fullfile(outDir, 'table1_mlp_models_hyperparams.csv');
t1_mlp = mlp_results.hyperparamModels;
t1_mlp.Properties.VariableNames = {'Model','Skryte_vrstvy','Neurony','Epochy','LR','Batch'};
writetable(t1_mlp, mlpModelsCsv);

mlpCsv = fullfile(outDir, 'table4_mlp_summary.csv');
t4_mlp = mlp_results.structureSummary;
t4_mlp.Properties.VariableNames = {'Model','Min_test_acc_pct','Max_test_acc_pct','Priemer_test_acc_pct','Priemer_test_loss'};
writetable(t4_mlp, mlpCsv);

% Tables 2-3: per-run results (one CSV per structure)
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

% Save full struct
save(fullfile(outDir, 'mlp_results.mat'), 'mlp_results', '-v7.3');

fprintf('Saved: %s\n', mlpCsv);
fprintf('Saved: %s\n', mlpRunsCsv);
fprintf('Saved: %s\n', mlpHpCsv);
fprintf('Saved: %s\n', mlpTimingCsv);
fprintf('Saved: %s\n', mlpModelsCsv);

% -----------------
% Run CNN
% -----------------
cnn_opts = struct();
cnn_opts.numRuns = 5;
cnn_opts.miniBatchSize = 64;
cnn_opts.initialLearnRate = 1e-3;
cnn_opts.maxEpochs = 15;
cnn_opts.validationPatience = 5;
cnn_opts.executionEnvironment = 'auto';
cnn_opts.variants = [1 2 3];
cnn_opts.variantNames = {'CNN1','CNN2','CNN3'};
cnn_opts.baseDropout = 0.0;
cnn_opts.dropoutRates = [0.0 0.3 0.5];
cnn_opts.doTiming = true;
cnn_opts.timingEpochs = 5;
cnn_opts.outDir = outDir;
cnn_opts.saveFigures = true;
cnn_opts.closeFiguresAfterSave = true;
cnn_opts.figureResolution = 300;
cnn_opts.saveBestArtifacts = true;

cnn_results = task7cnn_run(cnn_opts);

% Export CNN tables
cnnModelsCsv = fullfile(outDir, 'table5_cnn_models_hyperparams.csv');
t5_cnn = cnn_results.archHyperparams;
t5_cnn.Properties.VariableNames = {'Model','Conv_vrstvy','Filtre','FC_vrstvy','Epochy','Batch'};
writetable(t5_cnn, cnnModelsCsv);

cnnArchCsv = fullfile(outDir, 'table9_cnn_summary.csv');
t9_cnn = cnn_results.archSummary;
t9_cnn.Properties.VariableNames = {'Model','Min_test_acc_pct','Max_test_acc_pct','Priemer_test_acc_pct','Priemer_test_loss'};
writetable(t9_cnn, cnnArchCsv);

% Tables 6-8: per-run results (one CSV per architecture)
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

% Tables 10-11: dropout
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

% Save full struct
save(fullfile(outDir, 'cnn_results.mat'), 'cnn_results', '-v7.3');

fprintf('Saved: %s\n', cnnArchCsv);
fprintf('Saved: %s\n', cnnDropCsv);
fprintf('Saved: %s\n', cnnArchRunsCsv);
fprintf('Saved: %s\n', cnnDropRunsCsv);
fprintf('Saved: %s\n', cnnHpCsv);
fprintf('Saved: %s\n', cnnTimingCsv);
fprintf('Saved: %s\n', cnnModelsCsv);
fprintf('Saved: %s\n', cnnDropOverfitCsv);

% -----------------
% Combined quick summary
% -----------------
combined = table({char(mlp_results.best.name)}, mlp_results.best.meanTestAcc * 100, ...
    {char(cnn_results.best.name)}, cnn_results.best.meanTestAcc * 100, ...
    'VariableNames', {'BestMLP','BestMLP_MeanTestAccPct','BestCNN','BestCNN_MeanTestAccPct'});

combinedCsv = fullfile(outDir, 'combined_best_summary.csv');
writetable(combined, combinedCsv);

fprintf('Saved: %s\n', combinedCsv);

% Table 12: MLP vs CNN mean results
table12 = table({'MLP'; 'CNN'}, ...
    [height(mlp_results.structureSummary); height(cnn_results.archSummary)], ...
    [mean(mlp_results.structureSummary.MeanTestAccPct); mean(cnn_results.archSummary.MeanTestAccPct)], ...
    [mean(mlp_results.structureSummary.MeanTestLoss); mean(cnn_results.archSummary.MeanTestLoss)], ...
    'VariableNames', {'Pristup','Pocet_modelov','Priemer_test_acc_pct','Priemer_test_loss'});

table12Csv = fullfile(outDir, 'table12_mlp_vs_cnn.csv');
writetable(table12, table12Csv);
fprintf('Saved: %s\n', table12Csv);

% Table 13: CPU vs GPU timing summary
mlpCPU = mlp_results.timing.cpuSeconds;
mlpGPU = mlp_results.timing.gpuSeconds;
cnnCPU = cnn_results.timing.cpuSeconds;
cnnGPU = cnn_results.timing.gpuSeconds;

speedup = @(cpu,gpu) cpu ./ gpu;

avgCPU = mean([mlpCPU; cnnCPU], 'omitnan');
avgGPU = mean([mlpGPU; cnnGPU], 'omitnan');

table13 = table({char(mlp_results.best.name); char(cnn_results.best.name); 'Priemer'}, ...
    [mlpCPU; cnnCPU; avgCPU], ...
    [mlpGPU; cnnGPU; avgGPU], ...
    [speedup(mlpCPU, mlpGPU); speedup(cnnCPU, cnnGPU); speedup(avgCPU, avgGPU)], ...
    'VariableNames', {'Model','CPU_cas_s','GPU_cas_s','Zrychlenie'});

table13Csv = fullfile(outDir, 'table13_cpu_vs_gpu.csv');
writetable(table13, table13Csv);
fprintf('Saved: %s\n', table13Csv);

% Save one bundle with everything needed to rebuild tables later
meta = struct();
meta.timestamp = stamp;
meta.matlabVersion = version;
try
    meta.ver = ver;
catch
    meta.ver = [];
end

exports = struct();
exports.outDir = outDir;
exports.tables = struct(
    'table1_mlp_models_hyperparams', mlpModelsCsv, ...
    'table2_3_mlp_runs_all', mlpRunsCsv, ...
    'table4_mlp_summary', mlpCsv, ...
    'table5_cnn_models_hyperparams', cnnModelsCsv, ...
    'table6_8_cnn_runs_all', cnnArchRunsCsv, ...
    'table9_cnn_summary', cnnArchCsv, ...
    'table10_dropout_overfit', cnnDropOverfitCsv, ...
    'table11_dropout_mean_summary', cnnDropCsv, ...
    'table12_mlp_vs_cnn', table12Csv, ...
    'table13_cpu_vs_gpu', table13Csv);

bundlePath = fullfile(outDir, 'task7_bundle.mat');
save(bundlePath, 'mlp_results', 'cnn_results', 'mlp_opts', 'cnn_opts', 'exports', 'meta', '-v7.3');
fprintf('Saved: %s\n', bundlePath);

% -----------------
% Auto-generate report (HTML, optional PDF)
% -----------------
try
    rep = task7_write_report(outDir);
    if ~isempty(rep.htmlPath)
        fprintf('Report (HTML): %s\n', rep.htmlPath);
    end
    if ~isempty(rep.pdfPath)
        fprintf('Report (PDF): %s\n', rep.pdfPath);
    else
        fprintf('Report (PDF): not generated (LaTeX may be missing).\n');
    end
catch ME
    warning('task7:report', 'Report generation failed: %s', ME.message);
end

fprintf('\n== Done ==\n');
