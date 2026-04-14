function out = task7_render_figures(outDir, varargin)
%TASK7_RENDER_FIGURES Regenerate figures from saved best artifacts (no retraining).
%   out = task7_render_figures(outDir, 'Resolution', 600)
%
% Requires that mlp_results.mat / cnn_results.mat contain results.bestArtifacts
% (created by setting opts.saveBestArtifacts=true during training).

p = inputParser;
addRequired(p, 'outDir', @(s) ischar(s) || isstring(s));
addParameter(p, 'Resolution', 600, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'CloseAfterSave', true, @(x) islogical(x) && isscalar(x));
parse(p, outDir, varargin{:});

outDir = char(p.Results.outDir);
res = double(p.Results.Resolution);
closeAfter = p.Results.CloseAfterSave;

figDir = fullfile(outDir, 'figures');
if ~exist(figDir, 'dir')
    mkdir(figDir);
end

out = struct();
out.outDir = outDir;
out.figDir = figDir;
out.resolution = res;

% Load results
mlpPath = fullfile(outDir, 'mlp_results.mat');
cnnPath = fullfile(outDir, 'cnn_results.mat');

hasMlp = exist(mlpPath, 'file') == 2;
hasCnn = exist(cnnPath, 'file') == 2;

if ~hasMlp && ~hasCnn
    error('No results mats found in %s', outDir);
end

% Load MNIST
[XTrainVec, YTrain, XTestVec, YTest, XTrain4D, XTest4D, imgSize] = loadMNIST_MATLAB('MNIST_MATLAB');

classNames = string(0:9);
YTrainCat = categorical(YTrain, 0:9, classNames);
YTestCat  = categorical(YTest,  0:9, classNames);

% MLP figures
if hasMlp
    S = load(mlpPath, 'mlp_results');
    mlp_results = S.mlp_results;

    if ~isfield(mlp_results, 'bestArtifacts') || isempty(mlp_results.bestArtifacts) || ~isfield(mlp_results.bestArtifacts, 'net')
        warning('MLP bestArtifacts not found in %s. Re-run training with opts.saveBestArtifacts=true.', mlpPath);
    else
        art = mlp_results.bestArtifacts;
        name = 'MLP_best';
        if isfield(art, 'modelName') && ~isempty(art.modelName)
            name = sprintf('MLP_%s', char(art.modelName));
        end

        % Loss plot
        if isfield(art, 'info') && ~isempty(art.info) && isfield(art.info, 'TrainingLoss')
            f = figure('Name', [name ' - Loss']);
            plot(art.info.TrainingLoss, 'LineWidth', 1.5); hold on;
            if isfield(art.info, 'ValidationLoss') && ~isempty(art.info.ValidationLoss)
                plot(art.info.ValidationLoss, 'LineWidth', 1.5);
                legend('Training loss','Validation loss','Location','best');
            else
                legend('Training loss','Location','best');
            end
            grid on; xlabel('Iteration'); ylabel('Loss');
            title([name ' - Training vs Validation Loss']);
            local_save_png(f, figDir, [name '_best_loss'], res, closeAfter);
        end

        % Confusion matrices (train/val/test)
        if isfield(art, 'trainIdx') && ~isempty(art.trainIdx) && isfield(art, 'valIdx') && ~isempty(art.valIdx)
            XTrainMat = XTrainVec';
            XTestMat  = XTestVec';
            XTr = XTrainMat(art.trainIdx, :);
            YTr = YTrainCat(art.trainIdx);
            XV  = XTrainMat(art.valIdx, :);
            YV  = YTrainCat(art.valIdx);

            YPredTr = classify(art.net, XTr, 'MiniBatchSize', 64);
            YPredV  = classify(art.net, XV,  'MiniBatchSize', 64);
            YPredTe = classify(art.net, XTestMat, 'MiniBatchSize', 64);

            f = figure('Name', [name ' - Confusions']);
            subplot(1,3,1); confusionchart(YTr, YPredTr); title('Train');
            subplot(1,3,2); confusionchart(YV,  YPredV);  title('Validation');
            subplot(1,3,3); confusionchart(YTestCat, YPredTe); title('Test');
            local_save_png(f, figDir, [name '_best_confusions'], res, closeAfter);
        end

        % One sample per digit (test)
        local_render_digit_samples_mlp(art.net, XTestVec, YTest, imgSize, figDir, name, res, closeAfter);
    end
end

