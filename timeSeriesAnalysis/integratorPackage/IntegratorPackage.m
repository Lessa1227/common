classdef IntegratorPackage < Package
    % The main class of the Integrator package
    
    % Sebastien Besson, Sep 2011
    
    methods
        function obj = IntegratorPackage(owner,outputDir)
            % Constructor of class QFSMPackage
            
            if nargin == 0
                super_args = {};
            else
                % Owner: MovieData object
                super_args{1} = owner;
                super_args{2} = [outputDir  filesep 'IntegratorPackage'];
            end
            
            % Call the superclass constructor
            obj = obj@Package(super_args{:});
        end
        
        function [status processExceptions] = sanityCheck(obj,varargin)
            % Check that the frame rate is present
%             if isempty(obj.owner_.timeInterval_)
%                 error('Missing frame rate! Please fill the time interval!');
%             end
            [status processExceptions] = sanityCheck@Package(obj,varargin{:});
        end
        
    end
    
    methods (Static)
        
        function m = getDependencyMatrix(i,j)
            
            m = [0 0 0; %1 CorrelationCalculationProcess
                1 0 0;  %2 CorrelationBootstrappingProcess
                0 0 0;];%3 EventAlignerProcess
            
            if nargin<2, j=1:size(m,2); end
            if nargin<1, i=1:size(m,1); end
            m=m(i,j);
        end
        
        function name = getName()
            if any(strcmp(getenv('USERNAME'),{'mv89','sb286'}))
                name = 'Hey dude! This is the ultimate integrator';
            else
                name='Integrator';
            end
        end
        
        function varargout = GUI(varargin)
            % Start the package GUI
            varargout{1} = integratorPackageGUI(varargin{:});
        end
        
        function procConstr = getDefaultProcessConstructors(index)
            integratorProcConstr = {
                @CorrelationCalculationProcess,...
                @CorrelationBootstrappingProcess,...
                @EventAlignerProcess};
            
            if nargin==0, index=1:numel(integratorProcConstr); end
            procConstr=integratorProcConstr(index);
        end
        function classes = getProcessClassNames(index)
            integratorClasses = {
                'CorrelationCalculationProcess',...
                'CorrelationBootstrappingProcess',...
                'EventAlignerProcess'};
            if nargin==0, index=1:numel(integratorClasses); end
            classes=integratorClasses(index);
        end
    end
end