function img = read_charact(txtFile)
%READ_CHARACT Read a 64x64 character image (0..31 grayscale) from ASCII file.
    fid = fopen(txtFile);
    assert(fid>0, 'Cannot open file: %s', txtFile);
    lf = char(10); cr = char(13);
    A = fscanf(fid, [cr lf '%c'], [64,64]);
    fclose(fid);
    A = A';
    A(isletter(A)) = A(isletter(A)) - 55;           % 'A'->10, 'B'->11, ...
    A(A>='0' & A<='9') = A(A>='0' & A<='9') - 48;   % '0'->0, '1'->1, ...
    img = uint8(A);
end
