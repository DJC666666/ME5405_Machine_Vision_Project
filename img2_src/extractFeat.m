function feat = extractFeat(Ibin)
%EXTRACTFEAT Extract HOG features (if available); otherwise 4x4 zoning.
    if exist('extractHOGFeatures','file')==2
        feat = extractHOGFeatures(Ibin>0,'CellSize',[4 4],'BlockOverlap',[1 1], ...
                                  'UseSignedOrientation',false);
    else
        B = Ibin>0; bs = 4; v = zeros(1,bs*bs); idx=1;
        for r = 1:bs
            rs = floor((r-1)*size(B,1)/bs)+1; re = floor(r*size(B,1)/bs);
            for c = 1:bs
                cs = floor((c-1)*size(B,2)/bs)+1; ce = floor(c*size(B,2)/bs);
                blk = B(rs:re,cs:ce);
                v(idx) = nnz(blk)/numel(blk); idx=idx+1;
            end
        end
        feat = v;
    end
end
