function logo=verification_generate_logo(logoText,outputPath)
%VERIFICATION_GENERATE_LOGO 使用固定字符库生成验证流程的2x2验证Logo。
% 输入:
%   logoText  - 4个0-9/A-Z字符，顺序为左上、右上、左下、右下。
%   outputPath- 可选PNG输出路径。
% 输出:
%   logo      - uint8二值Logo，黑色字符、白色背景。

validTextType=(ischar(logoText) && isrow(logoText)) || ...
    (isstring(logoText) && isscalar(logoText));
if ~validTextType
    error('Verification:InvalidLogoText','Logo文本必须是字符行向量或标量字符串。');
end
logoText=upper(char(logoText));
if isempty(regexp(logoText,'^[0-9A-Z]{4}$','once'))
    error('Verification:LogoTextLength','Logo文本必须恰好包含4个0-9/A-Z字符。');
end
scale=8; padding=8; gap=12;
glyphHeight=7*scale; glyphWidth=5*scale;
tileHeight=glyphHeight+2*padding; tileWidth=glyphWidth+2*padding;
logo=uint8(255*ones(2*tileHeight+gap,2*tileWidth+gap));
for index=1:4
    glyph=logical(kron(verification_character_templates(logoText(index)),ones(scale)));
    tile=uint8(255*ones(tileHeight,tileWidth));
    rows=padding+(1:glyphHeight); columns=padding+(1:glyphWidth);
    region=tile(rows,columns); region(glyph)=0; tile(rows,columns)=region;
    tileRow=floor((index-1)/2); tileColumn=mod(index-1,2);
    r0=1+tileRow*(tileHeight+gap); c0=1+tileColumn*(tileWidth+gap);
    logo(r0:r0+tileHeight-1,c0:c0+tileWidth-1)=tile;
end
if nargin>=2 && ~isempty(outputPath)
    if ~((ischar(outputPath) && isrow(outputPath)) || ...
            (isstring(outputPath) && isscalar(outputPath)))
        error('Verification:InvalidOutputPath','Logo输出路径必须是字符行向量或标量字符串。');
    end
    outputPath=char(outputPath);
    parent=fileparts(outputPath);
    if ~isempty(parent) && ~isfolder(parent), mkdir(parent); end
    imwrite(logo,outputPath);
end
end
