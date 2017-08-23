

%% Implementation is not performed as most efficient as purpose is to apply algorithms seperatively. Also I fucking hate typeconverstion in Matlab
function main()
    
I = imread('chaplin.jpg'); I = rgb2gray(I);
qf = 50;
N = 8;

% Test block
% I = [5	176	193	168	168	170	167	165;
% 6	176	158	172	162	177	168	151;
% 5	167	172	232	158	61	145	214;
% 33	179	169	174	5	5	135	178;
% 8	104	180	178	172	197	188	169;
% 63	5	102	101	160	142	133	139;
% 51	47	63	5	180	191	165	5;
% 49	53	43	5	184	170	168	74];


I = I - 127; %% translate pixel value by -127 to center the intensities about the value 0 to simple transformation and quantization steps


%% Preprocessing - Turn image into 8x8 blocks of pixels
[row, col] = size(I);
blockRows = row / N;
blockCols = col/N;


index = @(x) (x-1)*N + 1: x*N;


%% Transformation - Compute DCT of all 8x8 blocks and save them in new matrix
DCTMatrix = zeros(row, col);
for i = 1:blockRows
    for j = 1:blockCols
        DCTMatrix(index(i),index(j)) = dct2(I(index(i), index(j)));
    end
end    



%% Quantization -  Eliminate unimportant coefficients in DCT'ed 8x8 blocks

Tb =[ % this is the jpeg quantization matrix. Developed with magic and wizardry
    16    11    10    16    24    40    51    61
    12    12    14    19    26    58    60    55
    14    13    16    24    40    57    69    56
    14    17    22    29    51    87    80    62
    18    22    37    56    68   109   103    77
    24    35    55    64    81   104   113    92
    49    64    78    87   103   121   120   101
    79    92    95    98   112   100   103    99];

% depending in the quality for compression Q (1-100), find scaling factor
qScale = 0;
if qf < 50
    qScale = floor(5000/qf);
else
    qScale = 200 - 2*qf;
end
% Scaling the quantization matrix depening on quality factor
Ts = (Tb *qScale)/100;
Ts(Ts == 0) = 1; % prevent dividing by 0

% Applying the scaled quantization matrix to all DCT'ed 8x8 blocks
QuantDCT = zeros(row, col);
for i = 1:blockRows
    for j = 1:blockCols
        QuantDCT(index(i),index(j)) = round(DCTMatrix(index(i), index(j))./Ts);
    end
end  
    



%% Predictor 
%  Since the DC coeficcient of 2 adjecent blocks are assumed to be similiar
%  because of the shape of the DCT, we make a prediciton that the
%  coeficcients of block n+1 is equal to those of block n. The first block
%  of a new row is predicted to be equal to the one above it. Since we
%  assume the error is small, we predict that there will be alot of
%  repeating numbers. Having coefficient in different blocks: 64, 65, 66,
%  67... would result in one code per number in original huffman coding.
%  Taking the error would result in 64, 1 , 1, 1 ... and we see that
%  huffman coding would be more efficient

% Calculating the error of the preduction
PredictionError = zeros(row, col);
% First row calculations
PredictionError(index(1),index(1)) = QuantDCT(index(1), index(1));
for j = 2:blockCols
    PredictionError(index(1), index(j)) =  QuantDCT(index(1), index(j-1)) - QuantDCT(index(1), index(j));
end

%% remainding rows
for i = 2:blockRows
    PredictionError(index(i), index(1)) = QuantDCT(index(i-1), index(1)) - QuantDCT(index(i), index(1));
    for j = 2:blockCols
        PredictionError(index(1), index(j)) =  QuantDCT(index(1), index(j-1)) - QuantDCT(index(1), index(j));
    end
end  


% Get list of remainding coeficcients by performing zigzag search on 8x8 blocks
coeficcientLists = [];
for i = 1:blockRows
    for j = 1:blockCols
        coeficcientLists = [ coeficcientLists zigZagSearch(PredictionError(index(i), index(j)))];
    end
