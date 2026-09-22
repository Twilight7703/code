function [package,artifacts] = telemedicine_send(carrierInput,patientInfoPath,cipherPath,metadataPath,password,carrierSource)
%TELEMEDICINE_SEND 远程医疗框架的发送方处理流程。
% 输入:
%   carrierInput  - 8位单通道图像路径，或uint8载体图像矩阵。
%   patientInfoPath - 患者附加信息TXT/JSON文件路径。
%   cipherPath   - 输出密文PNG/TIFF路径。
%   metadataPath - 输出JSON旁信息路径。
%   password     - 嵌入填充和Salomon映射使用的算法口令。
%   carrierSource - 可选的数据集来源结构体。
% 输出:
%   package      - 已写入JSON的远程医疗数据包结构体。
%   artifacts    - 可选的实验中间结果结构体，包含原始载体、嵌入数据后的
%                  标记图像和最终密文图像；不写入package.json。

if nargin<6, carrierSource=[]; end
if ischar(carrierInput) || isstring(carrierInput)
    rawCarrier=imread(char(carrierInput));
else
    rawCarrier=carrierInput;
end
carrier=prepare_carrier_image(rawCarrier);
patientInfo=read_binary_file(patientInfoPath);
[compressedInfo,compressionMetadata]=additional_info_diff_lzw_compress(patientInfo);
fillSeed=sha_bytes(unicode2native(char(password),'UTF-8'),'SHA-256');
[marked,embeddingMetadata]=xorp_huffman_embed(carrier,compressedInfo,fillSeed);
[cipher,encryptionMetadata]=encrypt_marked_image(marked,password);

ensure_parent_directory(cipherPath); imwrite(cipher,cipherPath);
package=struct(); package.version=2; package.encryption=encryptionMetadata;
package.embedding=embeddingMetadata; package.additionalCompression=compressionMetadata;
if ~isempty(carrierSource), package.carrierSource=carrierSource; end
package.carrierSha256=bytes_to_hex(sha_bytes(array_to_bytes(carrier),'SHA-256'));
package.patientInfoSha256=bytes_to_hex(sha_bytes(patientInfo,'SHA-256'));
package.cipherSha256=bytes_to_hex(sha_bytes(array_to_bytes(cipher),'SHA-256'));
write_json(metadataPath,package);

% 仅在调用方需要第二个输出时返回中间图像，避免改变既有单输出调用行为。
if nargout>1
    artifacts=struct('carrierImage',carrier,'markedImage',marked,'cipherImage',cipher);
end

fprintf(['发送方完成：患者信息 %d 字节，差分候选 %d 字节，选中%s码流 %d 字节，', ...
    '嵌入负载 %d/%d bit。\n'],numel(patientInfo),compressionMetadata.differentialLength, ...
    compressionMetadata.method,numel(compressedInfo),embeddingMetadata.payloadBits, ...
    embeddingMetadata.usableCapacityBits);
end

function ensure_parent_directory(pathValue)
% 若输出文件含父目录且目录不存在，则创建目录。
parent=fileparts(pathValue); if ~isempty(parent) && ~exist(parent,'dir'), mkdir(parent); end
end

function write_json(pathValue,value)
% 将结构体以UTF-8 JSON写入磁盘。
ensure_parent_directory(pathValue);
try
    text=jsonencode(value,'PrettyPrint',true);
catch
    text=jsonencode(value);
end
% 仅对写入磁盘的JSON字段名增加中文说明；内存中的value仍保持英文键名，
% 因此不会影响后续算法调用。
text=to_bilingual_json_keys(text);
fid=fopen(pathValue,'w','n','UTF-8');
if fid<0, error('无法写入元数据文件：%s',pathValue); end
cleanup=onCleanup(@()fclose(fid));
fwrite(fid,text,'char');
end

function text = to_bilingual_json_keys(text)
%TO_BILINGUAL_JSON_KEYS 将package.json字段显示为“英文（中文）”。
englishKeys={'version','encryption','embedding','additionalCompression', ...
    'carrierSource','carrierSha256','patientInfoSha256','cipherSha256', ...
    'originalHeight','originalWidth','paddedHeight','paddedWidth','nonceHex', ...
    'markedSha512','keyDerivation','firstLambda','codebook','usableCapacityBits', ...
    'payloadBits','blockRows','blockColumns','method','originalLength', ...
    'differentialLength','signByteCount','codeCount','originalSha256', ...
    'compressedLength','dataset','modality','datasetRoot','datasetJson', ...
    'trainingIndex','imageRelativePath','labelRelativePath','imaskRelativePath', ...
    'originalChannels','carrierHeight','carrierWidth','sourceImageSha256'};
chineseKeys={'版本','加密信息','嵌入信息','附加信息压缩', ...
    '载体来源','载体SHA256','患者信息SHA256','密文SHA256', ...
    '原始高度','原始宽度','填充高度','填充宽度','随机数Nonce', ...
    '标记图像SHA512','密钥派生方式','首块Lambda','哈夫曼码本','可用容量比特数', ...
    '嵌入负载比特数','块行数','块列数','压缩方法','原始长度', ...
    '差分流长度','符号字节数','LZW码字数','原始信息SHA256', ...
    '压缩长度','数据集','模态','数据集根目录','数据集描述文件', ...
    '训练索引','图像相对路径','标签相对路径','掩码相对路径', ...
    '原始通道数','载体高度','载体宽度','源图像SHA256'};
for index=1:numel(englishKeys)
    text=strrep(text,['"',englishKeys{index},'"'], ...
        ['"',englishKeys{index},'（',chineseKeys{index},'）"']);
end
end
