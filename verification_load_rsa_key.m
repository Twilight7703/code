function key=verification_load_rsa_key(pathValue,keyType)
%VERIFICATION_LOAD_RSA_KEY 读取PKCS#8私钥或X.509公钥PEM。
% 输入:
%   pathValue - PEM文件路径。
%   keyType   - 'private'或'public'。
% 输出:
%   key       - Java RSA PrivateKey/PublicKey对象。

if ~isfile(pathValue), error('Verification:KeyNotFound','密钥文件不存在：%s',pathValue); end
switch lower(char(keyType))
    case 'private'
        pemLabel='PRIVATE KEY';
    case 'public'
        pemLabel='PUBLIC KEY';
    otherwise
        error('Verification:InvalidKeyType','keyType必须是private或public。');
end
text=fileread(pathValue);
beginMarker=['-----BEGIN ',pemLabel,'-----'];
endMarker=['-----END ',pemLabel,'-----'];
if ~contains(text,beginMarker) || ~contains(text,endMarker)
    error('Verification:InvalidPemLabel','密钥PEM标签与%s类型不匹配。',keyType);
end
body=strrep(text,beginMarker,'');
body=strrep(body,endMarker,'');
body=regexprep(body,'\s','');
decoder=javaMethod('getDecoder','java.util.Base64');
try
    decoded=decoder.decode(java.lang.String(body));
catch exception
    error('Verification:InvalidPem','PEM Base64解析失败：%s',exception.message);
end
try
    factory=javaMethod('getInstance','java.security.KeyFactory','RSA');
    switch lower(char(keyType))
        case 'private'
        specification=javaObject('java.security.spec.PKCS8EncodedKeySpec',decoded);
        key=factory.generatePrivate(specification);
        case 'public'
        specification=javaObject('java.security.spec.X509EncodedKeySpec',decoded);
        key=factory.generatePublic(specification);
    end
catch exception
    error('Verification:InvalidRsaKey','RSA密钥DER解析失败：%s',exception.message);
end
modulus=key.getModulus();
if double(modulus.bitLength())~=3072
    error('Verification:InvalidRsaKeySize','验证密钥必须恰好为RSA-3072。');
end
end
