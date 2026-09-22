function write_binary_file(pathValue,data)
%WRITE_BINARY_FILE 将恢复的患者附加信息逐字节写回TXT/JSON文件。
% 输入: pathValue-输出路径；data-uint8字节向量。
% 输出: 无。

parent=fileparts(pathValue); if ~isempty(parent) && ~exist(parent,'dir'), mkdir(parent); end
fid=fopen(pathValue,'wb');
if fid<0, error('无法写入恢复的附加信息文件：%s',pathValue); end
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fwrite(fid,uint8(data),'uint8');
end

