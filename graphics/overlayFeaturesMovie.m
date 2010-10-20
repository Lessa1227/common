function overlayFeaturesMovie(movieInfo,startend,saveMovie,movieName,...
    filterSigma,showRaw,intensityScale)
%Overlays detected features obtained via detectSubResFeatures2D_Movie on movies
%
%SYNPOSIS overlayFeaturesMovie(movieInfo,startend,saveMovie,movieName,...
%    filterSigma,showRaw,autoscaleImage)
%
%INPUT  movieInfo   : Output of detectSubResFeatures2D_Movie.
%       startend    : Row vector indicating first and last frame to
%                     include in movie. Format: [startframe endframe].
%                     Optional. Default: [1 (maximum available frame)]
%       saveMovie   : 1 to save movie (as Quicktime), 0 otherwise.
%                     Optional. Default: 0
%       movieName   : filename for saving movie.
%                     Optional. Default: FeaturesMovie (if saveMovie = 1).
%       filterSigma : 0 to overlay on raw image, PSF sigma to overlay on image
%                     filtered with given filterSigma.
%                     Optional. Default: 0
%       showRaw     : 1 to add raw movie to the left of the movie with
%                     tracks overlaid, 2 to add raw movie at the top of
%                     the movie with tracks overlaid, 0 otherwise.
%                     Optional. Default: 0.
%       intensityScale: 0 to autoscale every image in the movie, 1
%                     to have a fixed scale using intensity mean and std, 2
%                     to have a fixed scale using minimum and maximum
%                     intensities.
%                     Optional. Default: 1.
%
%OUTPUT If movie is to be saved, the QT movie is written into directory
%       where TIFFs are located
%
%Khuloud Jaqaman, August 2007

%% input

%check whether correct number of input arguments was used
if nargin < 1
    disp('--overlayFeaturesMovie: Incorrect number of input arguments!');
    return
end

%record directory before start of function
% startDir = pwd;

%ask user for images
[fName,dirName] = uigetfile('*.tif','specify first image in the stack - specify very first image, even if not to be plotted');

%if input is valid ...
if(isa(fName,'char') && isa(dirName,'char'))
    
    %get all file names in stack
    outFileList = getFileStackNames([dirName,fName]);
    numFiles = length(outFileList);
    
    %determine which frames the files correspond to, and generate the inverse map
    %indicate missing frames with a zero
    frame2fileMap = zeros(numFiles,1);
    for iFile = 1 : numFiles
        [~,~,frameNumStr] = getFilenameBody(outFileList{iFile});
        frameNum = str2double(frameNumStr);
        frame2fileMap(frameNum) = iFile;
    end
    
    %assign as number of frames the last frame number observed
    numFrames = frameNum;
    
    %read first image to get image size
    currentImage = imread(outFileList{1});
    [isx,isy] = size(currentImage);
    
else %else, exit
    
    disp('--overlayFeaturesMovie: Bad file selection');
    return
    
end

%check startend and assign default if necessary
if nargin < 2 || isempty(startend)
    startend = [1 numFrames];
else
    startend(2) = min(startend(2),numFrames); %make sure that last frame does not exceed real last frame
end

%check whether to save movie
if nargin < 3 || isempty(saveMovie)
    saveMovie = 0;
end

%check name for saving movie
if saveMovie && (nargin < 4 || isempty(movieName))
    movieName = 'featuresMovie.mov';
end

%check whether to use filtered images
if nargin < 5 || isempty(filterSigma)
    filterSigma = 0;
end

%check whether to put raw movie adjacent to movie with tracks overlaid
if nargin < 6 || isempty(showRaw)
    showRaw = 0;
end

%check how to scale image intensity
if nargin < 7 || isempty(intensityScale)
    intensityScale = 1;
end

%keep only the frames of interest
outFileList = outFileList(frame2fileMap(startend(1)):frame2fileMap(startend(2)));
frame2fileMap = frame2fileMap(startend(1):startend(2));
indxNotZero = find(frame2fileMap~=0);
frame2fileMap(indxNotZero) = frame2fileMap(indxNotZero) - frame2fileMap(indxNotZero(1)) + 1;

