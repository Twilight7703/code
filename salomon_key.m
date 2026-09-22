function key = salomon_key(password,nonce,contentDigest)
%SALOMON_KEY 从口令、nonce和图像摘要派生改进二维Salomon密钥。
% 输入:
%   password      - 字符串或字符向量口令。
%   nonce         - 16字节公开随机数。
%   contentDigest - 64字节标记图像SHA-512摘要；可选空值仅供独立分析。
% 输出:
%   key - 含x0、y0、a、b、c、d和discard的结构体。
%
% a、b为原Salomon指数控制参数；c、d为增益内正弦交叉反馈参数。
% 保留既有摘要域标识，使原方程与改进方程可在相同初值和a/b下公平比较；
% 实际数据包由improved-salomon-cross-feedback-v4标识新方程版本。

if nargin<3 || isempty(contentDigest)
    keyMaterial=[unicode2native(char(password),'UTF-8'),uint8(nonce(:).')];
else
    contentDigest=uint8(contentDigest(:).');
    if numel(contentDigest)~=64
        error('Salomon内容摘要必须是64字节SHA-512结果。');
    end
    keyMaterial=[uint8('SALOMON-CONTENT-V2'), ...
        unicode2native(char(password),'UTF-8'),uint8(nonce(:).'),contentDigest];
end

digest=sha_bytes(keyMaterial,'SHA-512');
x0=(bytes_to_double(digest(1:8))+0.5)/2^64;
y0=(bytes_to_double(digest(9:16))+0.5)/2^64;
a=4.5+bytes_to_double(digest(17:20))/2^32;
b=4.5+bytes_to_double(digest(21:24))/2^32;
discard=1000+mod(bytes_to_double(digest(25:28)),1000);
c=0.5+bytes_to_double(digest(29:32))/2^32;
d=0.5+bytes_to_double(digest(33:36))/2^32;
key=struct('x0',x0,'y0',y0,'a',a,'b',b,'c',c,'d',d, ...
    'discard',floor(discard));
end

function value=bytes_to_double(bytes)
%BYTES_TO_DOUBLE 按大端顺序将最多8字节转换为double整数。
value=0;
for byte=double(bytes(:).')
    value=value*256+byte;
end
end
