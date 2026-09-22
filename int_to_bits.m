function bits = int_to_bits(value, width)
%INT_TO_BITS 把非负整数转换为固定宽度、MSB在前的比特行向量。
% 输入: value-非负整数，width-输出位数。
% 输出: bits-uint8类型0/1行向量。

if value < 0 || value >= 2^width
    error('整数%d不能用%d位表示。', value, width);
end
bits = zeros(1, width, 'uint8');
for k = 1:width
    bits(k) = uint8(bitget(uint32(value), width-k+1));
end
end

