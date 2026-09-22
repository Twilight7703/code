function [recoveredCarrier,recoveredPatientInfo] = telemedicine_receive(cipherPath,metadataPath,recoveredCarrierPath,recoveredPatientInfoPath,password)
%TELEMEDICINE_RECEIVE 验证授权通过后的低层解密、提取和重建流程。
% 输入:
%   cipherPath             - 接收到的密文图像。
%   metadataPath           - 接收到的JSON旁信息。
%   recoveredCarrierPath  - 恢复载体输出路径。
%   recoveredPatientInfoPath - 恢复患者TXT/JSON信息输出路径。
%   password               - 验证通过后由发送方在内存中授权的算法口令。
% 输出:
%   recoveredCarrier      - 无损恢复的医学载体图像。
%   recoveredPatientInfo  - 与原患者信息文件逐字节一致的uint8数据。

cipher=imread(cipherPath);
package=read_bilingual_package_json(metadataPath);
marked=decrypt_marked_image(cipher,password,package.encryption);
[recoveredCarrier,compressedInfo]=xorp_huffman_extract(marked,package.embedding);
recoveredPatientInfo=additional_info_diff_lzw_decompress(compressedInfo,package.additionalCompression);

carrierHash=bytes_to_hex(sha_bytes(array_to_bytes(recoveredCarrier),'SHA-256'));
patientInfoHash=bytes_to_hex(sha_bytes(recoveredPatientInfo,'SHA-256'));
if ~strcmpi(carrierHash,char(package.carrierSha256))
    error('恢复载体SHA-256与发送端记录不一致。');
end
if ~strcmpi(patientInfoHash,char(package.patientInfoSha256))
    error('恢复患者附加信息SHA-256与发送端记录不一致。');
end
ensure_parent_directory(recoveredCarrierPath); imwrite(recoveredCarrier,recoveredCarrierPath);
write_binary_file(recoveredPatientInfoPath,recoveredPatientInfo);
fprintf('接收方完成：医学载体与患者附加信息均已无损恢复。\n');
end

function ensure_parent_directory(pathValue)
parent=fileparts(pathValue); if ~isempty(parent) && ~exist(parent,'dir'), mkdir(parent); end
end
