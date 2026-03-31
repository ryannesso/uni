clear; clc; close all;
load CTGdata.mat; 

if size(typ_ochorenia, 1) > size(typ_ochorenia, 2)
    typ_ochorenia = typ_ochorenia'; 
end

inputs = NDATA'; 
targets = full(ind2vec(typ_ochorenia));

% 1. Definícia 3 štruktúr na porovnanie (podľa zadania) 
allConfigs = { [50], [40 20], [40 25 15] };
numConfigs = length(allConfigs);
numRuns = 5; 

% Indexy vzoriek pre testovanie (normálny, podozrivý, patologický)
s1 = find(typ_ochorenia == 1, 1); 
s2 = find(typ_ochorenia == 2, 1); 
s3 = find(typ_ochorenia == 3, 1); 
selected_inputs = NDATA([s1, s2, s3], :)';

% Príprava tabuľky pre celkové výsledky
summary = struct('Config', {}, 'MinAcc', [], 'MaxAcc', [], 'AvgAcc', []);

for c = 1:numConfigs
    hiddenLayers = allConfigs{c};
    configStr = num2str(hiddenLayers);
    
    fprintf('\n==================================================\n');
    fprintf('SPÚŠŤAM TRÉNOVANIE PRE ŠTRUKTÚRU: [%s]\n', configStr);
    fprintf('--------------------------------------------------\n');
    
    stats = struct('trainAcc', zeros(1, numRuns), 'testAcc', zeros(1, numRuns));
    allNets = cell(1, numRuns);
    allTr = cell(1, numRuns);

    for i = 1:numRuns
        net = patternnet(hiddenLayers);
        
        % Parametrizácia 
        net.divideParam.trainRatio = 0.6; 
        net.divideParam.valRatio   = 0.2; 
        net.divideParam.testRatio  = 0.2;
       
        net.trainParam.epochs = 200;     
        net.trainParam.showWindow = false; 
        net.trainParam.max_fail = 12;
        net.performParam.regularization = 0.1;  
        
        [net, tr] = train(net, inputs, targets);
        
        % Výpočet presnosti
        outputs = net(inputs);
        
        % Train Acc
        trainOut = outputs(:, tr.trainInd);
        trainTar = targets(:, tr.trainInd);
        [cTrain, ~] = confusion(trainTar, trainOut);
        stats.trainAcc(i) = (1 - cTrain) * 100;
        
        % Test Acc
        testOut = outputs(:, tr.testInd);
        testTar = targets(:, tr.testInd);
        [cTest, ~] = confusion(testTar, testOut);
        stats.testAcc(i) = (1 - cTest) * 100;
        
        allNets{i} = net;
        allTr{i} = tr;
        
        fprintf('Beh č. %d: Train Acc: %6.2f%% | Test Acc: %6.2f%%\n', ...
                i, stats.trainAcc(i), stats.testAcc(i));
    end

    % Uloženie štatistík
    summary(c).Config = configStr;
    summary(c).MinAcc = min(stats.testAcc);
    summary(c).MaxAcc = max(stats.testAcc);
    summary(c).AvgAcc = mean(stats.testAcc);

    % Výber najlepšieho behu pre vizualizáciu a metriky
    [~, bestIdx] = max(stats.testAcc);
    bestNet = allNets{bestIdx};
    bestTr = allTr{bestIdx};

    % --- KLASIFIKÁCIA JEDNOTLIVÝCH VZORIEK (pre každú štruktúru) ---
    res = sim(bestNet, selected_inputs);
    predicted = vec2ind(res);
    fprintf('\n--- Klasifikácia vzoriek pre najlepší beh [%s] ---\n', configStr);
    fprintf('Normálny (1): Predikovaná trieda = %d\n', predicted(1));
    fprintf('Podozrivý (2): Predikovaná trieda = %d\n', predicted(2));
    fprintf('Patologický (3): Predikovaná trieda = %d\n', predicted(3));

    % --- SENZITIVITA A ŠPECIFICITA ---
    finalOut = bestNet(inputs);
    [~, cm] = confusion(targets, finalOut);
    fprintf('\nMetriky pre najlepší beh (č. %d):\n', bestIdx);
    for j = 1:3
        TP = cm(j,j);
        FN = sum(cm(j,:)) - TP;
        FP = sum(cm(:,j)) - TP;
        TN = sum(cm(:)) - (TP + FN + FP); 
        sens = TP / (TP + FN);
        spec = TN / (TN + FP);
        fprintf('  Trieda %d: Senzitivita: %.3f, Špecificita: %.3f\n', j, sens, spec);
    end

    %% Grafy
    % Performance (Loss vs Epochs)
    figure('Name', ['Performance - Štruktúra [' configStr ']']);
    plotperform(bestTr);

    % Confusion Matrix
    figure('Name', ['Confusion Matrix - Štruktúra [' configStr ']']);
    plotconfusion(targets, bestNet(inputs));
end

%% FINÁLNE POROVNANIE
fprintf('\n==============================================================\n');
fprintf('ZÁVEREČNÉ POROVNANIE ŠTRUKTÚR:\n');
fprintf('%-15s | %-12s | %-12s | %-12s\n', 'Štruktúra', 'Min Acc [%]', 'Max Acc [%]', 'Priemer [%]');
fprintf('--------------------------------------------------------------\n');
for c = 1:numConfigs
    fprintf('%-15s | %-12.2f | %-12.2f | %-12.2f\n', ...
        summary(c).Config, summary(c).MinAcc, summary(c).MaxAcc, summary(c).AvgAcc);
end