%% MATLAB Codes for the Image Inpainting Problem
%  Copyright (c) 2016, Simone Parisotto and Carola-Bibiane Schoenlieb
%  All rights reserved.
% 
%  Redistribution and use in source and binary forms, with or without 
%  modification, are permitted provided that the following conditions are met:
% 
%  1. Redistributions of source code must retain the above copyright notice,
%     this list of conditions and the following disclaimer.
% 
%  2. Redistributions in binary form must reproduce the above copyright 
%     notice, this list of conditions and the following disclaimer in the 
%     documentation and/or other materials provided with the distribution.
% 
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
%  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
%  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
%  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
%  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
%  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
%  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
%  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
%  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
%  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
%  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%  Authors:
%  Simone Parisotto (email: sp751 at cam dot ac dot uk)
%  Carola-Bibiane Schoenlieb (email: cbs31 at cam dot ac dot uk)
%      
%  Address:
%  Cambridge Image Analysis
%  Centre for Mathematical Sciences
%  Wilberforce Road
%  Cambridge CB3 0WA
%  United Kingdom
%  
%  Date:
%  September, 2016
%%

% function inpainting_cahn_hilliard(imagefilename,maskfilename,maxiter,param)
function inpainting_cahn_hilliard(img,maskfilename,maxiter,param,iteration_num,fileID)

% Cahn-Hilliard inpainting based on the paper
%
% Bertozzi, Andrea L., Selim Esedoglu, and Alan Gillette.
% "Inpainting of binary images using the Cahn-Hilliard equation."
% IEEE Transactions on image processing 16.1 (2007): 285-291.
%
% The modified Cahn-Hilliard equation was discretized based on
% convexity splitting proposed in the same paper and analysed in
%
% C.-B. Sch�nlieb, A. Bertozzi, Unconditionally stable schemes for
% higher order inpainting, Communications in Mathematical Sciences,
% Volume 9, Issue 2, pp. 413-457 (2011).
%
% Namely
%
% E_1  = \int_{\Omega} \ep/2 |\nabla u|^2 + 1/\ep W(u) dx , W(u) = u^2 (1-u)^2
% E_11 = \int_{\Omega} \ep/2 |\nabla u|^2 + C_1/2 |u|^2 dx, E_12 =
% \int_{\Omega} - 1/\ep W(u) + C_1/2 |u|^2 dx
%
% E_2 = \lambda \int_{\Omega\D} (f-u)^2 dx,
% E_21 = \int_{\Omega\D} C_2/2 |u|^2 dx, E_22 = \int_{\Omega\D} -\lambda (f-u)^2 + C_2/2|u|^2 dx

%% ------------------------------------ IMPORT THE CLEAN INPUT AND THE MASK
% iminfo = imfinfo(imagefilename);
% input  = im2double(imread(imagefilename));
iminfo.Height = size(img,1);
iminfo.Width = size(img,2);
input = im2double(img);
% check if grayscale/truecolor dimension of image grey/colour
colors = size(input,3);

mask = im2double(imread(maskfilename));
mask = double(mat2gray(mask)==0); % indicator function of the intact image
if size(mask,3)==1 && colors>1
    mask = repmat(mask,[1,1,colors]);
end

mask         = double(mask);
u0           = double(input);
noise        = mat2gray(randn(size(u0)));
u0(~mask)    = noise(~mask);
imwrite(u0,sprintf('%s%i%s',...
 'C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\Real_Time_Cahn_Hilliard\masked_',iteration_num,'.png'));
%% PARAMETERS
h1           = 1;
h2           = 1;
swap         = round(maxiter/2);
ep           = [param.epsilon(1)*ones(numel(1:swap-1),1); param.epsilon(2)*ones(numel(swap:maxiter),1)];
c1           = 1/param.epsilon(2);
lambda       = param.lambda*double(mask);
dt           = param.dt;

% Diagonalize the Laplace Operator by: Lu + uL => D QuQ + QuQ D, where 
% Q is nonsingular, the matrix of eigenvectors of L and D is a diagonal matrix.
% We have to compute QuQ. This we can do in a fast way by using the fft-transform:

Lambda1 = spdiags(2*(cos(2*(0:iminfo.Height-1)'*pi/iminfo.Width)-1),0,iminfo.Height,iminfo.Height)/h1^2;
Lambda2 = spdiags(2*(cos(2*(0:iminfo.Width-1)'*pi/iminfo.Width)-1),0,iminfo.Width,iminfo.Width)/h2^2;

Denominator = Lambda1*ones(iminfo.Height,iminfo.Width) + ones(iminfo.Height,iminfo.Width)*Lambda2;

% Now we can write the above equation in much simpler way and compute the
% solution u_hat

u_end = ones(size(u0));

 writerObj = VideoWriter(sprintf('%s%i%s',...
 'C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\Real_Time_Cahn_Hilliard\theProcess', iteration_num , '.avi'));

 writerObj.FrameRate = 1;
  images = cell(maxiter,1);

for k=1:3
    
    % Initialization of u and its Fourier transform:
    u          = u0(:,:,k);
    u_hat      = fft2(u);
    lu0_hat    = fft2(lambda(:,:,k).*u);
    
    for it = 1:maxiter
        
        lu_hat     = fft2(lambda(:,:,k).*u);
        Fprime_hat = fft2(2*(2*u.^3-3*u.^2+u));
        
        % CH-inpainting
        u_hat = ((1+lambda(:,:,k)*dt-dt*Denominator/param.epsilon(2)).*u_hat...
            + dt/ep(it)*Denominator.*Fprime_hat...
            + dt*(lu0_hat-lu_hat))./(1+lambda(:,:,k)*dt+ep(it)*dt*Denominator.^2-dt*Denominator/param.epsilon(2));
        
        u = real(ifft2(u_hat));
        images{it}(:,:,k) = u;

    end 
    u_end(:,:,k) = u;
    clear u;
end

open(writerObj);
    for t=1:length(images)
        writeVideo(writerObj, mat2gray(images{t}));
    end
close(writerObj);

% [thr,sorh,keepapp] = ddencmp('den','wv',u_end);
% denoised_u_end = wdencmp('gbl',u_end,'sym4',2,thr,sorh,keepapp);  ----  DENOISING
% imshow(denoised_u_end);

[peaksnr, snr] = psnr(u_end, input); %calculate PSNR and SNR
fprintf(fileID,'\nThe Peak-SNR value of %i is %0.4f', iteration_num, peaksnr);
fprintf(fileID,'\nThe SNR value of %i is %0.4f \n',iteration_num, snr);

[ssimval, ssimmap] = ssim(u_end,input);
fprintf(fileID,'The SSIM value of %i is %0.4f \n',iteration_num, ssimval);

%% ---------------------------------------------------- WRITE IMAGE OUTPUTS
% imwrite(u0,'masked_cahn_hilliard.png')
% imwrite(u_end,'output_cahn_hilliard.png')
imwrite(u_end,sprintf('%s%i%s','C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\Real_Time_Cahn_Hilliard\out_',iteration_num,'.png'));
