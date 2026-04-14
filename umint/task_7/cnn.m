clc; clear; close all;

% ===============================
% Nastavenie ciest k datasetu
% ===============================
zipSubor = fullfile(pwd, 'MNIST_MATLAB.zip');
korenovyPriecinok = fullfile(pwd, 'MNIST_MATLAB');

if ~isfolder(korenovyPriecinok)
    if ~isfile(zipSubor)
        error('Subor MNIST_MATLAB.zip nebol najdeny v aktualnom priecinku.');
    end
    unzip(zipSubor, pwd);
end

trainFolder = fullfile(korenovyPriecinok, 'train');
testFolder  = fullfile(korenovyPriecinok, 'test');

trainImagesFile = fullfile(trainFolder, 'images.idx3-ubyte');
trainLabelsFile = fullfile(trainFolder, 'labels.idx1-ubyte');
testImagesFile  = fullfile(testFolder,  'images.idx3-ubyte');
testLabelsFile  = fullfile(testFolder,  'labels.idx1-ubyte');

% ===============================
% Kontrola existencie suborov
% ===============================
if ~isfile(trainImagesFile)
    error('Subor train/images.idx3-ubyte nebol najdeny.');
end

if ~isfile(trainLabelsFile)
    error('Subor train/labels.idx1-ubyte nebol najdeny.');
end

if ~isfile(testImagesFile)
    error('Subor test/images.idx3-ubyte nebol najdeny.');
end

if ~isfile(testLabelsFile)
    error('Subor test/labels.idx1-ubyte nebol najdeny.');
end

% ===============================
% Nacitanie datasetu MNIST z IDX suborov
% ===============================
XTrain = nacitajMNISTObrazky(trainImagesFile);
YTrain = nacitajMNISTStitky(trainLabelsFile);

XTest = nacitajMNISTObrazky(testImagesFile);
YTest = nacitajMNISTStitky(testLabelsFile);

% ===============================
% Prevod stitkov na categorical
% ===============================
classNames = string(0:9);
YTrain = categorical(YTrain, 0:9, classNames);
YTest  = categorical(YTest,  0:9, classNames);

% ===============================
% Zakladne parametre
% ===============================
num_runs = 5;
miniBatchSize = 64;
img_size = 28;

train_total_all = zeros(1, num_runs);
test_total_all  = zeros(1, num_runs);

best_net = [];
best_accuracy = 0;
best_info = [];

% ===============================
% Architektura CNN
% ===============================
layers = [
    imageInputLayer([img_size img_size 1], 'Normalization', 'none', 'Name', 'input')

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
    dropoutLayer(0.2, 'Name', 'drop1')

    fullyConnectedLayer(10, 'Name', 'fc_out')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'output')
];

for opakovanie = 1:num_runs
    fprintf('\n== Training run %d ==\n', opakovanie);

    % ===============================
    % Nastavenie trenovania
    % ===============================
    options = trainingOptions('adam', ...
        'InitialLearnRate', 1e-3, ...
        'MaxEpochs', 15, ...
        'MiniBatchSize', miniBatchSize, ...
        'Shuffle', 'every-epoch', ...
        'Verbose', true, ...
        'Plots', 'training-progress', ...
        'ExecutionEnvironment', 'gpu');   % manualne prepni na 'cpu' alebo 'gpu'

    [net, info] = trainNetwork(XTrain, YTrain, layers, options);

    % ===============================
    % Vyhodnotenie modelu
    % ===============================
    YPredTrain = classify(net, XTrain, 'MiniBatchSize', miniBatchSize);
    YPredTest  = classify(net, XTest,  'MiniBatchSize', miniBatchSize);

    train_accuracy = mean(YPredTrain == YTrain);
    test_accuracy  = mean(YPredTest  == YTest);

    train_total_all(opakovanie) = train_accuracy;
    test_total_all(opakovanie)  = test_accuracy;

    if test_accuracy > best_accuracy
        best_accuracy = test_accuracy;
        best_net = net;
        best_info = info;
    end

    fprintf('Training accuracy: %.2f %%\n', train_accuracy * 100);
    fprintf('Testing accuracy:  %.2f %%\n', test_accuracy * 100);

    % ===============================
    % Kontingencne matice
    % ===============================
    figure('Name', sprintf('Kontingencne matice - Beh %d', opakovanie));

    subplot(1,2,1);
    confusionchart(YTrain, YPredTrain);
    title(sprintf('Training - Beh %d', opakovanie));

    subplot(1,2,2);
    confusionchart(YTest, YPredTest);
    title(sprintf('Testing - Beh %d', opakovanie));
