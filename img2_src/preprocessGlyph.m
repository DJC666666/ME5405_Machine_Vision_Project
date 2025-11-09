function Iout = preprocessGlyph(Iin, targetSize)
%PREPROCESSGLYPH Convert any input glyph to targetSize (default 28x28) with
% white foreground (1) and black background (0), including square padding.
    if nargin<2 || isempty(targetSize), targetSize=[28 28]; end
    I = squeeze(Iin);
    if ~islogical(I)
        I = double(I);
        if max(I(:))>1, I = I/(max(I(:))+eps); end
        bw = imbinarize(I, graythresh(I));
    else
        bw = I;
    end
    % If the border is mostly white, invert so that background=0
    border = [bw(1,:), bw(end,:), bw(:,1).', bw(:,end).'];
    if mean(border) > 0.5, bw = ~bw; end
    bw = bwareaopen(bw,20);
    bw = imclose(bw, strel('square',2));
    stats = regionprops(bw,'BoundingBox','Area');
    if isempty(stats)
        Iout = uint8(zeros(targetSize)); 
        return;
    end
    [~,imax] = max([stats.Area]); bb = stats(imax).BoundingBox;
    x=floor(bb(1)); y=floor(bb(2)); w=ceil(bb(3)); h=ceil(bb(4));
    x=max(1,x); y=max(1,y);
    crop = bw(y:min(end,y+h-1), x:min(end,x+w-1));

    % Scale longest side to (min(targetSize)-8), leaving margins
    maxInner = min(targetSize)-8;
    scale = maxInner / max(size(crop));
    inner = imresize(crop, scale, 'nearest');

    Iout = false(targetSize);
    [ih,iw] = size(inner);
    oy = floor((targetSize(1)-ih)/2)+1; 
    ox = floor((targetSize(2)-iw)/2)+1;
    Iout(oy:oy+ih-1, ox:ox+iw-1) = inner;
    Iout = uint8(Iout)*255;
end
