function image = inverse_dna_center_diffuse(cipher,chaosBytes,maskBits)
%INVERSE_DNA_CENTER_DIFFUSE 逆转DNA中心扩散、互补和累加。
% 输入: cipher-密文；chaosBytes、maskBits-与加密端相同的Salomon材料。
% 输出: image-DNA中心扩散前的补齐图像。

R=dna_encode_rule1(cipher); L=dna_encode_rule1(chaosBytes);
[height,width]=size(R); cr=max(1,floor(height/2)); cc=max(1,floor(width/2));
D=zeros(size(R),'uint8'); D(cr,cc)=bitxor(R(cr,cc),L(cr,cc));
for column=cc-1:-1:1
    D(cr,column)=bitxor(bitxor(R(cr,column),L(cr,column)),R(cr,column+1));
end
for column=cc+1:width
    D(cr,column)=bitxor(bitxor(R(cr,column),L(cr,column)),R(cr,column-1));
end
for row=cr-1:-1:1
    D(row,:)=bitxor(bitxor(R(row,:),L(row,:)),R(row+1,:));
end
for row=cr+1:height
    D(row,:)=bitxor(bitxor(R(row,:),L(row,:)),R(row-1,:));
end
D(maskBits)=uint8(3)-D(maskBits);
cumulative=reshape(D.',1,[]); sequence=zeros(size(cumulative),'uint8');
sequence(1)=cumulative(1);
for index=2:numel(cumulative)
    sequence(index)=uint8(mod(double(cumulative(index))-double(cumulative(index-1)),4));
end
d1=reshape(sequence,width,height).';
image=dna_decode_rule1(d1);
end
