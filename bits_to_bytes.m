function data = bits_to_bytes(bits)
%BITS_TO_BYTES 将高位在前的0/1序列打包为uint8字节串。
% 输入:
%   bits - 0/1向量；不足8位时仅在末尾补0。
% 输出:
%   data - uint8字节行向量。

bits = uint8(bits(:).');
remainder = mod(numel(bits), 8);
if remainder ~= 0
    bits = [bits, zeros(1, 8-remainder, 'uint8')]; %#ok<AGROW>
end
if isempty(bits)
    data = zeros(1, 0, 'uint8');
    return;
end
matrix = reshape(bits, 8, []);
weights = 2.^(7:-1:0).';
data = uint8(sum(double(matrix).*weights, 1));
end

