function calculateMovieCorrelation(movieObject,varargin)
% calculateMovieCorrelation calculate the autocorrelation and cross-correlation
% between the protrusion and activity maps
%
% SYNOPSIS calculateMovieCorrelation(movieObject,paramsIn)
%
% INPUT   
%   movieObject - A MovieData object describing the movie to be processed
%
%   paramsIn - Structure with inputs for optional parameters. The
%   parameters should be stored as fields in the structure, with the field
%   names and possible values as described below
%

% Marco Vilela, Sep 2011
% Sebastien Besson, Sep 2011
%% ----------- Input ----------- %%

%Check input
ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('movieObject', @(x) isa(x,'MovieObject'));
ip.addOptional('paramsIn',[], @isstruct);
ip.parse(movieObject,varargin{:});
paramsIn=ip.Results.paramsIn;

%Get the indices of any previous stage drift processes                                                                     
iProc = movieObject.getProcessIndex('CorrelationCalculationProcess',1,0);

%If the process doesn't exist, create it
if isempty(iProc)
    iProc = numel(movieObject.processes_)+1;
    movieObject.addProcess(CorrelationCalculationProcess(movieObject,...
        movieObject.outputDirectory_));                                                                                                 
end

corrProc = movieObject.processes_{iProc};

%Parse input, store in parameter structure
p = parseProcessParams(corrProc,paramsIn);

% Delegates correlation processes to movies if object is a movieList 
if isa(movieObject,'MovieList')
    movieParams.ProcessName=p.ProcessName;
    movieParams.BandMin=p.BandMin;
    movieParams.BandMax=p.BandMax;
    for i =1:numel(p.MovieIndex);
        movieParams.SliceIndex=p.SliceIndex{p.MovieIndex(i)};
        movieData = movieObject.movies_{p.MovieIndex(i)};
        iProc = movieData.getProcessIndex('CorrelationCalculationProcess',1,0);
        if isempty(iProc)
            iProc = numel(movieData.processes_)+1;
            movieData.addProcess(CorrelationCalculationProcess(movieData,...
                movieData.outputDirectory_));
        end
        corrProc = movieData.processes_{iProc};
        parseProcessParams(movieData.processes_{iProc},movieParams);
        corrProc.run();
        
    end  
    return
end    



%% --------------- Initialization ---------------%%
if feature('ShowFigureWindows')
    [~,movieName]=fileparts(movieObject.getPath);
    wtBar = waitbar(0,'Initializing...','Name',movieName);
else
    wtBar=-1;
end

input = corrProc.getInput;
nInput=numel(input);

% Test the presence and output validity of the speckle detection process
iSignalPreproc =movieObject.getProcessIndex('SignalPreprocessingProcess',1,1);     
if isempty(iSignalPreproc)
    error([SignalPreprocessingProcess.getName ' has not yet been performed'...
    'on this movie! Please run first!!']);
end        

% %Check that there is a valid output
signalPreproc = movieObject.processes_{iSignalPreproc};
preprocInput =signalPreproc.getInput;
preprocIndex=zeros(nInput,1);
for i=1:nInput
    index = find(arrayfun(@(x) isequal(input(i),x),preprocInput));
    assert(isscalar(index))
    preprocIndex(i) = index;
end
if ~signalPreproc.checkChannelOutput(preprocIndex)
    error(['Each time series must have been preprocessesd !' ...
        'Please apply pre-processing to all time series before '...
        'running correlation calculatino!'])
end

% Load input
inFilePaths = cell(nInput,1);
data = cell(nInput,1);
range = cell(nInput,1);
for iInput=1:nInput
    inFilePaths{1,iInput} = signalPreproc.outFilePaths_{1,preprocIndex(iInput)};
    [data{iInput},range{iInput}] = signalPreproc.loadChannelOutput(preprocIndex(iInput));
end
corrProc.setInFilePaths(inFilePaths)

% Set up output files
outFilePaths=cell(nInput,nInput);
for i=1:nInput
    for j=1:i-1
        outFilePaths{i,j} = [p.OutputDirectory filesep 'correlation' ...
            input(i).name '_' input(j).name '.mat'];
    end
    outFilePaths{i,i} = [p.OutputDirectory filesep 'autocorrelation' ...
        input(i).name '.mat'];
end
mkClrDir(p.OutputDirectory);
corrProc.setOutFilePaths(outFilePaths);

%% --------------- Correlation calculation ---------------%%% 
disp('Starting calculating correlation...')

%At least 50 points are needed to calculate the ACF
%Number of lags <= N/4;
%Ref: Time Series Analysis, Forecast and Control. Jenkins, G. Box,G
minP     = 50;

nLagsMax =round(movieObject.nFrames_/4);
nBands =cellfun(@numel,data);
nSlices = numel(data{1}{1});

