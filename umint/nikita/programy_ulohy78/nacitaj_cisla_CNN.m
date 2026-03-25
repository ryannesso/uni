clear;

% Load MNIST-like data
load('datapiscisla_all.mat');  % XDataall: 784 x 4940

% Generate labels: 494 samples per digit, digits 0–9
Y = [];
for i = 0:9
    Y = [Y, i * ones(1, 494)];
end

% Convert labels to one-hot encoded format
targets = full(ind2vec(Y + 1));  % Classes 1–10 for digits 0–9
inputs = XDataall;               % 784 x 4940

% Set number of repetitions (for cross-validation or random splitting)
runs = 1;

% Store accuracies
acc_train_all = zeros(1, runs);
acc_test_all = zeros(1, runs);
acc_total_all = zeros(1, runs);

% Loop for running training and testing multiple times
for run = 1:runs
    % Shuffle data randomly
    idx = randperm(size(inputs, 2));  % Random permutation of indices
    inputs_shuffled = inputs(:, idx);
    targets_shuffled = targets(:, idx);
    
    % Create neural network
    neurons = 80;
    net = patternnet(neurons);

    % Use ratio-based automatic division
    net.divideParam.trainRatio = 0.6;
    net.divideParam.valRatio = 0.0;
    net.divideParam.testRatio = 0.4;

    % Set training parameters
    net.trainParam.goal = 1e-5;
    net.trainParam.epochs = 300;
    net.trainParam.show = 20;

    % Train the network
    [net, tr] = train(net, inputs_shuffled, targets_shuffled);

    % Simulate output on all data
    outputs = net(inputs_shuffled);

    % Convert to predicted class indices
    predicted = vec2ind(outputs);
    true_labels = vec2ind(targets_shuffled);

    % Compute accuracy for this run
    acc_train_all(run) = sum(predicted(tr.trainInd) == true_labels(tr.trainInd)) / length(tr.trainInd) * 100;
    acc_test_all(run) = sum(predicted(tr.testInd) == true_labels(tr.testInd)) / length(tr.testInd) * 100;
    acc_total_all(run) = sum(predicted == true_labels) / length(true_labels) * 100;
    
    fprintf('\n--- Výsledky klasifikácie pre beh %d ---\n', run);
    fprintf('Train Accuracy: %.2f %%\n', acc_train_all(run));
    fprintf('Test Accuracy: %.2f %%\n', acc_test_all(run));
    fprintf('Total Accuracy: %.2f %%\n', acc_total_all(run));

    % Confusion matrices
    figure, plotconfusion(targets_shuffled(:, tr.trainInd), outputs(:, tr.trainInd), 'Training')
    figure, plotconfusion(targets_shuffled(:, tr.testInd), outputs(:, tr.testInd), 'Testing')
    figure, plotconfusion(targets_shuffled, outputs, 'Overall')

    % Show 10 test digit predictions
    figure
    random_test_ids = tr.testInd(randperm(length(tr.testInd), 10));
    for i = 1:10
        idx = random_test_ids(i);
        digit_img = reshape(inputs_shuffled(:,idx), [28,28]);
        predicted_digit = predicted(idx) - 1;  % Back to 0–9

        subplot(2,5,i)
        imshow(digit_img')
        title(['Pred: ', num2str(predicted_digit)])
    end
end

% Calculate min, max, and average accuracy
fprintf('\n--- Štatistiky z %d bežov ---\n', runs);
fprintf('Minimálna úspešnosť na trénovacích dátach: %.2f %%\n', min(acc_train_all));
fprintf('Maximálna úspešnosť na trénovacích dátach: %.2f %%\n', max(acc_train_all));
fprintf('Priemerná úspešnosť na trénovacích dátach: %.2f %%\n', mean(acc_train_all));

fprintf('Minimálna úspešnosť na testovacích dátach: %.2f %%\n', min(acc_test_all));
fprintf('Maximálna úspešnosť na testovacích dátach: %.2f %%\n', max(acc_test_all));
fprintf('Priemerná úspešnosť na testovacích dátach: %.2f %%\n', mean(acc_test_all));

fprintf('Minimálna celková úspešnosť: %.2f %%\n', min(acc_total_all));
fprintf('Maximálna celková úspešnosť: %.2f %%\n', max(acc_total_all));
fprintf('Priemerná celková úspešnosť: %.2f %%\n', mean(acc_total_all));

fprintf('\n--- Klasifikácia jednej vzorky z každej číslice (0–9) ---\n');
for digit = 0:9
    % Find the first occurrence of each digit in the shuffled dataset
    idx = find(true_labels == digit + 1, 1);  % true_labels are 1–10
    
    % Make sure we're using the trained network from the current run
    sample_input = inputs_shuffled(:, idx);  % Use shuffled input
    result = net(sample_input);  % Use the network trained in this run
    predicted_class = vec2ind(result) - 1;  % back to 0–9

    fprintf('Číslica %d → Predikovaná trieda = %d\n', digit, predicted_class);
end

