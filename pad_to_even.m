function [padded,originalShape] = pad_to_even(image)
%PAD_TO_EVEN 将uint8图像右侧/底部零填充到偶数尺寸。
% 输入: image-uint8二维图像。
% 输出: padded-偶数尺寸图像；originalShape-[原高 原宽]。

if ~isa(image,'uint8') || ~ismatrix(image), error('输入必须是uint8二维图像。'); end
[height,width]=size(image); originalShape=[height,width];
padded=zeros(height+mod(height,2),width+mod(width,2),'uint8');
padded(1:height,1:width)=image;
end

