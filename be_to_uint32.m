function value = be_to_uint32(bytes)
%BE_TO_UINT32 将4字节大端序转换为uint32标量。
% 输入: bytes-至少4个uint8字节。
% 输出: value-uint32整数。

bytes = uint32(bytes(1:4));
value = bitshift(bytes(1),24) + bitshift(bytes(2),16) + ...
    bitshift(bytes(3),8) + bytes(4);
end

