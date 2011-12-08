classdef CorrelationGraphDisplay < MovieDataDisplay
    %Concreate display class for displaying points or lines
    properties
        Marker = 'none';
        LineStyle = '-';
        LineWidth = 2;
        Color='r';
        Input1 ='';
        Input2 ='';
        sfont = {'FontName', 'Helvetica', 'FontSize', 18};
        lfont = {'FontName', 'Helvetica', 'FontSize', 22};
    end
    properties (SetAccess = protected)
        bands;
    end
    methods
        function obj=CorrelationGraphDisplay(varargin)
            obj@MovieDataDisplay(varargin{:});
        end
        function h=initDraw(obj,data,tag,varargin)
            
            nBands = size(data.avgCorrFun,2);
            colors = hsv(nBands);
            
            % Plot data
            h=-ones(nBands,2);
            for i=1:nBands
                h(i,1)=plot(data.lags(:,i),data.avgCorrFun(:,i),'Line',obj.LineStyle,...
                    'LineWidth',obj.LineWidth,'Color',colors(i,:));
                hold on
                h(i,2)=errorbar(data.lags(:,i),data.avgCorrFun(:,i),data.steCorrFun(:,i),...
                    'LineWidth', 2,'Color',colors(i,:));
            end
            %             if ~isempty(data.avgBounds)
            %                 upline  = repmat(data.avgBounds(1,:),nx,1);
            %                 h(3)=plot(data.lags,upline,'Linewidth',2,'Color','r');
            %
            %                 dline  = repmat(data.avgBounds(2,:),nx,1);
            %                 h(4)=plot(data.lags,dline,'Linewidth',2,'Color','r');
            %             end
            set(h,'Tag',tag);
            
            % Set axis options
            xLim=[min(data.lags(:)) max(data.lags(:))];
            yLim =[min(data.avgCorrFun(:)-data.steCorrFun(:)) max(data.avgCorrFun(:)+data.steCorrFun(:))];
            xlabel('Lag (s)',obj.lfont{:})
            if min(data.lags(:))==0
                ylabel('Autocorrelation',obj.lfont{:})
            else
                ylabel('Cross-correlation',obj.lfont{:})
            end
            set(gca, 'LineWidth', 1.5, obj.sfont{:},'XLim',xLim,'YLim',yLim);
            
            % Add arrow for cross-correlation graphs
            if min(data.lags(:))<0
                pos = get(gca,'Position');
                annotation('arrow',[pos(1)+pos(3)/2-pos(3)/100 pos(1)+pos(3)/100],...
                    [pos(2)+pos(4)/100 pos(2)+pos(4)/100],'Linewidth',2);
                annotation('textbox',[pos(1)+pos(3)/10 pos(2)+pos(4)/100 ...
                    pos(3)/2 pos(4)/20],'String',['After ' obj.Input1],'EdgeColor','none',obj.sfont{:});
                annotation('arrow',[pos(1)+pos(3)/2+pos(3)/100 pos(1)+pos(3)-pos(3)/100],...
                    [pos(2)+pos(4)/100 pos(2)+pos(4)/100],'Linewidth',2);
                annotation('textbox',[pos(1)+6*pos(3)/10 pos(2)+pos(4)/100 ...
                    pos(3)/2 pos(4)/20],'String',['Before ' obj.Input1],'EdgeColor','none',obj.sfont{:});
            end
            
            % Create checkboxes if multiple bands
            axesPos = get(get(h(1),'Parent'),'Position');
            mainFig = get(get(h(1),'Parent'),'Parent');
            if nBands>1
                set(mainFig,'Toolbar','figure');
                axesRightPos = axesPos(1)+axesPos(3);
                bandPanel = uipanel(mainFig,...
                    'BackgroundColor',get(mainFig,'Color'),....
                    'BorderType','none',....
                    'Position',[axesRightPos axesPos(2) 1-axesRightPos axesPos(4)]);
                for i=1:nBands
                    obj.bands(i) = uicontrol(bandPanel,'Style','checkbox',...
                        'BackgroundColor',get(mainFig,'Color'),....
                        'Units','normalized','String',['Band ' num2str(i)],...
                        'ForegroundColor',colors(i,:),'Value',1,obj.sfont{:},...
                        'Position',[0 1-i/nBands 1 1/nBands],...
                        'Callback',@(hObject,event) updateDraw(obj,h,data));
                end
            end
        end
        
        function updateDraw(obj,h,data)
            nBands = size(data.avgCorrFun,2);
            if nBands>1
                states=logical(arrayfun(@(x) get(x,'Value'),obj.bands));
                set(h(states,:),'Visible','on');
                set(h(~states,:),'Visible','off');
            end
        end
        
    end
    
    methods (Static)
        function params=getParamValidators()
            params(1).name='Color';
            params(1).validator=@ischar;
            params(2).name='Marker';
            params(2).validator=@ischar;
            params(3).name='LineStyle';
            params(3).validator=@ischar;
            params(4).name='Input1';
            params(4).validator=@ischar;
            params(5).name='Input2';
            params(5).validator=@ischar;
            params(6).name='sfont';
            params(6).validator=@iscell;
            params(7).name='lfont';
            params(7).validator=@iscell;
        end
        
        function f=getDataValidator()
            f=@isstruct;
        end
    end
end