clear; clc;

S1 = 1;         
S2 = 1;         

S10 = 100 / 10000; 
S20 = 100 / 10000; 

mu = 0.62;     
g = 9.81;      

Q1_initial = 0.01942;    
Q1_step_time = 700;      
Q1_final = Q1_initial / 2; 

K_out1 = mu * S10 * sqrt(2 * g); 
K_out2 = mu * S20 * sqrt(2 * g); 
inv_S1 = 1 / S1;
inv_S2 = 1 / S2;

h2_target = 0.3; 

Q1_target_sys1 = mu * S20 * sqrt(2 * g * h2_target);

Q1_target_sys2 = (mu * S10 * sqrt(2) + mu * S20) * sqrt(2 * g * h2_target);

disp(['Q1 = ', num2str(Q1_target_sys1)]);
disp(['Q1 = ', num2str(Q1_target_sys2)]);