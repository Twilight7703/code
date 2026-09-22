function [recovered,secretData] = xorp_huffman_extract(marked,metadata)
%XORP_HUFFMAN_EXTRACT 提取秘密数据并无损恢复原载体图像。
% 输入:
%   marked   - 解密后的uint8二维标记图像。
%   metadata - xorp_huffman_embed生成/JSON恢复的旁信息。
% 输出:
%   recovered  - 无损恢复的原载体。
%   secretData - 提取出的uint8秘密字节。

if ~isa(marked,'uint8') || ~ismatrix(marked)
    error('XORP提取输入必须是uint8二维图像。');
end
codebook=metadata.codebook;
if isstring(codebook), codebook=cellstr(codebook); end
codebook=reshape(codebook,1,[]);
currentLambda=double(metadata.firstLambda);
recovered=marked; globalBits=zeros(1,0,'uint8');
b2Positions=zeros(0,2); reachedEnd=false;
[height,width]=size(marked);
for row=1:2:height-1
    for column=1:2:width-1
        marker=bitget(marked(row,column),8);
        if marker==1
            b2Positions(end+1,:)=[row,column]; %#ok<AGROW>
            continue;
        end
        if reachedEnd, error('哈夫曼结束符后仍出现B1块。'); end
        if currentLambda<0 || currentLambda>6, error('XORP阈值lambda越界。'); end
        bitsPerNeighbor=8-currentLambda;
        positions=[row,column+1;row+1,column;row+1,column+1];
        localBits=zeros(1,3*bitsPerNeighbor,'uint8');
        for n=1:3
            prefix=bitshift(marked(positions(n,1),positions(n,2)),-currentLambda);
            startIndex=(n-1)*bitsPerNeighbor+1;
            localBits(startIndex:startIndex+bitsPerNeighbor-1)=int_to_bits(double(prefix),bitsPerNeighbor);
        end
        originalMSB=localBits(1);
        [nextSymbol,codeLength]=decode_huffman_prefix(localBits,2,codebook);
        globalBits=[globalBits,localBits(2+codeLength:end)]; %#ok<AGROW>

        reference=bitor(bitand(marked(row,column),uint8(127)),bitshift(uint8(originalMSB),7));
        recovered(row,column)=reference;
        if currentLambda==0, lowMask=uint8(0); else, lowMask=uint8(2^currentLambda-1); end
        for n=1:3
            xorValue=bitand(marked(positions(n,1),positions(n,2)),lowMask);
            recovered(positions(n,1),positions(n,2))=bitxor(reference,xorValue);
        end
        if nextSymbol==7
            reachedEnd=true;
        else
            currentLambda=nextSymbol;
        end
    end
end
if ~reachedEnd, error('标签链中未找到哈夫曼结束符。'); end

headerBytes=45; headerBits=headerBytes*8;
if numel(globalBits)<headerBits, error('提取负载不足以包含头部。'); end
header=bits_to_bytes(globalBits(1:headerBits));
if ~isequal(char(header(1:4)),'XHAC') || header(5)~=1
    error('XORP嵌入负载标识或版本不正确。');
end
secretLength=double(be_to_uint32(header(6:9)));
b2Count=double(be_to_uint32(header(10:13)));
secretDigest=header(14:45);
if b2Count~=size(b2Positions,1), error('B2块数量不一致。'); end
requiredBits=headerBits+b2Count+secretLength*8;
if numel(globalBits)<requiredBits, error('提取的全局负载长度不足。'); end
b2Bits=globalBits(headerBits+1:headerBits+b2Count);
secretStart=headerBits+b2Count+1;
secretData=bits_to_bytes(globalBits(secretStart:secretStart+secretLength*8-1));
if ~isequal(sha_bytes(secretData,'SHA-256'),secretDigest)
    error('嵌入秘密数据SHA-256校验失败。');
end
for k=1:b2Count
    row=b2Positions(k,1); column=b2Positions(k,2);
    recovered(row,column)=bitor(bitand(marked(row,column),uint8(127)),bitshift(uint8(b2Bits(k)),7));
end
end
