%--------------Brief description-------------------------------------------
% This demo contains the implementation of the algorithm for video rain streaks removal
% An early version document of the this menthod is:
% Tai-Xiang Jiang, Ting-Zhu Huang, Xi-Le Zhao, Liang-Jian Deng, Yao Wang;
% ''A Novel Tensor-Based Video Rain Streaks Removal Approach via Utilizing
% Discriminatively Intrinsic Priors'' The IEEE Conference on Computer Vision
% and Pattern Recognition (CVPR), 2017, pp. 4057-4066
% 
% Contact: taixiangjiang@gmail.com
% Date: 03/03/2018

clear all;close all;clc;
path(path,genpath(pwd));
%%--- Load Video ---%%%
load oblique_rain_streaks_highway2.mat   % Rainy video  ( "highway2" with the synthetic oblique rain streaks in case 2), parameter opts, and Clean video
implay(Rainy)
[O_Rainy,~]=rgb2gray_hsv(Rainy);   %rgb2hsv
[O_clean,O_hsv]=rgb2gray_hsv(B_clean);
Rain = O_Rainy-O_clean;
padsize = 5;

%% quanlity assements of the rainy video
fprintf('Calculating the indices of the rainy data...\n');
fprintf('Index                         | PSNR    | MSSIM   | MFSIM   | MVIF   |  MUIQI | MGMSD\n');
PSNR0 = psnr(Rainy(:),B_clean(:),max(B_clean(:)));
MPSNR0 = MPSNR(Rainy,B_clean);
MSSIM0 = MSSIM(Rainy,B_clean);
MFSIM0 = MFSIM(Rainy*255,B_clean*255);
MUQI0 = MUQI(Rainy*255,B_clean*255);
MVIF0 = MEANVIF(Rainy*255,B_clean*255);
MGMSD0 = MGMSD(Rainy,B_clean);
fprintf('Rainy                          | %.4f   |  %.4f | %.4f | %.4f | %.4f | %.4f \n',PSNR0,MSSIM0 ,MFSIM0,MVIF0,MUQI0,MGMSD0);
%% FastDeRain with shift strategy

%%%  shift operation
[l1,l2,l3] = size(O_Rainy);
O_Rainy1 = biger(O_Rainy,padsize);
Shiftdata = gpuArray.ones(l1+10,(l1+l2+20-1),l3+10);
for i = 1:(l1+10)
    Shiftdata(i,i:(i+l2+10-1),:) = O_Rainy1(i,:,:);
end
%%% FastDeRain
tStart =  tic;
[B_S,R_S,iter] = FastDeRain_GPU(Shiftdata,optsS);
timeS = toc(tStart);
%%% shift back
for j = 1:(l1+10)
    B_Sb(j,:,:) = B_S(j,j:(j+l2+10-1),:);
end
B_1 = smaller(B_Sb,padsize);
B_1c = gray2color_hsv(O_hsv,gather(B_1));
implay(B_1c);
fprintf('Calculating the indices of the results form FastDeRain (SHIFT)...\n');
fprintf('Index                               | PSNR    | MSSIM   | MFSIM   | MVIF     |  MUIQI | MGMSD\n');
    PSNR1 = psnr(B_1c(:),B_clean(:),max(B_clean(:)));
    MPSNR1 = MPSNR(B_1c,B_clean);
    MSSIM1 = MSSIM(B_1c,B_clean);
    MFSIM1 = MFSIM(B_1c*255,B_clean*255);
    MVIF1 = MEANVIF(B_1c*255,B_clean*255);
    MUQI1 = MUQI(B_1c*255,B_clean*255);
    MGMSD1 = MGMSD(B_1c,B_clean);
fprintf('FastDeRain (SHIFT)          | %.4f   |  %.4f | %.4f | %.4f | %.4f | %.4f \n',PSNR1,MSSIM1 ,MFSIM1,MVIF1,MUQI1,MGMSD1);
fprintf('FastDeRain (SHIFT)  running time (GPU) :    %.4f  s\n', timeS);

%% FastDeRain with rotation strategy
%%% rotate operation
small_Size=size(O_Rainy);
height=floor(small_Size(1)/2);
width=floor(small_Size(2)/2);
RainyR = gather(biger(O_Rainy,padsize));
CleanR = gather(biger(O_clean,padsize));
degree = 45;
for i=1:size(RainyR,3)
    Rainy_rotated(:,:,i)=imrotate(RainyR(:,:,i),degree,'bicubic');
end
Rainy_rotated = gpuArray(Rainy_rotated);
%%% FastDeRain
tStart =  tic;
[B_R,~,iter] = FastDeRain_GPU(Rainy_rotated,optsR);   %%% rain_removal3_GPU noisy case
timeR = toc(tStart);
%%% rotate back
degree = -45;
for i=1:size(RainyR,3)
    B_Rb (:,:,i)=imrotate(gather(B_R(:,:,i)),degree,'bicubic');
end

mid1=floor(size(B_Rb,1)/2);
mid2=floor(size(B_Rb,2)/2);
B_2 =B_Rb(mid1-height+1:mid1+height  ,  mid2-width+1:mid2+width  , 6 :105);  
B_2c = gray2color_hsv(O_hsv,gather(B_2));
implay(B_2c);
fprintf('Calculating the indices of the results form FastDeRain (ROTATION)...\n');
fprintf('Index                              | PSNR    | MSSIM   | MFSIM   | MVIF   |  MUIQI  | MGMSD\n');

PSNR2 = psnr(B_2c(:),B_clean(:),max(B_clean(:)));
MPSNR2 = MPSNR(B_2c,B_clean);
MSSIM2 = MSSIM(B_2c,B_clean);
MFSIM2 = MFSIM(B_2c*255,B_clean*255);
MVIF2 = MEANVIF(B_2c*255,B_clean*255);
MUQI2 = MUQI(B_2c*255,B_clean*255);
MGMSD2 = MGMSD(B_2c,B_clean);

fprintf('FastDeRain  (ROTATION)  | %.4f   |  %.4f | %.4f | %.4f | %.4f | %.4f \n',PSNR2,MSSIM2 ,MFSIM2,MVIF2,MUQI2,MGMSD2);
fprintf('FastDeRain  (ROTATION)  running time (GPU) :    %.4f  s\n', timeR);



