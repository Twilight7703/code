function blocks = xorp_analyze_blocks(image)
%XORP_ANALYZE_BLOCKS 分析所有不重叠2x2块的XORP参数。
% 输入: image-uint8二维载体图像。
% 输出: blocks-结构体数组，含row、column、lambda、embeddable、refMSB。

if ~isa(image,'uint8') || ~ismatrix(image) || any(size(image)<2)
    error('XORP输入必须是至少2x2的uint8二维图像。');
end
[height,width]=size(image);
template=struct('row',0,'column',0,'lambda',0,'embeddable',false,'refMSB',0);
blocks=repmat(template,1,floor(height/2)*floor(width/2));
index=0;
for row=1:2:height-1
    for column=1:2:width-1
        index=index+1;
        reference=image(row,column);
        neighbors=[image(row,column+1),image(row+1,column),image(row+1,column+1)];
        dmax=max(double(bitxor(reference,neighbors)));
        if dmax==0, lambda=0; else, lambda=floor(log2(dmax))+1; end
        blocks(index)=struct('row',row,'column',column,'lambda',lambda, ...
            'embeddable',lambda<=6,'refMSB',double(bitget(reference,8)));
    end
end
end

