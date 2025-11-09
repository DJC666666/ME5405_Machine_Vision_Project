function S = my_regionprops(L)
    num = max(L(:));
    S = struct('Centroid',{},'BoundingBox',{});
    for k = 1:num
        [r,c] = find(L==k);  
        if isempty(r)
            S(k).Centroid = [NaN NaN];
            S(k).BoundingBox = [0 0 0 0];
        else
            cx = mean(c);         % coloum
            cy = mean(r);         % row
            S(k).Centroid = [cx cy];
            x = min(c);  y = min(r);
            w = max(c)-x+1;  h = max(r)-y+1;
            S(k).BoundingBox = [x y w h];
        end
    end
end