logMsg = @(i) ['Please wait, calculating ' input(i).name ' autocorrelation'];

% Calculate autocorrelation
for iInput=1:nInput
    disp(logMsg(iInput));
    % Initialize autocorrelation function and bounds
    corrFun = nan(nLagsMax+1,nSlices,nBands(iInput));
    lags = nan(nLagsMax+1,nSlices,nBands(iInput));
    bounds = nan(2,nSlices,nBands(iInput));
    if ishandle(wtBar), waitbar(0,wtBar,logMsg(iInput)); end
    
    % Calculate band index
    validBands = find(~cellfun(@isempty,data{iInput}));
    for iBand=find(validBands<=p.BandMax & validBands>=p.BandMin )'
        validSlices = ~cellfun(@isempty,data{iInput}{iBand});
        for iSlice=find(validSlices & p.SliceIndex)'
            nLags = round(length(data{iInput}{iBand}{iSlice})/4);
            [corrFun(1:nLags+1,iSlice,iBand),lags(1:nLags+1,iSlice,iBand),...
                bounds(:,iSlice,iBand)] = autocorr(data{iInput}{iBand}{iSlice},nLags);
        end
        if ishandle(wtBar), waitbar(iBand/nBands(iInput),wtBar); end
    end
       
    lags =lags*movieObject.timeInterval_; %#ok<NASGU>
    
    % Stupid bootstrapping-like function to test the grapical output
    bootstrapCorrFun=nan(nLagsMax+1,nBands(iInput));
    bootstrapSteCorrFun=nan(nLagsMax+1,nBands(iInput));
    for iBand=find(validBands<=p.BandMax & validBands>=p.BandMin )'
        bootstrapCorrFun(:,iBand) = nanmean(corrFun(:,:,iBand),2);
        bootstrapSteCorrFun(:,iBand) = nanstd(corrFun(:,:,iBand),1,2);
    end
    
    save(outFilePaths{iInput,iInput},'corrFun','bounds','lags',...
        'bootstrapCorrFun','bootstrapSteCorrFun');  
end

logMsg = @(i,j) ['Please wait, calculating ' input(i).name '/'...
    input(j).name ' cross-correlation'];

% Calculate cross-correlation
for iInput1=1:nInput
    for iInput2=1:iInput1-1
        disp(logMsg(iInput1,iInput2));
        
        % Initialize cross-correlation function and bounds
        corrFun = nan(2*nLagsMax+1,nSlices,nBands(iInput1),nBands(iInput2));
        bounds  = nan(2,nSlices,nBands(iInput1),nBands(iInput2));
        lags  = nan(2*nLagsMax+1,nSlices,nBands(iInput1),nBands(iInput2));
        
        if ishandle(wtBar), waitbar(0,wtBar,logMsg(iInput1,iInput2)); end
        
        % Loop over bands and window slices
        for iBand1=p.BandMin:min(nBands(iInput1),p.BandMax)
            for iBand2=p.BandMin:min(nBands(iInput2),p.BandMax)
                for iSlice=find(p.SliceIndex)'
                    
                    [~,range1,range2] = intersect(range{iInput1}{iBand1}{iSlice},range{iInput2}{iBand2}{iSlice});
                    ccL               = length(range1);
                    if ccL >= minP
                        nLags = round(ccL/4);
                        [corrFun(1:2*nLags+1,iSlice,iBand1,iBand2),lags(1:2*nLags+1,iSlice,iBand1,iBand2),...
                            bounds(:,iSlice,iBand1,iBand2)] =...
                            crosscorr(data{iInput1}{iBand1}{iSlice}(range1),data{iInput2}{iBand2}{iSlice}(range2),nLags);
                    end
                end
            end
            if ishandle(wtBar), waitbar(iBand1/nBands(iInput1),wtBar); end
        end
        lags=lags*movieObject.timeInterval_; %#ok<NASGU>
        
        % Stupid bootstrapping-like function to test the grapical output
        bootstrapCorrFun=nan(2*nLagsMax+1,nBands(iInput1),nBands(iInput2));
        bootstrapSteCorrFun=nan(2*nLagsMax+1,nBands(iInput1),nBands(iInput2));
        for iBand1=p.BandMin:min(nBands(iInput1),p.BandMax)
            for iBand2=p.BandMin:min(nBands(iInput2),p.BandMax)                
                bootstrapCorrFun(:,iBand1,iBand2) = nanmean(corrFun(:,:,iBand1,iBand2),2);
                bootstrapSteCorrFun(:,iBand1,iBand2) = nanstd(corrFun(:,:,iBand1,iBand2),1,2);
            end
        end
    
        save(outFilePaths{iInput1,iInput2},'corrFun','bounds','lags',...
        'bootstrapCorrFun','bootstrapSteCorrFun');
    end
end

disp('Finished calculating correlation...')
if ishandle(wtBar), close(wtBar); end

