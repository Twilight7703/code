function [chaosBytes,maskBits] = salomon_material(height,width,password,nonce,contentDigest,streamMode)
%SALOMON_MATERIAL 生成改进Salomon-DNA扩散所需混沌材料。
% 输入:
%   height,width  - 待处理图像的行数和列数。
%   password      - 加密口令。
%   nonce         - 16字节随机数。
%   contentDigest - 标记图像SHA-512摘要。
%   streamMode    - 数据包记录的映射与四路序列版本标识。
% 输出:
%   chaosBytes - height×width的uint8混沌矩阵。
%   maskBits   - height×(4*width)的DNA互补逻辑掩码。

if nargin<5 || isempty(contentDigest)
    error('改进Salomon映射必须绑定标记图像SHA-512摘要。');
end
if nargin<6 || isempty(streamMode)
    error('数据包缺少改进Salomon映射版本标识。');
end

v4Mode='password+nonce+markedSha512+improved-salomon-cross-feedback-v4';
if ~strcmpi(char(streamMode),v4Mode)
    error(['当前代码已直接替换为改进Salomon交叉反馈方程，', ...
        '不支持旧v2/v3映射数据包。']);
end

pixelCount=height*width;
key=salomon_key(password,nonce,contentDigest);
[x,y]=salomon_sequence(2*pixelCount,key);
% x、y两个维度分别按奇偶下标拆分为两路，共得到四路长度N的序列。
streams=[x(1:2:end).',x(2:2:end).',y(1:2:end).',y(2:2:end).'];
byteVector=uint8(min(255,floor(256*streams(:,1))));
chaosBytes=reshape(byteVector,width,height).';
maskBits=reshape((streams>0.5).',4*width,height).';
end
