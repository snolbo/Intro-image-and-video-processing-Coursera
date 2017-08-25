function = encoding( QuantDCT )
%ENCODING.. NOT FINISHED DECODING



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

