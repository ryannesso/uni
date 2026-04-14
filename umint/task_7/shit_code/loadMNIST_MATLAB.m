function [XTrainVec, YTrain, XTestVec, YTest, XTrain4D, XTest4D, imgSize] = loadMNIST_MATLAB(baseDir)
%LOADMNIST_MATLAB Load MNIST from the MNIST_MATLAB folder (IDX files).
%
% Usage:
%   [XTrainVec, YTrain, XTestVec, YTest, XTrain4D, XTest4D, imgSize] = loadMNIST_MATLAB('MNIST_MATLAB');
%
% Outputs:
%   XTrainVec: [784 x Ntrain] single, normalized to [0,1]
%   YTrain:    [1 x Ntrain] double labels 0..9
%   XTestVec:  [784 x Ntest] single, normalized to [0,1]
%   YTest:     [1 x Ntest] double labels 0..9
%   XTrain4D:  [H x W x 1 x Ntrain] single
%   XTest4D:   [H x W x 1 x Ntest] single
%   imgSize:   [H W]

if nargin < 1 || strlength(string(baseDir)) == 0
    baseDir = 'MNIST_MATLAB';
end

trainImagesFile = fullfile(baseDir, 'train', 'images.idx3-ubyte');
trainLabelsFile = fullfile(baseDir, 'train', 'labels.idx1-ubyte');
testImagesFile  = fullfile(baseDir, 'test',  'images.idx3-ubyte');
testLabelsFile  = fullfile(baseDir, 'test',  'labels.idx1-ubyte');

trainImages = mnistReadImages(trainImagesFile); % [H x W x N]
trainLabels = mnistReadLabels(trainLabelsFile); % [1 x N]

testImages = mnistReadImages(testImagesFile);
testLabels = mnistReadLabels(testLabelsFile);

imgSize = [size(trainImages, 1) size(trainImages, 2)];

numTrain = size(trainImages, 3);
numTest  = size(testImages, 3);

XTrainVec = reshape(trainImages, [], numTrain);
XTestVec  = reshape(testImages,  [], numTest);

XTrain4D = reshape(trainImages, imgSize(1), imgSize(2), 1, numTrain);
XTest4D  = reshape(testImages,  imgSize(1), imgSize(2), 1, numTest);

YTrain = trainLabels;
YTest  = testLabels;
end
