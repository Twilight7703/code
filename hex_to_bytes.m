function data = hex_to_bytes(text)
%HEX_TO_BYTES 将偶数长度十六进制文本转换为uint8字节。
text = char(text);
if mod(numel(text), 2) ~= 0
    error('十六进制字符串长度必须为偶数。');
end
data = uint8(hex2dec(reshape(text, 2, []).')).';
end

