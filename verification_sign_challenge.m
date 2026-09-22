function signature=verification_sign_challenge(challenge,privateKeyPath)
%VERIFICATION_SIGN_CHALLENGE 验证方使用私钥签名挑战值r。
% 输入:
%   challenge      - uint8挑战字节。
%   privateKeyPath - 验证方PKCS#8私钥路径。
% 输出:
%   signature      - uint8 RSA SHA-256签名字节。

challenge=uint8(challenge(:).');
if numel(challenge)~=32
    error('Verification:InvalidChallengeLength','验证流程挑战值必须恰好为32字节。');
end
key=verification_load_rsa_key(privateKeyPath,'private');
engine=javaMethod('getInstance','java.security.Signature','SHA256withRSA');
engine.initSign(key); engine.update(typecast(challenge,'int8'));
signed=engine.sign(); signature=reshape(typecast(int8(signed),'uint8'),1,[]);
end
