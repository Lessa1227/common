classdef SegmentationProcess < Process
% A concrete process for mask process info
    properties (SetAccess = private, GetAccess = public)
    % SetAccess = private - cannot change the values of variables outside object
    % GetAccess = public - can get the values of variables outside object without
    % definging accessor functions
       maskPaths_

    end
    
    methods (Access = public)
        function obj = SegmentationProcess (owner,name,funName, funParams,...
                        maskPaths)
           % Constructor of class SegmentationProcess
           if nargin == 0
              super_args = {};
           else
               super_args{1} = owner;
               super_args{2} = name;                
           end
           % Call the superclass constructor - these values are private
           obj = obj@Process(super_args{:});
           if nargin > 2
               obj.funName_ = funName;               
           end
           if nargin > 3
              obj.funParams_ = funParams;              
           end
           if nargin > 4               
              if ~isempty(maskPaths) && numel(maskPaths) ...
                      ~= numel(owner.channelPath_) || ~iscell(maskPaths)
                 error('lccb:set:fatal','Mask paths must be a cell-array of the same size as the number of image channels!\n\n'); 
              end
              obj.maskPaths_ = maskPaths;              
           else
               obj.maskPaths_ = cell(1,numel(owner.channelPath_));               
           end
        end
        function sanityCheck(obj) % throw exception
            % Sanity Check
            disp('Sanity check passes');
            % Check mask path for each channel
            % ... ...
        end
        function setMaskPath(obj,chanNum,maskPath)           
            if isnumeric(chanNum) && chanNum > 0 && ...
                    chanNum <= numel(obj.owner_.channelPath_)
                obj.maskPaths_{chanNum} = maskPath;
            else
                error('lccb:set:fatal','Invalid mask channel number for mask path!\n\n'); 
            end
        end
        function fileNames = getMaskFileNames(obj,iChan)
            if isnumeric(iChan) && min(iChan)>0 && max(iChan) <= ...
                    numel(obj.owner_.channelPath_) && isequal(round(iChan),iChan)                
                fileNames = cellfun(@(x)(imDir(x)),obj.maskPaths_(iChan),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nIm = cellfun(@(x)(length(x)),fileNames);
                if ~all(nIm == obj.owner_.nFrames_)                    
                    error('Incorrect number of masks found in one or more channels!')
                end                
            else
                error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end    
            
            
        end
    end
    methods (Static)
        function text = getHelp(obj)
           text = 'This process will create masks for the selected movie channels. These masks will be saved to a directory specified by the user as binary .tif files.'; 
        end
    end
end