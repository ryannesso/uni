clear
% suradnice x,y,z piatich skupin bodov
load databody

% vykreslenie bodov podla skupin
h=figure;
plot3(data1(:,1),data1(:,2),data1(:,3),'b+')
hold on
plot3(data2(:,1),data2(:,2),data2(:,3),'co')
plot3(data3(:,1),data3(:,2),data3(:,3),'g*')
plot3(data4(:,1),data4(:,2),data4(:,3),'r*')
plot3(data5(:,1),data5(:,2),data5(:,3),'mx')

axis([0 1 0 1 0 1])
title('Data body')
xlabel('x')
ylabel('y')
zlabel('z')

disp(' --------------- stlac klavesu --------------')
pause

% vstupne a vystupne data na trenovanie neuronovej siete
% 3x250
datainnet=[data1; data2; data3; data4; data5]';

% 5x250
dataoutnet = [repmat([1;0;0;0;0],1,50), ...
              repmat([0;1;0;0;0],1,50), ...
              repmat([0;0;1;0;0],1,50), ...
              repmat([0;0;0;1;0],1,50), ...
              repmat([0;0;0;0;1],1,50)];

% vytvorenie struktury siete
pocet_neuronov=6;
net = patternnet(pocet_neuronov);

% parametre rozdelenia dat na trenovanie, validacne a testovanie
% net.divideFcn='dividerand';
% net.divideParam.trainRatio=0.8;
% net.divideParam.valRatio=0;
% net.divideParam.testRatio=0.2;

% vlastne delenie dat, napr. indexove
indx=randperm(250);
net.divideFcn='divideind';      % indexove
net.divideParam.trainInd=indx(1:200);
net.divideParam.valInd=[];
net.divideParam.testInd=indx(201:250);


% nastavenie parametrov trenovania 
net.trainParam.goal = 1e-6;       
net.trainParam.show = 20;          
net.trainParam.epochs = 200;        
net.trainParam.max_fail=12;

% trenovanie NS
[net, tr] = train(net,datainnet,dataoutnet);

% zobrazenie struktury siete
view(net)

% simulacia vystupu NS pre trenovacie data
% testovanie NS
outnetsim = sim(net,datainnet);

% chyba NS a dat
err=(outnetsim-dataoutnet);

% percento neuspesne klasifikovanych bodov
c = confusion(dataoutnet,outnetsim);

% kontingenèná matica
figure
plotconfusion(dataoutnet,outnetsim)

% klasifikacia 5 novych bodov do tried
novepointy = [0.1 0.3 0.6 0.9 0.5;
              0.2 0.4 0.7 0.8 0.5;
              0.3 0.5 0.2 0.7 0.5];

outnew = sim(net, novepointy);
classnew = vec2ind(outnew);
disp('New points classified into groups:');
disp(classnew)

figure;
hold on

colors = ['b', 'c', 'g', 'r', 'm'];

for i = 1:5
    klas = classnew(i);             
    x = novepointy(1,i);                  
    y = novepointy(2,i);                  
    z = novepointy(3,i);                  
    plot3(x, y, z, 's', 'MarkerSize', 10, 'LineWidth', 2, 'Color', colors(klas)) 
    text(x, y, z, ['  ' num2str(klas)], 'FontSize', 12, 'Color', 'k')
end

figure;
plotperform(tr);