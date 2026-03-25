clear;

load datapiscisla_all

% Transpose to get rows as samples (more convenient)
X = XDataall';      % Now X is 4940 × 784
Y = YDataall';      % Now Y is 4940 × 10

inputSize = [28 28 1];
numClasses = 10;

layers = [
    imageInputLayer(inputSize)
    convolution2dLayer(5, 20)   % 1st
    batchNormalizationLayer
    reluLayer
    convolution2dLayer(3, 40)   % 2nd
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(numClasses)
    softmaxLayer
];

options = trainingOptions("sgdm", ...
    MaxEpochs=5, ...
    ValidationFrequency=30, ...
    Plots="training-progress", ...
    Metrics="accuracy", ...
    Verbose=false);

numRuns = 1;
accuracies = zeros(numRuns, 1);
bestAccuracy = -inf;

for i = 1:numRuns
    fprintf("\n--- Run %d ---\n", i);

    % Shuffle dataset again
    [~, classLabels] = max(Y, [], 2);  % back to one-hot to class number
    XTrain = []; YTrain = []; XVal = []; YVal = [];
    
    for class = 1:10
        idx = find(classLabels == class);
        idx = idx(randperm(length(idx)));

        numTrain = round(0.6 * length(idx));
        trainIdx = idx(1:numTrain);
        valIdx = idx(numTrain+1:end);

        XTrain = [XTrain; X(trainIdx, :)];
        YTrain = [YTrain; Y(trainIdx, :)];
        XVal = [XVal; X(valIdx, :)];
        YVal = [YVal; Y(valIdx, :)];
    end

    % Reshape
    XTrainImg = reshape(XTrain', 28, 28, 1, []);
    XValImg = reshape(XVal', 28, 28, 1, []);
    [~, trainClass] = max(YTrain, [], 2);
    [~, valClass] = max(YVal, [], 2);
    YTrainLbl = categorical(trainClass - 1);
    YValLbl = categorical(valClass - 1);

    % Add validation data
    options.ValidationData = {XValImg, YValLbl};

    % Train network
    net = trainnet(XTrainImg, YTrainLbl, layers, "crossentropy", options);

    % Evaluate accuracy using testnet
    trainAcc = testnet(net, XTrainImg, YTrainLbl, "accuracy");  % Training accuracy
    acc = testnet(net, XValImg, YValLbl, "accuracy");           % Validation accuracy
    accuracies(i) = acc;
    
    fprintf("Train Accuracy (Run %d): %.2f %%\n", i, trainAcc);
    fprintf("Validation Accuracy (Run %d): %.2f %%\n", i, acc);
    
    % Save best result
    if acc > bestAccuracy
        bestAccuracy = acc;
        bestNet = net;
    
        % Raw prediction scores: 10 x N
        bestYPred = predict(net, XValImg);  % DON'T convert to categorical here
    
        % Convert true labels to one-hot format (targets)
        bestTrueIdx = double(YValLbl);      % categorical → 1-10
        bestTargets = full(ind2vec(bestTrueIdx'));  % Make it 10 x N
    
        bestYTrue = bestTargets;
    end
end

fprintf("\nBest accuracy from 5 runs: %.2f %%\n", bestAccuracy);

figure;
plotconfusion(bestYTrue, bestYPred', "Confusion Matrix – Best CNN Run");

% Print the final best training accuracy (for best model)
fprintf("Best Train Accuracy: %.2f %%\n", trainAcc);
fprintf("Best Validation Accuracy: %.2f %%\n", bestAccuracy);
