function isValid=verification_verify_challenge(challenge,signature,publicKeyPath)
%VERIFICATION_VERIFY_CHALLENGE 发送方使用验证方公钥核验挑战签名。
% 输入:
%   challenge     - 原始挑战值r。
%   signature     - 验证方返回的签名Sig。
%   publicKeyPath - 验证方X.509公钥路径。
% 输出:
%   isValid       - 签名有效时为true，对应验证流程中的R=r。

challenge=uint8(challenge(:).'); signature=uint8(signature(:).');
if numel(challenge)~=32 || numel(signature)~=384
    isValid=false;
    return;
end
try
    key=verification_load_rsa_key(publicKeyPath,'public');
    engine=javaMethod('getInstance','java.security.Signature','SHA256withRSA');
    engine.initVerify(key); engine.update(typecast(challenge,'int8'));
    isValid=logical(engine.verify(typecast(signature,'int8')));
catch
    isValid=false;
end
end
