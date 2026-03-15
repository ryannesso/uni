function v_sum = v_sum(x)
    s = sum(x);
    v = [max(0, s - 10e6), max(0, (x(1)+x(2)) - 2.5e6), ...
         max(0, x(5) - x(4)), max(0, (x(3)+x(4)) - 0.5*s), sum(max(0,-x))];
    v_sum = sum(v);
end