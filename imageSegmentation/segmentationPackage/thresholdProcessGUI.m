function varargout = thresholdProcessGUI(varargin)
% thresholdProcessGUI M-file for thresholdProcessGUI.fig
%      thresholdProcessGUI, by itself, creates a new thresholdProcessGUI or raises the existing
%      singleton*.
%
%      H = thresholdProcessGUI returns the handle to a new thresholdProcessGUI or the handle to
%      the existing singleton*.
%
%      thresholdProcessGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in thresholdProcessGUI.M with the given input arguments.
%
%      thresholdProcessGUI('Property','Value',...) creates a new thresholdProcessGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before thresholdProcessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to thresholdProcessGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help thresholdProcessGUI

% Last Modified by GUIDE v2.5 14-Mar-2017 18:58:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @thresholdProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @thresholdProcessGUI_OutputFcn, ...
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


% --- Executes just before thresholdProcessGUI is made visible.
function thresholdProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)

processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',0);

% ---------------------- Channel Setup -------------------------
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;

% Set up available input channels
set(handles.listbox_availableChannels,'String',userData.MD.getChannelPaths(), ...
    'UserData',1:numel(userData.MD.channels_));

channelIndex = funParams.ChannelIndex;

% Find any parent process
userData.parentProc = userData.crtPackage.getParent(userData.procID);
if isempty(userData.crtPackage.processes_{userData.procID}) && ~isempty(userData.parentProc)
    % Check existence of all parent processes
    emptyParentProc = any(cellfun(@isempty,userData.crtPackage.processes_(userData.parentProc)));
    if ~emptyParentProc
        % Intersect channel index with channel index of parent processes
        parentChannelIndex = @(x) userData.crtPackage.processes_{x}.funParams_.ChannelIndex;
        for i = userData.parentProc
            channelIndex = intersect(channelIndex,parentChannelIndex(i));
        end
    end
   
end

if ~isempty(channelIndex)
    channelString = userData.MD.getChannelPaths(channelIndex);
else
    channelString = {};
end

set(handles.listbox_selectedChannels,'String',channelString,...
    'UserData',channelIndex);

set(handles.edit_GaussFilterSigma,'String',funParams.GaussFilterSigma);

threshMethods = userData.crtProc.getMethods();
set(handles.popupmenu_thresholdingMethod,'String',{threshMethods(:).name},...
    'Value',funParams.MethodIndx);

if(~isfield(funParams,'PreThreshold'))
    funParams.PreThreshold = false;
end

useAutomatic = isempty(funParams.ThresholdValue) || funParams.PreThreshold;
useFixed = ~isempty(funParams.ThresholdValue) || funParams.PreThreshold;

if useAutomatic
   
    set(handles.checkbox_auto, 'Value', 1);
    set(get(handles.uipanel_automaticThresholding,'Children'),'Enable','on');
    if funParams.MaxJump
        set(handles.checkbox_max, 'Value', 1);
        set(handles.edit_jump, 'Enable','on','String',funParams.MaxJump);
    else
        set(handles.edit_jump, 'Enable', 'off');
    end
    if funParams.PreThreshold
        set(handles.checkbox_preThreshold, 'Value', 1);
    end
        

else
    set(handles.checkbox_auto, 'Value', 0);
    set(get(handles.uipanel_automaticThresholding,'Children'),'Enable','off');
    
end

if useFixed    
    if(isempty(funParams.ThresholdValue))
        funParams.ThresholdValue(1) = 0;
    end
    if(isempty(funParams.IsPercentile))
        funParams.IsPercentile = false(size(funParams.ThresholdValue));
    end
%     set(handles.checkbox_auto, 'Value', 0);
    set(get(handles.uipanel_fixedThreshold,'Children'),'Enable','on');
%     set(get(handles.uipanel_automaticThresholding,'Children'),'Enable','off');
    set(handles.listbox_thresholdValues, 'String', thresholdsToString(funParams.ThresholdValue,funParams.IsPercentile));
    userData.thresholdValue=funParams.ThresholdValue(1);
    set(handles.slider_threshold, 'Value',funParams.ThresholdValue(1))
    set(handles.checkbox_is_percentile,'Value',funParams.IsPercentile(1));
