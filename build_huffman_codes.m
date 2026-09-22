function codebook = build_huffman_codes(labels)
%BUILD_HUFFMAN_CODES 构造最大码长不超过5位的自适应哈夫曼码。
% 输入:
%   labels - XORP可嵌入块的lambda标签(0~6)。
% 输出:
%   codebook - 1x8元胞；第symbol+1项为码字，symbol=7是结束符。
%
% 当普通哈夫曼树超过5层时，通过增加平滑伪计数重新建树，使lambda=6
% 的最小容量块仍能保存“1位参考MSB+不超过5位的下一块标签”。

labels = double(labels(:).');
if any(labels<0 | labels>6)
    error('哈夫曼标签必须位于0~6。');
end
counts = zeros(1,8);
for value = labels
    counts(value+1) = counts(value+1)+1;
end
counts(8) = counts(8)+1; % symbol=7为标签链结束符
present = find(counts>0)-1;
smoothing = 0;
while true
    weights = counts(present+1)+smoothing;
    codebook = build_once(present,weights);
    lengths = cellfun(@numel,codebook(present+1));
    if max(lengths)<=5
        return;
    end
    if smoothing==0
        smoothing=1;
    else
        smoothing=smoothing*2;
    end
end
end

function codebook = build_once(symbols,weights)
% 使用小规模稳定合并实现标准二叉哈夫曼树。
codebook = repmat({''},1,8);
groups = cell(1,numel(symbols));
codes = cell(1,numel(symbols));
serial = 1:numel(symbols);
for k=1:numel(symbols)
    groups{k}=symbols(k);
    codes{k}={''};
end
if isscalar(symbols)
    codebook{symbols(1)+1}='0';
    return;
end
nextSerial=numel(symbols)+1;
while numel(weights)>1
    [~,order]=sortrows([weights(:),serial(:)],[1 2]);
    a=order(1); b=order(2);
    codeA=cellfun(@(s)['0',s],codes{a},'UniformOutput',false);
    codeB=cellfun(@(s)['1',s],codes{b},'UniformOutput',false);
    newGroup=[groups{a},groups{b}];
    newCodes=[codeA,codeB];
    keep=true(1,numel(weights)); keep([a b])=false;
    weights=[weights(keep),weights(a)+weights(b)];
    serial=[serial(keep),nextSerial]; nextSerial=nextSerial+1;
    groups=[groups(keep),{newGroup}];
    codes=[codes(keep),{newCodes}];
end
for k=1:numel(groups{1})
    codebook{groups{1}(k)+1}=codes{1}{k};
end
end
