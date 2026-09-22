function request=verification_build_receiver_request(logoInput,additionalIndices)
%VERIFICATION_BUILD_RECEIVER_REQUEST 构建接收方提交的Logo验证参数。
% 输入:
%   logoInput        - 接收方持有的Logo路径或图像。
%   additionalIndices- 指定字符位置，默认[1 3]。
% 输出:
%   request - 字符串、比例、Logo哈希和局部字符哈希。

if nargin<2 || isempty(additionalIndices), additionalIndices=[1 3]; end
analysis=verification_analyze_logo(logoInput,additionalIndices);
request=struct('version','verification-v2', ...
    'stringReceived',char(analysis.result), ...
    'proportionReceived',double(analysis.proportionText), ...
    'logoSha256',char(analysis.logoSha256), ...
    'additionalIndices',double(analysis.additionalIndices), ...
    'additionalCharacters',analysis.additionalCharacters);
end
