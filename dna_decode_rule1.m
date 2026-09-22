function bytes = dna_decode_rule1(dna)
%DNA_DECODE_RULE1 将规则1 DNA碱基ID矩阵恢复为uint8像素矩阵。
% 输入: dna-Mx4N矩阵，ID为A=0,G=1,C=2,T=3。
% 输出: bytes-MxN uint8矩阵。

if ~isa(dna,'uint8') || mod(size(dna,2),4)~=0, error('DNA矩阵列数必须为4的倍数。'); end
[height,totalColumns]=size(dna); width=totalColumns/4;
idToPair=uint8([0,2,1,3]); bytes=zeros(height,width,'uint8');
for k=1:4
    ids=dna(:,k:4:end);
    pair=reshape(idToPair(double(ids)+1),height,width);
    bytes=bitor(bytes,bitshift(pair,2*(4-k)));
end
end

