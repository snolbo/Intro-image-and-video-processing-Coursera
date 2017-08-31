function main ()

    I = imread('lena.jpg');
    if length(size(I)) == 3
        I = rgb2gray(I);
    end
%     m = 0;
%     sig = 0.05;
%     
%     J = imnoise(I, 'salt & pepper', 0.3); % hard noise
%     K = imnoise(I, 'gaussian', m, sig); % gaussian noise4
%     
%     figure(1); imshow(I);
%     figure(3); imshow(J);
%     figure(2); imshow(K);
% 
%     neigh = [7 7]; % increasing the window size greatly increases the amount of salt & pepper noise the median filter manages
%                     % to remove, without greatly destroying the image. The
%                     % mean filter becomes sauce
%     Jmed = medfilt2(J, neigh, 'symmetric');
%     Kmed = medfilt2(K, neigh, 'symmetric');
%     figure(4); imshow(Jmed);
%     figure(5); imshow(Kmed);

    WienerFiltering(I);
end


function WienerFiltering(I)
    
    
    N = imnoise(I, 'gaussian', 0, 0.05);
    
    figure(1); imshow(I);
    figure(2); imshow(N);
    J = wiener2(N, [10,10]);
    figure(3); imshow(J);

    
    
end