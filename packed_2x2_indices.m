function linearIndices = packed_2x2_indices(height,width)
%PACKED_2X2_INDICES Return output positions for row-wise 2-by-2 blocks.

if height ~= width || mod(height,2) ~= 0
    error(['The rotational block scrambling algorithm requires an even ', ...
        'square single-channel image.']);
end

blockSide = height/2;
linearIndices = zeros(1,height*width);
count = 0;
for blockRow = 1:blockSide
    for blockColumn = 1:blockSide
        row = 2*blockRow-1;
        column = 2*blockColumn-1;
        positions = [sub2ind([height,width],row,column), ...
            sub2ind([height,width],row+1,column), ...
            sub2ind([height,width],row,column+1), ...
            sub2ind([height,width],row+1,column+1)];
        linearIndices(count+1:count+4) = positions;
        count = count + 4;
    end
end
end
