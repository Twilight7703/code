function infoBytes = additional_info_diff_lzw_decompress(compressed,metadata)
%ADDITIONAL_INFO_DIFF_LZW_DECOMPRESS 恢复差分-LZW10及历史编码的患者信息。
% 输入:
%   compressed - additional_info_diff_lzw_compress输出的选中码流。
%   metadata   - 对应压缩旁信息。
% 输出:
%   infoBytes  - 与发送端TXT/JSON文件逐字节一致的uint8数据。

version=double(metadata.version);
switch version
    case 1
        infoBytes=decode_differential_lzw(compressed,metadata,12);
    case 2
        if ~isfield(metadata,'method')
            error('患者信息编码元数据缺少method字段。');
        end
        method=char(metadata.method);
        switch method
            case 'raw'
                infoBytes=uint8(compressed(:).');
                if numel(infoBytes)~=double(metadata.originalLength)
                    error('raw患者信息长度与元数据不一致。');
                end
            case 'lzw12'
                infoBytes=lzw12_decode(uint8(compressed),double(metadata.codeCount));
                if numel(infoBytes)~=double(metadata.originalLength)
                    error('直接LZW解压长度与元数据不一致。');
                end
            case 'lzw10'
                infoBytes=lzw10_decode(uint8(compressed),double(metadata.codeCount));
                if numel(infoBytes)~=double(metadata.originalLength)
                    error('直接LZW10解压长度与元数据不一致。');
                end
            case 'diff-lzw12'
                infoBytes=decode_differential_lzw(compressed,metadata,12);
            case 'diff-lzw10'
                infoBytes=decode_differential_lzw(compressed,metadata,10);
            otherwise
                error('不支持的患者信息编码模式：%s。',method);
        end
    otherwise
        error('不支持的患者信息编码版本：%g。',version);
end

if ~strcmpi(bytes_to_hex(sha_bytes(infoBytes,'SHA-256')),char(metadata.originalSha256))
    error('患者附加信息SHA-256校验失败。');
end
end

function infoBytes=decode_differential_lzw(compressed,metadata,codeWidth)
%DECODE_DIFFERENTIAL_LZW 解码version 1或version 2差分-LZW码流。
originalLength=double(metadata.originalLength);
differentialLength=double(metadata.differentialLength);
signByteCount=double(metadata.signByteCount);
if codeWidth==10
    stream=lzw10_decode(uint8(compressed),double(metadata.codeCount));
else
    stream=lzw12_decode(uint8(compressed),double(metadata.codeCount));
end
if numel(stream)~=differentialLength
    error('附加信息LZW解压长度与元数据不一致。');
end
if originalLength==0
    infoBytes=zeros(1,0,'uint8');
else
    differenceCount=originalLength-1;
    expectedLength=1+differenceCount+signByteCount;
    if numel(stream)~=expectedLength
        error('附加信息差分流布局不正确。');
    end
    baseline=stream(1);
    magnitudes=double(stream(2:1+differenceCount));
    signBytes=stream(2+differenceCount:end);
    signs=bytes_to_bits(signBytes); signs=double(signs(1:differenceCount));
    differences=magnitudes; differences(signs==0)=-differences(signs==0);
    values=zeros(1,originalLength); values(1)=double(baseline);
    for index=2:originalLength
        values(index)=values(index-1)+differences(index-1);
    end
    if any(values<0 | values>255)
        error('附加信息差分重建字节越界，数据可能已损坏。');
    end
    infoBytes=uint8(values);
end
end
