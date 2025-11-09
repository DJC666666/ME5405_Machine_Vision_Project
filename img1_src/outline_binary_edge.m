function outline = outline_binary_edge(bw)


    %  Sobel 
    Gx = [1 0 -1;
          2 0 -2;
          1 0 -1];
    Gy = [1 2 1;
          0 0 0;
         -1 -2 -1];

    % gradients
    grad_x = conv2(bw, Gx, 'same');
    grad_y = conv2(bw, Gy, 'same');

    grad_mag = sqrt(grad_x.^2 + grad_y.^2);

    % normalization
    grad_mag = grad_mag ./ max(grad_mag(:) + eps);

    % threshold
    T = graythresh(grad_mag);

    outline = grad_mag > T;
end