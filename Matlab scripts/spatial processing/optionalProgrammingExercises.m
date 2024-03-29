

function optionalProgrammingExercises ()

    %% Implement a histogram equalization function. If using Matlab, compare your implementation with Matlab�s built-in function.

    
%    I = imread('dark2.jpg');
%    G = 255;
%    Ieq = globalImageEqualization(I,G);
   
   
%    
%    J = imread('chaplin.jpg');
%    
%    if(size(J,3) == 3)
%         J = rgb2gray(J);
%     end
%    J = imnoise(J, 'salt & pepper', 0.1);
%    figure(1); imshow(J);
% 
%    
%    medianJ = medianFilter(J);
%    figure(2);imshow(medianJ);
%    Jmed = medfilt2(J);
%    figure(3); imshow(Jmed);


% %% Non local means algorithm
%     K = imread('lena.jpg');
%     if(size(K,3) == 3)
%         K = rgb2gray(K);
%     end
%     K = imnoise(K, 'gaussian',0, 0.01);
%     figure(11); imshow(K);
% 
%     Knlm = uint8(NonLocalMeansFilter(K));
%     figure(12); imshow(Knlm);
%     figure(13); imshow(uint8(abs(K-Knlm)));
%     figure(15); imhist(K);
%     figure(16); imhist(Knlm);


%% Temporal averaging. Averaging n realizations  of the same uncorrelated noise reduced the noise power (variance) by a factor of n
%     K = imread('lena.jpg');
%     if(size(K,3) == 3)
%         K = rgb2gray(K);
%     end
%     N = 2;
%     I = K;
%     for i = 1:20
%        I =  (I +  imnoise(K, 'gaussian',0, 0.01))/2;
%     end
%     I = uint8(I);
%     figure(11); imshow(I);



%% Edge detection 
%     K = imread('lena.jpg');
%     if(size(K,3) == 3)
%         K = rgb2gray(K);
%     end
%     K = double(K);
%     LaplacianKernel = [
%         -1 -1 -1;
%         -1 8 -1;
%         -1 -1 -1]; 
%     L = imfilter(K,LaplacianKernel);
%     L = L * 255 / max(max(L));
%     
%     % scaling filter
%     sharp = uint8(K+L);
%     L = uint8(L);
%     K = uint8(K);
%     figure(1); imshow(L);
%     figure(2); imshow(K);
%     figure(3); imshow(sharp);


end

function Iequalized = globalImageEqualization(I, G)
    if(size(I,3) == 3)
        I = rgb2gray(I);
    end
    [rows, cols] = size(I);
    histogram = zeros(1,256);
    for i = 1:rows
        for j = 1:cols
            histogram( I(i,j) +1) = histogram( I(i,j) +1) + 1;
        end
    end
    probabilities = histogram / (rows*cols);
    cumProbabilities = cumsum(probabilities);
    
    Iequalized = zeros(rows, cols);
    for i = 1:rows
        for j = 1:cols
            Iequalized(i,j) = G * cumProbabilities(I(i,j) +1);
        end
    end
    Iequalized = uint8(Iequalized); % turning image from double to grayscale ( uint8)
    figure(1); imshow(I);
    figure(2); imhist(I);
    figure(3); plot(cumProbabilities);
    figure(4); imhist(Iequalized);
    figure(5); imshow(Iequalized);
%     %% matlabs built in equalizer
%     J = histeq(I);
%     figure(6); imhist(J);
%     figure(7); imshow(J);
end

function medianImage = medianFilter(I)
    if(size(I,3) == 3)
        I = rgb2gray(I);
    end
    [rows, cols] = size(I);
    I = [ zeros(rows,1), I, zeros(rows,1)];
    I = [zeros(1,cols + 2); I ; zeros(1,cols + 2)];
    
    colSeg = @(x) x-1:x+1;
    medianImage = zeros(rows,cols);
    for i = 2:rows +1
        for j = 2:cols +1
            neigborList = [I(i-1, colSeg(j)),  I(i, colSeg(j)), I(i+1,colSeg(j))];
            medianImage(i-1,j-1) = median(neigborList);
        end
    end
    medianImage = uint8(medianImage);
end

% computes non local means using gaussian function for computing weights.
% Brute force baby......
function NLMImage = NonLocalMeansFilter(I)
    [rows, cols] = size(I);
    % adding rows of zero to image for computing 3x3 means
    J = [ zeros(rows,1), I, zeros(rows,1)];
    J = [zeros(1,cols + 2); J ; zeros(1,cols + 2)];
         F = gpuArray(I);
     h = ones(3,3)/9;
     B = imfilter(F, h);
     B = double(gather(B));
    gaussWeight = @(Bq, Bp, sig) exp( - ((Bq -Bp)/sig)^2); % function to compute gauss weights
    gpuI = gpuArray(I);
    gpuB = gpuArray(B);
    gpuBPHolder = ones(rows, cols, 'gpuArray');
    gpuBP = zeros(rows, cols, 'gpuArray');
    gpuGauss = zeros(rows, cols, 'gpuArray');
    
    NLMImage = zeros(rows, cols);
    for i = 1:rows
        for j = 1:cols
%             NLMImage(i,j) = NLMValue(i,j,I, rows, cols, B);
            NLMImage(i,j) = gpuNLMValue(B(i,j), gpuB, gpuI, gpuBPHolder);
        end
        fprintf("computed row %d\n", i);
    end
end
    

function [value, weight] = gaussWeightsMultI(a,b, c) 
    weight = exp(-((a-b))^2);
    value = weight * c;
end

function NLMValue = gpuNLMValue(bp, gpuB, gpuI, gpuBPHolder)
    gpuBP = gpuBPHolder*bp;
    [values, weights] = arrayfun(@gaussWeightsMultI, gpuBP, gpuB, gpuI);
    C = sum(sum(weights));
    NLMValue = gather(sum(sum(values))/C);
end

function NLMValue = NLMValue(i,j, I, rows, cols, B)
      C = 0; 
      NLMValue = 0;
        for r = 1:rows
            for c = 1:cols
              [val, weight] = gaussWeightsMultI(B(r,c), B(i,j), I(r,c));
              NLMValue = NLMValue + val;
              C = C + weight;
            end
        end
        NLMValue = NLMValue / C;
end








