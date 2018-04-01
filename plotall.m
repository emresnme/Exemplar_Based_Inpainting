clc; close all; clear all;

%% 

% img = imread('emre.png');
% img_gray = rgb2gray(img);

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



% for x=1:edge_sobel(img,1)
%     for y=1:edge_sobel(img,2)
%         if(edge_sobel(x,y)==1)
%             mask(x,y,1)=0;
%             mask(x,y,2)=255;
%             mask(x,y,3)=0;
%         end
%     end
% end
% imwrite(img, 'img_mask.png');
%%

[i1,i2,i3,c,d]=inpaint7('manzara.png','manzara_mask.png',[0 255 0]);

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
