clear all
close all
clc
%% Originally Created and Developed By Vedant Koranne
%% Read Image
tic
Image = imread(Image_Path);
Background = imread(Background_Path);

%% RGB to YCbCr
Image_ycbcr = rgb2ycbcr(Image);
Background_ycbcr = rgb2ycbcr(Background);

%% Local Laplacian Filtered
Image_lap = locallapfilt(imgaussfilt(im2gray(Image_ycbcr),0.6), 0.7,0.1);
Background_lap = locallapfilt(imgaussfilt(im2gray(Background_ycbcr),0.6), 0.7,0.1);
%% Y-Channel Contrast Modification, Noise Reduction, Binarization and Morph Operations
I3 = double(imadjust(Image_ycbcr(:,:,1),[0.3 0.8]))./255;
I3_binarized = imbinarize(I3);
I3_binarized = imfill(I3_binarized, 'holes');
SE3 = strel("disk",2);
J3t = imopen(I3_binarized,SE3);
BW3 = bwareafilt(J3t,1);
SE3 = strel("disk",8);
J3 = imclose(BW3,SE3);
%% Org Difference Image Computation, Noise Reduction, Binarization and Morph Operations
org_diff = (rgb2gray(Image - Background));
org_diff_med = medfilt2(org_diff,[15 15]);
for i =1:size(org_diff_med,1)
    for j=1:size(org_diff_med,2)
        if(org_diff_med(i,j)<30)
            org_diff_med(i,j) = 0;
        end
    end
end
org_diff_bin = imbinarize(org_diff_med);
SE2_org = strel("disk",50);
J_org = imclose(org_diff_bin,SE2_org);

%% Laplacian Filtered Difference Image Computation, Noise Reduction, Binarization and Morph Operations
diff = imabsdiff(Image_lap,Background_lap);

diff_med = medfilt2(diff,[15 15]);
for i =1:size(diff_med,1)
    for j=1:size(diff_med,2)
        if(diff_med(i,j)<30)
            diff_med(i,j) = 0;
        end
    end
end
diff_med = 2.*diff_med;
Diffavg = mean2(diff_med);
Diffstd = std2(diff_med);
Diffmask = diff_med > Diffavg + Diffstd;
Diffmask = imfill(Diffmask, 'holes');
Diffmask = bwareafilt(Diffmask,50);
SE2 = strel("disk",16);
BW2 = imclose(Diffmask,SE2);
BW5 = bwmorph(BW2,'fill');
SE5 = strel("disk",8);
J4 = imopen(BW5,SE5);
%% Logical ANDing and extracting largest area binary image
J5 = J3 & (J4 | J_org);
J6 = bwareafilt(J5,1);
FinalMask = imfill(J6,'holes');
toc
