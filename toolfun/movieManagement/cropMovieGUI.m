function varargout = cropMovieGUI(varargin)
% cropMovieGUI M-file for cropMovieGUI.fig
%      cropMovieGUI, by itself, creates a new cropMovieGUI or raises the existing
%      singleton*.
%
%      H = cropMovieGUI returns the handle to a new cropMovieGUI or the handle to
%      the existing singleton*.
%
%      cropMovieGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in cropMovieGUI.M with the given input arguments.
%
%      cropMovieGUI('Property','Value',...) creates a new cropMovieGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cropMovieGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cropMovieGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cropMovieGUI

% Last Modified by GUIDE v2.5 22-Sep-2011 15:49:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cropMovieGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @cropMovieGUI_OutputFcn, ...
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


% --- Executes just before cropMovieGUI is made visible.
function cropMovieGUI_OpeningFcn(hObject,eventdata,handles,varargin)

% Check input
% The mainFig and procID should always be present
% procCOnstr and procName should only be present if the concrete process
% initation is delegated from an abstract class. Else the constructor will
% be directly read from the package constructor list.
ip = inputParser;
ip.addRequired('hObject',@ishandle);
ip.addRequired('eventdata',@(x) isstruct(x) || isempty(x));
ip.addRequired('handles',@isstruct);
ip.addOptional('MD',[],@(x)isa(x,'MovieData'));
ip.addParamValue('mainFig',-1,@ishandle);
ip.parse(hObject,eventdata,handles,varargin{:});
userData.MD =ip.Results.MD;
userData.mainFig =ip.Results.mainFig;
        
% Set up copyright statement
set(handles.text_copyright, 'String',userfcn_softwareConfig(handles));

% Set up available input channels
set(handles.listbox_selectedChannels,'String',userData.MD.getChannelPaths(), ...
    'UserData',1:numel(userData.MD.channels_));

% Save the image directories and names (for cropping preview)

userData.imageFileNames = userData.MD.getImageFileNames();
userData.imDirs  = userData.MD.getChannelPaths();
userData.nFrames = userData.MD.nFrames_;
userData.imRectHandle.isvalid=0;
userData.cropROI = [1 1 userData.MD.imSize_(end:-1:1)];
userData.previewFig=-1;

% Read the first image and update the sliders max value and steps
props = get(handles.listbox_selectedChannels, {'String','Value'});
userData.chanIndx = find(strcmp(props{1}{props{2}},userData.imDirs));
set(handles.edit_frameNumber,'String',1);
set(handles.slider_frameNumber,'Min',1,'Value',1,'Max',userData.nFrames,...
    'SliderStep',[1/double(userData.nFrames-1)  10/double(userData.nFrames-1)]);
userData.imIndx=1;
userData.imData=mat2gray(imread([userData.imDirs{userData.chanIndx} filesep...
        userData.imageFileNames{userData.chanIndx}{userData.imIndx}]));
    
set(handles.listbox_selectedChannels,'Callback',@(h,event) update_data(h,event,guidata(h)));
    
% Choose default command line output for cropMovieGUI
handles.output = hObject;

% Update user data and GUI data
set(hObject, 'UserData', userData);
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = cropMovieGUI_OutputFcn(~, ~, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(~, ~, handles)
% Delete figure
delete(handles.figure1);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, ~, handles)
% Notify the package GUI that the setting panel is closed
userData = get(handles.figure1, 'UserData');

if isfield(userData, 'helpFig') && ishandle(userData.helpFig)
   delete(userData.helpFig) 
end

if ishandle(userData.previewFig), delete(userData.previewFig); end

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);


% --- Executes on key press with focus on pushbutton_crop and none of its controls.
function pushbutton_crop_KeyPressFcn(~, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_crop, [], handles);
end

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(~, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_crop, [], handles);
end

 % --- Executes on button press in checkbox_crop.
function update_data(hObject, eventdata, handles)
userData = get(handles.figure1, 'UserData');

% Retrieve the channel index
props=get(handles.listbox_selectedChannels,{'String','Value'});
chanIndx = find(strcmp(props{1}{props{2}},userData.imDirs));
imIndx = get(handles.slider_frameNumber,'Value');

% Load a new image if either the image number or the channel has been changed
if (chanIndx~=userData.chanIndx) ||  (imIndx~=userData.imIndx)
    % Update image flag and dat
    userData.imData=mat2gray(imread([userData.imDirs{chanIndx} filesep...
        userData.imageFileNames{chanIndx}{imIndx}]));
    userData.updateImage=1;
    userData.chanIndx=chanIndx;
    userData.imIndx=imIndx;
        
    % Update roi
    if userData.imRectHandle.isvalid
        userData.cropROI=getPosition(userData.imRectHandle);
    end    
