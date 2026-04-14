function results = task7cnn_run(opts)
%TASK7CNN_RUN Run Task 7 CNN experiment on MNIST_MATLAB.
%   results = task7cnn_run() compares 3 CNN architectures (5 runs each)
%   and compares 3 dropout settings (5 runs each) on MNIST.
%
%   opts (optional struct fields):
%     - numRuns (scalar) default 5
%     - miniBatchSize (scalar) default 64
%     - initialLearnRate (scalar) default 1e-3
%     - maxEpochs (scalar) default 15
%     - validationPatience (scalar) default 5
%     - executionEnvironment (char/string) default 'auto'
%     - variants (numeric vector) default [1 2 3]
%     - variantNames (string array) default ["CNN1_16_32" "CNN2_32_64" "CNN3_32_64_128"]
%     - baseDropout (scalar) default 0.0
%     - dropoutRates (numeric vector) default [0.0 0.3 0.5]
%     - doTiming (logical) default true
%     - timingEpochs (scalar) default 5
%
% Returns:
%   results.archSummary (table)
%   results.dropoutSummary (table)
%   results.best (struct)
%   results.bestDropout (struct)
%   results.timing (struct)

if nargin < 1
    opts = struct();
end

if ~isfield(opts, 'numRuns'),              opts.numRuns = 5; end
if ~isfield(opts, 'miniBatchSize'),        opts.miniBatchSize = 64; end
if ~isfield(opts, 'initialLearnRate'),     opts.initialLearnRate = 1e-3; end
if ~isfield(opts, 'maxEpochs'),            opts.maxEpochs = 15; end
if ~isfield(opts, 'validationPatience'),   opts.validationPatience = 5; end
if ~isfield(opts, 'executionEnvironment'), opts.executionEnvironment = 'auto'; end
if ~isfield(opts, 'variants'),             opts.variants = [1 2 3]; end
if ~isfield(opts, 'variantNames'),         opts.variantNames = {'CNN1_16_32','CNN2_32_64','CNN3_32_64_128'}; end
if ~isfield(opts, 'baseDropout'),          opts.baseDropout = 0.0; end
if ~isfield(opts, 'dropoutRates'),         opts.dropoutRates = [0.0 0.3 0.5]; end
if ~isfield(opts, 'doTiming'),             opts.doTiming = true; end
if ~isfield(opts, 'timingEpochs'),         opts.timingEpochs = 5; end
if ~isfield(opts, 'outDir'),               opts.outDir = ''; end
if ~isfield(opts, 'saveFigures'),          opts.saveFigures = false; end
if ~isfield(opts, 'closeFiguresAfterSave'), opts.closeFiguresAfterSave = false; end
if ~isfield(opts, 'saveBestArtifacts'),     opts.saveBestArtifacts = false; end

[~, YTrain, ~, YTest, XTrain4D, XTest4D, imgSize] = loadMNIST_MATLAB('MNIST_MATLAB');

classNames = string(0:9);
YTrainCat = categorical(YTrain, 0:9, classNames);
YTestCat  = categorical(YTest,  0:9, classNames);

numTrain = numel(YTrainCat);
numTest  = numel(YTestCat); %#ok<NASGU>

% Ratios consistent with 70k total (56k train, 10k test, 4k val)
trainRatioTotal = 0.8;
testRatioTotal  = 0.143;
valRatioTotal   = 1 - trainRatioTotal - testRatioTotal;
valFractionWithinTrain = valRatioTotal / (trainRatioTotal + valRatioTotal);

num_runs = opts.numRuns;
miniBatchSize = opts.miniBatchSize;
initialLearnRate = opts.initialLearnRate;
maxEpochs = opts.maxEpochs;
validationPatience = opts.validationPatience;
mainExecutionEnvironment = opts.executionEnvironment;

cnn_variants = opts.variants;
cnn_names = opts.variantNames;
baseDropout = opts.baseDropout;

