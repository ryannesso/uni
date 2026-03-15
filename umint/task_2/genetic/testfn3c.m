% Test function 3c (New Schwefel's objective function)
% global optimum: x(i)=-864.72 ;  min F(x)= -792.72*n , n-number of variables
% -1000 < x(i) < 1000

function[Fit]=testfn3c(Pop)

x0=30;  
y0=100; 

[lpop,lstring]=size(Pop);
Fit=zeros(1,lpop);

for i=1:lpop
  x=Pop(i,:);
  Fit(i)=0;	
  for j=1:lstring
    Fit(i)=Fit(i)-(x(j)-x0)*sin(sqrt(abs((x(j)-x0))))+y0;
  end    
end
