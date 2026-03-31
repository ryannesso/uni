clear; clc; close all;

% 1. Načítanie dát
load('CTGdata.mat'); 
inputs = NDATA'; 
targets = full(ind2vec(typ_ochorenia')); 

% 2. Nastavenie parametrov
num_runs = 5;
neurons = 20; 
net = patternnet(neurons);
best_accs = zeros(num_runs, 1);
all_nets = cell(num_runs, 1);
all_tr = cell(num_runs, 1);

fprintf('Začínam trénovanie pre štruktúru: [%d]\n', neurons);

for i = 1:num_runs

    
    net.divideFcn = 'dividerand';
    net.divideParam.trainRatio = 0.6;
    net.divideParam.valRatio = 0.2; 
    net.divideParam.testRatio = 0.2;
    
    net.trainParam.showWindow = false; 
    net.trainParam.goal = 1e-6;       
    net.trainParam.max_fail = 10;

    net.trainParam.epochs = 100;
    
    [net, tr] = train(net, inputs, targets);
    
    all_nets{i} = net;
    all_tr{i} = tr;
    
    outputs = sim(net, inputs);
    
    [c, cm] = confusion(targets, outputs);
    best_accs(i) = 100 * (1 - c);
    
    fprintf('Beh %d: Úspešnosť = %.2f%%\n', i, best_accs(i));
end

% 4. Výsledky
fprintf('\n--- Štatistika pre štruktúru [%d] ---\n', neurons);
fprintf('Min úspešnosť: %.2f%%\n', min(best_accs));
fprintf('Max úspešnosť: %.2f%%\n', max(best_accs));
fprintf('Priemerná úspešnosť: %.2f%%\n', mean(best_accs));

% 5. Výber najlepšieho behu
[~, best_idx] = max(best_accs);
best_net = all_nets{best_idx};
best_tr = all_tr{best_idx};

% --- Bod 11: Testovanie konkrétnych vzoriek ---
sample1 = find(typ_ochorenia == 1, 1);
sample2 = find(typ_ochorenia == 2, 1);
sample3 = find(typ_ochorenia == 3, 1);
selected_inputs = NDATA([sample1, sample2, sample3], :)';
results = sim(best_net, selected_inputs);
predicted = vec2ind(results);

fprintf('\n--- Klasifikácia jednotlivých vzoriek ---\n');
fprintf('Normálny (1): Predikovaná trieda = %d\n', predicted(1));
fprintf('Podozrivý (2): Predikovaná trieda = %d\n', predicted(2));
fprintf('Patologický (3): Predikovaná trieda = %d\n', predicted(3));

% --- Bod 12: Senzitivita a Špecificita ---
finalOut = best_net(inputs);
% Prevod na triedy pre confusionmat
[~, true_classes] = max(targets);
[~, pred_classes] = max(finalOut);
confMat = confusionmat(true_classes, pred_classes);

fprintf('\n--- Metriky pre najlepší beh (č. %d) ---\n', best_idx);
for j = 1:3
    TP = confMat(j,j);
    FN = sum(confMat(j,:)) - TP;
    FP = sum(confMat(:,j)) - TP;
    TN = sum(confMat(:)) - (TP + FN + FP); 
    sens = TP / (TP + FN);
    spec = TN / (TN + FP);
    fprintf('Trieda %d: Senzitivita: %.3f, Špecificita: %.3f\n', j, sens, spec);
end

% 6. Vizualizácia
figure('Name', ['Performance - Štruktúra [' num2str(neurons) ']']);
plotperform(best_tr);

figure('Name', ['Confusion Matrix - Štruktúra [' num2str(neurons) ']']);
plotconfusion(targets, best_net(inputs));