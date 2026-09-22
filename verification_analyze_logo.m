function analysis=verification_analyze_logo(logoInput,additionalIndices)
%VERIFICATION_ANALYZE_LOGO 按验证流程识别Logo字符、比例和局部哈希。
% 输入:
%   logoInput        - Logo路径或uint8二维/RGB图像。
%   additionalIndices- 需要附加核验的1-based字符位置，默认[1 3]。
% 输出:
%   analysis - 含result、proportionText、logoSha256和局部字符哈希。

if nargin<2 || isempty(additionalIndices), additionalIndices=[1 3]; end
additionalIndices=double(additionalIndices(:).');
if any(~isfinite(additionalIndices)) || ...
        any(additionalIndices<1 | additionalIndices>4 | fix(additionalIndices)~=additionalIndices) || ...
        numel(unique(additionalIndices))~=numel(additionalIndices)
    error('Verification:InvalidCharacterIndex','附加验证字符位置必须是互不重复的1到4整数。');
end
if (ischar(logoInput) && isrow(logoInput)) || (isstring(logoInput) && isscalar(logoInput))
    raw=imread(char(logoInput));
elseif isnumeric(logoInput) || islogical(logoInput)
    raw=logoInput;
else
    error('Verification:InvalidLogoInput','Logo必须是有效图像路径或数值/逻辑图像矩阵。');
end
if isempty(raw) || ~(ismatrix(raw) || (ndims(raw)==3 && size(raw,3)==3))
    error('Verification:InvalidLogoInput','Logo图像必须是非空二维灰度图或三通道RGB图。');
end
gray=prepare_carrier_image(raw);
binary=gray<128;

% 验证流程所述形态学优化：3x3膨胀后腐蚀，完成一次闭运算。
kernel=ones(3);
dilated=conv2(double(binary),kernel,'same')>0;
closed=conv2(double(dilated),kernel,'same')>=9;

rowRuns=find_runs(any(closed,2));
columnRuns=find_runs(any(closed,1));
if size(rowRuns,1)~=2 || size(columnRuns,1)~=2
    error('Verification:LogoSegmentationFailed', ...
        'Logo投影分割应得到2个字符行和2个字符列，实际为%d行、%d列。', ...
        size(rowRuns,1),size(columnRuns,1));
end

templates=verification_character_templates(); charset='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
result=repmat(' ',1,4); normalizedBlocks=cell(1,4); counter=0;
for rowIndex=1:2
    for columnIndex=1:2
        counter=counter+1;
        block=closed(rowRuns(rowIndex,1):rowRuns(rowIndex,2), ...
            columnRuns(columnIndex,1):columnRuns(columnIndex,2));
        normalized=normalize_binary(block,7,5);
        normalizedBlocks{counter}=normalized;
        bestDistance=inf; bestCharacter='?';
        for candidate=charset
            distance=nnz(xor(normalized,templates(candidate)));
            if distance<bestDistance
                bestDistance=distance; bestCharacter=candidate;
            end
        end
        result(counter)=bestCharacter;
    end
end

additional=repmat(struct('index',0,'hash',''),1,numel(additionalIndices));
for k=1:numel(additionalIndices)
    index=additionalIndices(k);
    blockBytes=uint8(normalizedBlocks{index}(:).');
    additional(k)=struct('index',index, ...
        'hash',bytes_to_hex(sha_bytes(blockBytes,'SHA-256')));
end

analysis=struct('result',result, ...
    'proportionText',nnz(closed)/numel(closed), ...
    'logoSha256',bytes_to_hex(sha_bytes(array_to_bytes(gray),'SHA-256')), ...
    'additionalIndices',additionalIndices, ...
    'additionalCharacters',additional);
end

function runs=find_runs(mask)
mask=logical(mask(:).'); padded=[false,mask,false];
starts=find(diff(padded)==1); stops=find(diff(padded)==-1)-1;
runs=[starts(:),stops(:)];
end

function normalized=normalize_binary(block,targetHeight,targetWidth)
[height,width]=size(block); normalized=false(targetHeight,targetWidth);
for row=1:targetHeight
    r1=floor((row-1)*height/targetHeight)+1;
    r2=max(r1,floor(row*height/targetHeight));
    for column=1:targetWidth
        c1=floor((column-1)*width/targetWidth)+1;
        c2=max(c1,floor(column*width/targetWidth));
        normalized(row,column)=mean(block(r1:r2,c1:c2),'all')>=0.45;
    end
end
end