figDir = '';
if ~isempty(opts.outDir) && (ischar(opts.outDir) || isstring(opts.outDir))
    figDir = fullfile(char(opts.outDir), 'figures');
    if opts.saveFigures && ~exist(figDir, 'dir')
        mkdir(figDir);
    end
end

allArchSummaries = table();
allArchRunResults = table();
cnnHyperparams = table();
best_overall = struct('net', [], 'name', '', 'meanTestAcc', -inf, 'bestInfo', [], 'variant', 0, 'baseDropout', baseDropout, 'bestSplit', []);

for a = 1:numel(cnn_variants)
    variant = cnn_variants(a);
    if iscell(cnn_names)
        archName = cnn_names{a};
    else
        archName = cnn_names(a);
    end
    archName = char(archName);

    fprintf('\n==============================\n');
    fprintf('== %s (variant %d, dropout=%.2f) ==\n', archName, variant, baseDropout);
    fprintf('==============================\n');

    train_acc_all = zeros(1, num_runs);
    val_acc_all   = zeros(1, num_runs);
    test_acc_all  = zeros(1, num_runs);
    train_loss_all = NaN(1, num_runs);
    test_loss_all  = NaN(1, num_runs);

    best_run = struct('net', [], 'info', [], 'testAcc', -inf, 'trainIdx', [], 'valIdx', []);

    for run = 1:num_runs
        fprintf('\n-- Run %d / %d --\n', run, num_runs);

        perm = randperm(numTrain);
        numVal = max(1, round(valFractionWithinTrain * numTrain));
        valIdx = perm(1:numVal);
        trainIdx = perm(numVal+1:end);

        XTrain = XTrain4D(:, :, :, trainIdx);
        YTrainLocal = YTrainCat(trainIdx);
        XVal   = XTrain4D(:, :, :, valIdx);
        YVal   = YTrainCat(valIdx);

        layers = create_cnn_layers(imgSize, variant, baseDropout);

        validationFrequency = max(1, floor(numel(YTrainLocal) / miniBatchSize));
        options = trainingOptions('adam', ...
            'InitialLearnRate', initialLearnRate, ...
            'MaxEpochs', maxEpochs, ...
            'MiniBatchSize', miniBatchSize, ...
            'Shuffle', 'every-epoch', ...
            'ValidationData', {XVal, YVal}, ...
            'ValidationFrequency', validationFrequency, ...
            'ValidationPatience', validationPatience, ...
            'Verbose', true, ...
            'Plots', 'none', ...
            'ExecutionEnvironment', mainExecutionEnvironment);

        [net, info] = trainNetwork(XTrain, YTrainLocal, layers, options);

        YPredTrain = classify(net, XTrain,  'MiniBatchSize', miniBatchSize);
        YPredVal   = classify(net, XVal,    'MiniBatchSize', miniBatchSize);
        YPredTest  = classify(net, XTest4D, 'MiniBatchSize', miniBatchSize);

        train_acc = mean(YPredTrain(:) == YTrainLocal(:));
        val_acc   = mean(YPredVal(:)   == YVal(:));
        test_acc  = mean(YPredTest(:)  == YTestCat(:));

        train_loss = NaN;
        if isfield(info, 'TrainingLoss') && ~isempty(info.TrainingLoss)
            train_loss = info.TrainingLoss(end);
        end
        test_loss = local_test_loss(net, XTest4D, YTestCat, miniBatchSize);

        train_acc_all(run) = train_acc;
        val_acc_all(run)   = val_acc;
        test_acc_all(run)  = test_acc;
        train_loss_all(run) = train_loss;
        test_loss_all(run)  = test_loss;

        fprintf('Train acc: %.2f %% | Val acc: %.2f %% | Test acc: %.2f %%\n', ...
            train_acc * 100, val_acc * 100, test_acc * 100);

        runRow = table(string(archName), run, train_loss, test_loss, train_acc * 100, test_acc * 100, ...
            'VariableNames', {'Model','Run','TrainLoss','TestLoss','TrainAccPct','TestAccPct'});
        if isempty(allArchRunResults)
            allArchRunResults = runRow;
        else
            allArchRunResults = [allArchRunResults; runRow];
        end

        if test_acc > best_run.testAcc
            best_run.net = net;
            best_run.info = info;
            best_run.testAcc = test_acc;
            best_run.trainIdx = trainIdx;
            best_run.valIdx = valIdx;
        end
    end

    summaryRow = table(string(archName), ...
        min(test_acc_all) * 100, max(test_acc_all) * 100, mean(test_acc_all) * 100, mean(test_loss_all, 'omitnan'), ...
        'VariableNames', {'Model','MinTestAccPct','MaxTestAccPct','MeanTestAccPct','MeanTestLoss'});

    disp(summaryRow);
    if isempty(allArchSummaries)
        allArchSummaries = summaryRow;
    else
        allArchSummaries = [allArchSummaries; summaryRow];
    end

    [convLayers, filtersStr, fcStr] = local_cnn_arch_desc(variant);
    hpRow = table(string(archName), convLayers, string(filtersStr), string(fcStr), maxEpochs, miniBatchSize, ...
        'VariableNames', {'Model','ConvLayers','Filters','FCLayers','Epochs','Batch'});
    if isempty(cnnHyperparams)
        cnnHyperparams = hpRow;
    else
        cnnHyperparams = [cnnHyperparams; hpRow];
    end

    if ~isempty(best_run.info)
        f1 = figure('Name', sprintf('%s - Best Run - Loss vs Iteration', archName));
        plot(best_run.info.TrainingLoss, 'LineWidth', 1.5); hold on;
        plot(best_run.info.ValidationLoss, 'LineWidth', 1.5);
        grid on;
        xlabel('Iteration');
        ylabel('Loss');
        title(sprintf('%s - Best Run: Training vs Validation Loss', archName));
        legend('Training loss', 'Validation loss', 'Location', 'best');
        local_maybe_save_figure(f1, figDir, sprintf('CNN_%s_best_loss', archName), opts);
    end

    XTrainBest = XTrain4D(:, :, :, best_run.trainIdx);
    YTrainBest = YTrainCat(best_run.trainIdx);
    XValBest   = XTrain4D(:, :, :, best_run.valIdx);
    YValBest   = YTrainCat(best_run.valIdx);
    YPredTrainBest = classify(best_run.net, XTrainBest, 'MiniBatchSize', miniBatchSize);
    YPredValBest   = classify(best_run.net, XValBest,   'MiniBatchSize', miniBatchSize);
    YPredTestBest  = classify(best_run.net, XTest4D,    'MiniBatchSize', miniBatchSize);

    f2 = figure('Name', sprintf('%s - Best Run - Confusion Matrices', archName));
    subplot(1,3,1);
    confusionchart(YTrainBest, YPredTrainBest);
    title('Train');
    subplot(1,3,2);
    confusionchart(YValBest, YPredValBest);
    title('Validation');
    subplot(1,3,3);
    confusionchart(YTestCat, YPredTestBest);
    title('Test');
    local_maybe_save_figure(f2, figDir, sprintf('CNN_%s_best_confusions', archName), opts);

    meanTestAcc = mean(test_acc_all);
    if meanTestAcc > best_overall.meanTestAcc
        best_overall.net = best_run.net;
        best_overall.bestInfo = best_run.info;
        best_overall.name = char(archName);
        best_overall.meanTestAcc = meanTestAcc;
        best_overall.variant = variant;
        best_overall.baseDropout = baseDropout;
        best_overall.bestSplit = best_run;
    end
