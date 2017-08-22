
function main()

    %%% Write a computer program capable of reducing the number of intensity levels in an image from 256 to 2, in integer powers of 2. The desired number of intensity levels needs to be a variable input to your program.
    %I = randi(10,3);
    I = imread('beans.jpg');
    I = rgb2gray(I);
    I = im2double(I);
    
    
    
%     integerPowerOf2 = 4;
%     J = intensityLevelReducer(I,integerPowerOf2);   % mist take image with values 0-255, not floating point
%     figure; imshow(I);
%     figure; imshow(J);
    
    
    %%% manually apply y x y average filter
    K = averageFilter(I,9);
    figure;imshow(I);
    figure;imshow(K);
    
    
    %% rotate image
    I45 = imrotate(I, 45);
    I90 = imrotate(I,90);
    
    
    
    %% for n x n block of image replace all corresponding n pixels by their average. This operation simulates reducing the image spatial resolution
    % matlab imresize does this, method 'cubic' kernel
    
    
end



function newImage = intensityLevelReducer(I, integerPower2)
    reductionFactor = 2^integerPower2;
    newImage =  floor(I./reductionFactor)* reductionFactor;
end


% n is the dimention of the neighborhood filter: n x n, n must be odd >= 3
function filteredImage = averageFilter(image, n)
    

    %% first append rows and columns of zeros to image
    [nrow, ncol] = size(image);
    extendedImage = image;
    N = floor(n/2);
    zeroRow = zeros(nrow, N);
    zeroCol = zeros(N, ncol + 2* N);
    extendedImage = [zeroRow, extendedImage, zeroRow];
    extendedImage = [zeroCol ; extendedImage; zeroCol];
    
    

    filteredImage = zeros(nrow, ncol);
    %% now apply n x n filter to image
    %  implemented ineffiecient, for learning purposes
    
    for i = 1 :2*N: nrow
        for j = 1 :2*N: ncol
            neighborhood = extendedImage(i: i + 2*N, j: j + 2*N);
            filteredImage(i,j) = sum(neighborhood(:))/n^2;
        end
    end
    
            
end




