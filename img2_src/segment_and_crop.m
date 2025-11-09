function [crops, keep, S] = segment_and_crop(bw, targetSize, showFig)
%SEGMENT_AND_CROP  Connected-component segmentation; filter noise; crop each
% character; square-pad; resize to targetSize.
% Returns:
%   crops: cell array of resized character images (logical)
%   keep:  indices of components that were kept
%   S:     regionprops struct of the connected components
    if nargin<2 || isempty(targetSize), targetSize=[28 28]; end
    if nargin<3, showFig=false; end

    CC = bwconncomp(bw, 8);
    S  = regionprops(CC, 'Area','BoundingBox','Centroid','EulerNumber','Solidity','Extent');
    areas = [S.Area];
    medA  = median(areas);
    keep  = find(areas > max(10, 0.2*medA));  % filter small fragments

    if showFig
        L  = labelmatrix(CC);
        RGB = label2rgb(L,'jet','k','shuffle');
        figure('Name','Step5: Labeled','Color','w');
        subplot(1,2,1); imshow(RGB); title(sprintf('Connected Components: %d', CC.NumObjects));
        subplot(1,2,2); imshow(bw); title('Counts'); hold on;
        for i=1:numel(keep)
            k = keep(i);
            c = S(k).Centroid;
            text(c(1), c(2), sprintf('%d', k), 'Color','r','FontWeight','bold','HorizontalAlignment','center');
            rectangle('Position', S(k).BoundingBox, 'EdgeColor','g', 'LineWidth', 0.75);
        end
        hold off;
    end

    crops = cell(1, numel(keep));
    for i=1:numel(keep)
        k = keep(i);
        bb = S(k).BoundingBox;  % [x y w h]
        sub = imcrop(bw, bb);

        % Square padding
        [h,w] = size(sub);
        m = max(h,w);
        padT = floor((m-h)/2); padB = ceil((m-h)/2);
        padL = floor((m-w)/2); padR = ceil((m-w)/2);
        subSq = padarray(sub, [padT padL], 0, 'pre');
        subSq = padarray(subSq, [padB padR], 0, 'post');

        crops{i} = imresize(subSq, targetSize, 'nearest');
    end
end
