clear;clc;
%% === open the file ===
fid = fopen('chromo.txt');
% read a char at a time, ignore linefeed and carriage return
% and put them in a 64 X 64 matrix
lf = char(10); % line feed character
cr = char(13); % carriage return character
A = fscanf(fid, [cr lf '%c'],[64,64]);
% close the file handler
fclose(fid);
A = A'; % transpose since fscanf returns column vectors
% convert letters A‐V to their corresponding values in 32 gray levels
% literal A becomes number 10 and so on...
A(isletter(A))= A(isletter(A)) - 55;
%convert number literals 0‐9 to their corresponding values in 32 gray
%levels. Numeric literal '0' becomes number 0 and so on...
A(A >= '0' & A <= '9') = A(A >= '0' & A <= '9') - 48;
img = uint8(A);


%% === Task 1: img show ===
figure('Name','Task 1: Original','NumberTitle','off','Color','w');
subplot(1,1,1);
imagesc(img); axis image off; colormap(gray(32)); caxis([0 31]); colorbar;
title('Original (0..31 grayscale)');

%% === Task 2: Thresholding ===
T=20;
bw = img >= T;
bw = bwareaopen(~bw, 5);%remove noise
bw=~bw;
figure('Name','Task 2: Binary','NumberTitle','off','Color','w');
subplot(1,2,1);
histogram(double(img(:)), 32); grid on;
xlabel('Gray level (0..31)'); ylabel('Count'); title('Histogram');
xline(T,'r--','LineWidth',1.5,'Label',sprintf('T=%d',T),'LabelVerticalAlignment','middle');
subplot(1,2,2); imshow(bw); title(sprintf('Binary (T=%d)', T));
%% === Task 3: One pixel thin ===
thin_img = zhangsuen_thin(bw);
figure('Name','Task 3: Original Thin','NumberTitle','off','Color','w');
subplot(1,2,1); imshow(bw);       title('Binary (input)');
subplot(1,2,2); imshow(thin_img); title('One-pixel Thin ');
%% === Task 4: outlines ===
outline1 = outline_binary_edge(bw);   % sobel
outline2 = outline(bw);   % erode difference
figure('Name','Task 4: Outlines','NumberTitle','off','Color','w');
imshow(outline1); title('outlines/EDGE');
figure('Name','Task 4: Outlines','NumberTitle','off','Color','w');
imshow(outline2); title('outlines/Erode');
%% === Task 5: initial label objects ===
[L, numObj] = ccl8(~bw);

% visualization
RGB = label2rgb(L,'jet','k','shuffle');
S   = my_regionprops(L);

figure('Color','w');
subplot(1,2,1); imshow(RGB); title(sprintf(' Original Connected: %d', numObj));
subplot(1,2,2); imshow(~bw); title('Counts'); hold on;
for k = 1:numObj
    c = S(k).Centroid;
    text(c(1), c(2), num2str(k), 'Color','g','FontWeight','bold', ...
        'HorizontalAlignment','center');
    rectangle('Position', S(k).BoundingBox, 'EdgeColor','g', 'LineWidth', 0.75);
end
hold off;
fprintf(' finished Task 1~5。detected numbers：%d .\n', numObj);

%% === repair broken link ===
bw_conn = ~bw;  

angles = [0 45 90 135];  % 4 directions
for a = 1:length(angles)

    % kernels
    if angles(a) == 0
        se = [1 1];                   
    elseif angles(a) == 90
        se = [1;1];                   
    elseif angles(a) == 45
        se = [1 0 ; 0 1 ];     % 45°
    elseif angles(a) == 135
        se = [0  1; 1 0 ];     % 135°
    end

    % Expansion
    H = conv2(double(bw_conn), double(se), 'same');
    bw_d = H > 0;   

    % erode
    H2 = conv2(double(bw_d), double(se), 'same');
    bw_e = H2 == sum(se(:));   

    bw_conn = bw_e;  
end

bw_recon = bwareaopen(bw_conn, 5);%remove noise

%% === Task 5: Final label objects ===
[L, numObj] = ccl8(bw_recon);

RGB = label2rgb(L,'jet','k','shuffle');
S   = my_regionprops(L);

figure('Color','w');
subplot(1,2,1); imshow(RGB); title(sprintf('Connected: %d', numObj));
subplot(1,2,2); imshow(bw_recon); title('counts'); hold on;
for k = 1:numObj
    c = S(k).Centroid;
    text(c(1), c(2), num2str(k), 'Color','g','FontWeight','bold', ...
        'HorizontalAlignment','center');
    rectangle('Position', S(k).BoundingBox, 'EdgeColor','g', 'LineWidth', 0.75);
end
hold off;
fprintf(' finished Task 1~5。detected numbers：%d .\n', numObj);













