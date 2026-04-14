%% ЧАСТЬ 1: ИДЕНТИФИКАЦИЯ (Для рабочего точки 4V)
clear; clc; close all;

% 1. ЗАГРУЖАЕМ ФАЙЛ С ДАННЫМИ ДЛЯ 4V (впиши свое название файла!)
load('cv7_kiriienko_lovkin.mat'); % <--- ИЗМЕНИ НАЗВАНИЕ ФАЙЛА

% Достаем данные (если они у тебя сохранены как объекты из Simulink)
% Если после load у тебя в Workspace уже есть um и ym, эти 3 строки не нужны.
um_4 = u_signal.Values.Data;
ym_4 = y_signal.Values.Data;
tm_4 = y_signal.Values.Time;

% --- OBR. 1: График начального скачка (до 10 секунд) ---
figure(1);
plot(tm_4, ym_4, 'LineWidth', 1.5); hold on;
yline(3.911, 'r--', 'Y0 = 3.911 V', 'LineWidth', 1.5);
grid on; title('OBR. 1: Skoková zmena (0 -> 4V)');
xlabel('t[s]'); ylabel('y[V]');

% --- Подготовка данных для идентификации (отрезаем первые 10 сек) ---
indxs = find(tm_4 > 10);
U0_4 = 4; 
Y0_4 = 3.911;

u_4 = um_4(indxs) - U0_4;
y_4 = ym_4(indxs) - Y0_4;
t_4 = tm_4(indxs);
z_4 = iddata(y_4, u_4, 0.01);

% --- Обучаем модели 1-го и 2-го порядка ---
m1 = arx(z_4, [1, 1, 1]); % Модель 1-го порядка
m2 = arx(z_4, [2, 2, 1]); % Модель 2-го порядка (ЛУЧШАЯ)

% Выводим формулы в консоль (чтобы ты скопировал их в Word-отчет)
disp('--- Prenosova funkcia 1. radu ---'); tf(polyform(m1), [1], 0.01)
disp('--- Prenosova funkcia 2. radu ---'); tf(polyform(m2), [1], 0.01)

% --- OBR. 2 и 3: Графики сравнения для 4V ---
figure(2); compare(z_4, m1); title('OBR. 2: Model 1. rádu (4V)');
figure(3); compare(z_4, m2); title('OBR. 3: Model 2. rádu (4V)');


%% ЧАСТЬ 2: ВАЛИДАЦИЯ (Для рабочего точки 5V)
% 2. ЗАГРУЖАЕМ ФАЙЛ С ДАННЫМИ ДЛЯ 5V (впиши свое название файла!)
load('cv7_kiriienko_lovkin_2.mat'); % <--- ИЗМЕНИ НАЗВАНИЕ ФАЙЛА

% Снова достаем переменные (они перезапишут старые um и ym, но m2 останется!)
um_5 = u_signal.Values.Data;
ym_5 = y_signal.Values.Data;
tm_5 = y_signal.Values.Time;

indxs_5 = find(tm_5 > 10);
U0_5 = 5; 
Y0_5 = 5.234; % Из твоего отчета

% Убираем постоянную составляющую 5V
u_5 = um_5(indxs_5) - U0_5;
y_5 = ym_5(indxs_5) - Y0_5;
z_5 = iddata(y_5, u_5, 0.01);

% --- OBR. 4: ВАЛИДАЦИЯ БЕЗ ПЕРЕОБУЧЕНИЯ ---
% Берем СТАРУЮ модель (m2) и проверяем на НОВЫХ данных (z_5)
figure(4);
compare(z_5, m2); 
title('OBR. 4: Validácia modelu 2. rádu v pracovnom bode U0=5V');