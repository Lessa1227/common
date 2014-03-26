function BA_output_cell = branch_analysis_movieList(ML)
% function to do branch analysis for a whole movielist
% Liya Ding, March, 2014
%
% Input:
%   ML:     The movieList object loaded before running this function

% the number of movies
movieNumber =  length(ML.movieDataFile_);
BA_output_cell= cell(1,1);

for iM  = 1 :movieNumber
    % load this movie
    load(ML.movieDataFile_{iM});
    % the number of channels
    nChannel = length(MD.channels_);
    for iChannel = 1 : nChannel        
        ROOT_DIR = MD.outputDirectory_;        
        for iCell = 1 : 10
            % the folder name if there is marking
            truthPath = [ROOT_DIR,'\SegmentationPackage\FixedChannel',num2str(iChannel),'Cell',num2str(iCell)];
            % check if this folder exist
            if(exist(truthPath,'dir'))
                % if it exist, try to do the branch analysis
                try
                    BA_output = branch_analysis_marked_cell(MD, iChannel, iCell);
                    % for the output, ignore the channel number since
                    % there is only one channel marked.
                    BA_output_cell{iM, iCell} = BA_output;
                end
            end
        end        
    end
end