function value = bits_to_int(bits)
%BITS_TO_INT 把MSB在前的比特序列转换为double整数。
% 输入: bits-0/1向量。
% 输出: value-对应非负整数。

value = 0;
for bit = uint8(bits(:).')
    value = value*2 + double(bit);
end
end