else
    set(get(handles.uipanel_fixedThreshold,'Children'),'Enable','off');
    nSelectedChannels  = numel(get(handles.listbox_selectedChannels, 'String'));
    set(handles.listbox_thresholdValues, 'String',...
        num2cell(zeros(1,nSelectedChannels)));
    userData.thresholdValue=0;
end

% Initialize the frame number slider and eidt
nFrames=userData.MD.nFrames_;
if nFrames > 1
    set(handles.slider_frameNumber,'Value',1,'Min',1,...
        'Max',nFrames,'SliderStep',[1/double(nFrames)  10/double(nFrames)]);
else
    set(handles.slider_frameNumber,'Enable','off');
end
set(handles.text_nFrames,'String',['/ ' num2str(nFrames)]);
set(handles.edit_frameNumber,'Value',1);


% Initialize previewing constants
userData.previewFig =-1;
userData.chanIndx = 0;
userData.imIndx=0;

% Update user data and GUI data
handles.output = hObject;
set(hObject, 'UserData', userData);
guidata(hObject, handles);
update_data(hObject,eventdata,handles);


% --- Outputs from this function are returned to the command line.
function varargout = thresholdProcessGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
% Delete figure
delete(handles.figure1);


% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)
% Call back function of 'Apply' button
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

% -------- Check user input --------
if isempty(get(handles.listbox_selectedChannels, 'String'))
   errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal') 
    return;
end
channelIndex = get (handles.listbox_selectedChannels, 'Userdata');
funParams.ChannelIndex = channelIndex;

