function histogramExample()
    I = imread('chaplin.jpg');
    figure(1); imshow(I) 
    figure(2); imhist(I);
    figure(3); imshow(255-I);
    figure(4); imhist(255-I);
    
    
    figure(1); imshow(I) 
    figure(2); imhist(I);
    figure(3); histeq(I);
    figure(4); imhist(histeq(I));

%     averaging applying gaussian filter is the same as considering a gray value as heatflow
end