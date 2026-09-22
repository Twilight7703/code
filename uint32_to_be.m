function bytes = uint32_to_be(value)
%UINT32_TO_BE 将标量转换为4字节大端序。
% 输入: value-0~2^32-1标量。
% 输出: bytes-1x4 uint8大端字节。

value = uint32(value);
bytes = uint8([bitshift(value,-24), bitand(bitshift(value,-16),255), ...
    bitand(bitshift(value,-8),255), bitand(value,255)]);
end

