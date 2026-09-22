function [xNext,yNext] = salomon_step(x,y,a,b,c,d)
%SALOMON_STEP 执行一次改进二维Salomon非线性交叉反馈映射。
% 输入:
%   x,y - 当前二维状态，取值范围为[0,1)。
%   a,b - 原Salomon映射的指数控制参数。
%   c,d - 正弦非线性交叉反馈强度，由salomon_key派生。
% 输出:
%   xNext,yNext - 下一次迭代的二维状态，取值范围为[0,1)。

radius=hypot(x,y);
xNext=mod(10^a-cos(2*pi*radius)+10^b*(radius+c*sin(2*pi*y)),1);
coupledRadius=hypot(xNext,y);
yNext=mod(10^b-cos(2*pi*coupledRadius)+ ...
    10^a*(coupledRadius+d*sin(2*pi*xNext)),1);
end
