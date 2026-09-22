function data = read_binary_file(pathValue)
%READ_BINARY_FILE 原样读取TXT、JSON或其他附加信息文件的全部字节。
% 输入: pathValue-输入文件路径。
% 输出: data-uint8字节行向量，不改变原文件编码和换行符。

fid=fopen(pathValue,'rb');
if fid<0, error('无法读取附加信息文件：%s',pathValue); end
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
data=reshape(fread(fid,Inf,'*uint8'),1,[]);
end

