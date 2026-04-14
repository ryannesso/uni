function results = task7mlp_run(opts)
%TASK7MLP_RUN Run Task 7 MLP experiment on MNIST_MATLAB.
%   results = task7mlp_run() trains and evaluates multiple MLP structures
%   (trainNetwork - fully-connected) on MNIST with fixed test set and val split from train.
%
%   opts (optional struct fields):
%     - useGPU (logical) default true
%     - numRuns (scalar) default 5
%     - structures (cell array) default {[128],[256 128]}
%     - names (cell array) default {'MLP1','MLP2'}
%     - regularization (scalar) default 1e-4 (L2)
%     - epochs (scalar) default 20
%     - initialLearnRate (scalar) default 1e-3
%     - miniBatchSize (scalar) default 64
%     - validationPatience (scalar) default 5
%     - outDir (char/string) default ''
%     - saveFigures (logical) default false
%     - closeFiguresAfterSave (logical) default false
%     - doTiming (logical) default true
%     - timingEpochs (scalar) default 5
%
% Returns:
%   results.structureSummary (table)
%   results.best (struct)
%   results.timing (struct)

if nargin < 1
    opts = struct();
end

% Defaults
if ~isfield(opts, 'useGPU'),          opts.useGPU = true; end
if ~isfield(opts, 'numRuns'),         opts.numRuns = 5; end
if ~isfield(opts, 'structures'),      opts.structures = {[128], [256 128]}; end
if ~isfield(opts, 'names'),           opts.names = {'MLP1', 'MLP2'}; end
if ~isfield(opts, 'regularization'),  opts.regularization = 1e-4; end
if ~isfield(opts, 'epochs'),          opts.epochs = 20; end
if ~isfield(opts, 'initialLearnRate'), opts.initialLearnRate = 1e-3; end
if ~isfield(opts, 'miniBatchSize'),    opts.miniBatchSize = 64; end
if ~isfield(opts, 'validationPatience'), opts.validationPatience = 5; end
if ~isfield(opts, 'outDir'),            opts.outDir = ''; end
if ~isfield(opts, 'saveFigures'),       opts.saveFigures = false; end
if ~isfield(opts, 'closeFiguresAfterSave'), opts.closeFiguresAfterSave = false; end
if ~isfield(opts, 'doTiming'),        opts.doTiming = true; end
if ~isfield(opts, 'timingEpochs'),    opts.timingEpochs = 5; end
if ~isfield(opts, 'saveBestArtifacts'), opts.saveBestArtifacts = false; end

% Load MNIST from MNIST_MATLAB/
[XTrainVec, YTrain, XTestVec, YTest, ~, ~, imgSize] = loadMNIST_MATLAB('MNIST_MATLAB');

numTrain = size(XTrainVec, 2);
numTest  = size(XTestVec, 2);

classNames = string(0:9);
YTrainCat = categorical(YTrain, 0:9, classNames);
YTestCat  = categorical(YTest,  0:9, classNames);

XTrainMatAll = XTrainVec'; % N x 784
XTestMat  = XTestVec';     % N x 784

% Ratios consistent with 70k total (56k train, 10k test, 4k val)
trainRatioTotal = 0.8;
testRatioTotal  = 0.143;
valRatioTotal   = 1 - trainRatioTotal - testRatioTotal;
valFractionWithinTrain = valRatioTotal / (trainRatioTotal + valRatioTotal);

num_runs = opts.numRuns;
mlp_structures = opts.structures;
mlp_names = opts.names;

allStructureSummaries = table();
allRunResults = table();
allHyperparams = table();

best_overall = struct('net', [], 'name', '', 'meanTestAcc', -inf, 'bestInfo', [], 'bestSplit', []);

figDir = '';
if ~isempty(opts.outDir) && (ischar(opts.outDir) || isstring(opts.outDir))
    figDir = fullfile(char(opts.outDir), 'figures');
    if opts.saveFigures && ~exist(figDir, 'dir')
        mkdir(figDir);
    end
end

