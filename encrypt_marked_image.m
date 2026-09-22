function [cipher,metadata] = encrypt_marked_image(marked,password,nonce)
%ENCRYPT_MARKED_IMAGE 调用单通道旋转置乱、Q矩阵和DNA中心扩散。
% 输入:
%   marked   - 已嵌入秘密信息的uint8灰度图。
%   password - 加密口令。
%   nonce    - 16字节随机数；省略时自动生成。
% 输出:
%   cipher   - uint8密文图像（必要时尺寸补到偶数）。
%   metadata - 原尺寸、填充尺寸和nonce。

if nargin<3 || isempty(nonce), nonce=randi([0,255],1,16,'uint8'); end
markedDigest=sha_bytes(array_to_bytes(marked),'SHA-512');
keyDerivation='password+nonce+markedSha512+improved-salomon-cross-feedback-v4';
scrambled=rotation_scramble(marked);
[padded,originalShape]=pad_to_even(scrambled);
[chaosBytes,maskBits]=salomon_material( ...
    size(padded,1),size(padded,2),password,nonce,markedDigest,keyDerivation);
cipher=dna_center_diffuse(padded,chaosBytes,maskBits);
metadata=struct('originalHeight',originalShape(1),'originalWidth',originalShape(2), ...
    'paddedHeight',size(cipher,1),'paddedWidth',size(cipher,2), ...
    'nonceHex',bytes_to_hex(nonce),'markedSha512',bytes_to_hex(markedDigest), ...
    'keyDerivation',keyDerivation);
end
