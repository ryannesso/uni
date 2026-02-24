S  = 1;         
S0 = 0.01;       
mu = 0.62;       
rho = 1000;      
g  = 9.81;      

h0 = 1; 
M1_steady = mu * S0 * rho * sqrt(2 * g * h0);
fprintf('M1 = %.2f kg/s\n\n', M1_steady);

% Формулы линеаризации
T_lin = (2 * S * sqrt(h0)) / (mu * S0 * sqrt(2 * g));
K_lin = (2 * sqrt(h0)) / (mu * S0 * rho * sqrt(2 * g));

fprintf('T = %.2f s\n', T_lin);
fprintf('K = %.4f\n\n', K_lin);

h_points = [2, 0.25]; 

for h_p = h_points
    T_p = (2 * S * sqrt(h_p)) / (mu * S0 * sqrt(2 * g));
    K_p = (2 * sqrt(h_p)) / (mu * S0 * rho * sqrt(2 * g));
    
    fprintf('h = %.2f м: T = %.2f s, K = %.4f\n', h_p, T_p, K_p);
end
fprintf('\n');

h_max = 2; 
M1_max = mu * S0 * rho * sqrt(2 * g * h_max);

fprintf('M1_max = %.2f kg/s\n', M1_max);