end  



%% Encoding
% we need to save the remainding coefficients from the 8x8 blocks using
% Huffman coding

% Find occurence of the coefficients of PredictionError. Using matlabs huffmandict to create huffman dictionary
occurenceVector = coeficcientLists; % creates vector with all occurences of elements of coeficcientLists
histSymbols = unique(occurenceVector);
if length(histSymbols) == 1
    symbol = histSymbols(1);
    dict = containers.Map(symbol, 1);
else
    [histFreq, histSymbols] = hist(occurenceVector, unique(occurenceVector));
    histProb = histFreq / sum(histFreq);
    cellDict = huffmandict(histSymbols, histProb);
    dict = containers.Map('KeyType', 'double', 'ValueType', 'char');
    for i = 1: length(cellDict)
        numArr = cell2mat(cellDict(i,2));
        value = '';
        for j = 1:length(numArr)
            value = strcat(value, num2str(numArr(j)));
        end
        key = cellDict{i,1};
        dict(key) = value;    
    end
    
end



%% Create string with symbols from huffmancode for all blocks, using '2' as block separator in this implementation
blockRepresentation = '';        
for k = 1: length(coeficcientLists)
    if(coeficcientLists(k) == 0)
        blockRepresentation = strcat(blockRepresentation, '2');
        continue;
    else
        blockRepresentation = strcat(blockRepresentation, dict(coeficcientLists(k)));
    end
end
    



%% Run length coding
numCode = blockRepresentation - '0'; % gives numerical array
J  = find(diff([numCode(1)-1, numCode])); % finds indexes where blockrepresentation changes symbol
runMatrix = [(numCode(J)); diff([J, length(numCode)+1])];  % 2. column calculates how long intervals of given symbol runs


huffmanEncoded = huffmanenco(numCode,cellDict);




% SEND HUFFMANENCODED, DICT AND Ts, row and col

huffmanDecoded = huffmandeco(huffmanEncoded, cellDict);

QuantDCTRestored = zeros(row,  col);
k = 1;
for i = 1:blockRows
    for j = 1:blockCols
        if k > 5150
            u = 2;
        end
        if huffmanDecoded(k) == 2
            k = k+1;
        else
            QuantDCTRestored( (i-1)*N+1, (j-1)*N +1) = huffmanDecoded(k);
            k = k+1;
            r = 1; c = 2;
            goLeft = true;
            while huffmanDecoded(k)~= 2
                QuantDCTRestored( (i-1)*N+r, (j-1)*N +c) = huffmanDecoded(k);
                k = k+1;
                if goLeft && c == 1
                    goLeft = false;
                    r = r + 1;
                    continue;
                elseif ~goLeft && r == 1
                    goLeft = true;
                    c = c + 1;
                    continue;
                end

                if(goLeft)
                    r = r + 1; c = c - 1;
                else
                    r = r - 1; c = c + 1;
                end
            end
        end
    end
end




end

% performs a zigzag search, starting from upper left, going to the right
% (1,2) then in a diagonal zigzag until it reaches the first 0, then
% returns
function elements = zigZagSearch(matrix)
    elements = [];
    if(matrix(1,1) == 0)
        elements = [0];
        return
    end
    elements(1) = matrix(1,1);
    r = 1; c = 2;
    goLeft = true;
    a = 2;
    while(matrix(r,c) ~= 0)
        elements(a) = matrix(r,c);
        if goLeft && c == 1
            goLeft = false;
            r = r + 1;
            continue;
        elseif ~goLeft && r == 1
            goLeft = true;
            c = c + 1;
            continue;
        end
        
        if(goLeft)
            r = r + 1; c = c - 1;
        else
            r = r - 1; c = c + 1;
        end
        a = a+1;
    end
end

function k = zigZagPlaceCoefficients(coefficcients, k)


end

