classdef TestParArrayfun_progress < TestParCellfun_progress
    %TestArrayfun_progress Tests function pararrayfun_progress
    
    properties
    end
    
    methods
        function self = TestParArrayfun_progress(name)
            self = self@TestParCellfun_progress(name);
            self.func = @pararrayfun_progress;
            self.nonparfunc = @arrayfun;
        end
        function setUp(self,A,B)
            self.pool = gcp('nocreate');
            if(isempty(self.pool))
                self.pool = parpool(3);
            end
            if(nargin < 2)
                self.A = 1:10;
            else
                self.A = A;
            end
            if(nargin < 3)
                self.B = randi(10,1,10);
            else
                self.B = B;
            end
        end
        function testInputVersusParam(self)
            out = self.func(@self.identity,'UniformOutput');
            assertEqual(out,'UniformOutput');
            out = self.func(@self.identity,'UniformOutput','UniformOutput',false);
            assertEqual(out,num2cell('UniformOutput'));
        end
    end
    
end

