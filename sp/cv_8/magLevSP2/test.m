figure
hold on
plot(out.y.Time,out.y.Data)
plot(out.r.Time,out.r.Data)
xlabel('t[s]');
ylabel('y,r [pu]');
legend('y(t)','r(t)');