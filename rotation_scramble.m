function scrambled = rotation_scramble(image)
%ROTATION_SCRAMBLE Rearrange a single-channel image by rotational blocks.
% Every 2-by-2 output block is formed from one pixel on each boundary of
% the current ring, while ring traversal proceeds from outside to inside.

if ~ismatrix(image) || isempty(image)
    error('Rotation scrambling input must be a non-empty 2-D matrix.');
end

sourceIndices = clockwise_ring_indices(size(image,1),size(image,2));
destinationIndices = packed_2x2_indices(size(image,1),size(image,2));
scrambled = zeros(size(image),'like',image);
scrambled(destinationIndices) = image(sourceIndices);
end
