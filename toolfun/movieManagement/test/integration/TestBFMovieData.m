classdef TestBFMovieData < TestMovieData & TestCase
    
    properties
        fakename = 'test.fake';
        lociToolsPath
    end
    
    methods
        function self = TestBFMovieData(name)
            self = self@TestCase(name);
        end
        
        %% Set up and tear down methods
        function setUp(self)
            self.setUp@TestMovieData();
            
            % Get path to loci_tools (assuming it is in Matlab path)
            self.lociToolsPath = which('loci_tools.jar');
            assert(~isempty(self.lociToolsPath));
            
            % Remove loci_tools from dynamic class path
            if ismember(self.lociToolsPath,javaclasspath('-dynamic'))
                javarmpath(self.lociToolsPath);
            end
        end
        
        function tearDown(self)
            self.tearDown@TestMovieData();
            
            % Remove loci_tools from dynamic class path
            if ismember(self.lociToolsPath,javaclasspath('-dynamic'))
                javarmpath(self.lociToolsPath);
            end
            
            bfCheckJavaPath;
            r = loci.formats.in.FakeReader();
            self.imSize = [r.DEFAULT_SIZE_Y r.DEFAULT_SIZE_X];
            self.nChan = r.DEFAULT_SIZE_C;
            self.nFrames = r.DEFAULT_SIZE_T;
        end
        
        function setUpMovie(self)
            filename = fullfile(self.path, self.fakename);
            fid = fopen(filename, 'w');
            fclose(fid);
            
            self.movie = MovieData.load(filename);
        end
        
        function checkChannelPaths(self)
            for i = 1 : self.nChan
                assertEqual(self.movie.getChannel(i).channelPath_,...
                    fullfile(self.path, self.fakename))
            end
        end
        
        %% Typecasting tests
        function checkPixelType(self, classname)
            if strcmp(classname, 'single'),
                pixelsType = 'float';
            else
                pixelsType = classname;
            end
            self.fakename = ['test&pixelType=' pixelsType '.fake'];
            self.setUpMovie();
            I = self.movie.getChannel(1).loadImage(1);
            assertTrue(isa(I, classname));
        end
        
        function testINT8(self)
            self.checkPixelType('int8');
        end
        
        function testUINT8(self)
            self.checkPixelType('uint8');
        end
        
        function testINT16(self)
            self.checkPixelType('int16');
        end
        
        function testUINT16(self)
            self.checkPixelType('uint16');
        end
        
        function testUINT32(self)
            self.checkPixelType('uint32');
        end
        
        function testSINGLE(self)
            self.checkPixelType('single');
        end
        
        function testDOUBLE(self)
            self.checkPixelType('double');
        end
        
        %% Dimensions tests
        function testSizeX(self)
            self.fakename = 'test&sizeX=100.fake';
            self.imSize(2) = 100;
            self.setUpMovie()
            self.checkDimensions();
        end
        
        function testSizeY(self)
            self.fakename = 'test&sizeY=100.fake';
            self.imSize(1) = 100;
            self.setUpMovie()
            self.checkDimensions();
        end
        
        function testSizeZ(self)
            self.fakename = 'test&sizeZ=256.fake';
            self.setUpMovie()
            self.checkDimensions();
        end
        
        function testSizeC(self)
            self.fakename = 'test&sizeC=4.fake';
            self.nChan = 4;
            self.setUpMovie()
            self.checkDimensions();
        end
        
        function testSizeT(self)
            self.fakename = 'test&sizeT=256.fake';
            self.nFrames = 256;
            self.setUpMovie()
            self.checkDimensions();
        end
    end
end
