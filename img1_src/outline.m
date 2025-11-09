function perim = outline(bw)
    % 3x3 kernel
    K = ones(3);

    cnt = conv2(double(bw), K, 'same');

    % Erode
    eroded = (cnt == 9);

    % difference
    perim = bw & ~eroded;
end