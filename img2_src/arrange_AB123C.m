function wordImg = arrange_AB123C(crops, keep, S)
%ARRANGE_AB123C Arrange the characters to form the sequence AB123C.
% Assumption: left-to-right order in the original image is [1, A, B, 2, C, 3].
% We sort components by centroid x and then permute indices to AB123C.
    if numel(crops) < 6
        error('Detected fewer than 6 components.');
    end
    % Sort by centroid x (left to right)
    cx = arrayfun(@(k) S(k).Centroid(1), keep);
    [~, ordLR] = sort(cx);
    cropsLR = crops(ordLR);

    % Fixed permutation to AB123C
    orderIdx = [2,3,1,4,6,5];
    arranged = cropsLR(orderIdx);

    % Horizontal concatenation (each is targetSize 28x28 by default)
    wordImg = cell2mat(arranged);
end
