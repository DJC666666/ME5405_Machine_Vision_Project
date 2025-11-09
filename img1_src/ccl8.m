function [L, numObj] = ccl8(BW)

    BW = logical(BW);
    [H, W] = size(BW);
    L = zeros(H, W, 'uint32');

    % ---- First pass: provisional labels + record equivalences ----
    nextLabel = uint32(1);
    % preallocate a generous parent array; worst-case every fg pixel new label
    parent = uint32(1:nnz(BW)+1);  % +1 to avoid empty

    % find with path compression
    function r = uf_find(x)
        while parent(x) ~= x
            parent(x) = parent(parent(x));
            x = parent(x);
        end
        r = x;
    end

    % union by root
    function uf_union(a,b)
        if a==0 || b==0, return; end
        ra = uf_find(a); rb = uf_find(b);
        if ra ~= rb, parent(rb) = ra; end
    end

    % Map from linear index of label to root later
    for i = 1:H
        for j = 1:W
            if ~BW(i,j), continue; end

            % 8-CCL: check four already-scanned neighbors: NW, N, NE, W
            lblNW = 0; lblN = 0; lblNE = 0; lblW = 0;
            if i>1 && j>1,   lblNW = L(i-1,j-1); end
            if i>1,          lblN  = L(i-1,j);   end
            if i>1 && j<W,   lblNE = L(i-1,j+1); end
            if j>1,          lblW  = L(i,  j-1); end

            neighbors = [lblNW, lblN, lblNE, lblW];
            nz = neighbors(neighbors>0);

            if isempty(nz)
                % no labeled neighbor: assign new label
                L(i,j) = nextLabel;
                parent(nextLabel) = nextLabel;
                nextLabel = nextLabel + 1;
            else
                % assign the smallest neighbor label
                m = min(nz);
                L(i,j) = m;
                % record equivalences among all nonzero neighbor labels
                if lblNW>0, uf_union(m, lblNW); end
                if lblN >0, uf_union(m, lblN ); end
                if lblNE>0, uf_union(m, lblNE); end
                if lblW >0, uf_union(m, lblW ); end
            end
        end
    end

    % ---- Second pass: replace provisional by root labels, then compress to 1..K ----
    % build a map from root -> compact index
    maxLabel = double(nextLabel-1);
    rootMap = containers.Map('KeyType','uint32','ValueType','uint32');
    k = uint32(0);

    for i = 1:H
        for j = 1:W
            if L(i,j)==0, continue; end
            r = uf_find(L(i,j));
            if ~isKey(rootMap, r)
                k = k + 1;
                rootMap(r) = k;
            end
            L(i,j) = rootMap(r);
        end
    end

    numObj = double(k);
end