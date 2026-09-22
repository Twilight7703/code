function digest = sha_bytes(data, algorithm)
%SHA_BYTES 使用Java MessageDigest计算SHA摘要。
% 输入:
%   data      - uint8字节向量。
%   algorithm - 'SHA-256'或'SHA-512'。
% 输出:
%   digest    - uint8摘要行向量。

md = java.security.MessageDigest.getInstance(algorithm);
% Java 的 update 不接受空数组；空消息直接调用 digest 即可。
if ~isempty(data)
    md.update(typecast(uint8(data(:)), 'int8'));
end
signedDigest = md.digest();
digest = reshape(typecast(int8(signedDigest), 'uint8'), 1, []);
end
