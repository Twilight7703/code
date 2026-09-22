function fingerprint=verification_public_key_fingerprint(publicKeyPath)
%VERIFICATION_PUBLIC_KEY_FINGERPRINT 计算可信验证方公钥文件的SHA-256指纹。
% 输入:
%   publicKeyPath - 验证方X.509 PEM公钥路径。
% 输出:
%   fingerprint - 64位小写十六进制SHA-256指纹。

if ~isfile(publicKeyPath)
    error('Verification:PublicKeyNotFound','验证方公钥不存在：%s',publicKeyPath);
end
fingerprint=lower(bytes_to_hex(sha_bytes(read_binary_file(publicKeyPath),'SHA-256')));
end
