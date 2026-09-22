function [compressed,metadata] = additional_info_diff_lzw_compress(infoBytes)
%ADDITIONAL_INFO_DIFF_LZW_COMPRESS 固定执行患者信息差分-LZW10编码。
% 输入:
%   infoBytes - 患者TXT/JSON等文件的原始uint8字节序列。
% 输出:
%   compressed - 差分流经固定10位LZW编码后的码流。
%   metadata   - 固定编码模式、原长度、差分流统计、码字数和SHA-256。
%
% 编码器始终执行“差分 -> LZW10”。

infoBytes=uint8(infoBytes(:).');
originalLength=numel(infoBytes);
[differentialStream,signByteCount]=build_differential_stream(infoBytes);
[differentialLzw,differentialCodeCount]=lzw10_encode(differentialStream);

compressed=uint8(differentialLzw);

metadata=struct('version',2,'method','diff-lzw10', ...
    'originalLength',originalLength,'differentialLength',numel(differentialStream), ...
    'signByteCount',signByteCount,'codeCount',double(differentialCodeCount), ...
    'originalSha256',bytes_to_hex(sha_bytes(infoBytes,'SHA-256')), ...
    'compressedLength',numel(compressed));
end

function [stream,signByteCount]=build_differential_stream(infoBytes)
%BUILD_DIFFERENTIAL_STREAM 构造基线、差值绝对值和符号位图候选。
if isempty(infoBytes)
    stream=zeros(1,0,'uint8');
    signByteCount=0;
    return;
end
differences=diff(double(infoBytes));
magnitudes=uint8(abs(differences));
signMap=uint8(differences>=0);
signBytes=bits_to_bytes(signMap);
signByteCount=numel(signBytes);
stream=[infoBytes(1),magnitudes,signBytes];
end