end

fprintf('\n== CNN Architectures Summary (min/mean/max) ==\n');
disp(allArchSummaries);
fprintf('Best CNN by mean test accuracy: %s | mean test acc = %.2f %%\n', ...
    best_overall.name, best_overall.meanTestAcc * 100);

% Dropout comparison (>= 3 settings, 5 runs each)
dropoutRates = opts.dropoutRates;
dropSummaries = table();
allDropRunResults = table();
dropOverfitSummary = table();
dropMeanSummary = table();
best_dropout = struct('net', [], 'dropout', NaN, 'meanTestAcc', -inf, 'bestInfo', [], 'bestSplit', []);

for d = 1:numel(dropoutRates)
    dr = dropoutRates(d);
    fprintf('\n==============================\n');
    fprintf('== Dropout comparison: variant %d, dropout=%.2f ==\n', best_overall.variant, dr);
    fprintf('==============================\n');

    train_acc_all = zeros(1, num_runs);
    val_acc_all   = zeros(1, num_runs);
    test_acc_all  = zeros(1, num_runs);
    train_loss_all = NaN(1, num_runs);
    test_loss_all  = NaN(1, num_runs);
    bestValEpoch_all = NaN(1, num_runs);
    bestValLoss_all  = NaN(1, num_runs);

    best_run = struct('net', [], 'info', [], 'testAcc', -inf, 'trainIdx', [], 'valIdx', []);

    for run = 1:num_runs
        perm = randperm(numTrain);
        numVal = max(1, round(valFractionWithinTrain * numTrain));
        valIdx = perm(1:numVal);
        trainIdx = perm(numVal+1:end);

        XTrain = XTrain4D(:, :, :, trainIdx);
        YTrainLocal = YTrainCat(trainIdx);
        XVal   = XTrain4D(:, :, :, valIdx);
        YVal   = YTrainCat(valIdx);

        layers = create_cnn_layers(imgSize, best_overall.variant, dr);

        validationFrequency = max(1, floor(numel(YTrainLocal) / miniBatchSize));
        options = trainingOptions('adam', ...
            'InitialLearnRate', initialLearnRate, ...
            'MaxEpochs', maxEpochs, ...
            'MiniBatchSize', miniBatchSize, ...
            'Shuffle', 'every-epoch', ...
            'ValidationData', {XVal, YVal}, ...
            'ValidationFrequency', validationFrequency, ...
            'ValidationPatience', validationPatience, ...
            'Verbose', true, ...
            'Plots', 'none', ...
            'ExecutionEnvironment', mainExecutionEnvironment);

        [net, info] = trainNetwork(XTrain, YTrainLocal, layers, options);

        YPredTrain = classify(net, XTrain,  'MiniBatchSize', miniBatchSize);
        YPredVal  = classify(net, XVal,     'MiniBatchSize', miniBatchSize);
        YPredTest = classify(net, XTest4D,  'MiniBatchSize', miniBatchSize);

        train_acc = mean(YPredTrain(:) == YTrainLocal(:));
        val_acc  = mean(YPredVal(:) == YVal(:));
        test_acc = mean(YPredTest(:) == YTestCat(:));

        train_loss = NaN;
        if isfield(info, 'TrainingLoss') && ~isempty(info.TrainingLoss)
            train_loss = info.TrainingLoss(end);
        end
        test_loss = local_test_loss(net, XTest4D, YTestCat, miniBatchSize);
        [bestValEpoch, bestValLoss] = local_best_val_epoch_loss(info, numel(YTrainLocal), miniBatchSize);

        train_acc_all(run) = train_acc;
        val_acc_all(run)   = val_acc;
        test_acc_all(run)  = test_acc;
        train_loss_all(run) = train_loss;
        test_loss_all(run)  = test_loss;
        bestValEpoch_all(run) = bestValEpoch;
        bestValLoss_all(run)  = bestValLoss;

        fprintf('Run %d: Train acc %.2f %% | Val acc %.2f %% | Test acc %.2f %%\n', ...
            run, train_acc * 100, val_acc * 100, test_acc * 100);

        runRow = table(dr, run, train_loss, test_loss, train_acc * 100, test_acc * 100, bestValEpoch, bestValLoss, ...
            'VariableNames', {'Dropout','Run','TrainLoss','TestLoss','TrainAccPct','TestAccPct','BestValEpoch','BestValLoss'});
        if isempty(allDropRunResults)
            allDropRunResults = runRow;
        else
            allDropRunResults = [allDropRunResults; runRow];
        end

        if test_acc > best_run.testAcc
            best_run.net = net;
            best_run.info = info;
            best_run.testAcc = test_acc;
            best_run.trainIdx = trainIdx;
            best_run.valIdx = valIdx;
        end
    end

    row = table(dr, ...
        min(train_acc_all), mean(train_acc_all), max(train_acc_all), ...
        min(val_acc_all), mean(val_acc_all), max(val_acc_all), ...
        min(test_acc_all), mean(test_acc_all), max(test_acc_all), ...
        'VariableNames', {'Dropout','TrainMin','TrainMean','TrainMax','ValMin','ValMean','ValMax','TestMin','TestMean','TestMax'});

    disp(row);
    if isempty(dropSummaries)
        dropSummaries = row;
    else
        dropSummaries = [dropSummaries; row];
    end

    % Assignment-style dropout tables
    overfitRow = table(string(sprintf('D%d', d)), dr, num_runs, mean(bestValEpoch_all, 'omitnan'), mean(bestValLoss_all, 'omitnan'), ...
        'VariableNames', {'Model','Dropout','NumRuns','MeanOverfitEpoch','MeanValLoss'});
    if isempty(dropOverfitSummary)
        dropOverfitSummary = overfitRow;
    else
        dropOverfitSummary = [dropOverfitSummary; overfitRow];
    end

    meanRow = table(dr, num_runs, mean(train_acc_all) * 100, mean(test_acc_all) * 100, mean(test_loss_all, 'omitnan'), ...
        'VariableNames', {'Dropout','NumRuns','MeanTrainAccPct','MeanTestAccPct','MeanTestLoss'});
    if isempty(dropMeanSummary)
        dropMeanSummary = meanRow;
    else
        dropMeanSummary = [dropMeanSummary; meanRow];
    end

    meanTest = mean(test_acc_all);
    if meanTest > best_dropout.meanTestAcc
        best_dropout.net = best_run.net;
        best_dropout.dropout = dr;
        best_dropout.meanTestAcc = meanTest;
        best_dropout.bestInfo = best_run.info;
        best_dropout.bestSplit = best_run;
    end
