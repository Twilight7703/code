function jacobian = salomon_jacobian(x,y,a,b,c,d)
%SALOMON_JACOBIAN 计算改进二维 Salomon 映射的解析雅可比矩阵。
% mod(u,1) 在不连续点以外的导数为 1，因此采用取模前表达式的局部导数。

tenA = 10^a;
tenB = 10^b;
radius = hypot(x,y);
if radius == 0
    error('Salomon 映射在原点处的半径导数未定义。');
end

radiusGain = 2*pi*sin(2*pi*radius) + tenB;
xDerivativeX = radiusGain*x/radius;
xDerivativeY = radiusGain*y/radius + ...
    tenB*c*2*pi*cos(2*pi*y);

[xNext,~] = salomon_step(x,y,a,b,c,d);
coupledRadius = hypot(xNext,y);
if coupledRadius == 0
    error('Salomon 映射在耦合原点处的半径导数未定义。');
end

coupledGain = 2*pi*sin(2*pi*coupledRadius) + tenA;
feedbackGain = tenA*d*2*pi*cos(2*pi*xNext);
chainGain = coupledGain*xNext/coupledRadius + feedbackGain;
yDerivativeX = chainGain*xDerivativeX;
yDerivativeY = chainGain*xDerivativeY + coupledGain*y/coupledRadius;
jacobian = [xDerivativeX,xDerivativeY;yDerivativeX,yDerivativeY];
end
