function logoText=verification_patient_logo_text(patientBytes)
%VERIFICATION_PATIENT_LOGO_TEXT 从患者字节确定性生成4字符Logo文本。
% 输入:
%   patientBytes - 患者TXT/JSON/二进制附加信息的uint8字节。
% 输出:
%   logoText     - 由0-9和A-Z组成的1x4字符向量。

if ~isa(patientBytes,'uint8') || ~isvector(patientBytes) || isempty(patientBytes)
    error('Verification:InvalidPatientBytes','患者附加信息必须是非空uint8字节向量。');
end
patientBytes=patientBytes(:).';
isDigit=patientBytes>=uint8('0') & patientBytes<=uint8('9');
isUpper=patientBytes>=uint8('A') & patientBytes<=uint8('Z');
isLower=patientBytes>=uint8('a') & patientBytes<=uint8('z');
selected=char(patientBytes(isDigit | isUpper | isLower));
selected=upper(selected);
digestText=upper(bytes_to_hex(sha_bytes(patientBytes,'SHA-256')));
combined=[selected,digestText];
logoText=combined(1:4);
end
