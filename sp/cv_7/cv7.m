logsout = out.get('logsout');
u_signal = logsout.get('u');
y_signal = logsout.get('y');
um = u_signal.Values.Data;
ym = y_signal.Values.Data;
tm = y_signal.Values.Time;
indxs = find(tm > 10);
Y0 = 3.911;
U0 = 4; % bolo 5
u = um(indxs)-U0;
y = ym(indxs)-Y0;
t = tm(indxs);
z = iddata(y,u, 0.01);
na = 2;
nb = 2;
nk = 1; %dopravne oneskorenie
n = [na,nb,nk];
%m = arx(z,n);    % Treba neskor zakomentovat 
[a,b] = polyform(m);    
sysdis = tf(b,a,0.01);
ys = idsim(u,m);

figure(1);
plot(t,y,t,ys)
grid on
xlabel('t[s]')
ylabel('y[V]')
legend('y(t)','y_s(t)') 


figure(2);
compare(z,m)
%save("data_cv7.mat");