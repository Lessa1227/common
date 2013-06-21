classdef Channel < hgsetget
    %  Class definition of channel class
    
    properties
        excitationWavelength_       % Excitation wavelength (nm)
        emissionWavelength_         % Emission wavelength (nm)
        exposureTime_               % Exposure time (ms)
        imageType_                  % e.g. Widefield, TIRF, Confocal etc.
        fluorophore_=''               % Fluorophore / Dye (e.g. CFP, Alexa, mCherry etc.)
        
        % ---- Un-used params ---- %
        excitationType_             % Excitation type (e.g. Xenon or Mercury Lamp, Laser, etc)
        neutralDensityFilter_       % Neutral Density Filter
        incidentAngle_              % Incident Angle - for TIRF (degrees)
        filterType_                 % Filter Type
        hcsPlatestack_              % HCS plate file names stack
        hcsFlags_  % HCS plate well imaged indicator in cell one, 
        %HCS plate site indicator in second cell HCS plate wavelength names
        %in the third cell
    end
    
    properties(SetAccess=protected)
        psfSigma_                   % Standard deviation of the psf
        channelPath_                % Channel path (directory containing image(s))
        owner_                      % MovieData object which owns this channel
    end
    
    properties(Transient=true)
        displayMethod_  = ImageDisplay; % Method to display the object content
    end
    
    methods
        function obj = Channel(channelPath, varargin)
            % Constructor of channel object
            %
            % Input:
            %    channelPath (required) - the absolute path where the channel images are stored
            %
            %    'PropertyName',propertyValue - A string with an valid channel property followed by the
            %    value.
            
            if nargin>0                
                % Construct the Channel object
                nVarargin = numel(varargin);
                if nVarargin > 1 && mod(nVarargin,2)==0
                    for i=1 : 2 : nVarargin-1
                        obj.(varargin{i}) = varargin{i+1};
                    end
                end
                
                if obj.hcsPlatestack_ == 1
                    [wellf, sitef, waveln,hcsPlatestack] = readIXMHTDFile(channelPath);
                    file_lists = dir(fullfile(channelPath, '*.TIF'));
                    if length(file_lists) ~= size(hcsPlatestack{1},1)*size(hcsPlatestack{1},2)*length(hcsPlatestack{1}{1,1})*length(waveln) ||...
                            strcmp(hcsPlatestack{1}{1,1}{1}(1:5),file_lists(2).name(1:5)) ~= 1
                        warndlg('File Miss Match!, rebuilding plate stack...');
                    [hcsPlatestack] = HCSplatestack(channelPath);
                    end
                    if isempty(hcsPlatestack)
                        h = errordlg('No HCS data detected, please uncheck HCS data box');
                        return;
                    end
                    for ich = 1:size(hcsPlatestack, 2)
                        obj(ich).channelPath_ = channelPath;
                        obj(ich).hcsPlatestack_ = hcsPlatestack{ich};
                        obj(ich).hcsFlags_.wellF = wellf;
                        obj(ich).hcsFlags_.siteF = sitef;
                        obj(ich).hcsFlags_.wN = waveln(ich);
                        %obj(ich).hcsFlags_.startI = starti;
                        %obj(ich).hcsFlags_.swI = startsw;
                    end
                else
                    obj.channelPath_ = channelPath;
                end
            end
        end
        
        %% Set / Get Methods
        function set.excitationWavelength_(obj, value)
            obj.checkPropertyValue('excitationWavelength_',value);
            obj.excitationWavelength_=value;
        end
        
        function set.emissionWavelength_(obj, value)
            obj.checkPropertyValue('emissionWavelength_',value);
            obj.emissionWavelength_=value;
        end
        
        function set.exposureTime_(obj, value)
            obj.checkPropertyValue('exposureTime_',value);
            obj.exposureTime_=value;
        end
        
        function set.excitationType_(obj, value)
            obj.checkPropertyValue('excitationType_',value);
            obj.excitationType_=value;
        end
        
        function set.neutralDensityFilter_(obj, value)
            obj.checkPropertyValue('neutralDensityFilter_',value);
            obj.neutralDensityFilter_=value;
        end
        
        function set.incidentAngle_(obj, value)
            obj.checkPropertyValue('incidentAngle_',value);
            obj.incidentAngle_=value;
        end
        
        function set.imageType_(obj, value)
            obj.checkPropertyValue('imageType_',value);
            obj.imageType_=value;
        end
        
        function set.filterType_(obj, value)
            obj.checkPropertyValue('filterType_',value);
            obj.filterType_=value;
        end
        
        function set.fluorophore_(obj, value)
            obj.checkPropertyValue('fluorophore_',value);
            obj.fluorophore_=value;
        end
        
        
        function setFig = edit(obj)
            setFig = channelGUI(obj);
        end
        
        function relocate(obj,oldRootDir,newRootDir)
            % Relocate location of the  channel object
            obj.channelPath_=  relocatePath(obj.channelPath_,oldRootDir,newRootDir);
        end
        
        function checkPropertyValue(obj,property, value)
            % Check if a property/value pair can be set up
            
            % Return if unchanged property
            if isequal(obj.(property),value), return; end
            propName = regexprep(regexprep(property,'(_\>)',''),'([A-Z])',' ${lower($1)}');
            
            % Test if the property is writable
            assert(obj.checkProperty(property),'lccb:set:readonly',...
                ['The channel''s ' propName ' has been set previously and cannot be changed!']);
            
            % Test if the supplied value is valid
            assert(obj.checkValue(property,value),'lccb:set:invalid',...
                ['The supplied ' propName ' is invalid!']);
        end
        
        
        function status = checkProperty(obj,property)
            % Returns true/false if the non-empty property is writable
            status = isempty(obj.(property));
            if status, return; end
            
            if strcmp(property,'channelPath_');
                stack = dbstack;
                if any(cellfun(@(x)strcmp(x,'Channel.relocate'),{stack.name})),
                    status  =true;
                end
            end
        end
        
        %---- Sanity Check ----%
        %Verifies that the channel specification is valid, and returns
        %properties of the channel
        
        function [width height nFrames] = sanityCheck(obj,varargin)
            % Check the sanity of the channels
            %
            % Check the validity of each channel and return pixel size and time
            % interval parameters
            
            % Check input
            ip = inputParser;
            ip.addOptional('owner',obj.owner_,@(x) isa(x,'MovieData'));
            ip.parse(varargin{:})
            
            % Set the channel owner
            if isempty(obj.owner_), obj.owner_=ip.Results.owner; end
            assert(isequal(obj.owner_,ip.Results.owner) ||...
                isequal(obj.owner_,ip.Results.owner.parent_),...
                'The channel''s owner is not the movie neither its parent')
            
            % Get the size along the X,Y and T dimensions
            width = obj.getReader().getSizeX(obj.getChannelIndex());
            height = obj.getReader().getSizeY(obj.getChannelIndex());
            nFrames = obj.getReader().getSizeT(obj.getChannelIndex());
            
            if isempty(obj.psfSigma_) && ~isempty(obj.owner_), obj.calculatePSFSigma(); end
        end
        
        function iChan = getChannelIndex(obj)
            if ~isempty(obj.owner_)
                iChan = find(obj.owner_.channels_ == obj, 1);
            else
                iChan = 1;
            end
        end
        
        function fileNames = getImageFileNames(obj,iFrame)
            
            fileNames = obj.getReader.getImageFileNames(obj.getChannelIndex());
            if nargin>1, fileNames=fileNames(iFrame); end
        end
        
        function Gname = getGenericName(obj, oFileName, flag) %oFileName is either from getImagesFiles or from hcsplatestack
