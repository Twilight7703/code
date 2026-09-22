function bits = bytes_to_bits(data)
%BYTES_TO_BITS 将字节串转换为高位在前的0/1行向量。
% 输入:
%   data - uint8字节向量。
% 输出:
%   bits - uint8类型比特行向量，每字节按MSB到LSB展开。

data = uint8(data(:));
if isempty(data)
    bits = zeros(1, 0, 'uint8');
    return;
end
matrix = zeros(8, numel(data), 'uint8');
for k = 1:8
    matrix(k, :) = uint8(bitget(data, 9-k));
end
bits = reshape(matrix, 1, []);
end