% CNN figures
if hasCnn
    S = load(cnnPath, 'cnn_results');
    cnn_results = S.cnn_results;

    if ~isfield(cnn_results, 'bestArtifacts') || isempty(cnn_results.bestArtifacts) || ~isfield(cnn_results.bestArtifacts, 'net')
        warning('CNN bestArtifacts not found in %s. Re-run training with opts.saveBestArtifacts=true.', cnnPath);
    else
        art = cnn_results.bestArtifacts;
        name = 'CNN_best';
        if isfield(art, 'modelName') && ~isempty(art.modelName)
            name = sprintf('CNN_%s', char(art.modelName));
        end

        % Loss plot
        if isfield(art, 'info') && ~isempty(art.info) && isfield(art.info, 'TrainingLoss')
            f = figure('Name', [name ' - Loss']);
            plot(art.info.TrainingLoss, 'LineWidth', 1.5); hold on;
            if isfield(art.info, 'ValidationLoss') && ~isempty(art.info.ValidationLoss)
                plot(art.info.ValidationLoss, 'LineWidth', 1.5);
                legend('Training loss','Validation loss','Location','best');
            else
                legend('Training loss','Location','best');
            end
            grid on; xlabel('Iteration'); ylabel('Loss');
            title([name ' - Training vs Validation Loss']);
            local_save_png(f, figDir, [name '_best_loss'], res, closeAfter);
        end

        % Confusion matrices (train/val/test)
        if isfield(art, 'trainIdx') && ~isempty(art.trainIdx) && isfield(art, 'valIdx') && ~isempty(art.valIdx)
            XTr = XTrain4D(:, :, :, art.trainIdx);
            YTr = YTrainCat(art.trainIdx);
            XV  = XTrain4D(:, :, :, art.valIdx);
            YV  = YTrainCat(art.valIdx);

            YPredTr = classify(art.net, XTr, 'MiniBatchSize', 64);
            YPredV  = classify(art.net, XV,  'MiniBatchSize', 64);
            YPredTe = classify(art.net, XTest4D, 'MiniBatchSize', 64);

            f = figure('Name', [name ' - Confusions']);
            subplot(1,3,1); confusionchart(YTr, YPredTr); title('Train');
            subplot(1,3,2); confusionchart(YV,  YPredV);  title('Validation');
            subplot(1,3,3); confusionchart(YTestCat, YPredTe); title('Test');
            local_save_png(f, figDir, [name '_best_confusions'], res, closeAfter);
        end

        % One sample per digit (test)
        local_render_digit_samples_cnn(art.net, XTest4D, YTestCat, figDir, name, res, closeAfter);
    end
end

fprintf('Re-rendered figures into: %s (r=%d)\n', figDir, round(res));
end

% ---------------- local helpers ----------------
function local_save_png(fig, figDir, baseName, res, closeAfter)
if isstring(baseName)
    baseName = char(baseName);
end
pngPath = fullfile(figDir, sprintf('%s.png', baseName));
try
    if exist('exportgraphics', 'file') == 2
        exportgraphics(fig, pngPath, 'Resolution', res);
    else
        print(fig, pngPath, '-dpng', sprintf('-r%d', round(res)));
    end
catch
    try
        print(fig, pngPath, '-dpng', sprintf('-r%d', round(res)));
    catch
    end
end
if closeAfter
    try, close(fig); catch, end
end
end

function local_render_digit_samples_mlp(net, XTestVec, YTest, imgSize, figDir, name, res, closeAfter)
figSamples = figure('Name', [name ' - Digit Samples'], 'Position', [100, 100, 1100, 450]);
figOutputs = figure('Name', [name ' - Outputs'], 'Position', [100, 100, 1100, 450]);

all_true = [];
all_pred = [];

for digit = 0:9
    idx = find(YTest == digit, 1);
    if isempty(idx)
        continue;
    end
    sampleVec = XTestVec(:, idx)';
    [pred_label, scores] = classify(net, sampleVec, 'MiniBatchSize', 1);
    pred = str2double(string(pred_label));

    all_true(end+1) = digit; %#ok<AGROW>
    all_pred(end+1) = pred;  %#ok<AGROW>

    img = reshape(sampleVec, imgSize(1), imgSize(2));
    figure(figSamples);
    subplot(2, 5, digit+1);
    imshow(img, []);
    title(sprintf('%d -> %d', digit, pred));

    figure(figOutputs);
    subplot(2, 5, digit+1);
    bar(scores);
    grid on;
    xlim([0.5 10.5]);
    title(sprintf('Digit %d', digit));
end

f3 = figure('Name', [name ' - Confusion (Digit Samples)']);
confusionchart(categorical(all_true), categorical(all_pred));
title('Confusion Matrix (one sample per digit)');

local_save_png(figSamples, figDir, [name '_digit_samples'], res, closeAfter);
local_save_png(figOutputs, figDir, [name '_digit_outputs'], res, closeAfter);
local_save_png(f3, figDir, [name '_digit_samples_confusion'], res, closeAfter);
end

function local_render_digit_samples_cnn(net, XTest4D, YTestCat, figDir, name, res, closeAfter)
figSamples = figure('Name', [name ' - Digit Samples'], 'Position', [100, 100, 1100, 450]);
figOutputs = figure('Name', [name ' - Outputs'], 'Position', [100, 100, 1100, 450]);

all_true = categorical;
all_pred = categorical;

for digit = 0:9
    digit_cat = categorical(digit, 0:9, string(0:9));
    idx = find(YTestCat == digit_cat, 1);
    if isempty(idx)
        continue;
    end
    sample = XTest4D(:, :, :, idx);
    [pred_label, scores] = classify(net, sample, 'MiniBatchSize', 1);

    all_true(end+1) = digit_cat; %#ok<AGROW>
    all_pred(end+1) = pred_label; %#ok<AGROW>

    figure(figSamples);
    subplot(2, 5, digit+1);
    imshow(sample(:, :, 1, 1), []);
    title(sprintf('%d -> %s', digit, char(string(pred_label))));

    figure(figOutputs);
    subplot(2, 5, digit+1);
    bar(scores);
    grid on;
    xlim([0.5 10.5]);
    title(sprintf('Digit %d', digit));
end

f3 = figure('Name', [name ' - Confusion (Digit Samples)']);
confusionchart(all_true, all_pred);
title('Confusion Matrix (one sample per digit)');

local_save_png(figSamples, figDir, [name '_digit_samples'], res, closeAfter);
local_save_png(figOutputs, figDir, [name '_digit_outputs'], res, closeAfter);
local_save_png(f3, figDir, [name '_digit_samples_confusion'], res, closeAfter);
end
