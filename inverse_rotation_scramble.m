function image = inverse_rotation_scramble(scrambled)
%INVERSE_ROTATION_SCRAMBLE Restore the original image positions.

if ~ismatrix(scrambled) || isempty(scrambled)
    error('Inverse rotation scrambling input must be a non-empty 2-D matrix.');
end

sourceIndices = clockwise_ring_indices(size(scrambled,1),size(scrambled,2));
destinationIndices = packed_2x2_indices(size(scrambled,1),size(scrambled,2));
image = zeros(size(scrambled),'like',scrambled);
image(sourceIndices) = scrambled(destinationIndices);
end