%             starti = obj.hcsFlags_.startI;
%             startsw = obj.hcsFlags_.swI;   
            [starti, startsw] = getindexstart(oFileName);
            if min(abs(str2double(oFileName(min(startsw)+2))-(0:9))) == 0
                adi = 1;
            else
                adi = 0;
            end
            if nargin > 2 && strcmp(flag, 'well_on') == 1
            Gname = oFileName(starti:max(startsw)+adi);
            elseif nargin > 2 && strcmp(flag, 'site_on') == 1
                Gname = oFileName(starti:min(startsw)+1+adi);
            else
                Gname = oFileName(starti:starti+2);
            end           
        end
        
        function I = loadImage(obj, iFrame)
            
            % Initialize image
            I = obj.getReader().loadImage(obj.getChannelIndex(), iFrame);
        end
        
        %% Bio-formats/OMERO functions
        function status = isOmero(obj)
            status = ~isempty(obj.owner_) && obj.owner_.isOmero();
        end
        
        function status = isBF(obj)
            status = ~isempty(obj.owner_) && obj.owner_.isBF();
        end
        
        function r = getReader(obj)
            if ~isempty(obj.owner_),
                r = obj.owner_.getReader();
            elseif ~isempty(obj.hcsPlatestack_),
                    r = HCSReader(obj);                    
            else
                r = TiffSeriesReader({obj.channelPath_});
            end
        end
        
        
        %% Display functions
        function color = getColor(obj)
            if ~isempty(obj.emissionWavelength_),
                color = wavelength2rgb(obj.emissionWavelength_*1e-9);
            else
                color =[1 1 1]; % Set to grayscale by default
            end
        end
        
        function h = draw(obj,iFrame,varargin)
            
            % Input check
            ip = inputParser;
            ip.addRequired('obj',@(x) isa(x,'Channel') || numel(x)<=3);
            ip.addRequired('iFrame',@isscalar);
            ip.addParamValue('hAxes',gca,@ishandle);
            ip.KeepUnmatched = true;
            ip.parse(obj,iFrame,varargin{:})
            
            % Initialize output
            if numel(obj)>1, zdim=3; else zdim=1; end
            data = zeros([obj(1).owner_.imSize_ zdim]);
            
            % Fill output
            for iChan=1:numel(obj)
                data(:,:,iChan)=mat2gray(obj(iChan).loadImage(iFrame));
            end
            drawArgs=reshape([fieldnames(ip.Unmatched) struct2cell(ip.Unmatched)]',...
                2*numel(fieldnames(ip.Unmatched)),1);
            h = obj(1).displayMethod_.draw(data,'channels','hAxes',ip.Results.hAxes,drawArgs{:});
        end
    end
    
    methods(Access=protected)
        function calculatePSFSigma(obj)
            % Read parameters for psf sigma calculation
            emissionWavelength=obj.emissionWavelength_*1e-9;
            numAperture=obj.owner_.numAperture_;
            pixelSize=obj.owner_.pixelSize_*1e-9;
            if isempty(emissionWavelength) || isempty(numAperture) || isempty(pixelSize),
                return;
            end
            
            obj.psfSigma_ = getGaussianPSFsigma(numAperture,1,pixelSize,emissionWavelength);
            % obj.psfSigma_ =.21*obj.emissionWavelength/(numAperture*pixelSize);
            
        end
    end
    methods(Static)
        function status=checkValue(property,value)
            % Return true/false if the value for a given property is valid
            
            % Parse input
            ip = inputParser;
            ip.addRequired('property',@(x) ischar(x) || iscell(x));
            ip.parse(property);
            if iscell(property)
                ip.addRequired('value',@(x) iscell(x)&&isequal(size(x),size(property)));
                ip.parse(property,value);
                status=cellfun(@(x,y) Channel.checkValue(x,y),property,value);
                return
            end
            
            % Get validator for single property
            validator=Channel.getPropertyValidator(property);
            propName = regexprep(regexprep(property,'(_\>)',''),'([A-Z])',' ${lower($1)}');
            assert(~isempty(validator),['No validator defined for property ' propName]);
            
            % Return result of validation
            status = isempty(value) || validator(value);
        end
        
        function validator = getPropertyValidator(property)
            switch property
                case {'emissionWavelength_','excitationWavelength_'}
                    validator=@(x) isscalar(x) && x>=300 && x<=800;
                case 'exposureTime_'
                    validator=@(x) isscalar(x) && x>0;
                case {'excitationType_','notes_','channelPath_','filterType_'}
                    validator=@ischar;
                case 'imageType_'
                    validator = @(x) ischar(x) && ismember(x,Channel.getImagingModes);
                case {'fluorophore_'}
                    validator= @(x) ischar(x) && ismember(x,Channel.getFluorophores);
                otherwise
                    validator=[];
            end
            
        end
        
        function modes=getImagingModes()
            modes={'Widefield';'TIRF';'Confocal'};
        end
        
        function fluorophores=getFluorophores()
            fluorPropStruct= getFluorPropStruct();
            fluorophores={fluorPropStruct.name};
        end
    end
end
