function [isValid,detail]=verification_verify_receiver_request(record,request)
%VERIFICATION_VERIFY_RECEIVER_REQUEST 比较验证流程接收方提交的多级验证参数。
% 输入:
%   record  - 发送方正确验证参数。
%   request - 接收方提交的验证参数。
% 输出:
%   isValid - 字符、比例、Logo哈希和附加字符均一致时为true。
%   detail  - 各子项布尔结果；格式错误时包含错误标识和说明。

isValid=false;
detail=empty_detail();
try
    validate_schema(record,request);
    supportedVersion='verification-v2';
    versionValid=strcmp(char(record.version),supportedVersion) && ...
        strcmp(char(request.version),supportedVersion);
    charactersValid=strcmp(char(record.result),char(request.stringReceived));
    proportionError=abs(double(record.proportionText)-double(request.proportionReceived));
    proportionValid=proportionError<=1e-12;
    logoHashValid=strcmpi(char(record.logoSha256),char(request.logoSha256));
    recordIndices=double(record.additionalIndices(:).');
    requestIndices=double(request.additionalIndices(:).');
    indicesValid=isequal(recordIndices,requestIndices);
    additionalHashValid=indicesValid && compare_additional( ...
        record.additionalCharacters,request.additionalCharacters,recordIndices);
    isValid=versionValid && charactersValid && proportionValid && logoHashValid && ...
        indicesValid && additionalHashValid;
    detail=struct('versionValid',versionValid,'charactersValid',charactersValid, ...
        'proportionValid',proportionValid,'proportionError',proportionError, ...
        'logoHashValid',logoHashValid,'indicesValid',indicesValid, ...
        'additionalHashValid',additionalHashValid,'isValid',isValid, ...
        'errorIdentifier','','errorMessage','');
catch exception
    detail.errorIdentifier=char(exception.identifier);
    detail.errorMessage=char(exception.message);
end
end

function validate_schema(record,request)
if ~isstruct(record) || ~isscalar(record) || ~isstruct(request) || ~isscalar(request)
    error('Verification:InvalidVerificationSchema','验证记录和接收方请求必须是标量结构体。');
end
recordFields={'version','result','proportionText','logoSha256', ...
    'additionalIndices','additionalCharacters'};
requestFields={'version','stringReceived','proportionReceived','logoSha256', ...
    'additionalIndices','additionalCharacters'};
if ~all(isfield(record,recordFields)) || ~all(isfield(request,requestFields))
    error('Verification:MissingVerificationField','验证记录或接收方请求缺少必需字段。');
end
validate_text(record.version,'record.version',false);
validate_text(request.version,'request.version',false);
validate_text(record.result,'record.result',true);
validate_text(request.stringReceived,'request.stringReceived',true);
validate_hash(record.logoSha256,'record.logoSha256');
validate_hash(request.logoSha256,'request.logoSha256');
validate_proportion(record.proportionText,'record.proportionText');
validate_proportion(request.proportionReceived,'request.proportionReceived');
validate_indices(record.additionalIndices,'record.additionalIndices');
validate_indices(request.additionalIndices,'request.additionalIndices');
if ~isstruct(record.additionalCharacters) || ~isstruct(request.additionalCharacters)
    error('Verification:InvalidAdditionalCharacters','附加字符参数必须是结构体数组。');
end
end

function validate_text(value,fieldName,isLogoText)
validType=(ischar(value) && isrow(value)) || (isstring(value) && isscalar(value));
if ~validType
    error('Verification:InvalidTextField','字段%s必须是字符行向量或标量字符串。',fieldName);
end
if isLogoText && isempty(regexp(char(value),'^[0-9A-Z]{4}$','once'))
    error('Verification:InvalidLogoText','字段%s必须恰好是4个大写字母或数字。',fieldName);
end
end

function validate_hash(value,fieldName)
validate_text(value,fieldName,false);
if isempty(regexp(char(value),'^[0-9A-Fa-f]{64}$','once'))
    error('Verification:InvalidHash','字段%s必须是64位十六进制SHA-256。',fieldName);
end
end

function validate_proportion(value,fieldName)
if ~isnumeric(value) || ~isscalar(value) || ~isreal(value) || ...
        ~isfinite(value) || value<0 || value>1
    error('Verification:InvalidProportion','字段%s必须是[0,1]内的有限实数标量。',fieldName);
end
end

function validate_indices(value,fieldName)
if ~isnumeric(value) || ~isvector(value) || isempty(value)
    error('Verification:InvalidCharacterIndex','字段%s必须是非空数值索引向量。',fieldName);
end
indices=double(value(:).');
if any(~isfinite(indices)) || any(indices~=fix(indices)) || ...
        any(indices<1 | indices>4) || numel(unique(indices))~=numel(indices)
    error('Verification:InvalidCharacterIndex','字段%s必须由互不重复的1到4整数构成。',fieldName);
end
end

function detail=empty_detail()
detail=struct('versionValid',false,'charactersValid',false, ...
    'proportionValid',false,'proportionError',NaN,'logoHashValid',false, ...
    'indicesValid',false,'additionalHashValid',false,'isValid',false, ...
    'errorIdentifier','','errorMessage','');
end

function valid=compare_additional(a,b,indices)
a=a(:); b=b(:); valid=numel(a)==numel(indices) && numel(b)==numel(indices);
if ~valid, return; end
for k=1:numel(indices)
    if double(a(k).index)~=indices(k) || double(b(k).index)~=indices(k) || ...
            ~strcmpi(char(a(k).hash),char(b(k).hash))
        valid=false; return;
    end
end
end
