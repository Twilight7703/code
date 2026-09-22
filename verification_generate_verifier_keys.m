function paths=verification_generate_verifier_keys(outputDirectory)
%VERIFICATION_GENERATE_VERIFIER_KEYS 生成验证方RSA-3072公私钥。
% 输入:
%   outputDirectory - PEM密钥输出目录。
% 输出:
%   paths - privateKeyPath和publicKeyPath字段。

if nargin<1 || isempty(outputDirectory), outputDirectory=fullfile('data','verification_keys'); end
if ~isfolder(outputDirectory), mkdir(outputDirectory); end
generator=javaMethod('getInstance','java.security.KeyPairGenerator','RSA');
generator.initialize(int32(3072)); pair=generator.generateKeyPair();
privatePath=fullfile(outputDirectory,'verifier_private_pkcs8.pem');
publicPath=fullfile(outputDirectory,'verifier_public_x509.pem');
write_pem(privatePath,'PRIVATE KEY',pair.getPrivate().getEncoded());
write_pem(publicPath,'PUBLIC KEY',pair.getPublic().getEncoded());
paths=struct('privateKeyPath',privatePath,'publicKeyPath',publicPath, ...
    'algorithm','RSA-3072','signatureAlgorithm','SHA256withRSA');
end

function write_pem(pathValue,label,javaBytes)
encoder=javaMethod('getEncoder','java.util.Base64');
base64=char(encoder.encodeToString(javaBytes));
lines=regexp(base64,'.{1,64}','match');
text=sprintf('-----BEGIN %s-----\n%s\n-----END %s-----\n', ...
    label,strjoin(lines,newline),label);
fid=fopen(pathValue,'w','n','UTF-8');
if fid<0, error('Verification:KeyWriteFailed','无法写入密钥：%s',pathValue); end
cleanup=onCleanup(@()fclose(fid)); fwrite(fid,text,'char');
end
