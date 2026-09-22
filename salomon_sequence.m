function [xValues,yValues] = salomon_sequence(lengthValue,key)
%SALOMON_SEQUENCE 生成改进二维Salomon交叉反馈混沌序列。
% 输入:
%   lengthValue - 舍弃暂态后需要的序列长度。
%   key         - salomon_key输出结构体，包含x0、y0、a、b、c、d和discard。
% 输出:
%   xValues,yValues - [0,1)范围的double行向量。

lengthValue=double(lengthValue);
xValues=zeros(1,lengthValue);
yValues=zeros(1,lengthValue);
x=key.x0;
y=key.y0;
tenA=10^key.a;
tenB=10^key.b;
out=0;
for index=1:key.discard+lengthValue
    radius=hypot(x,y);
    x=mod(tenA-cos(2*pi*radius)+tenB*(radius+key.c*sin(2*pi*y)),1);
    coupledRadius=hypot(x,y);
    y=mod(tenB-cos(2*pi*coupledRadius)+ ...
        tenA*(coupledRadius+key.d*sin(2*pi*x)),1);
    if index>key.discard
        out=out+1;
        xValues(out)=x;
        yValues(out)=y;
    end
end
end
