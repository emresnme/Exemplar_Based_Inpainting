
clc; close all; clear all;

%% 

% flower = imread('top.png');
% flower_gray = rgb2gray(flower);

% faceDetector=vision.CascadeObjectDetector('FrontalFaceCART');
% BB=step(faceDetector,lenna_gray);
% face = lenna_gray(BB(1):BB(1)+BB(3),BB(2):BB(2)+BB(4));

% edge_prewitt = edge(flower_gray, 'Prewitt',0.1);
% edge_roberts = edge(flower_gray, 'Roberts',0.1);
% edge_sobel = edge(flower_gray, 'Sobel',0.1);
% 
% figure; subplot(3,1,1);
% imshow(imfill(edge_prewitt, 'holes'));
% subplot(3,1,2);
% imshow(imfill(edge_roberts, 'holes'));
% subplot(3,1,3);
% imshow(imfill(edge_sobel, 'holes'));
% 
% edge_sobel = imfill(edge_sobel, 'holes');
% 
% for x=1:size(edge_sobel,1)
%     for y=1:size(edge_sobel,2)
%         if(edge_sobel(x,y)==1)
%             flower(x,y,1)=0;
%             flower(x,y,2)=255;
%             flower(x,y,3)=0;
%         end
%     end
% end
% imwrite(flower, 'flower_mask.png');
%%

[i1,i2,i3,c,d]=inpaint7('flower2.png','flower_mask.png',[0 255 0]);

figure;
subplot(231);image(uint8(i2)); title('Original image');
subplot(232);image(uint8(i3)); title('Fill region');
subplot(233);image(uint8(i1)); title('Inpainted image');
subplot(234);imagesc(c); title('Confidence term');
subplot(235);imagesc(d); title('Data term');

figure;
subplot(121);imagesc(c); title('Confidence term');
subplot(122);imagesc(d); title('Data term');

imwrite(uint8(i1),'inpainted_image.png');