for s = 1:numel(mlp_structures)
    hiddenSizes = mlp_structures{s};
    structName  = mlp_names{s};

    fprintf('\n==============================\n');
    fprintf('== %s (hidden = %s) ==\n', structName, mat2str(hiddenSizes));
    fprintf('==============================\n');

    train_acc_all = zeros(1, num_runs);
    val_acc_all   = zeros(1, num_runs);
    test_acc_all  = zeros(1, num_runs);
    train_loss_all = zeros(1, num_runs);
    test_loss_all  = zeros(1, num_runs);

    best_run = struct('net', [], 'info', [], 'testAcc', -inf, 'trainIdx', [], 'valIdx', []);

    for run = 1:num_runs
        fprintf('\n-- Run %d / %d --\n', run, num_runs);

        % Split only within training part; test set is fixed
        trainPerm = randperm(numTrain);
        numVal = max(1, round(valFractionWithinTrain * numTrain));
        valIdxTrain = trainPerm(1:numVal);
        trainIdxTrain = trainPerm(numVal+1:end);

        trainIdx = trainIdxTrain;
        valIdx   = valIdxTrain;

        XTrainMat = XTrainMatAll(trainIdx, :);
        YTrainLocal = YTrainCat(trainIdx);
        XValMat   = XTrainMatAll(valIdx, :);
        YVal      = YTrainCat(valIdx);

        layers = local_create_mlp_layers(hiddenSizes);

        validationFrequency = max(1, floor(numel(YTrainLocal) / opts.miniBatchSize));
        execEnv = 'cpu';
        if opts.useGPU
            execEnv = 'auto';
        end

        options = trainingOptions('adam', ...
            'InitialLearnRate', opts.initialLearnRate, ...
            'L2Regularization', opts.regularization, ...
            'MaxEpochs', opts.epochs, ...
            'MiniBatchSize', opts.miniBatchSize, ...
            'Shuffle', 'every-epoch', ...
            'ValidationData', {XValMat, YVal}, ...
            'ValidationFrequency', validationFrequency, ...
            'ValidationPatience', opts.validationPatience, ...
            'Verbose', true, ...
            'Plots', 'none', ...
            'ExecutionEnvironment', execEnv);

        [net, info] = trainNetwork(XTrainMat, YTrainLocal, layers, options);

        YPredTrain = classify(net, XTrainMat, 'MiniBatchSize', opts.miniBatchSize);
        YPredVal   = classify(net, XValMat,   'MiniBatchSize', opts.miniBatchSize);
        YPredTest  = classify(net, XTestMat,  'MiniBatchSize', opts.miniBatchSize);

        train_acc = mean(YPredTrain(:) == YTrainLocal(:));
        val_acc   = mean(YPredVal(:)   == YVal(:));
        test_acc  = mean(YPredTest(:)  == YTestCat(:));

        train_loss = NaN;
        if isfield(info, 'TrainingLoss') && ~isempty(info.TrainingLoss)
            train_loss = info.TrainingLoss(end);
        end
        test_loss = local_test_loss(net, XTestMat, YTestCat, opts.miniBatchSize);

        train_acc_all(run) = train_acc;
        val_acc_all(run)   = val_acc;
        test_acc_all(run)  = test_acc;
        train_loss_all(run) = train_loss;
        test_loss_all(run)  = test_loss;

        fprintf('Train acc: %.2f %% | Val acc: %.2f %% | Test acc: %.2f %%\n', ...
            train_acc * 100, val_acc * 100, test_acc * 100);

        runRow = table(string(structName), run, train_loss, test_loss, train_acc * 100, test_acc * 100, ...
            'VariableNames', {'Model','Run','TrainLoss','TestLoss','TrainAccPct','TestAccPct'});
        if isempty(allRunResults)
            allRunResults = runRow;
        else
            allRunResults = [allRunResults; runRow];
        end

        if test_acc > best_run.testAcc
            best_run.net = net;
            best_run.info = info;
            best_run.testAcc = test_acc;
            best_run.trainIdx = trainIdx;
            best_run.valIdx   = valIdx;
        end
    end

    summaryRow = table(string(structName), ...
        min(test_acc_all) * 100, max(test_acc_all) * 100, mean(test_acc_all) * 100, mean(test_loss_all), ...
        'VariableNames', {'Model','MinTestAccPct','MaxTestAccPct','MeanTestAccPct','MeanTestLoss'});

    disp(summaryRow);
    if isempty(allStructureSummaries)
        allStructureSummaries = summaryRow;
    else
        allStructureSummaries = [allStructureSummaries; summaryRow];
    end

    hpRow = table(string(structName), numel(hiddenSizes), string(strjoin(string(hiddenSizes), ',')), opts.epochs, opts.initialLearnRate, opts.miniBatchSize, ...
        'VariableNames', {'Model','HiddenLayers','Neurons','Epochs','LR','Batch'});
    if isempty(allHyperparams)
        allHyperparams = hpRow;
    else
        allHyperparams = [allHyperparams; hpRow];
    end

    % Save best run plots (loss + confusion) for this structure
    if ~isempty(best_run.info)
        f1 = figure('Name', sprintf('%s - Best Run - Loss vs Iteration', structName));
        plot(best_run.info.TrainingLoss, 'LineWidth', 1.5); hold on;
        if isfield(best_run.info, 'ValidationLoss')
            plot(best_run.info.ValidationLoss, 'LineWidth', 1.5);
            legend('Training loss', 'Validation loss', 'Location', 'best');
        else
            legend('Training loss', 'Location', 'best');
        end
        grid on;
        xlabel('Iteration'); ylabel('Loss');
        title(sprintf('%s - Best Run: Training vs Validation Loss', structName));
        local_maybe_save_figure(f1, figDir, sprintf('MLP_%s_best_loss', structName), opts);
    end

    XTrainBest = XTrainMatAll(best_run.trainIdx, :);
    YTrainBest = YTrainCat(best_run.trainIdx);
    XValBest   = XTrainMatAll(best_run.valIdx, :);
    YValBest   = YTrainCat(best_run.valIdx);
    YPredTrainBest = classify(best_run.net, XTrainBest, 'MiniBatchSize', opts.miniBatchSize);
    YPredValBest   = classify(best_run.net, XValBest,   'MiniBatchSize', opts.miniBatchSize);
    YPredTestBest  = classify(best_run.net, XTestMat,   'MiniBatchSize', opts.miniBatchSize);

    f2 = figure('Name', sprintf('%s - Best Run - Confusion Matrices', structName));
    subplot(1,3,1); confusionchart(YTrainBest, YPredTrainBest); title('Train');
    subplot(1,3,2); confusionchart(YValBest,   YPredValBest);   title('Validation');
    subplot(1,3,3); confusionchart(YTestCat,   YPredTestBest);  title('Test');
    local_maybe_save_figure(f2, figDir, sprintf('MLP_%s_best_confusions', structName), opts);

    meanTestAcc = mean(test_acc_all);
    if meanTestAcc > best_overall.meanTestAcc
        best_overall.net = best_run.net;
        best_overall.bestInfo = best_run.info;
        best_overall.bestSplit = best_run;
        best_overall.name = structName;
        best_overall.meanTestAcc = meanTestAcc;
    end