end

fprintf('\n== Dropout Summary (variant %d) ==\n', best_overall.variant);
disp(dropSummaries);
fprintf('Best dropout by mean test accuracy: %.2f | mean test acc = %.2f %%\n', ...
    best_dropout.dropout, best_dropout.meanTestAcc * 100);

% CPU vs GPU timing (at least one CNN)
timing = struct('didRun', false, 'epochs', opts.timingEpochs, 'cpuSeconds', NaN, 'gpuSeconds', NaN, 'gpuAvailable', local_can_use_gpu());

if opts.doTiming
    timing.didRun = true;
    fprintf('\n== Timing (CPU vs GPU) for best CNN variant %d (dropout=%.2f) ==\n', ...
        best_overall.variant, best_overall.baseDropout);

    perm = randperm(numTrain);
    numVal = max(1, round(valFractionWithinTrain * numTrain));
    valIdx = perm(1:numVal);
    trainIdx = perm(numVal+1:end);

    XTrain = XTrain4D(:, :, :, trainIdx);
    YTrainLocal = YTrainCat(trainIdx);
    XVal   = XTrain4D(:, :, :, valIdx);
    YVal   = YTrainCat(valIdx);

    layers = create_cnn_layers(imgSize, best_overall.variant, best_overall.baseDropout);
    validationFrequency = max(1, floor(numel(YTrainLocal) / miniBatchSize));

    optionsCPU = trainingOptions('adam', ...
        'InitialLearnRate', initialLearnRate, ...
        'MaxEpochs', opts.timingEpochs, ...
        'MiniBatchSize', miniBatchSize, ...
        'Shuffle', 'every-epoch', ...
        'ValidationData', {XVal, YVal}, ...
        'ValidationFrequency', validationFrequency, ...
        'ValidationPatience', validationPatience, ...
        'Verbose', true, ...
        'Plots', 'none', ...
        'ExecutionEnvironment', 'cpu');

    fprintf('CPU timing...\n');
    tic;
    trainNetwork(XTrain, YTrainLocal, layers, optionsCPU);
    timing.cpuSeconds = toc;
    fprintf('CPU time: %.2f s\n', timing.cpuSeconds);

    if timing.gpuAvailable
        optionsGPU = trainingOptions('adam', ...
            'InitialLearnRate', initialLearnRate, ...
            'MaxEpochs', opts.timingEpochs, ...
            'MiniBatchSize', miniBatchSize, ...
            'Shuffle', 'every-epoch', ...
            'ValidationData', {XVal, YVal}, ...
            'ValidationFrequency', validationFrequency, ...
            'ValidationPatience', validationPatience, ...
            'Verbose', true, ...
            'Plots', 'none', ...
            'ExecutionEnvironment', 'gpu');

        fprintf('GPU timing...\n');
        tic;
        trainNetwork(XTrain, YTrainLocal, layers, optionsGPU);
        timing.gpuSeconds = toc;
        fprintf('GPU time: %.2f s\n', timing.gpuSeconds);
    else
        fprintf('GPU not available -> skipping GPU timing.\n');
    end
