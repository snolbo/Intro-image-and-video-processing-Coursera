
function main()
    
I = randi(10, 8);
J = imread('lena.jpg'); 



I8x8 = image2NxNBlocks(I, 8);

[cRow, cCol] = size(I8x8);
DCTCellMatrix = cell(cRow, cCol);
%% comnpute DCT of all cell elements
for i = 1:cRow
    for j = 1:cCol
        DCTCellMatrix(i,j) = { dct(cell2mat(I8x8(i,j))) };
    end
end    


%% quantify the matrix
DFTCellQuantifiedMatrix = cell(cRow, cCol);
for i = 1:cRow
    for j = 1:cCol
        DFTCellQuantifiedMatrix(i,j) = { JPEGQuantifier(cell2mat(I8x8(i,j)), 80) };
    end
end    




celldisp(DFTCellQuantifiedMatrix)
celldisp(invertQuantMatrix);

end


%% creates a cellMatrix with NxN matrices as contents ( no check for error in regards to dimentions of image and N)
function cellMatrix = image2NxNBlocks(image, N)
    if isempty(N)
        N = 8;
    end
    [nrow, ncol] = size(image);
    crow = ceil(nrow/N);
    ccol = ceil(ncol/N);

    cellMatrix = cell(crow, ccol);
    for i = 1:crow
        for j = 1:ccol
            cellMatrix(i,j) = { image( (i-1)*N + 1: i*N, (j-1)*N +1: j*N) };
        end
    end
end

% Q = quality: (1,100)
function quantifiedMatrix = JPEGQuantifier(matrix, Q)
    % jpeg quantifier matrix
    Tb =[   16    11    10    16    24    40    51    61;
            12    12    14    19    26    58    60    55;
            14    13    16    24    40    57    69    56;
            14    17    22    29    51    87    80    62;
            18    22    37    56    68   109   103    77;
            24    35    55    64    81   104   113    92;
            49    64    78    87   103   121   120   101;
            72    92    95    98   112   100   103    99    ];
    S = 0;
    if(Q < 50)
        S = 5000/Q;
    else
        S = 200 - 2*Q;
    end
    Ts = floor((S*Tb + 50) / 100);
    Ts(Ts==0) = 1; % to prevent dividing by 0
    
    quantifiedMatrix = floor(matrix./Ts).*Ts;
      
end





