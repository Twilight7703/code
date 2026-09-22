function [recoveredCarrier,recoveredPatientInfo,detail]=telemedicine_receive_verification( ...
    cipherPath,metadataPath,logoPath,verificationRecordInput,receiverRequestInput, ...
    recoveredCarrierPath,recoveredPatientInfoPath,password,verifierPublicKeyPath)
%TELEMEDICINE_RECEIVE_VERIFICATION 验证通过后授权当前算法口令并恢复。
% 输入:
%   cipherPath,metadataPath - 密文和当前算法JSON数据包。
%   logoPath                - 验证Logo。
%   verificationRecordInput- 发送方正确参数结构体或JSON路径。
%   receiverRequestInput    - 接收方提交参数结构体或JSON路径。
%   recoveredCarrierPath   - 恢复医学图像输出路径。
%   recoveredPatientInfoPath-恢复患者信息输出路径。
%   password                - 验证成功后仅在当前调用内存中授权的算法口令。
%   verifierPublicKeyPath   - 接收端预先信任的验证方X.509公钥路径。
% 输出:
%   recoveredCarrier,recoveredPatientInfo-无损恢复结果。
%   detail                  - 验证子项结果。

[isValid,detail]=verify_package(cipherPath,metadataPath,logoPath, ...
    verificationRecordInput,receiverRequestInput,verifierPublicKeyPath);
if ~isValid
    error('Verification:AuthorizationRejected','验证失败，未授权算法口令和恢复操作。');
end
[recoveredCarrier,recoveredPatientInfo]=telemedicine_receive( ...
    cipherPath,metadataPath,recoveredCarrierPath,recoveredPatientInfoPath,password);
end
