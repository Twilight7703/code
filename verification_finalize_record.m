function record=verification_finalize_record(record,privateKeyPath,publicKeyPath)
%VERIFICATION_FINALIZE_RECORD 使用验证方密钥签名完整验证记录。
% 输入:
%   record         - verification_build_verification_record生成的记录。
%   privateKeyPath - 验证方PKCS#8私钥路径。
%   publicKeyPath  - 与私钥配对的可信X.509公钥路径。
% 输出:
%   record - 增加公钥指纹、记录摘要和记录签名后的verification-v2记录。

record.verifierPublicKeySha256=verification_public_key_fingerprint(publicKeyPath);
record.signatureAlgorithm='SHA256withRSA';
digest=verification_record_digest(record);
record.signedRecordSha256=bytes_to_hex(digest);
record.recordSignatureHex=bytes_to_hex(verification_sign_challenge(digest,privateKeyPath));
if ~verification_verify_challenge(digest,hex_to_bytes(record.recordSignatureHex),publicKeyPath)
    error('Verification:RecordSignatureSelfCheckFailed','完整验证记录签名自检失败。');
end
end
