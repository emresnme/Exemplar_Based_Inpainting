function varargout = main(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @main_OpeningFcn, ...
                   'gui_OutputFcn',  @main_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before main is made visible.
function main_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to main (see VARARGIN)

% Choose default command line output for main
handles.output = hObject;
set(handles.uibuttongroup_ciz, 'Visible', 'off');
addpath('C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\Tutarli_Tasima_Toolbox',...
    'C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\Real_Time_Cahn_Hilliard',...
    'C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\Cahn_Hilliard_Toolbox',...
    'C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\Ornek_Bazli_Toolbox');
% Update handles structure
guidata(hObject, handles);


% UIWAIT makes main wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = main_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton_sec.
function pushbutton_sec_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_sec (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[file, path] = uigetfile({'*.png';'*.jpg';'*.jpeg'}, 'Fotoðraf Seçici');
set(handles.text_durum,'String',sprintf('%s%s%s','"', file, '" secildi.'));

myImage = imread(fullfile(path,file));
axes(handles.axes1);
imshow(myImage);
imwrite(myImage,'selected_picture.png');
imwrite(imresize(imread('selected_picture.png'),[480 640]),'selected_picture_resized.png');
set(handles.uibuttongroup_ciz, 'Visible', 'on');
set(handles.pushbutton_inpaint, 'Visible', 'on');
set(handles.pushbutton_tutarli, 'Visible', 'on');
set(handles.pushbutton_cahn_hilliard_1, 'Visible', 'on');

set(handles.text_ssim_deger, 'Visible', 'off');
set(handles.text_psnr_deger, 'Visible', 'off');
set(handles.text_snr_deger, 'Visible', 'off');
set(handles.text_ssim, 'String', '');
set(handles.text_psnr, 'String', '');
set(handles.text_snr, 'String', '');

% --- Executes on button press in radiobutton_ciz.
function radiobutton_ciz_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_ciz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of radiobutton_ciz

redThresh = 0.25;

img = imread('selected_picture.png');
img=imresize(img,[480,640]);

vidDevice = imaq.VideoDevice('winvideo', 1, 'YUY2_640x480', ...
                    'ROI', [1 1 640 480], ...
                    'ReturnedColorSpace', 'rgb');  % Input Video from current adapter
vidInfo = imaqhwinfo(vidDevice);  % Acquire video information
hblob = vision.BlobAnalysis('AreaOutputPort', false, ... 
                                'CentroidOutputPort', true, ... 
                                'BoundingBoxOutputPort', true', ...
                                'MaximumBlobArea', 3000, ...
                                'MaximumCount', 1);  % Make system object for blob analysis
hshapeinsRedBox = vision.ShapeInserter('BorderColor', 'Custom', ...
                                    'CustomBorderColor', [1 0 0], ...
                                    'Fill', true, ...
                                    'FillColor', 'Custom', ...
                                    'CustomFillColor', [1 0 0], ...
                                    'Opacity', 0.4);  % Make system object for Red Filled Box
htextinsCent = vision.TextInserter('Text', '+      X:%5.2f, Y:%5.2f', ...
                                    'LocationSource', 'Input port', ...
                                    'Color', [1 1 0], ...
                                    'FontSize', 14);  % Make system object for Text: Centroid Infication
                           
hVideoIn = vision.VideoPlayer('Name', 'Final Video', ...
                                'Position', [60+vidInfo.MaxWidth 100 vidInfo.MaxWidth+20 vidInfo.MaxHeight+30]);
                            
                            centX = 1; centY = 1;  % Feature Centroid initialization                            
set(handles.text_durum,'String','Çizdiriliyor.');

maske_sayisi = 0;
while maske_sayisi<str2double(get(handles.edit_maske_sayisi,'String'));
    rgbFrame = step(vidDevice);  % Extract Single Frame
    diffFrame = imsubtract(rgbFrame(:,:,1), rgb2gray(rgbFrame));  % Extract Red component
    diffFrame = medfilt2(diffFrame, [3 3]);  % Applying Medial Filter for denoising
    binFrame = im2bw(diffFrame, redThresh);  % Convert to binary image using red threshold
    binFrame = bwareaopen(binFrame,800);  % Discard small areas
    [centroid, bbox] = step(hblob, binFrame);  % Get the reqired statistics of remaining blobs
    if ~isempty(bbox)  %  Get the centroid of remaining blobs
        centX = centroid(1); centY = centroid(2);
    end
    vidIn = step(hshapeinsRedBox, rgbFrame, bbox);  % Put a Red bounding box in input video stream    
    vidIn = step(htextinsCent, vidIn, [centX centY], [uint16(centX)-6 uint16(centY)-9]);  % Write centroid
    step(hVideoIn, vidIn);  % Show the output video stream
    
    if centY>10 && centX>10
        for x=round(centY-8):round(centY+8)
            for y=round(centX-8):round(centX+8)
                img(x,y,1) = 0;
                img(x,y,2) = 255;
                img(x,y,3) = 0;
            end
        end
    end
    imwrite(img,'selected_picture_mask.png');,
    imshow(img); hold on; box on;
    maske_sayisi = maske_sayisi + 1;
end
axes(handles.axes1);
imshow(img);
set(handles.text_durum,'String','Maske Çizdirildi.');




% --- Executes on mouse press over axes background.
function axes1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
SliderLocation = round(get(handles.slider_threshold,'Value'));
[xlist ylist]=ginput(5);
tableData = {xlist(1),ylist(1),SliderLocation};
set(handles.CoordinateTable,'Data',tableData)
% Update handles structure
guidata(hObject, handles)


% --- Executes on button press in pushbutton_inpaint.
function pushbutton_inpaint_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_inpaint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.text_ssim_deger, 'Visible', 'on');
set(handles.text_psnr_deger, 'Visible', 'on');
set(handles.text_snr_deger, 'Visible', 'on');
set(handles.text_durum,'String','Ýçboyama yapýlýyor.');
[i1,i2,i3,c,d]=inpaint7('selected_picture_resized.png','selected_picture_mask.png',[0 255 0]);

figure;
subplot(231);image(uint8(i2)); title('Original image');
subplot(232);image(uint8(i3)); title('Fill region');
subplot(233);image(uint8(i1)); title('Inpainted image');
subplot(234);imagesc(c); title('Confidence term');
subplot(235);imagesc(d); title('Data term');

imwrite(uint8(i1),'inpainted_image.png');
axes(handles.axes1);
imshow(imread('inpainted_image.png'));

[ssimval, ssimmap] = ssim(imread('inpainted_image.png'),imread('selected_picture_resized.png'));
set(handles.text_ssim,'String',ssimval);

[peaksnr, snr] = psnr(imread('inpainted_image.png'), imread('selected_picture_resized.png')); %calculate PSNR and SNR
set(handles.text_psnr,'String',peaksnr);
set(handles.text_snr,'String',snr);

set(handles.text_durum,'String','Örnek Bazlý Ýçboyama yapýldý.');
guidata(hObject,handles);



% --- Executes on button press in radiobutton_cizme.
function radiobutton_cizme_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_cizme (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_cizme
handles.DrawStart = 0;
guidata(hObject,handles);


% --- Executes on button press in radiobutton_mouse_ciz.
function radiobutton_mouse_ciz_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_mouse_ciz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_mouse_ciz
set(handles.text_durum,'String','Maske çiziliyor.');
fontSize = 16;
fullFileName = 'C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\selected_picture.png';

if ~exist(fullFileName, 'file')
	% File doesn't exist -- didn't find it there.  Check the search path for it.
	fullFileName = baseFileName; % No path this time.
	if ~exist(fullFileName, 'file')
		% Still didn't find it.  Alert user.
		errorMessage = sprintf('Hata: %s bulunamadý.', fullFileName);
		uiwait(warndlg(errorMessage));
		return;
	end
end

img = imread(fullFileName);
img = imresize(img,[480,640]);
imshow(img, []);
title('Orjinal Resim', 'FontSize', fontSize);
message = sprintf('Mouse ile sol týklayýn ve basýlý tutun.\nÇizimi bitirmek içinse sadece sol týký kaldýrýn.');
uiwait(msgbox(message));
% User draws curve on image here.
hFH = imfreehand();
% Get the xy coordinates of where they drew.
xy = hFH.getPosition
% get rid of imfreehand remnant.
delete(hFH);

kalinlik = str2double(get(handles.edit_maske_kalinligi, 'String'));

hold on; % Keep image, and direction of y axis.
xCoordinates = xy(:, 1);
yCoordinates = xy(:, 2);
plot(xCoordinates, yCoordinates, 'gs', 'LineWidth', kalinlik, 'MarkerSize', kalinlik);
caption = sprintf('Çizme hýzýnýza göre maskelenecek piksellerin yeri düzgün olmayabilir.\nYavaþ çiziniz.');
title(caption, 'FontSize', fontSize);
promptMessage = sprintf('Maskelemek istediðinizden emin misiniz?');
titleBarCaption = 'Devam?';
button = questdlg(promptMessage, titleBarCaption, 'Yes', 'No', 'Yes');
if strcmpi(button, 'Yes')
	cla;
	hold off;
    for k = 1 : length(xCoordinates)
		row = int32(yCoordinates(k));
		column = int32(xCoordinates(k));
		img(row-kalinlik:row+kalinlik, column-kalinlik:column+kalinlik,1) = 0;
        img(row-kalinlik:row+kalinlik, column-kalinlik:column+kalinlik,2) = 255;
        img(row-kalinlik:row+kalinlik, column-kalinlik:column+kalinlik,3) = 0;
    end
	imshow(img, []);
    imwrite(img,'selected_picture_mask.png');
    set(handles.text_durum,'String','Maske kaydedildi.');
	caption = sprintf('Çizme hýzýnýza göre maskelenecek piksellerin yeri düzgün olmayabilir.\nYavaþ çiziniz.');
	title(caption, 'FontSize', fontSize);
else
    set(handles.text_durum,'String','Maske henuz kaydedilmedi.');
end


% --- Executes on button press in pushbutton_cahn_hilliard_face.
function pushbutton_cahn_hilliard_face_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cahn_hilliard_face (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

faceDetector=vision.CascadeObjectDetector('FrontalFaceCART'); %Create a detector object
profileFaceDetector = vision.CascadeObjectDetector('ProfileFace');

% PARAMETERS
% maxiter       = 50;
% param.epsilon = [100 0.9];
% param.lambda  = 10;
% param.dt      = 1;
% frame_number = 5;


maxiter = str2double(get(handles.edit_iterasyon_sayisi, 'String'));
param.epsilon = [str2double(get(handles.edit_epsilon_1,'String')) str2double(get(handles.edit_epsilon_2,'String'))];
param.lambda = str2double(get(handles.edit_lambda,'String'));
param.dt = str2double(get(handles.edit_dt,'String'));
frame_number = str2double(get(handles.edit_frame_sayisi,'String'));

cam = webcam

logfilename = 'C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\Real_Time_Cahn_Hilliard\log_cahnhilliard.log';
if exist(logfilename,'file')
    delete(logfilename);
end
fileID = fopen(logfilename,'w');

tic
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

maskfilename  = 'C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting\Real_Time_Cahn_Hilliard\mask_cahn_hilliard_face_detection.png';
imwrite(mask,maskfilename);

inpainting_cahn_hilliard(img_re,maskfilename,maxiter,param,i,fileID);
end
 t2 = toc;
 fprintf(fileID,'\n %i resmin iþlem süresi toplam %0.4f saniye sürdü. \n', frame_number, t2);
 fclose(fileID);
 delete(maskfilename);
 
 message = sprintf('Toplanan verileri Real_Time_Cahn_Hilliard dosyasýnda inceleyebilirsiniz.');
uiwait(msgbox(message));
 



function edit_iterasyon_sayisi_Callback(hObject, eventdata, handles)
% hObject    handle to edit_iterasyon_sayisi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_iterasyon_sayisi as text
%        str2double(get(hObject,'String')) returns contents of edit_iterasyon_sayisi as a double


% --- Executes during object creation, after setting all properties.
function edit_iterasyon_sayisi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_iterasyon_sayisi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_epsilon_1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_epsilon_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_epsilon_1 as text
%        str2double(get(hObject,'String')) returns contents of edit_epsilon_1 as a double


% --- Executes during object creation, after setting all properties.
function edit_epsilon_1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_epsilon_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_epsilon_2_Callback(hObject, eventdata, handles)
% hObject    handle to edit_epsilon_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_epsilon_2 as text
%        str2double(get(hObject,'String')) returns contents of edit_epsilon_2 as a double


% --- Executes during object creation, after setting all properties.
function edit_epsilon_2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_epsilon_2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_lambda_Callback(hObject, eventdata, handles)
% hObject    handle to edit_lambda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_lambda as text
%        str2double(get(hObject,'String')) returns contents of edit_lambda as a double


% --- Executes during object creation, after setting all properties.
function edit_lambda_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_lambda (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_dt_Callback(hObject, eventdata, handles)
% hObject    handle to edit_dt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_dt as text
%        str2double(get(hObject,'String')) returns contents of edit_dt as a double


% --- Executes during object creation, after setting all properties.
function edit_dt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_dt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_frame_sayisi_Callback(hObject, eventdata, handles)
% hObject    handle to edit_frame_sayisi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_frame_sayisi as text
%        str2double(get(hObject,'String')) returns contents of edit_frame_sayisi as a double


% --- Executes during object creation, after setting all properties.
function edit_frame_sayisi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_frame_sayisi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_maske_sayisi_Callback(hObject, eventdata, handles)
% hObject    handle to edit_maske_sayisi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_maske_sayisi as text
%        str2double(get(hObject,'String')) returns contents of edit_maske_sayisi as a double


% --- Executes during object creation, after setting all properties.
function edit_maske_sayisi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_maske_sayisi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_tutarli.
function pushbutton_tutarli_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_tutarli (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

original_image = imread('selected_picture.png');
original_image=imresize(original_image,[480,640]);
selected_picture_mask = imread('selected_picture_mask.png');

mask = zeros(size(original_image,1),size(original_image,2),'uint8');
for x = 1 : size(original_image,1)
    for y = 1 : size(original_image, 2)
        if selected_picture_mask(x,y,1)==0 && selected_picture_mask(x,y,2)==255 && selected_picture_mask(x,y,3)==0
            mask(x,y) = 1;
        else
            mask(x,y) = 0;
        end
    end
end

for radius=1:5
    for i=1:3
        image(:,:,i) = original_image(:,:,i) .* (1-mask);
    end
    image = inpaint(image, mask, radius);
    snr(radius) = psnr(image, original_image);
end

for i=1:3
    image(:,:,i) = original_image(:,:,i) .* (1-mask);
end
best_radius = find(snr==max(snr),1) -1;
image = inpaint(image, mask, best_radius);

imwrite(image,'inpainted_image.png');
imshow(image);
set(handles.text_ssim_deger, 'Visible', 'on');
set(handles.text_psnr_deger, 'Visible', 'on');
set(handles.text_snr_deger, 'Visible', 'on');
[ssimval, ssimmap] = ssim(imread('inpainted_image.png'),imread('selected_picture_resized.png'));
set(handles.text_ssim,'String',ssimval);

[peaksnr, nsnr] = psnr(imread('inpainted_image.png'), imread('selected_picture_resized.png'));
set(handles.text_psnr,'String',peaksnr);
set(handles.text_snr,'String',nsnr);

figure;
plot(snr);
xlabel 'Neighborhood size'
ylabel 'Peak Signal-Noise Ratio'

set(handles.text_durum,'String','Tutarlý Taþýma Bazlý Ýçboyama yapýldý.');


% --- Executes on button press in pushbutton_cahn_hilliard_1.
function pushbutton_cahn_hilliard_1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cahn_hilliard_1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
original_image = imread('selected_picture_resized.png');
selected_picture_mask = imread('selected_picture_mask.png');

mask = zeros(size(original_image,1),size(original_image,2),'uint8');

for x = 1 : size(original_image,1)
    for y = 1 : size(original_image, 2)
        if selected_picture_mask(x,y,1)==0 && selected_picture_mask(x,y,2)==255 && selected_picture_mask(x,y,3)==0
            mask(x,y) = 255;
        else
            mask(x,y) = 0;
        end
    end
end
imwrite(mask,'cahn_hilliard_mask.png');

% PARAMETERS
maxiter = str2double(get(handles.edit_iterasyon_sayisi, 'String'));
param.epsilon = [str2double(get(handles.edit_epsilon_1,'String')) str2double(get(handles.edit_epsilon_2,'String'))];
param.lambda = str2double(get(handles.edit_lambda,'String'));
param.dt = str2double(get(handles.edit_dt,'String'));

inpainting_cahn_hilliard_1('selected_picture_resized.png','cahn_hilliard_mask.png',maxiter,param)

set(handles.text_durum,'String','Cahn-Hilliard Bazlý Ýçboyama yapýldý.');
set(handles.text_ssim_deger, 'Visible', 'on');
set(handles.text_psnr_deger, 'Visible', 'on');
set(handles.text_snr_deger, 'Visible', 'on');
[ssimval, ssimmap] = ssim(imread('inpainted_image.png'),imread('selected_picture_resized.png'));
set(handles.text_ssim,'String',ssimval);

[peaksnr, snr] = psnr(imread('inpainted_image.png'), imread('selected_picture_resized.png'));
set(handles.text_psnr,'String',peaksnr);
set(handles.text_snr,'String',snr);

delete('cahn_hilliard_mask.png');


function edit_maske_kalinligi_Callback(hObject, eventdata, handles)
% hObject    handle to edit_maske_kalinligi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_maske_kalinligi as text
%        str2double(get(hObject,'String')) returns contents of edit_maske_kalinligi as a double


% --- Executes during object creation, after setting all properties.
function edit_maske_kalinligi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_maske_kalinligi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_sansli.
function pushbutton_sansli_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_sansli (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
imshow('selected_picture_resized.png');
format long g;
format compact;
fontSize = 20;
folder = 'C:\Users\vega_\Documents\GitHub\Exemplar_Based_Inpainting';
baseFileName = 'selected_picture_resized.png';

fullFileName = fullfile(folder, baseFileName);
if ~exist(fullFileName, 'file')
	fullFileName = baseFileName; 
	if ~exist(fullFileName, 'file')
		errorMessage = sprintf('Error: %s does not exist.', fullFileName);
		uiwait(warndlg(errorMessage));
		return;
	end
end

grayImage=imread(fullFileName);
mask = grayImage;
[rows, columns, numberOfColorBands] = size(grayImage);
if numberOfColorBands > 1
	grayImage = grayImage(:, :, 2);
end

binaryImage = grayImage < str2double(get(handles.text_threshold_deger,'String'));
labeledImage = bwlabel(1-binaryImage);
measurements = regionprops(labeledImage, 'BoundingBox', 'Area');

for k = 1 : length(measurements)
  thisBB = measurements(k).BoundingBox;
  rectangle('Position', [thisBB(1),thisBB(2),thisBB(3),thisBB(4)],...
  'EdgeColor','r','LineWidth',2 )
end

allAreas = [measurements.Area];
[sortedAreas, sortingIndexes] = sort(allAreas, 'descend');
handIndex = sortingIndexes(1);
theObject = ismember(labeledImage, handIndex) 
theObject = theObject > 0;

for x=1:size(grayImage,1)
    for y=1:size(grayImage,2)
        if theObject(x,y) == 1
            mask(x,y,1)=0;
            mask(x,y,2)=255;
            mask(x,y,3)=0;
        end
    end
end
imwrite(mask,'selected_picture_mask.png');
imshow(mask);
set(handles.text_durum,'String','Olasý maske kaydedildi.');


% --- Executes on slider movement.
function slider_threshold_Callback(hObject, eventdata, handles)
% hObject    handle to slider_threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
slider_degeri = get(hObject,'Value');
set(handles.text_threshold_deger,'String',num2str(slider_degeri));


% --- Executes during object creation, after setting all properties.
function slider_threshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton_yuz_bul.
function pushbutton_yuz_bul_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_yuz_bul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
faceDetector=vision.CascadeObjectDetector('FrontalFaceCART'); %Create a detector object
se = strel('disk',10);

img=imread('selected_picture_resized.png'); %Read input image
mask = img;
img=rgb2gray(img); % convert to gray
BB=step(faceDetector,img); % Detect faces

if size(BB,1) == 0
		errorMessage = 'Fotoðrafta yüz bulunamadý.';
		uiwait(warndlg(errorMessage));
		return;
end

a = round(BB(2)-(BB(4)/4));
b = round(BB(1)-(BB(3)/4));
c = round(BB(2)+(BB(4)/4)+BB(4));
d = round(BB(1)+(BB(3)/4)+BB(3));

face_edge = edge(img(a:c,b:d),'canny',...
    str2double(get(handles.text_thr_edge_deger,'String')));
face_edge = bwmorph(bwmorph(imfill(imclose(bwmorph(face_edge,'thicken',10),se),'holes'),'shrink',5),'spur');

labeledImage = bwlabel(face_edge);
measurements = regionprops(labeledImage, 'BoundingBox', 'Area');

allAreas = [measurements.Area];
[sortedAreas, sortingIndexes] = sort(allAreas, 'descend');
handIndex = sortingIndexes(1);
theObject = ismember(labeledImage, handIndex) 
theObject = theObject > 0;

for x = 0 : size(theObject,1)-1
    for y = 0 : size(theObject,2)-1
        if theObject(x+1,y+1) == 1
            mask(a+x,b+y,1)=0;
            mask(a+x,b+y,2)=255;
            mask(a+x,b+y,3)=0;
        end
    end
end

imwrite(mask,'selected_picture_mask.png');
imshow(mask);
set(handles.text_durum,'String','Yüz maske olarak kaydedildi.');

% --- Executes on slider movement.
function slider_threshold_edge_Callback(hObject, eventdata, handles)
% hObject    handle to slider_threshold_edge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
slider_degeri = get(hObject,'Value');
set(handles.text_thr_edge_deger,'String',num2str(slider_degeri));


% --- Executes during object creation, after setting all properties.
function slider_threshold_edge_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_threshold_edge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton_insan_bul.
function pushbutton_insan_bul_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_insan_bul (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
peopleDetector = vision.PeopleDetector;
se = strel('disk',10);

img=imread('selected_picture_resized.png'); %Read input image
mask = img;
img=rgb2gray(img); % convert to gray
BB=step(peopleDetector,img); % Detect faces

if size(BB,1) == 0
		errorMessage = 'Fotoðrafta insan bulunamadý.';
		uiwait(warndlg(errorMessage));
		return;
end

a = round(BB(2));
b = round(BB(1));
c = round(BB(2)+BB(4));
d = round(BB(1)+BB(3));

body_edge = edge(img( a : c, b : d ),'canny',...
    str2double(get(handles.text_thr_edge_deger,'String')));
body_edge = bwmorph(bwmorph(imfill(imclose(bwmorph(body_edge,'thicken',10),se),'holes'),'shrink',5),'spur');


labeledImage = bwlabel(body_edge);
measurements = regionprops(labeledImage, 'BoundingBox', 'Area');

allAreas = [measurements.Area];
[sortedAreas, sortingIndexes] = sort(allAreas, 'descend');
handIndex = sortingIndexes(1);
theObject = ismember(labeledImage, handIndex) 
theObject = theObject > 0;

for x = 0 : size(theObject,1)-1
    for y = 0 : size(theObject,2)-1
        if theObject(x+1,y+1) == 1
            mask(a+x,b+y,1)=0;
            mask(a+x,b+y,2)=255;
            mask(a+x,b+y,3)=0;
        end
    end
end

imwrite(mask,'selected_picture_mask.png');
imshow(mask);
set(handles.text_durum,'String','Ýnsan maske olarak kaydedildi.');
