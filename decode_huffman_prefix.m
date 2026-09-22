function [symbol,consumed] = decode_huffman_prefix(bits,startIndex,codebook)
%DECODE_HUFFMAN_PREFIX 从指定位置解码一个哈夫曼前缀码。
% 输入:
%   bits       - 完整0/1向量。
%   startIndex - MATLAB起始下标。
%   codebook   - build_huffman_codes产生的1x8元胞。
% 输出:
%   symbol     - 解出的0~7符号。
%   consumed   - 消耗比特数。

maxLength=max(cellfun(@numel,codebook));
prefix='';
for offset=0:maxLength-1
    if startIndex+offset>numel(bits), break; end
    prefix=[prefix,char('0'+bits(startIndex+offset))]; %#ok<AGROW>
    for index=1:numel(codebook)
        if ~isempty(codebook{index}) && strcmp(prefix,codebook{index})
            symbol=index-1;
            consumed=offset+1;
            return;
        end
    end
end
error('无法从嵌入块中解码哈夫曼标签。');
end

