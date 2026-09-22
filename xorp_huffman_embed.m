function [marked,metadata] = xorp_huffman_embed(carrier,secretData,fillSeed)
%XORP_HUFFMAN_EMBED 论文2的XOR保持与哈夫曼自适应可逆嵌入。
% 输入:
%   carrier    - uint8二维单通道载体图像。
%   secretData - 待嵌入uint8字节，通常为差分LZW容器。
%   fillSeed   - 剩余容量伪随机填充种子(uint8)，不参与秘密恢复。
% 输出:
%   marked     - 嵌入后的uint8标记图像。
%   metadata   - 首块lambda、哈夫曼码本及容量等解码旁信息。

if nargin<3, fillSeed=zeros(1,0,'uint8'); end
secretData=uint8(secretData(:).'); fillSeed=uint8(fillSeed(:).');
blocks=xorp_analyze_blocks(carrier);
b1=blocks([blocks.embeddable]); b2=blocks(~[blocks.embeddable]);
if isempty(b1), error('载体中没有可嵌入的XORP块。'); end
labels=[b1.lambda];
codebook=build_huffman_codes(labels);
nextSymbols=[labels(2:end),7];
b2MSB=uint8([b2.refMSB]);

payloadHeader=[uint8('XHAC'),uint8(1),uint32_to_be(numel(secretData)), ...
    uint32_to_be(numel(b2)),sha_bytes(secretData,'SHA-256')];
globalBits=[bytes_to_bits(payloadHeader),b2MSB,bytes_to_bits(secretData)];
usableCapacity=0;
for k=1:numel(b1)
    blockCapacity=3*(8-b1(k).lambda);
    usableCapacity=usableCapacity+blockCapacity-1-numel(codebook{nextSymbols(k)+1});
end
if numel(globalBits)>usableCapacity
    error(['秘密数据超过载体容量：需要%d bit，可用%d bit。', ...
        '请换用更大的平滑载体或更小的秘密图像。'],numel(globalBits),usableCapacity);
end

marked=carrier; globalIndex=1;
for k=1:numel(b1)
    block=b1(k); row=block.row; column=block.column; lambda=block.lambda;
    bitsPerNeighbor=8-lambda; capacity=3*bitsPerNeighbor;
    labelBits=uint8(codebook{nextSymbols(k)+1}-'0');
    localBits=[uint8(block.refMSB),labelBits];
    take=min(capacity-numel(localBits),numel(globalBits)-globalIndex+1);
    if take>0
        localBits=[localBits,globalBits(globalIndex:globalIndex+take-1)]; %#ok<AGROW>
        globalIndex=globalIndex+take;
    end
    localBits=[localBits,xorp_filler_bits(fillSeed,row,column,capacity-numel(localBits))]; %#ok<AGROW>

    reference=carrier(row,column);
    marked(row,column)=bitand(reference,uint8(127)); % MSB=0标记B1
    positions=[row,column+1;row+1,column;row+1,column+1];
    if lambda==0, lowMask=uint8(0); else, lowMask=uint8(2^lambda-1); end
    for n=1:3
        xorLow=bitand(bitxor(reference,carrier(positions(n,1),positions(n,2))),lowMask);
        startIndex=(n-1)*bitsPerNeighbor+1;
        prefix=bits_to_int(localBits(startIndex:startIndex+bitsPerNeighbor-1));
        marked(positions(n,1),positions(n,2))=bitor(bitshift(uint8(prefix),lambda),xorLow);
    end
end
for k=1:numel(b2)
    marked(b2(k).row,b2(k).column)=bitor(marked(b2(k).row,b2(k).column),uint8(128));
end
if globalIndex~=numel(globalBits)+1
    error('内部错误：全局秘密比特未完全写入。');
end
metadata=struct('version',1,'firstLambda',labels(1),'codebook',{codebook}, ...
    'usableCapacityBits',usableCapacity,'payloadBits',numel(globalBits), ...
    'blockRows',floor(size(carrier,1)/2),'blockColumns',floor(size(carrier,2)/2));
end

function bits=xorp_filler_bits(seed,row,column,count)
% 使用SHA-256计数模式生成不参与恢复的填充比特。
bits=zeros(1,0,'uint8'); counter=0;
while numel(bits)<count
    material=[seed,uint32_to_be(row),uint32_to_be(column),uint32_to_be(counter)];
    bits=[bits,bytes_to_bits(sha_bytes(material,'SHA-256'))]; %#ok<AGROW>
    counter=counter+1;
end
bits=bits(1:count);
end

