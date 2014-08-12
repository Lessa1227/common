classdef  BioFormatsReader < Reader
    % Concrete implementation of MovieObject for a single movie
    
    properties (Transient =true)
        formatReader
        series = 0;
    end
    
    methods
        %% Constructor
        function obj = BioFormatsReader(varargin)
            % Check loci-tools.jar is in the Java path
            bfCheckJavaPath();
            if isa(varargin{1}, 'loci.formats.IFormatReader'),
                obj.formatReader = varargin{1};
                obj.series = obj.formatReader.getSeries();
            else
                loci.common.DebugTools.enableLogging('OFF');
                obj.formatReader = bfGetReader(varargin{1}, false);
            end
            if nargin>1,
                obj.series = varargin{2};
                obj.formatReader.setSeries(obj.series);
            end
        end
        
        function metadataStore = getMetadataStore(obj)
            metadataStore = obj.formatReader.getMetadataStore();
        end
        
        function r = getReader(obj)
            r = obj.formatReader;
            r.setSeries(obj.getSeries());
        end
        
        function series = getSeries(obj)
            series = obj.series;
        end
        
        function sizeX = getSizeX(obj, varargin)
            sizeX = obj.getMetadataStore().getPixelsSizeX(obj.getSeries()).getValue();
        end
        
        function sizeY = getSizeY(obj, varargin)
            sizeY = obj.getMetadataStore().getPixelsSizeY(obj.getSeries()).getValue();
        end
        
        function sizeZ = getSizeZ(obj, varargin)
            sizeZ = obj.getMetadataStore().getPixelsSizeZ(obj.getSeries()).getValue();
        end
        
        function sizeT = getSizeT(obj, varargin)
            sizeT = obj.getMetadataStore().getPixelsSizeT(obj.getSeries()).getValue();
        end
        
        function sizeC = getSizeC(obj, varargin)
            sizeC = obj.getMetadataStore().getPixelsSizeC(obj.getSeries()).getValue();
        end
        
        function bitDepth = getBitDepth(obj, varargin)
            pixelType = obj.getReader().getPixelType();
            bpp = loci.formats.FormatTools.getBytesPerPixel(pixelType);
            bitDepth = 8 * bpp;
        end
        
        function fileNames = getImageFileNames(obj, iChan, varargin)
            % Generate image file names
            usedFiles = obj.getReader().getUsedFiles(true);
            [~, fileName] = fileparts(char(usedFiles(1)));
            basename = sprintf('%s_s%g_c%d_t',fileName, obj.getSeries()+1, iChan);
            fileNames = arrayfun(@(t) [basename num2str(t, ['%0' num2str(floor(log10(obj.getSizeT))+1) '.f']) '.tif'],...
                1:obj.getSizeT,'Unif',false);
        end
        
        function channelNames = getChannelNames(obj, iChan)
            usedFiles = obj.getReader().getUsedFiles(true);
            [~, fileName, fileExt] = fileparts(char(usedFiles(1)));
            
            if obj.getReader().getSeriesCount() > 1
                base = [fileName fileExt ' Series ' num2str(obj.getSeries()+1) ' Channel '];
            else
                base = [fileName fileExt ' Channel '];
            end
            
            channelNames = arrayfun(@(x) [base num2str(x)], iChan, 'Unif',false);
        end
        
        function index = getIndex(obj, z, c, t)
            index = loci.formats.FormatTools.getIndex(obj.getReader(), z, c, t);
        end
        
        function I = loadImage(obj, c, t, varargin)
            
            ip = inputParser;
            ip.addRequired('c', @(x) isscalar(x) && ismember(x, 1 : obj.getSizeC()));
            ip.addRequired('t', @(x) isscalar(x) && ismember(x, 1 : obj.getSizeT()));
            ip.addOptional('z', 1, @(x) isscalar(x) && ismember(x, 1 : obj.getSizeZ()));
            ip.parse(c, t, varargin{:});
            
            % Using bioformat tools, get the reader and retrieve dimension order
            javaIndex =  obj.getIndex(ip.Results.z - 1, c - 1, t - 1);
            I = bfGetPlane(obj.getReader(), javaIndex + 1);
        end
        
        function I = loadStack(obj, c, t, varargin)
            
            ip = inputParser;
            ip.addRequired('c', @(x) isscalar(x) && ismember(x, 1 : obj.getSizeC()));
            ip.addRequired('t', @(x) isscalar(x) && ismember(x, 1 : obj.getSizeT()));
            ip.addOptional('z', 1 : obj.getSizeZ(), @(x) all(ismember(x, 1 : obj.getSizeZ())));
            ip.parse(c, t, varargin{:});
            
            %Get one plane to let reader determine variable class
            for iz = 1 : numel(ip.Results.z)
                I(:, :, iz) = obj.loadImage(c, t, ip.Results.z(iz));
            end
        end
        
        function delete(obj)
            obj.formatReader.close()
        end
    end
end