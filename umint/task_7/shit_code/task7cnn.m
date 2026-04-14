clc; clear; close all;

% =========================================================
% Task 7 (UMINT): CNN on MNIST_MATLAB (IDX)
% - fixed test set (10k)
% - validation is split from training set (60k)
% - compare >= 3 CNN architectures, each run >= 5 times
% - additionally compare >= 3 dropout settings (5 runs each)
% =========================================================

[~, YTrain, ~, YTest, XTrain4D, XTest4D, imgSize] = loadMNIST_MATLAB('MNIST_MATLAB');

classNames = string(0:9);
YTrainCat = categorical(YTrain, 0:9, classNames);
YTestCat  = categorical(YTest,  0:9, classNames);

numTrain = numel(YTrainCat);
numTest  = numel(YTestCat);

% Ratios kept consistent with the original template (70k total => 56k train, 10k test, 4k val)
num_runs = 5;
trainRatioTotal = 0.8;
testRatioTotal  = 0.143;
valRatioTotal   = 1 - trainRatioTotal - testRatioTotal;

trainFractionWithinTrain = trainRatioTotal / (trainRatioTotal + valRatioTotal);
valFractionWithinTrain   = valRatioTotal / (trainRatioTotal + valRatioTotal);

miniBatchSize = 64;
initialLearnRate = 1e-3;
maxEpochs = 15;
validationPatience = 5;

% Use 'auto' for normal runs (GPU if available)
mainExecutionEnvironment = 'auto';

clc; clear; close all;

% Script wrapper to keep the original run style.
cnn_results = task7cnn_run();