end

fprintf('\n== MLP Structures Summary (min/mean/max) ==\n');
disp(allStructureSummaries);
fprintf('Best MLP by mean test accuracy: %s | mean test acc = %.2f %%\n', ...
    best_overall.name, best_overall.meanTestAcc * 100);

% CPU vs GPU timing (at least one MLP)
timing = struct('didRun', false, 'epochs', opts.timingEpochs, 'cpuSeconds', NaN, 'gpuSeconds', NaN, 'gpuAvailable', local_can_use_gpu());

if opts.doTiming
    timing.didRun = true;
    fprintf('\n== Timing (CPU vs GPU) for %s ==\n', best_overall.name);

    idxStruct = find(strcmp(best_overall.name, mlp_names), 1);
    if isempty(idxStruct)
        idxStruct = 1;
    end
    hiddenSizes = mlp_structures{idxStruct};

    % Fixed split for timing
    trainPerm = randperm(numTrain);
    numVal = max(1, round(valFractionWithinTrain * numTrain));
    valIdxTrain = trainPerm(1:numVal);
    trainIdxTrain = trainPerm(numVal+1:end);
    trainIdx = trainIdxTrain;
    valIdx   = valIdxTrain;
    testIdx  = numTrain + (1:numTest);

    XTrainMat = XTrainMatAll(trainIdx, :);
    YTrainLocal = YTrainCat(trainIdx);
    XValMat   = XTrainMatAll(valIdx, :);
    YVal      = YTrainCat(valIdx);
    layers = local_create_mlp_layers(hiddenSizes);
    validationFrequency = max(1, floor(numel(YTrainLocal) / opts.miniBatchSize));

    fprintf('CPU timing...\n');
    tic;
    optionsCPU = trainingOptions('adam', ...
        'InitialLearnRate', opts.initialLearnRate, ...
        'L2Regularization', opts.regularization, ...
        'MaxEpochs', opts.timingEpochs, ...
        'MiniBatchSize', opts.miniBatchSize, ...
        'Shuffle', 'every-epoch', ...
        'ValidationData', {XValMat, YVal}, ...
        'ValidationFrequency', validationFrequency, ...
        'ValidationPatience', opts.validationPatience, ...
        'Verbose', true, ...
        'Plots', 'none', ...
        'ExecutionEnvironment', 'cpu');
    trainNetwork(XTrainMat, YTrainLocal, layers, optionsCPU);
    timing.cpuSeconds = toc;
    fprintf('CPU time: %.2f s\n', timing.cpuSeconds);

    if timing.gpuAvailable
        fprintf('GPU timing...\n');
        tic;
        optionsGPU = trainingOptions('adam', ...
            'InitialLearnRate', opts.initialLearnRate, ...
            'L2Regularization', opts.regularization, ...
            'MaxEpochs', opts.timingEpochs, ...
            'MiniBatchSize', opts.miniBatchSize, ...
            'Shuffle', 'every-epoch', ...
            'ValidationData', {XValMat, YVal}, ...
            'ValidationFrequency', validationFrequency, ...
            'ValidationPatience', opts.validationPatience, ...
            'Verbose', true, ...
            'Plots', 'none', ...
            'ExecutionEnvironment', 'gpu');
        trainNetwork(XTrainMat, YTrainLocal, layers, optionsGPU);
        timing.gpuSeconds = toc;
        fprintf('GPU time: %.2f s\n', timing.gpuSeconds);
    else
        fprintf('GPU not available -> skipping GPU timing.\n');
    end
