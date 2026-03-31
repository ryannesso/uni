clear; clc; close all;

% Načítanie dát
load CTGdata.mat
inputs = NDATA';                    
targets = full(ind2vec(typ_ochorenia'));  

% Definovanie 3 štruktúr pre porovnanie
allConfigs = {[60 30 10]};
numConfigs = length(allConfigs);
runs = 5;

% Premenné pre uloženie globálne najlepšej siete (Bod 5)
globalBestAcc = 0;
globalBestNet =[];
globalBestConfigStr = '';
globalBestIdx = 0;

fprintf('==============================================================\n');
fprintf('ÚLOHA 6: KLASIFIKÁCIA NA MEDICÍNSKYCH DÁTACH\n');
fprintf('==============================================================\n');

for c = 1:numConfigs
    neurons = allConfigs{c};
    configStr = num2str(neurons);
    
    trainAccs = zeros(runs, 1);
    testAccs = zeros(runs, 1);
    overallAccs = zeros(runs, 1);
    allNets = cell(1, runs);
    allTr = cell(1, runs);

    fprintf('\n>>> Porovnávaná štruktúra: [%s] <<<\n', configStr);
    
    for run = 1:runs
        net = patternnet(neurons);
        net.divideParam.trainRatio = 0.6; 
        net.divideParam.valRatio = 0.2;   
        net.divideParam.testRatio = 0.2;  

        net.trainParam.goal = 1e-4;       
        net.trainParam.epochs = 300;      
        net.trainParam.showWindow = false;[net, tr] = train(net, inputs, targets);
        
        allNets{run} = net;
        allTr{run} = tr;
        
        outnetsim = sim(net, inputs);
        predicted_classes = vec2ind(outnetsim);
        true_classes = vec2ind(targets);
        
        trainAccs(run) = sum(predicted_classes(tr.trainInd) == true_classes(tr.trainInd)) / length(tr.trainInd) * 100;
        testAccs(run) = sum(predicted_classes(tr.testInd) == true_classes(tr.testInd)) / length(tr.testInd) * 100;
        overallAccs(run) = sum(predicted_classes == true_classes) / length(true_classes) * 100;

        fprintf(' Beh %d: Train: %6.2f%% | Test: %6.2f%% | Celkovo: %6.2f%%\n', run, trainAccs(run), testAccs(run), overallAccs(run));
    end

    % Bod 4: Pre každú štruktúru uveďte minimálnu, maximálnu a priemernú úspešnosť
    fprintf(' --------------------------------------------------------\n');
    fprintf(' Štatistika pre [%s] na TEST dátach:\n', configStr);
    fprintf(' Min: %.2f%% | Max: %.2f%% | Priemer: %.2f%%\n', min(testAccs), max(testAccs), mean(testAccs));
    
    % Bod 4: Pre najlepší výsledok z každej štruktúry uveďte priebeh učenia a maticu
    [bestTestAccOfConfig, bestIdx] = max(testAccs);
    bestNetOfConfig = allNets{bestIdx};
    bestTrOfConfig = allTr{bestIdx};
    
    figure('Name', ['Performance - Štruktúra [' configStr ']']);
    plotperform(bestTrOfConfig);
    
    figure('Name',['Confusion Matrix - Štruktúra [' configStr ']']);
    plotconfusion(targets, bestNetOfConfig(inputs));
    title(['Kontingenčná matica (najlepší beh č. ' num2str(bestIdx) ' pre štruktúru[' configStr '])']);
    
    % Hľadanie úplne najlepšej siete pre bod 5
    if bestTestAccOfConfig > globalBestAcc
        globalBestAcc = bestTestAccOfConfig;
        globalBestNet = bestNetOfConfig;
        globalBestConfigStr = configStr;
        globalBestIdx = bestIdx;
    end
end

fprintf('\n==============================================================\n');
fprintf('BOD 5: ANALÝZA ÚPLNE NAJLEPŠEJ SIETE ZO VŠETKÝCH\n');
fprintf('Najlepšia štruktúra: [%s] (beh č. %d) s Test Acc = %.2f%%\n', globalBestConfigStr, globalBestIdx, globalBestAcc);
fprintf('==============================================================\n');

% Bod 5: postup testovania vybraných vzoriek
sample1 = find(typ_ochorenia == 1, 1);  % normálny
sample2 = find(typ_ochorenia == 2, 1);  % podozrivý
sample3 = find(typ_ochorenia == 3, 1);  % patologický

selected_inputs = NDATA([sample1, sample2, sample3], :)';
results = sim(globalBestNet, selected_inputs);
predicted = vec2ind(results);

fprintf('\n--- Klasifikácia vybraných vzoriek ---\n');
fprintf('Vzorka index %d (Skutočnosť: 1 - normálny): Predikcia = %d\n', sample1, predicted(1));
fprintf('Vzorka index %d (Skutočnosť: 2 - podozrivý): Predikcia = %d\n', sample2, predicted(2));
fprintf('Vzorka index %d (Skutočnosť: 3 - patologický): Predikcia = %d\n', sample3, predicted(3));

% Bod 5: Výsledná úspešnosť klasifikácie, senzitivita a špecificita
finalOut = globalBestNet(inputs);
predicted_global = vec2ind(finalOut);
true_global = vec2ind(targets);

final_overall_acc = sum(predicted_global == true_global) / length(true_global) * 100;
fprintf('\n--- Výsledná celková úspešnosť najlepšej siete: %.2f%% ---\n', final_overall_acc);

[~, cm] = confusion(targets, finalOut);
fprintf('\n--- Senzitivita a Špecificita (najlepšia sieť) ---\n');
for j = 1:3
    TP = cm(j,j);
    FN = sum(cm(j,:)) - TP;
    FP = sum(cm(:,j)) - TP;
    TN = sum(cm(:)) - (TP + FN + FP); 
    
    sens = TP / (TP + FN);
    spec = TN / (TN + FP);
    fprintf(' Trieda %d: Senzitivita: %.3f, Špecificita: %.3f\n', j, sens, spec);
end