else
    userData.updateImage=0;
end

% In case of crop previewing mode
if get(handles.checkbox_crop,'Value')
    % Create figure if non-existing or closed
    if ~isfield(userData, 'previewFig') || ~ishandle(userData.previewFig)
        userData.previewFig = figure('Name','Select the region to crop',...
            'DeleteFcn',@close_previewFig,'UserData',handles.figure1);
        userData.newFigure = 1;
    else
        figure(userData.previewFig);
        userData.newFigure = 0;
    end
    
    % Retrieve the image object handle
    imHandle =findobj(userData.previewFig,'Type','image');
    if userData.newFigure || userData.updateImage
        if isempty(imHandle)
            imHandle=imshow(userData.imData);
            axis off;
        else
            set(imHandle,'CData',userData.imData);
        end
    end
        
    if userData.imRectHandle.isvalid
        % Update the imrect position
        setPosition(userData.imRectHandle,userData.cropROI)
    else 
        % Create a new imrect object and store the handle
        userData.imRectHandle = imrect(get(imHandle,'Parent'),userData.cropROI);
        fcn = makeConstrainToRectFcn('imrect',get(imHandle,'XData'),get(imHandle,'YData'));
        setPositionConstraintFcn(userData.imRectHandle,fcn);
    end
else
    % Save the roi if applicable
    if userData.imRectHandle.isvalid, 
        userData.cropROI=getPosition(userData.imRectHandle); 
    end
    % Close the figure if applicable
    if ishandle(userData.previewFig), delete(userData.previewFig); end
end
set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);

function close_previewFig(hObject, eventdata)
handles = guidata(get(hObject,'UserData'));
set(handles.checkbox_crop,'Value',0);
update_data(handles.checkbox_crop, eventdata, handles);


% --- Executes on slider movement.
function frameNumberEdition_Callback(hObject, eventdata, handles)
userData = get(handles.figure1, 'UserData');

% Retrieve the value of the selected image
if strcmp(get(hObject,'Tag'),'edit_frameNumber')
    frameNumber = str2double(get(handles.edit_frameNumber, 'String'));
else
    frameNumber = get(handles.slider_frameNumber, 'Value');
end
frameNumber=round(frameNumber);

% Check the validity of the frame values
if isnan(frameNumber)
    warndlg('Please provide a valid frame value.','Setting Error','modal');
end
frameNumber = min(max(frameNumber,1),userData.nFrames);

% Store value
set(handles.slider_frameNumber,'Value',frameNumber);
set(handles.edit_frameNumber,'String',frameNumber);

% Save data and update graphics
set(handles.figure1, 'UserData', userData);
guidata(hObject, handles);
update_data(hObject,eventdata,handles);


% --- Executes on button press in pushbutton_outputDirectory.
function pushbutton_outputDirectory_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');
pathname = uigetdir(userData.MD.movieDataPath_,'Select output directory');

% Test uigetdir output and store its results
if isequal(pathname,0), return; end
set(handles.edit_outputDirectory,'String',pathname);

% Save data
set(handles.figure1,'UserData',userData);
guidata(hObject, handles);


% --- Executes on button press in pushbutton_addfile.
function pushbutton_addfile_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');
[filename, pathname]=uigetfile({'*.tif;*.TIF;*.stk;*.STK;*.bmp;*.BMP;*.jpg;*.JPG',...
    'Image files (*.tif,*.stk,*.bmp,*.jpg)'},...
    'Select the reference frame',userData.MD.movieDataPath_);

% Test uigetdir output and store its results
if isequal(pathname,0) || isequal(filename,0), return; end
files = get(handles.listbox_additionalFiles,'String');
if any(strcmp([pathname filename],files)),return; end
files{end+1} = [pathname filename];
set(handles.listbox_additionalFiles,'String',files,'Value',numel(files));

% --- Executes on button press in pushbutton_removeFile.
function pushbutton_removeFile_Callback(hObject, eventdata, handles)

props = get(handles.listbox_additionalFiles,{'String','Value'});
if isempty(props{1}), return; end
files= props{1};
files(props{2})=[];
set(handles.listbox_additionalFiles,'String',files,'Value',props{2}-1);

% --- Executes on button press in pushbutton_crop.
function pushbutton_crop_Callback(hObject, eventdata, handles)

userData = get(handles.figure1, 'UserData');
% Read cropRoi if crop window is still visible
if userData.imRectHandle.isvalid
    userData.cropROI=getPosition(userData.imRectHandle);
end
% Check valid output directory
outputDirectory = get(handles.edit_outputDirectory,'String');
if isempty(outputDirectory),
    errordlg('Please select an output directory','Error','modal');
end

