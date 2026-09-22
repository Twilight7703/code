function data = lzw12_decode(packed, codeCount)
%LZW12_DECODE 解码固定12位LZW码流。
% 输入:
%   packed    - lzw12_encode输出的uint8数据。
%   codeCount - 有效码字数。
% 输出:
%   data      - 完整恢复的uint8原始字节串。

codeCount = double(codeCount);
if codeCount == 0
    data = zeros(1,0,'uint8');
    return;
end
bits = bytes_to_bits(packed);
if numel(bits) < 12*codeCount
    error('LZW码流长度不足。');
end
codes = zeros(1, codeCount, 'uint16');
for index = 1:codeCount
    codes(index) = uint16(bits_to_int(bits((index-1)*12+1:index*12)));
end

dictionary = cell(1,4096);
for value = 0:255
    dictionary{value+1} = uint8(value);
end
nextCode = 256;
firstCode = double(codes(1));
if firstCode > 255
    error('LZW首码字不合法。');
end
previous = dictionary{firstCode+1};
parts = cell(1,codeCount);
parts{1} = previous;
for index = 2:codeCount
    code = double(codes(index));
    if code < nextCode && ~isempty(dictionary{code+1})
        entry = dictionary{code+1};
    elseif code == nextCode
        entry = [previous, previous(1)];
    else
        error('LZW码流损坏或码字顺序不合法。');
    end
    parts{index} = entry;
    if nextCode <= 4095
        dictionary{nextCode+1} = [previous, entry(1)];
        nextCode = nextCode + 1;
    end
    previous = entry;
end
data = [parts{:}];
end

