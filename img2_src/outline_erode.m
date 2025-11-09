function perim = outline_erode(bw)
%OUTLINE_PERIMETER 8-connected perimeter: perim = bw & ~erode(bw)
    K = ones(3);
    cnt = conv2(double(bw), K, 'same');
    eroded = (cnt == 9);
    perim = bw & ~eroded;
end