end

% Test one sample per digit (0-9) for the best CNN
fprintf('\n== Testing one sample per digit (0-9) on FIXED TEST set ==\n');

figSamples = figure('Name', sprintf('CNN Best (%s) - Digit Samples', best_overall.name), 'Position', [100, 100, 1100, 450]);
figOutputs = figure('Name', sprintf('CNN Best (%s) - Network Outputs', best_overall.name), 'Position', [100, 100, 1100, 450]);

all_true = categorical();
all_pred = categorical();
all_scores = cell(1, 10);

for digit = 0:9
    digit_cat = categorical(digit, 0:9, classNames);
    idx = find(YTestCat == digit_cat, 1);
    if isempty(idx)
        warning('Digit %d not found in test set!', digit);
        continue;
    end

    sample = XTest4D(:, :, :, idx);
    [pred_label, scores] = classify(best_overall.net, sample, 'MiniBatchSize', 1);

    all_true(end+1) = digit_cat;
    all_pred(end+1) = pred_label;
    all_scores{digit+1} = scores(:)';

    figure(figSamples);
    subplot(2, 5, digit+1);
    imshow(sample(:, :, 1, 1), []);
    if pred_label == digit_cat
        title(sprintf('%d -> %s (OK)', digit, string(pred_label)), 'Color', 'g');
    else
        title(sprintf('%d -> %s (ERR)', digit, string(pred_label)), 'Color', 'r');
    end

    figure(figOutputs);
    subplot(2, 5, digit+1);
    bar(scores);
    grid on;
    xlim([0.5 10.5]);
    title(sprintf('Digit %d (pred %s)', digit, string(pred_label)));
