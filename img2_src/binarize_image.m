function bw = binarize_image(img, T)
%BINARIZE_IMAGE Simple thresholding. Return logical image.
    if nargin<2, T = 1; end
    bw = img >= T;
    bw = logical(bw);
end
