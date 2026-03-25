clear;

load datapiscisla_all  % This loads XDataall

% Transpose to get rows as samples (more convenient)
X = XDataall';      % Now X is 4940 × 784
Y = YDataall';      % Now Y is 4940 × 10

[~, classLabels] = max(Y, [], 2);  % Convert one-hot to label (1–10)
classCounts = histcounts(classLabels, 1:11);

disp("Samples per class:")
disp(classCounts)

% Set number of training samples per class
numTrainPerClass = 297;  % if you have 494 per class, for example

XTrain = [];
YTrain = [];
XValidation = [];
YValidation = [];

for class = 1:10
    idx = find(classLabels == class);
    idx = idx(randperm(length(idx)));  % shuffle
    
    trainIdx = idx(1:numTrainPerClass);
    valIdx = idx(numTrainPerClass+1:end);

    XTrain = [XTrain; X(trainIdx, :)];
    YTrain = [YTrain; Y(trainIdx, :)];

    XValidation = [XValidation; X(valIdx, :)];
    YValidation = [YValidation; Y(valIdx, :)];
end


XTrainImages = reshape(XTrain', 28, 28, 1, []);
XValidationImages = reshape(XValidation', 28, 28, 1, []);
[~, YTrainClass] = max(YTrain, [], 2);
[~, YValidationClass] = max(YValidation, [], 2);

YTrainLabels = categorical(YTrainClass - 1);            % Labels: [2970x1], 0-based
YValidationLabels = categorical(YValidationClass - 1);  % Labels: [1970x1]

inputSize = [28 28 1];
numClasses = 10;

layers = [
    imageInputLayer(inputSize)
    convolution2dLayer(5,20)
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(numClasses)
    softmaxLayer];

options = trainingOptions("sgdm", ...
    MaxEpochs=5, ...
    ValidationData={XValidationImages, YValidationLabels}, ...
    ValidationFrequency=30, ...
    Plots="training-progress", ...
    Metrics="accuracy", ...
    Verbose=false);

net = trainnet(XTrainImages, YTrainLabels, layers, "crossentropy", options);

accuracy = testnet(net,XValidationImages,YValidationLabels,"accuracy")
