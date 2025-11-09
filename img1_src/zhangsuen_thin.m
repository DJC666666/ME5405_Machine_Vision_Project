function thin_img = zhangsuen_thin(bw)
    if ~islogical(bw)
        bw = bw > 0;                     
    end

    if mean(bw(:)) > 0.5
        bw = ~bw;
    end



    bw = padarray(bw,[1 1],0,'both');

    prev = false(size(bw));
    while true
        % -------- Sub-iteration 1 --------
        toDelete = false(size(bw));
        for i = 2:size(bw,1)-1
            for j = 2:size(bw,2)-1
                if ~bw(i,j), continue; end
                p2 = bw(i-1,j);     % N
                p3 = bw(i-1,j+1);   % NE
                p4 = bw(i,  j+1);   % E
                p5 = bw(i+1,j+1);   % SE
                p6 = bw(i+1,j);     % S
                p7 = bw(i+1,j-1);   % SW
                p8 = bw(i,  j-1);   % W
                p9 = bw(i-1,j-1);   % NW
                B = p2+p3+p4+p5+p6+p7+p8+p9;                  % A1
                seq = [p2 p3 p4 p5 p6 p7 p8 p9 p2];         
                A = sum(seq(1:end-1)==0 & seq(2:end)==1);     % B1
                if (B>=2 && B<=6 && A==1 && (p2*p4*p6)==0 && (p4*p6*p8)==0)
                    toDelete(i,j) = true;
                end
            end
        end
        bw(toDelete) = false;

        % -------- Sub-iteration 2 --------
        toDelete = false(size(bw));
        for i = 2:size(bw,1)-1
            for j = 2:size(bw,2)-1
                if ~bw(i,j), continue; end
                p2 = bw(i-1,j);
                p3 = bw(i-1,j+1);
                p4 = bw(i,  j+1);
                p5 = bw(i+1,j+1);
                p6 = bw(i+1,j);
                p7 = bw(i+1,j-1);
                p8 = bw(i,  j-1);
                p9 = bw(i-1,j-1);
                B = p2+p3+p4+p5+p6+p7+p8+p9;
                seq = [p2 p3 p4 p5 p6 p7 p8 p9 p2];
                A = sum(seq(1:end-1)==0 & seq(2:end)==1);
                if (B>=2 && B<=6 && A==1 && (p2*p4*p8)==0 && (p2*p6*p8)==0)
                    toDelete(i,j) = true;
                end
            end
        end
        bw(toDelete) = false;

        if isequal(bw, prev), break; end
        prev = bw;
    end

    thin_img = bw(2:end-1, 2:end-1);
end