% Create log message
wtBar = waitbar(0,'Initializing');
logMsg = @(chan) ['Please wait, cropping images for channel ' num2str(chan)];
timeMsg = @(t) ['\nEstimated time remaining: ' num2str(round(t)) 's'];
tic;

% Read channel information (number of frames, channel names)
nFrames = userData.MD.nFrames_;
nChan = numel(userData.MD.channels_);
nTot = nChan*nFrames;
inImage = @(chan,frame) [userData.imDirs{chan} filesep...
    userData.imageFileNames{chan}{frame}];

% Create new channel directory names for image writing
[~,chanNames]=cellfun(@fileparts,userData.imDirs,'UniformOutput',false);
userData.newImDirs = cellfun(@(x) [outputDirectory filesep x],chanNames,...
    'UniformOutput',false);
outImage = @(chan,frame) [userData.newImDirs{chan} filesep...
    userData.imageFileNames{chan}{frame}];

% Read public access channel properties
m=?Channel;
channelFieldsAccess=cellfun(@(x) x.SetAccess,m.Properties,'Unif',false);
channelPublicFields= cellfun(@(x) strcmpi(x,'public'),channelFieldsAccess);

%Copy channel images
for i = 1:nChan
    disp('Results will be saved under:')
    disp(userData.newImDirs{i});
    mkClrDir(userData.newImDirs{i});
    
    % Create channel object and copy public properties
    channels(i)=Channel(userData.newImDirs{i});
    s= struct(userData.MD.channels_(i));
    fields=fieldnames(s);    
    set(channels(i),rmfield(s,fields(~channelPublicFields)));
    
    for j= 1:nFrames
        % Read original image, crop it and save it
        imwrite(imcrop(imread(inImage(i,j)),userData.cropROI), outImage(i,j));
        if mod(j,5)==1 && feature('ShowFigureWindows')
            tj=toc;
            nj = (i-1)*nFrames+ j;
            waitbar(nj/nTot,wtBar,sprintf([logMsg(i) timeMsg(tj*nTot/nj-tj)]));
        end
    end
end

% Crop and write additional files at the base of the ouput directory
additionalFiles= get(handles.listbox_additionalFiles,'String');
if ~isempty(additionalFiles)
    waitbar(nj/nTot,wtBar,'Please wait, croppping additional files...');
    for i = 1:numel(additionalFiles)
        [~,fileName,fileExt]=fileparts(additionalFiles{i});

        % Read original image, crop it and save it
        imwrite(imcrop(imread(additionalFiles{i}),userData.cropROI),...
            [outputDirectory filesep fileName fileExt]);
    end
end
close(wtBar);

% Read public access & unchanged movie properties
m=?MovieData;
movieFieldsAccess=cellfun(@(x) x.SetAccess,m.Properties,'Unif',false);
moviePublicFields= cellfun(@(x) strcmpi(x,'public'),movieFieldsAccess);
changedFields = {'outputDirectory_','movieDataPath_','movieDataFileName_'};
movieChangedFields= cellfun(@(x) any(strcmpi(x.Name,changedFields)),m.Properties);

% Create movieData object and copy public properties
MD=MovieData(channels,outputDirectory,'movieDataPath_',outputDirectory,...
    'movieDataFileName_','movieData.mat');
s= struct(userData.MD);
fields=fieldnames(s);
set(MD,rmfield(s,fields(~moviePublicFields | movieChangedFields)));

% Perform sanityCheck
MD.sanityCheck

% If new MovieData was created (from movieSelectorGUI)
if userData.mainFig ~=-1, 
    % Retrieve main window userData
    userData_main = get(userData.mainFig, 'UserData');
    handles_main = guidata(userData.mainFig);
    
    % Check if files in movie list are saved in the same file
    contentlist = get(handles_main.listbox_movie, 'String');
    movieDataFullPath = [MD.movieDataPath_ filesep MD.movieDataFileName_];
    if any(strcmp(movieDataFullPath, contentlist))
        errordlg('Cannot overwrite a movie data file which is already in the movie list. Please choose another file name or another path.','Error','modal');
        return
    end
    
    % Append  MovieData object to movie selector panel
    userData_main.MD = cat(2, userData_main.MD, MD);
    
    % Refresh movie list box in movie selector panel
    contentlist{end+1} = movieDataFullPath;
    nMovies = length(contentlist);
    set(handles_main.listbox_movie, 'String', contentlist, 'Value', nMovies)
    title = sprintf('Movie List: %s/%s movie(s)', num2str(nMovies), num2str(nMovies));
    set(handles_main.text_movie_1, 'String', title)
    
    % Save the main window data
    set(userData.mainFig, 'UserData', userData_main)
end
% Delete current window
delete(handles.figure1)
