function linearIndices = clockwise_ring_indices(height,width)
%CLOCKWISE_RING_INDICES Generate ring-wise 2-by-2 block indices.
% Each block takes one pixel from the top, right, bottom, and left
% boundaries at the same offset. The blocks are generated from the outer
% ring to the inner ring. The returned order is block(:), so the first
% 2-by-2 block is [top-left top-right; bottom-left bottom-right].

if nargin < 2 || ~isscalar(height) || ~isscalar(width) || ...
        height ~= fix(height) || width ~= fix(width) || ...
        height <= 0 || width <= 0
    error('Image dimensions must be positive integers.');
end
if height ~= width || mod(height,2) ~= 0
    error(['The rotational block scrambling algorithm requires an even ', ...
        'square single-channel image.']);
end

linearIndices = zeros(1,height*width);
count = 0;
top = 1;
bottom = height;
left = 1;
right = width;

while top <= bottom
    ringSize = bottom - top + 1;
    for offset = 0:ringSize-2
        topPixel = sub2ind([height,width],top,left+offset);
        rightPixel = sub2ind([height,width],top+offset,right);
        bottomPixel = sub2ind([height,width],bottom,right-offset);
        leftPixel = sub2ind([height,width],bottom-offset,left);

        % MATLAB column-major order preserves the displayed block:
        % [top-left top-right; bottom-left bottom-right].
        blockIndices = [topPixel,leftPixel,rightPixel,bottomPixel];
        linearIndices(count+1:count+4) = blockIndices;
        count = count + 4;
    end

    top = top + 1;
    bottom = bottom - 1;
    left = left + 1;
    right = right - 1;
end

linearIndices = linearIndices(1:count);
end
