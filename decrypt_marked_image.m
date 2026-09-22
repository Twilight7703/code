function marked = decrypt_marked_image(cipher,password,metadata)
%DECRYPT_MARKED_IMAGE 严格逆序恢复嵌入后的标记图像。
% 输入: cipher-密文；password-口令；metadata-加密旁信息。
% 输出: marked-XORP嵌入后的uint8标记图像。

nonce=hex_to_bytes(metadata.nonceHex);
if isfield(metadata,'markedSha512')
    markedDigest=hex_to_bytes(metadata.markedSha512);
else
    % 兼容修改前生成的version=1数据包。
    markedDigest=[];
end
if isfield(metadata,'keyDerivation')
    streamMode=char(metadata.keyDerivation);
else
    streamMode='legacy';
end
[chaosBytes,maskBits]=salomon_material( ...
    size(cipher,1),size(cipher,2),password,nonce,markedDigest,streamMode);
padded=inverse_dna_center_diffuse(cipher,chaosBytes,maskBits);
scrambled=padded(1:double(metadata.originalHeight),1:double(metadata.originalWidth));
marked=inverse_rotation_scramble(scrambled);
if ~isempty(markedDigest)
    actualDigest=sha_bytes(array_to_bytes(marked),'SHA-512');
    if ~strcmpi(bytes_to_hex(actualDigest),char(metadata.markedSha512))
        error('恢复标记图像SHA-512校验失败，口令、摘要或密文不正确。');
    end
end
end