end

f3 = figure('Name', sprintf('CNN Best (%s) - Confusion (Digit Samples)', best_overall.name));
confusionchart(all_true, all_pred);
title('Confusion Matrix (one sample per digit)');

local_maybe_save_figure(figSamples, figDir, sprintf('CNN_%s_digit_samples', best_overall.name), opts);
local_maybe_save_figure(figOutputs, figDir, sprintf('CNN_%s_digit_outputs', best_overall.name), opts);
local_maybe_save_figure(f3, figDir, sprintf('CNN_%s_digit_samples_confusion', best_overall.name), opts);

fprintf('\n== Done (CNN) ==\n');

results = struct();
results.archSummary = allArchSummaries;
results.dropoutSummary = dropSummaries;
results.archRunResults = allArchRunResults;
results.dropoutRunResults = allDropRunResults;
results.archHyperparams = cnnHyperparams;
results.dropoutOverfitSummary = dropOverfitSummary;
results.dropoutMeanSummary = dropMeanSummary;
results.best = struct('name', best_overall.name, 'variant', best_overall.variant, 'baseDropout', best_overall.baseDropout, 'meanTestAcc', best_overall.meanTestAcc);
results.bestDropout = struct('dropout', best_dropout.dropout, 'meanTestAcc', best_dropout.meanTestAcc);
results.bestArtifacts = [];
results.bestDropoutArtifacts = [];
if opts.saveBestArtifacts
    results.bestArtifacts = best_overall.bestSplit;
    results.bestArtifacts.modelName = best_overall.name;
    results.bestArtifacts.variant = best_overall.variant;
    results.bestArtifacts.baseDropout = best_overall.baseDropout;

    results.bestDropoutArtifacts = best_dropout.bestSplit;
    results.bestDropoutArtifacts.dropout = best_dropout.dropout;
    results.bestDropoutArtifacts.variant = best_overall.variant;
