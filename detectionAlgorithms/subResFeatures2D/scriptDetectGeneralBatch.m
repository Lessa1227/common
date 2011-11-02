
%% define batch job locations

%image locations
imageDir = {...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench0/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench1/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench2/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench3/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench4/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench5/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench6/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench7/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench8/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench9/',...
    };

%file name bases
filenameBase = {...
    'im_',...
    'im_',...
    'im_',...
    'im_',...
    'im_',...
    'im_',...
    'im_',...
    'im_',...
    'im_',...
    'im_',...
    };

%directory for saving results
saveResDir = {...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench0/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench1/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench2/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench3/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench4/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench5/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench6/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench7/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench8/',...
    '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_8/tiffs/bench9/',...
    };

% %background image locations
% bgImageDir = {...
%     '/home/kj35/files/LCCB/receptors/Galbraiths/data/farnesylAndCellEdge/110829_Cs1C1_CHO_Farn/bg01/',...
%     '/home/kj35/files/LCCB/receptors/Galbraiths/data/farnesylAndCellEdge/110829_Cs1C2_CHO_Farn/bg01/',...
%     '/home/kj35/files/LCCB/receptors/Galbraiths/data/farnesylAndCellEdge/110829_Cs1C4_CHO_Farn/bg01/',...
%     '/home/kj35/files/LCCB/receptors/Galbraiths/data/farnesylAndCellEdge/110829_Cs2C1_CHO_Farn/bg01/',...
%     };
% 
% %background file name bases
% bgFilenameBase = {...
%     'crop_110829_Cs1C1_CHO_mEos2Farn_',...
%     'crop_110829_Cs1C2_CHO_mEos2Farn_',...
%     'crop_110829_Cs1C4_CHO_mEos2Farn_',...
%     'crop_110829_Cs2C1_CHO_mEos2Farn_',...
%     };

%% calculate number of movies
numMovies = length(filenameBase);

for iMovie = 1 : numMovies
    
    try
        
        %display movie number
        disp(['Movie ' num2str(iMovie) ' / ' num2str(numMovies) ' ...'])
        
        %% movie information
        movieParam.imageDir = imageDir{iMovie}; %directory where images are
        movieParam.filenameBase = filenameBase{iMovie}; %image file name base
        movieParam.firstImageNum = 1; %number of first image in movie
        movieParam.lastImageNum = 50; %number of last image in movie
        movieParam.digits4Enum = 4; %number of digits used for frame enumeration (1-4).
        
        %% detection parameters
        detectionParam.psfSigma = 1.85; %point spread function sigma (in pixels)
        detectionParam.testAlpha = struct('alphaR',0.01,'alphaA',0.25,'alphaD',0.01,'alphaF',0); %alpha-values for detection statistical tests
        detectionParam.visual = 0; %1 to see image with detected features, 0 otherwise
        detectionParam.doMMF = 1; %1 if mixture-model fitting, 0 otherwise
        detectionParam.bitDepth = 16; %Camera bit depth
        detectionParam.alphaLocMax = 0.25; %alpha-value for initial detection of local maxima
        detectionParam.numSigmaIter = 0; %maximum number of iterations for PSF sigma estimation
        detectionParam.integWindow = 0; %number of frames before and after a frame for time integration
        
%         %background info ...
%         background.imageDir = bgImageDir{iMovie};
%         background.filenameBase = bgFilenameBase{iMovie};
%         background.alphaLocMaxAbs = 0.01;
%         detectionParam.background = background;
        
        %% save results
        saveResults.dir = saveResDir{iMovie}; %directory where to save input and output
        saveResults.filename = 'detectionAll5.mat'; %name of file where input and output are saved
        %         saveResults = 0;
        
        %% run the detection function
        [movieInfo,exceptions,localMaxima,background,psfSigma] = ...
            detectSubResFeatures2D_StandAlone(movieParam,detectionParam,saveResults);
        
    catch %#ok<CTCH>
        disp(['Movie ' num2str(iMovie) ' failed!']);
    end
    
end



%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench0/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench1/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench2/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench3/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench4/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench5/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench6/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench7/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench8/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench9/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench0/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench1/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench2/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench3/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench4/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench5/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench6/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench7/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench8/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench9/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench0/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench1/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench2/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench3/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench4/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench5/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench6/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench7/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench8/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench9/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench0/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench1/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench2/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench3/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench4/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench5/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench6/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench7/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench8/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench9/',...
% 
% 
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
%     'im_',...
% 
% 
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench0/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench1/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench2/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench3/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench4/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench5/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench6/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench7/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench8/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_30/tiffs/bench9/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench0/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench1/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench2/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench3/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench4/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench5/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench6/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench7/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench8/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_20/tiffs/bench9/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench0/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench1/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench2/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench3/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench4/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench5/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench6/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench7/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench8/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_15/tiffs/bench9/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench0/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench1/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench2/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench3/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench4/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench5/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench6/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench7/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench8/',...
%     '/home/kj35/files/LCCB/receptors/codeTesting/Olivo-Marin/trackingPerformanceEvaluation/synthetic/amplitude_10/tiffs/bench9/',...
