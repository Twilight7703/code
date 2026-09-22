function data = array_to_bytes(array)
%ARRAY_TO_BYTES 按MATLAB列主序提取数值数组的原始字节。
% 输入: array-uint8或uint16数组。
% 输出: data-uint8字节行向量。

if isa(array, 'uint8')
    data = reshape(array, 1, []);
elseif isa(array, 'uint16')
    data = reshape(typecast(array(:), 'uint8'), 1, []);
else
    error('array_to_bytes仅支持uint8或uint16数组。');
end
end

