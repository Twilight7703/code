function [challenge,metadata]=verification_generate_challenge(password,patientBytes,nonce)
%VERIFICATION_GENERATE_CHALLENGE 使用当前改进Salomon轨道生成验证流程挑战值r。
% 输入:
%   password     - 当前算法口令，仅发送方用于派生挑战轨道。
%   patientBytes - 患者附加信息uint8字节。
%   nonce        - 可选16字节交互随机数；省略时由Java SecureRandom生成。
% 输出:
%   challenge    - 32字节挑战值r。
%   metadata     - nonceHex、challengeHex和派生说明。

patientBytes=uint8(patientBytes(:).');
if nargin<3 || isempty(nonce)
    random=javaObject('java.security.SecureRandom');
    nonce=reshape(typecast(int8(random.generateSeed(int32(16))),'uint8'),1,[]);
else
    nonce=uint8(nonce(:).');
end
if numel(nonce)~=16, error('Verification:InvalidChallengeNonce','挑战nonce必须为16字节。'); end
patientDigest=sha_bytes(patientBytes,'SHA-512');
contentDigest=sha_bytes([uint8('VERIFICATION-CHALLENGE-V1'),patientDigest],'SHA-512');
key=salomon_key(password,nonce,contentDigest);
[x,~]=salomon_sequence(32,key);
challenge=uint8(min(255,floor(256*x(:).')));
metadata=struct('nonceHex',bytes_to_hex(nonce), ...
    'challengeHex',bytes_to_hex(challenge), ...
    'keyDerivation','improved-salomon-verification-v1', ...
    'challengeLength',numel(challenge));
end
