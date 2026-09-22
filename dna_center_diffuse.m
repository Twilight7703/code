function cipher = dna_center_diffuse(image,chaosBytes,maskBits)
%DNA_CENTER_DIFFUSE 论文5的DNA累加、互补与中心向外扩散。
% 输入:
%   image       - 补齐后的MxN uint8图像。
%   chaosBytes  - MxN二维Salomon混沌字节矩阵。
%   maskBits    - Mx4N逻辑互补掩码。
% 输出:
%   cipher      - 中心扩散后的MxN uint8密文图像。

d1=dna_encode_rule1(image); L=dna_encode_rule1(chaosBytes);
if ~isequal(size(d1),size(maskBits)) || ~isequal(size(d1),size(L))
    error('DNA中心扩散的图像、混沌矩阵和掩码尺寸不一致。');
end
sequence=reshape(d1.',1,[]); cumulative=zeros(size(sequence),'uint8');
cumulative(1)=sequence(1); % 指定初始碱基d0=A(ID=0)
for index=2:numel(sequence)
    cumulative(index)=uint8(mod(double(cumulative(index-1))+double(sequence(index)),4));
end
D=reshape(cumulative,size(d1,2),size(d1,1)).';
D(maskBits)=uint8(3)-D(maskBits); % Watson-Crick互补A<->T,G<->C
R=center_xor_forward(D,L);
cipher=dna_decode_rule1(R);
end

function R=center_xor_forward(D,L)
% 按中心点、中心行左右、再向上/下的顺序执行DNA XOR扩散。
[height,width]=size(D); cr=max(1,floor(height/2)); cc=max(1,floor(width/2));
R=zeros(size(D),'uint8'); R(cr,cc)=bitxor(D(cr,cc),L(cr,cc));
for column=cc-1:-1:1
    R(cr,column)=bitxor(bitxor(D(cr,column),L(cr,column)),R(cr,column+1));
end
for column=cc+1:width
    R(cr,column)=bitxor(bitxor(D(cr,column),L(cr,column)),R(cr,column-1));
end
for row=cr-1:-1:1
    R(row,:)=bitxor(bitxor(D(row,:),L(row,:)),R(row+1,:));
end
for row=cr+1:height
    R(row,:)=bitxor(bitxor(D(row,:),L(row,:)),R(row-1,:));
end
end
