function out = rotate_about_center(img, angleDeg, fillVal)
%ROTATE_ABOUT_CENTER Nearest-neighbor rotation around the center.
% Expands canvas to fit the rotated image.
    if nargin < 3, fillVal = 0; end
    [H, W] = size(img);
    cx = (W+1)/2; cy = (H+1)/2;
    ang = deg2rad(angleDeg); c=cos(ang); s=sin(ang);
    corners = [1-cx,1-cy; W-cx,1-cy; W-cx,H-cy; 1-cx,H-cy];
    Rinv = [ c, s; -s, c];
    rotCorners = (Rinv * corners.').';
    minX=min(rotCorners(:,1)); maxX=max(rotCorners(:,1));
    minY=min(rotCorners(:,2)); maxY=max(rotCorners(:,2));
    outW = ceil(maxX - minX + 1);
    outH = ceil(maxY - minY + 1);
    cxo=(outW+1)/2; cyo=(outH+1)/2;
    out = repmat(cast(fillVal,'like',img), outH, outW);
    for y = 1:outH
        for x = 1:outW
            xr = x - cxo; yr = y - cyo;
            src = Rinv * [xr; yr];
            xs = src(1) + cx; ys = src(2) + cy;
            xsN = round(xs); ysN = round(ys);
            if xsN>=1 && xsN<=W && ysN>=1 && ysN<=H
                out(y,x) = img(ysN,xsN);
            end
        end
    end
end