end
results.timing = timing;
results.digitSample = struct('true', all_true, 'pred', all_pred, 'scores', {all_scores});

results.hyperparams = table(opts.numRuns, opts.maxEpochs, opts.miniBatchSize, opts.initialLearnRate, opts.validationPatience, string(opts.executionEnvironment), ...
    string(mat2str(opts.variants)), opts.baseDropout, string(mat2str(opts.dropoutRates)), opts.doTiming, opts.timingEpochs, ...
    'VariableNames', {'NumRuns','MaxEpochs','MiniBatchSize','InitialLearnRate','ValidationPatience','ExecutionEnvironment','Variants','BaseDropout','DropoutRates','DoTiming','TimingEpochs'});

results.opts = opts;
results.meta = struct('matlabVersion', version, 'timestamp', datestr(now));
end

% =========================================================
% Local helper functions
% =========================================================
function layers = create_cnn_layers(imgSize, variant, dropoutRate)
inputLayer = imageInputLayer([imgSize(1) imgSize(2) 1], 'Normalization', 'none', 'Name', 'input');

switch variant
    case 1
        layers = [
            inputLayer
            convolution2dLayer(3, 16, 'Padding', 'same', 'Name', 'conv1')
            batchNormalizationLayer('Name', 'bn1')
            reluLayer('Name', 'relu1')
            maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool1')

            convolution2dLayer(3, 32, 'Padding', 'same', 'Name', 'conv2')
            batchNormalizationLayer('Name', 'bn2')
            reluLayer('Name', 'relu2')
            maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool2')

            fullyConnectedLayer(128, 'Name', 'fc1')
            reluLayer('Name', 'relu3')
            dropoutLayer(dropoutRate, 'Name', 'drop1')

            fullyConnectedLayer(10, 'Name', 'fc_out')
            softmaxLayer('Name', 'softmax')
            classificationLayer('Name', 'output')
        ];

    case 2
        layers = [
            inputLayer
            convolution2dLayer(3, 32, 'Padding', 'same', 'Name', 'conv1')
            batchNormalizationLayer('Name', 'bn1')
            reluLayer('Name', 'relu1')
            maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool1')

            convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'conv2')
            batchNormalizationLayer('Name', 'bn2')
            reluLayer('Name', 'relu2')
            maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool2')

            fullyConnectedLayer(128, 'Name', 'fc1')
            reluLayer('Name', 'relu3')
            dropoutLayer(dropoutRate, 'Name', 'drop1')

            fullyConnectedLayer(10, 'Name', 'fc_out')
            softmaxLayer('Name', 'softmax')
            classificationLayer('Name', 'output')
        ];

    case 3
        layers = [
            inputLayer
            convolution2dLayer(3, 32, 'Padding', 'same', 'Name', 'conv1')
            batchNormalizationLayer('Name', 'bn1')
            reluLayer('Name', 'relu1')
            maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool1')

            convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'conv2')
            batchNormalizationLayer('Name', 'bn2')
            reluLayer('Name', 'relu2')
            maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool2')

            convolution2dLayer(3, 128, 'Padding', 'same', 'Name', 'conv3')
            batchNormalizationLayer('Name', 'bn3')
            reluLayer('Name', 'relu3')
            maxPooling2dLayer(2, 'Stride', 2, 'Name', 'pool3')

            fullyConnectedLayer(256, 'Name', 'fc1')
            reluLayer('Name', 'relu4')
            dropoutLayer(dropoutRate, 'Name', 'drop1')

            fullyConnectedLayer(10, 'Name', 'fc_out')
            softmaxLayer('Name', 'softmax')
            classificationLayer('Name', 'output')
        ];

    otherwise
        error('Unknown CNN variant: %d', variant);