end

% ===============================
% Suhrn vysledkov
% ===============================
fprintf('\n== Summary of %d runs ==\n', num_runs);
fprintf('Training: Min=%.2f%% | Avg=%.2f%% | Max=%.2f%%\n', ...
    min(train_total_all)*100, mean(train_total_all)*100, max(train_total_all)*100);
fprintf('Testing:  Min=%.2f%% | Avg=%.2f%% | Max=%.2f%%\n', ...
    min(test_total_all)*100, mean(test_total_all)*100, max(test_total_all)*100);

% ===============================
% Graf priebehu ucenia najlepsieho behu
% ===============================
if ~isempty(best_info)
    figure('Name', 'Najlepsi beh - Loss vs Iteration');
    plot(best_info.TrainingLoss, 'LineWidth', 1.5);
    grid on;
    xlabel('Iteration');
    ylabel('Loss');
    title('Najlepsi CNN beh: Training Loss');
    legend('Training loss', 'Location', 'best');
end

% ===============================
% Testovanie jednej vzorky pre kazdu cislicu 0-9
% ===============================
fprintf('\n== Testovanie jednej vzorky pre kazdu cislicu 0-9 ==\n');

figure('Name', 'Vzorky cislic', 'Position', [100, 100, 1000, 400]);

all_true = categorical();
all_pred = categorical();

for digit = 0:9
    digit_cat = categorical(digit, 0:9, classNames);

    idx = find(YTest == digit_cat, 1);

    if isempty(idx)
        warning('Cislica %d nebola najdena!', digit);
        continue;
    end

    sample = XTest(:, :, :, idx);
    pred_label = classify(best_net, sample);

    all_true(end+1) = digit_cat;
    all_pred(end+1) = pred_label;

    subplot(2, 5, digit+1);
    imshow(sample(:, :, 1), []);
    if pred_label == digit_cat
        title(sprintf('%d -> %s (OK)', digit, string(pred_label)), 'Color', 'g');
    else
        title(sprintf('%d -> %s (ERR)', digit, string(pred_label)), 'Color', 'r');
    end
end

figure('Name', 'Finalna kontingencna matica pre testovanie cislic');
confusionchart(all_true, all_pred);
title('Kontingencna matica pre testovanie cislic (0-9)');

fprintf('\n== Done ==\n');

% ===============================
% Pomocna funkcia na nacitanie obrazkov MNIST z IDX suboru
% ===============================
function X = nacitajMNISTObrazky(filename)
    fid = fopen(filename, 'rb');

    if fid == -1
        error('Subor %s sa nepodarilo otvorit.', filename);
    end

    magic = fread(fid, 1, 'int32', 0, 'ieee-be');
    if magic ~= 2051
        fclose(fid);
        error('Subor %s nema spravny format IDX pre obrazky.', filename);
    end

    pocetObrazkov = fread(fid, 1, 'int32', 0, 'ieee-be');
    pocetRiadkov  = fread(fid, 1, 'int32', 0, 'ieee-be');
    pocetStlpcov  = fread(fid, 1, 'int32', 0, 'ieee-be');

    data = fread(fid, inf, 'unsigned char');
    fclose(fid);

    expectedCount = pocetObrazkov * pocetRiadkov * pocetStlpcov;
    if numel(data) ~= expectedCount
        error('Pocet nacitanych pixelov v subore %s nesedi.', filename);
    end

    data = reshape(data, [pocetStlpcov, pocetRiadkov, pocetObrazkov]);
    data = permute(data, [2 1 3]);
    data = single(data) / 255;

    X = reshape(data, [pocetRiadkov, pocetStlpcov, 1, pocetObrazkov]);
end

% ===============================
% Pomocna funkcia na nacitanie stitkov MNIST z IDX suboru
% ===============================
function Y = nacitajMNISTStitky(filename)
    fid = fopen(filename, 'rb');

    if fid == -1
        error('Subor %s sa nepodarilo otvorit.', filename);
    end

    magic = fread(fid, 1, 'int32', 0, 'ieee-be');
    if magic ~= 2049
        fclose(fid);
        error('Subor %s nema spravny format IDX pre stitky.', filename);
    end

    pocetStitkov = fread(fid, 1, 'int32', 0, 'ieee-be');
    Y = fread(fid, inf, 'unsigned char');
    fclose(fid);

    if numel(Y) ~= pocetStitkov
        error('Pocet nacitanych stitkov v subore %s nesedi.', filename);
    end

    Y = double(Y(:));
end