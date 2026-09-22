function text = bytes_to_hex(data)
%BYTES_TO_HEX 将uint8字节转换为小写十六进制字符行向量。
text = lower(reshape(dec2hex(uint8(data), 2).', 1, []));
end