gaussFilterSigma = str2double(get(handles.edit_GaussFilterSigma, 'String'));
if isnan(gaussFilterSigma) || gaussFilterSigma < 0
    errordlg(['Please provide a valid input for '''...
        get(handles.text_GaussFilterSigma,'String') '''.'],'Setting Error','modal');
    return;
end
funParams.GaussFilterSigma=gaussFilterSigma;

useAutomatic = get(handles.checkbox_auto, 'value');
useFixed = ~useAutomatic || get(handles.checkbox_preThreshold, 'value');

if useAutomatic
%     funParams.ThresholdValue = [ ];
    funParams.MethodIndx=get(handles.popupmenu_thresholdingMethod,'Value');
    
    if get(handles.checkbox_max, 'Value')
        % If both checkbox are checked
        maxJump=str2double(get(handles.edit_jump, 'String'));
        if isnan(maxJump) || maxJump < 1
            errordlg('Please provide a valid input for ''Maximum threshold jump''.','Setting Error','modal');
            return;
        end    
        funParams.MaxJump = str2double(get(handles.edit_jump,'String'));
    else
        funParams.MaxJump = 0;
    end
    
    if useFixed
        % If both checkbox are checked
%         preThreshold=str2double(get(handles.edit_preThreshold, 'String'));
%         if isnan(preThreshold)
%             errordlg('Please provide a valid input for ''The fixed threshold applied before automatic thresholding''.','Setting Error','modal');
%             return;
%         end    
        funParams.PreThreshold = true;
    else
        funParams.PreThreshold = false;
        funParams.ThresholdValue = [ ];
    end
else
    funParams.PreThreshold = false;
    funParams.ThresholdValue = [ ];
    funParams.MaxJump = 0;
end

if useFixed
    threshold = get(handles.listbox_thresholdValues, 'String');
    if isempty(threshold)
       errordlg('Please provide at least one threshold value.','Setting Error','modal')
       return
    elseif length(threshold) ~= 1 && length(threshold) ~= length(channelIndex)
       errordlg('Please provide the same number of threshold values as the input channels.','Setting Error','modal')
       return
    else
        [threshold,isPercentile] = stringToThresholds(threshold);
%         threshold = str2double(threshold);
        if any(isnan(threshold)) || any(threshold < 0)
            errordlg('Please provide valid threshold values. Threshold cannot be a negative number.','Setting Error','modal')
            return            
        end
    end
    funParams.ThresholdValue = threshold;
    funParams.IsPercentile = isPercentile;
end
   

% -------- Process Sanity check --------
% ( only check underlying data )

try
    userData.crtProc.sanityCheck;
catch ME

    errordlg([ME.message 'Please double check your data.'],...
                'Setting Error','modal');
    return;
end

processGUI_ApplyFcn(hObject, eventdata, handles,funParams);

% --- Executes on button press in checkbox_all.
function checkbox_all_Callback(hObject, eventdata, handles)

% Hint: get(hObject,'Value') returns toggle state of checkbox_all
contents1 = get(handles.listbox_availableChannels, 'String');

chanIndex1 = get(handles.listbox_availableChannels, 'Userdata');
chanIndex2 = get(handles.listbox_selectedChannels, 'Userdata');

% Return if listbox1 is empty
if isempty(contents1)
    return;
end

switch get(hObject,'Value')
    case 1
        set(handles.listbox_selectedChannels, 'String', contents1);
        chanIndex2 = chanIndex1;
        thresholdValues =zeros(1,numel(chanIndex1));
    case 0
        set(handles.listbox_selectedChannels, 'String', {}, 'Value',1);
        chanIndex2 = [ ];
        thresholdValues = [];
end
set(handles.listbox_selectedChannels, 'UserData', chanIndex2);
set(handles.listbox_thresholdValues,'String',num2cell(thresholdValues))
update_data(hObject,eventdata,handles);

% --- Executes on button press in pushbutton_select.
function pushbutton_select_Callback(hObject, eventdata, handles)
% call back function of 'select' button

contents1 = get(handles.listbox_availableChannels, 'String');
contents2 = get(handles.listbox_selectedChannels, 'String');
id = get(handles.listbox_availableChannels, 'Value');

% If channel has already been added, return;
chanIndex1 = get(handles.listbox_availableChannels, 'Userdata');
chanIndex2 = get(handles.listbox_selectedChannels, 'Userdata');
[thresholdValues,isPercentile] = stringToThresholds(get(handles.listbox_thresholdValues,'String'));
% thresholdValues = cellfun(@str2num,get(handles.listbox_thresholdValues,'String'));

for i = id
    if any(strcmp(contents1{i}, contents2) )
        continue;
    else
        contents2{end+1} = contents1{i};
        thresholdValues(end+1) = 0;
        isPercentile(end+1) = false;
        chanIndex2 = cat(2, chanIndex2, chanIndex1(i));

    end
end

set(handles.listbox_selectedChannels, 'String', contents2, 'Userdata', chanIndex2);
set(handles.listbox_thresholdValues,'String',thresholdsToString(thresholdValues,isPercentile))
update_data(hObject,eventdata,handles);


% --- Executes on button press in pushbutton_delete.
function pushbutton_delete_Callback(hObject, eventdata, handles)
% Call back function of 'delete' button
contents = get(handles.listbox_selectedChannels,'String');
id = get(handles.listbox_selectedChannels,'Value');

% Return if list is empty
if isempty(contents) || isempty(id)
    return;
end

% Delete selected item
contents(id) = [ ];

% Delete userdata
chanIndex2 = get(handles.listbox_selectedChannels, 'Userdata');
chanIndex2(id) = [ ];
set(handles.listbox_selectedChannels, 'Userdata', chanIndex2);

% Update thresholdValues
% thresholdValues = cellfun(@str2num,get(handles.listbox_thresholdValues,'String'));
[thresholdValues,isPercentile] = stringToThresholds(get(handles.listbox_thresholdValues,'String'));
thresholdValues(id) = [];
isPercentile(id) = [];
set(handles.listbox_thresholdValues,'String',thresholdsToString(thresholdValues,isPercentile));

% Point 'Value' to the second last item in the list once the 
% last item has been deleted
if (id >length(contents) && id>1)
    set(handles.listbox_selectedChannels,'Value',length(contents));
    set(handles.listbox_thresholdValues,'Value',length(contents));
end
% Refresh listbox
set(handles.listbox_selectedChannels,'String',contents);
update_data(hObject,eventdata,handles);

% --- Executes on button press in checkbox_auto.
function checkbox_auto_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkbox_auto
if get(hObject, 'Value')
    set(get(handles.uipanel_automaticThresholding,'Children'),'Enable','on');
    if ~get(handles.checkbox_preThreshold,'Value')
%         set(handles.edit_preThreshold,'Enable','off'); 
        set(get(handles.uipanel_fixedThreshold,'Children'),'Enable','off');
    end
    if ~get(handles.checkbox_max,'Value'), set(handles.edit_jump,'Enable','off'); end
else 
    set(get(handles.uipanel_automaticThresholding,'Children'),'Enable','off');
    set(get(handles.uipanel_fixedThreshold,'Children'),'Enable','on')
    set(handles.checkbox_max, 'Value', 0);
    set(handles.checkbox_preThreshold, 'Value', 0);
    set(handles.checkbox_applytoall, 'Value',0);
    set(handles.checkbox_preview, 'Value',1);
end
update_data(hObject,eventdata,handles);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% Notify the package GUI that the setting panel is closed
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

if ishandle(userData.helpFig), delete(userData.helpFig); end
if ishandle(userData.previewFig), delete(userData.previewFig); end

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);

% --- Executes on button press in checkbox_max.
function checkbox_max_Callback(hObject, eventdata, handles)

if get(hObject, 'value')
    set(handles.edit_jump, 'Enable', 'on');
else 
    set(handles.edit_jump, 'Enable', 'off');
end

function edit_preThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to edit_preThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_preThreshold as text
%        str2double(get(hObject,'String')) returns contents of edit_preThreshold as a double


% --- Executes during object creation, after setting all properties.
function edit_preThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_preThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_preThreshold.
function checkbox_preThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_preThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_preThreshold
if get(hObject, 'value')
    set(get(handles.uipanel_fixedThreshold,'Children'),'Enable','on')
%     set(handles.checkbox_max, 'Value', 0);
%     set(handles.checkbox_preThreshold, 'Value', 0);
%     set(handles.checkbox_applytoall, 'Value',0);
    set(handles.checkbox_preview, 'Value',1);
else 
    set(get(handles.uipanel_fixedThreshold,'Children'),'Enable','off');
%     set(handles.edit_preThreshold, 'Enable', 'off');
end
update_data(hObject,eventdata,handles);


% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(hObject, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)

if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end


% --- Executes on button press in pushbutton_set_threshold.
function pushbutton_set_threshold_Callback(hObject, eventdata, handles)

newThresholdValue = get(handles.slider_threshold,'Value');
newIsPercentile = get(handles.checkbox_is_percentile,'Value');
indx = get(handles.listbox_selectedChannels,'Value');
% thresholdValues = cellfun(@str2num,get(handles.listbox_thresholdValues,'String'));
[thresholdValues,isPercentile] = stringToThresholds(get(handles.listbox_thresholdValues,'String'));
thresholdValues(indx) = newThresholdValue;
isPercentile(indx) = newIsPercentile;
set(handles.listbox_thresholdValues,'String',thresholdsToString(thresholdValues,isPercentile));


% --- Executes on button press in checkbox_preview.
function checkbox_preview_Callback(hObject, eventdata, handles)

if get(handles.checkbox_preview,'Value'), 
    update_data(hObject,eventdata,handles); 
else
    userData = get(handles.figure1, 'UserData');
    if ishandle(userData.previewFig), delete(userData.previewFig); end
    % Save data and update graphics
    set(handles.figure1,'UserData',userData);
    guidata(hObject, handles);
end

function threshold_edition(hObject,eventdata, handles)

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

% Retrieve the valuye of the selected threshold
if strcmp(get(hObject,'Tag'),'edit_threshold')
    thresholdValue = str2double(get(handles.edit_threshold, 'String'));
else
    thresholdValue = get(handles.slider_threshold, 'Value');
end
thresholdValue=round(thresholdValue);

% Check the validity of the supplied threshold
if isnan(thresholdValue) || thresholdValue < get(handles.slider_threshold,'Min') || thresholdValue > get(handles.slider_threshold,'Max')
    warndlg('Please provide a valid coefficient.','Setting Error','modal');
    thresholdValue=userData.thresholdValue;
end

set(handles.slider_threshold,'Value',thresholdValue);
set(handles.edit_threshold,'String',thresholdValue);
    
% Save data and update graphics
set(handles.figure1,'UserData',userData);
guidata(hObject, handles);
update_data(hObject,eventdata,handles);


function imageNumber_edition(hObject,eventdata, handles)

% Retrieve the value of the selected image
if strcmp(get(hObject,'Tag'),'edit_imageNumber')
    imageNumber = str2double(get(handles.edit_frameNumber, 'String'));
else
    imageNumber = get(handles.slider_frameNumber, 'Value');
end
imageNumber=round(imageNumber);

% Check the validity of the supplied threshold
if isnan(imageNumber) || imageNumber < 0 || imageNumber > get(handles.slider_frameNumber,'Max')
    warndlg('Please provide a valid coefficient.','Setting Error','modal');
end

set(handles.slider_frameNumber,'Value',imageNumber);
set(handles.edit_frameNumber,'String',imageNumber);

% Save data and update graphics
guidata(hObject, handles);
update_data(hObject,eventdata,handles);


function update_data(hObject,eventdata, handles)

userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

if strcmp(get(get(hObject,'Parent'),'Tag'),'uipanel_channels') ||...
        strcmp(get(hObject,'Tag'),'listbox_thresholdValues')
    % Check if changes have been at the list box level
    linkedListBoxes = {'listbox_selectedChannels','listbox_thresholdValues'};
    checkLinkBox = strcmp(get(hObject,'Tag'),linkedListBoxes);
    if any(checkLinkBox)
        value = get(handles.(linkedListBoxes{checkLinkBox}),'Value');
        set(handles.(linkedListBoxes{~checkLinkBox}),'Value',value);
    else
        value = get(handles.listbox_selectedChannels,'Value');
    end
    thresholdString = get(handles.listbox_thresholdValues,'String');
    if ~isempty(thresholdString)
%         thresholdValue = str2double(thresholdString{value});
        [thresholdValue,isPercentile] = stringToThresholds(thresholdString{value});
    else
        thresholdValue=0;
    end
    set(handles.edit_threshold,'String',thresholdValue);
    set(handles.slider_threshold,'Value',thresholdValue);
    setPercentileMode(handles,isPercentile);
    if isempty(thresholdString),
        if isfield(userData, 'previewFig'), delete(userData.previewFig); end
        set(handles.figure1, 'UserData', userData);
        guidata(hObject,handles);
        return
    end
end


% Retrieve the channex index
props=get(handles.listbox_selectedChannels,{'UserData','Value'});
if isempty(props{1}), return; end
chanIndx = props{1}(props{2});
imIndx = get(handles.slider_frameNumber,'Value');
thresholdValue = get(handles.slider_threshold, 'Value');

% Load a new image in case the image number or channel has been changed
if (chanIndx~=userData.chanIndx) ||  (imIndx~=userData.imIndx)
    if ~isempty(userData.parentProc) && ~isempty(userData.crtPackage.processes_{userData.parentProc}) &&...
            userData.crtPackage.processes_{userData.parentProc}.checkChannelOutput(chanIndx)
        userData.imData=userData.crtPackage.processes_{userData.parentProc}.loadOutImage(chanIndx,imIndx);
    else
        userData.imData=userData.MD.channels_(chanIndx).loadImage(imIndx);
    end
    
    % Get the value of the new maximum threshold
    if(get(handles.checkbox_is_percentile,'Value'))
        maxThresholdValue = 100;
        minThresholdValue = 0;
    else
        maxThresholdValue=max(max(userData.imData(:)),1);
        minThresholdValue=min(min(userData.imData(:)),0);
    end
    % Update the threshold Value if above the new maximum
    thresholdValue=min(thresholdValue,maxThresholdValue);
    
    set(handles.slider_threshold,'Value',thresholdValue,'Max',maxThresholdValue,...
        'Min',minThresholdValue, ...
        'SliderStep',[1/double(maxThresholdValue)  10/double(maxThresholdValue)]);
    set(handles.edit_threshold,'String',thresholdValue);
    
    userData.updateImage=1;
    userData.chanIndx=chanIndx;
    userData.imIndx=imIndx;
else
    userData.updateImage=0;
end


% Save the data
set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);

% Update graphics if applicable
if get(handles.checkbox_preview,'Value')

    % Create figure if non-existing or closed
    if ~ishandle(userData.previewFig)
        userData.previewFig = figure('NumberTitle','off','Name','Thresholding preview',...
            'Position',[50 50 userData.MD.imSize_(2) userData.MD.imSize_(1)]);
        axes('Position',[0 0 1 1]);
    else
        figure(userData.previewFig);
    end
    
    % Retrieve the handle of the figures image
    imHandle = findobj(userData.previewFig,'Type','image');
    if userData.updateImage || isempty(imHandle)
        if isempty(imHandle)
            imHandle=imagesc(userData.imData);
            axis off;
        else
            set(imHandle,'CData',userData.imData);
        end
    end
    
    % Preview the tresholding output using the alphaData mapping    
    alphamask=ones(size(userData.imData));
    gaussFilterSigma = str2double(get(handles.edit_GaussFilterSigma, 'String'));
    if ~isnan(gaussFilterSigma) && gaussFilterSigma >0
        imData = filterGauss2D(userData.imData,gaussFilterSigma);
    else
        imData=userData.imData;
    end
    
    
    if get(handles.checkbox_auto,'Value')
        methodIndx=get(handles.popupmenu_thresholdingMethod,'Value');
        threshMethod = userData.crtProc.getMethods(methodIndx).func;
        
        try %#ok<TRYNC>
            if ~get(handles.checkbox_preThreshold,'Value')
                currThresh = threshMethod( imData);
            else
                thresholdValue = get(handles.slider_threshold, 'Value');
                if(get(handles.checkbox_is_percentile,'Value'))
                    thresholdValue = prctile(userData.imData(:),thresholdValue);
                end
                currThresh = threshMethod( imData(imData > thresholdValue) );
                currThresh = max(currThresh,thresholdValue);
            end
            alphamask(imData<=currThresh)=.4;
        end
    else
        % Preview manual threshold
        thresholdValue = get(handles.slider_threshold, 'Value');
        if(get(handles.checkbox_is_percentile,'Value'))
            thresholdValue = prctile(userData.imData(:),thresholdValue);
        end
        alphamask(imData<=thresholdValue)=.4;
    end
    set(imHandle,'AlphaData',alphamask,'AlphaDataMapping','none');


    
    set(handles.figure1, 'UserData', userData);
    guidata(hObject,handles);
end


% --- Executes on button press in checkbox_is_percentile.
function checkbox_is_percentile_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_is_percentile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_is_percentile
if get(handles.checkbox_is_percentile,'Value')
    % Convert threshold values into percentiles
    thresholdValue = get(handles.slider_threshold, 'Value');
    userData = get(handles.figure1, 'UserData');
    threshPercent = sum(userData.imData(:) < thresholdValue)/numel(userData.imData(:))*100;
    set(handles.slider_threshold,'Value',threshPercent,'Min',0,'Max',100, ...
        'SliderStep',[0.01 0.1] ...
        );
    set(handles.edit_threshold,'String',threshPercent);
    set(handles.text_percentile,'String','%');
    update_data(hObject,eventdata, handles)
else
    % Convert percentile to threshold values
    thresholdPercent = get(handles.slider_threshold, 'Value');
    userData = get(handles.figure1, 'UserData');
    thresholdValue = prctile(userData.imData(:),thresholdPercent);
    maxThresholdValue=max(max(userData.imData(:)),1);
    minThresholdValue=min(min(userData.imData(:)),0);
    set(handles.slider_threshold,'Value',thresholdValue,'Min',minThresholdValue,'Max',maxThresholdValue, ...
        'SliderStep',[1/double(maxThresholdValue)  10/double(maxThresholdValue)]);
    set(handles.edit_threshold,'String',thresholdValue);
    set(handles.text_percentile,'String','');
end

function strings = thresholdsToString(thresholdValues,isPercentile)
    strings = num2cell(thresholdValues);
    strings = cellfun(@num2str,strings,'UniformOutput',false);
    percent = cell(size(strings));
    [percent{isPercentile}] = deal('%');
    strings = strcat(strings,percent);
    
    
function [thresholdValues,isPercentile] = stringToThresholds(thresholdStrings)
    if(ischar(thresholdStrings))
        thresholdStrings = {thresholdStrings};
    end
    isPercentile = cellfun(@(x) x(end) == '%',thresholdStrings);
    thresholdStrings(isPercentile) = cellfun(@(x) x(1:end-1),thresholdStrings(isPercentile),'UniformOutput',false);
    thresholdValues = str2double(thresholdStrings);

function setPercentileMode(handles,isPercentile)
    percent = '%';
    set(handles.text_percentile,'String',percent(isPercentile));
    set(handles.checkbox_is_percentile,'Value',isPercentile);