end

% Test one sample per digit (0-9) for the best MLP
fprintf('\n== Testing one sample per digit (0-9) on FIXED TEST set ==\n');

figSamples = figure('Name', sprintf('MLP Best (%s) - Digit Samples', best_overall.name), 'Position', [100, 100, 1100, 450]);
figOutputs = figure('Name', sprintf('MLP Best (%s) - Network Outputs', best_overall.name), 'Position', [100, 100, 1100, 450]);

all_true = [];
all_pred = [];
all_scores = cell(1, 10);

for digit = 0:9
    idx = find(YTest == digit, 1);
    if isempty(idx)
        warning('Digit %d not found in test set!', digit);
        continue;
    end

    sampleVec = XTestVec(:, idx)';
    [pred_label, scores] = classify(best_overall.net, sampleVec, 'MiniBatchSize', 1);
    pred = str2double(string(pred_label));

    all_true(end+1) = digit;
    all_pred(end+1) = pred;
    all_scores{digit+1} = scores(:)';

    img = reshape(sampleVec, imgSize(1), imgSize(2));
    figure(figSamples);
    subplot(2, 5, digit+1);
    imshow(img, []);
    if pred == digit
        title(sprintf('%d -> %d (OK)', digit, pred), 'Color', 'g');
    else
        title(sprintf('%d -> %d (ERR)', digit, pred), 'Color', 'r');
    end

    figure(figOutputs);
    subplot(2, 5, digit+1);
    bar(scores);
    grid on;
    xlim([0.5 10.5]);
    title(sprintf('Digit %d (pred %d)', digit, pred));
end

figure('Name', sprintf('MLP Best (%s) - Confusion (Digit Samples)', best_overall.name));
confusionchart(categorical(all_true), categorical(all_pred));
title('Confusion Matrix (one sample per digit)');

local_maybe_save_figure(figSamples, figDir, sprintf('MLP_%s_digit_samples', best_overall.name), opts);
local_maybe_save_figure(figOutputs, figDir, sprintf('MLP_%s_digit_outputs', best_overall.name), opts);
local_maybe_save_figure(gcf, figDir, sprintf('MLP_%s_digit_samples_confusion', best_overall.name), opts);

fprintf('\n== Done (MLP) ==\n');

results = struct();
results.structureSummary = allStructureSummaries;
results.runResults = allRunResults;
results.hyperparamModels = allHyperparams;
results.best = struct('name', best_overall.name, 'meanTestAcc', best_overall.meanTestAcc);
results.bestArtifacts = [];
if opts.saveBestArtifacts
    results.bestArtifacts = best_overall.bestSplit;
    results.bestArtifacts.modelName = best_overall.name;
end
results.timing = timing;
results.digitSample = struct('true', all_true, 'pred', all_pred, 'scores', {all_scores});

results.hyperparams = table(opts.numRuns, opts.epochs, opts.initialLearnRate, opts.miniBatchSize, opts.regularization, opts.useGPU, opts.doTiming, opts.timingEpochs, ...
    'VariableNames', {'NumRuns','Epochs','InitialLearnRate','MiniBatchSize','L2Regularization','UseGPU','DoTiming','TimingEpochs'});

results.opts = opts;
results.meta = struct('matlabVersion', version, 'timestamp', datestr(now));
end

% =========================================================
% Local helper functions
% =========================================================
function layers = local_create_mlp_layers(hiddenSizes)
layers = [
    featureInputLayer(784, 'Normalization', 'none', 'Name', 'input')
];

for i = 1:numel(hiddenSizes)
    layers = [layers
        fullyConnectedLayer(hiddenSizes(i), 'Name', sprintf('fc_%d', i))
        reluLayer('Name', sprintf('relu_%d', i))
    ];
end

layers = [layers
    fullyConnectedLayer(10, 'Name', 'fc_out')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'output')
];
end

function loss = local_test_loss(net, XTestMat, YTestCat, miniBatchSize)
probs = predict(net, XTestMat, 'MiniBatchSize', miniBatchSize);
if size(probs, 2) ~= 10
    probs = probs';
end
idx = double(YTestCat);
n = numel(idx);
pTrue = probs(sub2ind(size(probs), (1:n)', idx(:)));
pTrue = max(pTrue, eps);
loss = -mean(log(pTrue));
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