end
end

function loss = local_test_loss(net, XTest4D, YTestCat, miniBatchSize)
% Average negative log-likelihood on the fixed test set.
probs = predict(net, XTest4D, 'MiniBatchSize', miniBatchSize);

% predict() usually returns N-by-K for image classification
if size(probs, 2) == 10
    probsNK = probs;
elseif size(probs, 1) == 10
    probsNK = probs';
else
    error('Unexpected predict() output size: %s', mat2str(size(probs)));
end

idx = double(YTestCat);
n = numel(idx);
pTrue = probsNK(sub2ind(size(probsNK), (1:n)', idx(:)));
pTrue = max(pTrue, eps);
loss = -mean(log(pTrue));
end

function [bestEpoch, bestValLoss] = local_best_val_epoch_loss(info, numTrainLocal, miniBatchSize)
bestEpoch = NaN;
bestValLoss = NaN;

if ~isfield(info, 'ValidationLoss') || isempty(info.ValidationLoss)
    return;
end

[bestValLoss, iBest] = min(info.ValidationLoss);

% In this script, validationFrequency is set to approximately iterationsPerEpoch,
% so each ValidationLoss point corresponds roughly to one epoch.
iterationsPerEpoch = max(1, ceil(numTrainLocal / miniBatchSize));
validationFrequency = max(1, floor(numTrainLocal / miniBatchSize));
bestEpoch = max(1, ceil((iBest * validationFrequency) / iterationsPerEpoch));
end

function [convLayers, filtersStr, fcStr] = local_cnn_arch_desc(variant)
switch variant
    case 1
        convLayers = 2;
        filtersStr = '16,32';
        fcStr = '128';
    case 2
        convLayers = 2;
        filtersStr = '32,64';
        fcStr = '128';
    case 3
        convLayers = 3;
        filtersStr = '32,64,128';
        fcStr = '256';
    otherwise
        error('Unknown CNN variant: %d', variant);
end
end

function local_maybe_save_figure(fig, figDir, baseName, opts)
if isempty(figDir) || ~opts.saveFigures
    return;
end

res = 300;
if isfield(opts, 'figureResolution') && ~isempty(opts.figureResolution)
    res = double(opts.figureResolution);
end

if isstring(baseName)
    baseName = char(baseName);
end

try
    pngPath = fullfile(figDir, sprintf('%s.png', char(baseName)));
    if exist('exportgraphics', 'file') == 2
        exportgraphics(fig, pngPath, 'Resolution', res);
    else
        print(fig, pngPath, '-dpng', sprintf('-r%d', res));
    end
catch
    try
        pngPath = fullfile(figDir, sprintf('%s.png', char(baseName)));
        print(fig, pngPath, '-dpng', sprintf('-r%d', res));
    catch
        % ignore
    end
end

if opts.closeFiguresAfterSave
    try
        close(fig);
    catch
    end
end
end

function tf = local_can_use_gpu()
tf = false;

try
    if exist('canUseGPU', 'file') == 2
        tf = canUseGPU();
        return;
    end
end

try
    if exist('gpuDeviceCount', 'file') == 2
        try
            tf = gpuDeviceCount('available') > 0;
        catch
            tf = gpuDeviceCount() > 0;
        end
    end
catch
    tf = false;
end
end
