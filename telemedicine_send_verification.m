function [package,record,artifacts]=telemedicine_send_verification( ...
    carrierInput,patientInfoPath,cipherPath,metadataPath,logoPath,recordPath, ...
    password,verifierPrivateKeyPath,verifierPublicKeyPath,nonce,carrierSource)
%TELEMEDICINE_SEND_VERIFICATION 验证流程挑战认证通过后的发送方完整流程。
% 输入:
%   carrierInput           - 当前算法的医学载体路径或uint8矩阵。
%   patientInfoPath        - 患者附加信息文件路径。
%   cipherPath,metadataPath- 当前算法密文与package.json输出路径。
%   logoPath,recordPath    - 外部验证Logo与发送方正确参数JSON路径。
%   password               - 当前嵌入与Salomon加密算法口令。
%   verifierPrivateKeyPath - 验证方用于签名挑战r的PKCS#8私钥。
%   verifierPublicKeyPath  - 发送方用于验证签名的X.509公钥。
%   nonce                  - 可选固定16字节挑战nonce；空值时安全随机生成。
%   carrierSource          - 可选的载体来源结构体。
% 输出:
%   package,record,artifacts- 算法包、验证记录和中间图像。

if nargin<10, nonce=[]; end
if nargin<11, carrierSource=[]; end
patientBytes=read_binary_file(patientInfoPath);
logoText=verification_patient_logo_text(patientBytes);
logo=verification_generate_logo(logoText,logoPath);
logoAnalysis=verification_analyze_logo(logo,[1 3]);
[challenge,challengeMetadata]=verification_generate_challenge(password,patientBytes,nonce);

% 验证流程挑战—响应：验证方用SK_VER签名，发送方用PK_VER验证R=r。
signature=verification_sign_challenge(challenge,verifierPrivateKeyPath);
if ~verification_verify_challenge(challenge,signature,verifierPublicKeyPath)
    error('Verification:VerifierAuthenticationFailed', ...
        '验证方挑战签名无效，发送方终止密文传输。');
end

[package,artifacts]=telemedicine_send(carrierInput,patientInfoPath, ...
    cipherPath,metadataPath,password,carrierSource);
record=verification_build_verification_record(logoAnalysis,challenge,signature, ...
    cipherPath,package.cipherSha256,package.patientInfoSha256,challengeMetadata);
record=verification_finalize_record(record,verifierPrivateKeyPath,verifierPublicKeyPath);
verification_write_json(recordPath,record);
fprintf('验证流程发送流程完成：挑战R=r，Logo=%s，验证记录已生成。\n',logoText);
end
