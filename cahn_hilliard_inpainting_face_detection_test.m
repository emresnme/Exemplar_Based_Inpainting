clc ; close all ; clear all;

faceDetector=vision.CascadeObjectDetector('FrontalFaceCART'); %Create a detector object
profileFaceDetector = vision.CascadeObjectDetector('ProfileFace');

% PARAMETERS
maxiter       = 50;
param.epsilon = [100 0.9];
param.lambda  = 10;
param.dt      = 1;
frame_number = 5;

cam = webcam
tic

logfilename = 'C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\Real_Time_Cahn_Hilliard\log_cahnhilliard.log';
if exist(logfilename,'file')
    delete(logfilename);
end
fileID = fopen(logfilename,'w');

for i = 1:frame_number
img=snapshot(cam);
img_re = imresize(img,0.25);

img=rgb2gray(img_re); % convert to gray
BB=step(faceDetector,img); % Detect faces
pBB=step(profileFaceDetector,img);

[img_row,img_column] = size(img); %create the mask
[BB_row,BB_column] = size(BB); 
[pBB_row,pBB_column] = size(pBB); 
mask=zeros(img_row,img_column);

for face_number = 1:BB_row
    for a = BB(face_number,2):6:BB(face_number,2)+BB(face_number,4)
        for b = BB(face_number,1):6:BB(face_number,1)+BB(face_number,3)
            mask(a:a+4,b:b+4,1) = 1;
            mask(a:a+4,b:b+4,2) = 1;
            mask(a:a+4,b:b+4,3) = 1;
        end
    end
end

for face_number = 1:pBB_row
    for a = pBB(face_number,2):6:pBB(face_number,2)+pBB(face_number,4)
        for b = pBB(face_number,1):6:pBB(face_number,1)+pBB(face_number,3)
            mask(a:a+4,b:b+4,1) = 1;
            mask(a:a+4,b:b+4,2) = 1;
            mask(a:a+4,b:b+4,3) = 1;
        end
    end
end

imwrite(mask,'C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\Real_Time_Cahn_Hilliard\mask_cahn_hilliard_face_detection.png');
maskfilename  = 'C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\Real_Time_Cahn_Hilliard\mask_cahn_hilliard_face_detection.png';

inpainting_cahn_hilliard(img_re,maskfilename,maxiter,param,i,fileID);
end
 t2 = toc;
 fprintf(fileID,'\n %i resmin iþlem süresi toplam %0.4f saniye sürdü. \n', frame_number, t2);
 fclose(fileID);