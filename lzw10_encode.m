function [packed, codeCount] = lzw10_encode(data)
%LZW10_ENCODE 使用固定10位码字执行LZW无损压缩。
% 输入：data为uint8字节序列；输出packed为打包码流，codeCount为码字数量。
data = uint8(data(:).');
if isempty(data)
    packed = zeros(1,0,'uint8');
    codeCount = uint32(0);
    return;
end

dictionary = containers.Map('KeyType','char','ValueType','uint16');
for value = 0:255
    dictionary(char(uint8(value))) = uint16(value);
end
nextCode = 256;
codes = zeros(1,max(1,numel(data)),'uint16');
count = 0;
current = data(1);
for index = 2:numel(data)
    symbol = data(index);
    candidate = [current,symbol]; %#ok<AGROW>
    key = char(candidate);
    if isKey(dictionary,key)
        current = candidate;
    else
        count = count + 1;
        codes(count) = dictionary(char(current));
        if nextCode <= 1023
            dictionary(key) = uint16(nextCode);
            nextCode = nextCode + 1;
        end
        current = symbol;
    end
end
count = count + 1;
codes(count) = dictionary(char(current));
codes = codes(1:count);
codeCount = uint32(count);

bits = zeros(1,10*count,'uint8');
for index = 1:count
    bits((index-1)*10+1:index*10) = int_to_bits(double(codes(index)),10);
end
packed = bits_to_bytes(bits);
end
