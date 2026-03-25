clear

% NDATA(2126x25) typ_ochorenia(2126x1)
load CTGdata.mat

inputs = NDATA';                    % 25 x 2126
targets = full(ind2vec(typ_ochorenia'));  % 3 x 2126

neurons = 45;
net = patternnet(neurons);

runs = 1;

% Initialize variables to store results
trainAccs = zeros(runs, 1);
testAccs = zeros(runs, 1);
overallAccs = zeros(runs, 1);
 
for run = 1:runs
    
    net.divideParam.trainRatio = 0.6; 
    net.divideParam.valRatio = 0.0;   
    net.divideParam.testRatio = 0.4;  

    % Set training parameters
    net.trainParam.goal = 1e-4;       
    net.trainParam.epochs = 300;      
    net.trainParam.show = 20;         
    
    % Train the network for this run
    [net, tr] = train(net, inputs, targets);
    
    % Simulate network output
    outnetsim = sim(net, inputs);
    
    % Convert output to predicted classes
    predicted_classes = vec2ind(outnetsim);
    true_classes = vec2ind(targets);
    
    % Calculate accuracy for training, testing, and overall
    trainAccs(run) = sum(predicted_classes(tr.trainInd) == true_classes(tr.trainInd)) / length(tr.trainInd) * 100;
    testAccs(run) = sum(predicted_classes(tr.testInd) == true_classes(tr.testInd)) / length(tr.testInd) * 100;
    overallAccs(run) = sum(predicted_classes == true_classes) / length(true_classes) * 100;

    % Confusion matrix calculation
    confMat = confusionmat(true_classes, predicted_classes);
    
    % Extract TP, FN, TN, FP from the confusion matrix
    TP = confMat(2, 2) + confMat(3, 3);  % True Positives (2nd and 3rd classes)
    FN = confMat(2, 1) + confMat(3, 1);  % False Negatives (1st class predicted as 2nd or 3rd)
    TN = confMat(1, 1);                  % True Negatives (1st class predicted as 1st)
    FP = confMat(1, 2) + confMat(1, 3);  % False Positives (1st class predicted as 2nd or 3rd)
    
    % Sensitivity (Recall for positive class)
    sensitivity = TP / (TP + FN);
    
    % Specificity (Recall for negative class)
    specificity = TN / (TN + FP);
    
    % Display confusion matrix for each run
    figure
    plotconfusion(targets(:, tr.trainInd), outnetsim(:, tr.trainInd), 'Training Run ' + string(run))
    figure
    plotconfusion(targets(:, tr.testInd), outnetsim(:, tr.testInd), 'Testing Run ' + string(run))
    figure
    plotconfusion(targets, outnetsim, 'Overall Run ' + string(run))
    % Display Sensitivity and Specificity
    fprintf('Run %d - Sensitivity: %.2f %%\n', run, sensitivity * 100);
    fprintf('Run %d - Specificity: %.2f %%\n', run, specificity * 100);
end

% Calculate min, max, and average accuracy
minTrainAcc = min(trainAccs);
maxTrainAcc = max(trainAccs);
avgTrainAcc = mean(trainAccs);

minTestAcc = min(testAccs);
maxTestAcc = max(testAccs);
avgTestAcc = mean(testAccs);

minOverallAcc = min(overallAccs);
maxOverallAcc = max(overallAccs);
avgOverallAcc = mean(overallAccs);

% Display results
fprintf('--- Results after 5 Runs ---\n');
fprintf('Min Training Accuracy: %.2f %%\n', minTrainAcc);
fprintf('Max Training Accuracy: %.2f %%\n', maxTrainAcc);
fprintf('Avg Training Accuracy: %.2f %%\n', avgTrainAcc);

fprintf('Min Test Accuracy: %.2f %%\n', minTestAcc);
fprintf('Max Test Accuracy: %.2f %%\n', maxTestAcc);
fprintf('Avg Test Accuracy: %.2f %%\n', avgTestAcc);

fprintf('Min Overall Accuracy: %.2f %%\n', minOverallAcc);
fprintf('Max Overall Accuracy: %.2f %%\n', maxOverallAcc);
fprintf('Avg Overall Accuracy: %.2f %%\n', avgOverallAcc);

sample1 = find(typ_ochorenia == 1, 1);  % normálny
sample2 = find(typ_ochorenia == 2, 1);  % podozrivý
sample3 = find(typ_ochorenia == 3, 1);  % patologický

% Získaj vstupy a simuluj sieť
selected_inputs = NDATA([sample1, sample2, sample3], :)';
results = sim(net, selected_inputs);
predicted = vec2ind(results);

% Výpis
fprintf('\n--- Klasifikácia jednotlivých vzoriek ---\n');
fprintf('Normálny (1): Predikovaná trieda = %d\n', predicted(1));
fprintf('Podozrivý (2): Predikovaná trieda = %d\n', predicted(2));
fprintf('Patologický (3): Predikovaná trieda = %d\n', predicted(3));