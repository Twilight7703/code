function dna = dna_encode_rule1(bytes)
%DNA_ENCODE_RULE1 按论文5表III规则1将每像素编码为4个DNA碱基ID。
% 输入: bytes-MxN uint8矩阵。
% 输出: dna-Mx4N uint8矩阵；ID顺序A=0,G=1,C=2,T=3。
% 规则1二进制映射为00->A,01->C,10->G,11->T。

if ~isa(bytes,'uint8') || ~ismatrix(bytes), error('DNA编码输入必须是uint8二维矩阵。'); end
[height,width]=size(bytes); dna=zeros(height,4*width,'uint8');
pairMap=uint8([0,2,1,3]);
pairs=cat(3,bitshift(bytes,-6),bitand(bitshift(bytes,-4),3), ...
    bitand(bitshift(bytes,-2),3),bitand(bytes,3));
for k=1:4
    dna(:,k:4:end)=reshape(pairMap(double(pairs(:,:,k))+1),height,width);
end
end