%initialize QT movie if it is to be saved
if saveMovie
    evalString = ['MakeQTMovie start ''' fullfile(dirName,movieName) ''''];
    eval(evalString);
end

%retain only the movieInfo of the frames of interest
if isempty(movieInfo)
    movieInfo = repmat(struct('xCoord',[],'yCoord',[],'amp',[]),...
        startend(2)-startend(1)+1,1);
else
    movieInfo = movieInfo(startend(1):startend(2));
end

%get image size
imageRange = [1 isx; 1 isy];

%% make movie

% %go to directory where movie will be saved
% cd(dirName);

%go over all specified frames and find minimum and maximum intensity in all
%of them combined
switch intensityScale
    case 0
        intensityMinMax = [];
    case 1
        meanIntensity = zeros(length(movieInfo),1);
        stdIntensity = meanIntensity;
        for iFrame = 1 : length(movieInfo)
            if frame2fileMap(iFrame) ~= 0
                imageStack = double(imread(outFileList{frame2fileMap(iFrame)}));
                meanIntensity(iFrame) = mean(imageStack(:));
                stdIntensity(iFrame) = std(imageStack(:));
            end
        end
        meanIntensity = mean(meanIntensity);
        stdIntensity = mean(stdIntensity);
        intensityMinMax = [meanIntensity-2*stdIntensity meanIntensity+6*stdIntensity];
    case 2
        minIntensity = zeros(length(movieInfo),1);
        maxIntensity = minIntensity;
        for iFrame = 1 : length(movieInfo)
            if frame2fileMap(iFrame) ~= 0
                imageStack = double(imread(outFileList{frame2fileMap(iFrame)}));
                minIntensity(iFrame) = min(imageStack(:));
                maxIntensity(iFrame) = max(imageStack(:));
            end
        end
        minIntensity = min(minIntensity);
        maxIntensity = max(maxIntensity);
        intensityMinMax = [minIntensity maxIntensity];
end

%go over all specified frames
for iFrame = 1 : length(movieInfo)
    
    if frame2fileMap(iFrame) ~= 0 %if frame exists
        
        %read specified image
        imageStack = imread(outFileList{frame2fileMap(iFrame)});
        
        %filter images if requested
        if filterSigma
            imageStack = Gauss2D(imageStack,filterSigma);
        end
        
    else %otherwise
        
        %make empty frame
        imageStack = zeros(isx,isy);
        
    end
    
    %plot image in current frame
    clf;
    
    switch showRaw
        case 1
            axes('Position',[0 0 0.495 1]);
            imshow(imageStack,intensityMinMax);
            xlim(imageRange(2,:));
            ylim(imageRange(1,:));
            hold on;
            textDeltaCoord = min(diff(imageRange,[],2))/20;
            text(imageRange(1,1)+textDeltaCoord,imageRange(2,1)+...
                textDeltaCoord,num2str(iFrame+startend(1)-1),'Color','white');
            axes('Position',[0.505 0 0.495 1]);
            imshow(imageStack,intensityMinMax);
            xlim(imageRange(2,:));
            ylim(imageRange(1,:));
            hold on;
        case 2
            axes('Position',[0 0.505 1 0.495]);
            imshow(imageStack,intensityMinMax);
            xlim(imageRange(2,:));
            ylim(imageRange(1,:));
            hold on;
            textDeltaCoord = min(diff(imageRange,[],2))/20;
            text(imageRange(1,1)+textDeltaCoord,imageRange(2,1)+...
                textDeltaCoord,num2str(iFrame+startend(1)-1),'Color','white');
            axes('Position',[0 0 1 0.495]);
            imshow(imageStack,intensityMinMax);
            xlim(imageRange(2,:));
            ylim(imageRange(1,:));
            hold on;
        otherwise
            axes('Position',[0 0 1 1]);
            imshow(imageStack,intensityMinMax);
            xlim(imageRange(2,:));
            ylim(imageRange(1,:));
            hold on;
            textDeltaCoord = min(diff(imageRange,[],2))/20;
            text(imageRange(1,1)+textDeltaCoord,imageRange(2,1)+...
                textDeltaCoord,num2str(iFrame+startend(1)-1),'Color','white');
    end
    
    %plot features
    if ~isempty(movieInfo(iFrame).xCoord)
        plot(movieInfo(iFrame).xCoord(:,1),movieInfo(iFrame).yCoord(:,1),'ro','MarkerSize',4);
    end
    
    %add frame to movie if movie is saved
    if saveMovie
        MakeQTMovie addaxes
    end
    
    %pause for a moment to see frame
    pause(0.1);
    
end

%finish movie
if saveMovie==1
    MakeQTMovie finish
end

%% change directory back to original
% cd(startDir);

%% ~~~ end ~~~