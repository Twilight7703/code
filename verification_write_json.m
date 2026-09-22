function verification_write_json(pathValue,value)
%VERIFICATION_WRITE_JSON 以UTF-8可读格式写入验证记录或请求JSON。
% 输入:
%   pathValue - 输出JSON路径。
%   value     - 待序列化结构体。

parent=fileparts(pathValue);
if ~isempty(parent) && ~isfolder(parent)
    mkdir(parent);
end
try
    text=jsonencode(value,'PrettyPrint',true);
catch
    text=jsonencode(value);
end
fid=fopen(pathValue,'w','n','UTF-8');
if fid<0
    error('Verification:JsonWriteFailed','无法写入验证JSON：%s',pathValue);
end
cleanup=onCleanup(@()fclose(fid));
fwrite(fid,text,'char');
end
