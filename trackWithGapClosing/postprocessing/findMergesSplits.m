function [mergesInfo,splitsInfo,mergesInfoSpace,splitsInfoSpace] = ...
    findMergesSplits(tracks,probDim,removePotArtifacts,plotRes,figureName,...
    image)
%FINDMERGESSPLITS finds the merges and splits in each track and gives back their location
%
%SYNOPSIS [mergesInfo,splitsInfo,mergesInfoSpace,splitsInfoSpace] = ...
%    findMergesSplits(tracks,probDim,removePotArtifacts,plotRes,figureName,...
%    image)
%
%INPUT  tracks    : Output of trackCloseGapsKalman:
%                   Structure array with number of entries equal to
%                   the number of tracks (or compound tracks when
%                   merging/splitting are considered). Contains the
%                   fields:
%           .tracksCoordAmpCG: The positions and amplitudes of the tracked
%                              features, after gap closing. Number of rows
%                              = number of track segments in compound
%                              track. Number of columns = 8 * number of 
%                              frames the compound track spans. Each row
%                              consists of 
%                              [x1 y1 z1 a1 dx1 dy1 dz1 da1 x2 y2 z2 a2 dx2 dy2 dz2 da2 ...]
%                              NaN indicates frames where track segments do
%                              not exist.
%           .seqOfEvents     : Matrix with number of rows equal to number
%                              of events happening in a track and 4
%                              columns:
%                              1st: Frame where event happens;
%                              2nd: 1 - start of track, 2 - end of track;
%                              3rd: Index of track segment that ends or starts;
%                              4th: NaN - start is a birth and end is a death,
%                                   number - start is due to a split, end
%                                   is due to a merge, number is the index
%                                   of track segment for the merge/split.
%       probDim   : 2 for 2D, 3 for 3D. Optional. Default: 2.
%       removePotArtifacts: 1 to remove potentially artifactual merges and
%                   splits, resulting for instance from detection
%                   artifact, 0 otherwise. 
%                   Optional. Default: 1.
%       plotRes   : 0 to not plot anything, 1 to make a spatial map of
%                   merges and splits (in cyan and magenta, respectively).
%                   Optional. Default: 0.
%       figureName: Figure name.
%       image     : Image to overlay spatial map on.
%                   Optional. Default: [].
%
%OUTPUT mergesInfo     : 2D array where first column indicates track number,
%                        second column indicates track type (1 linear, 0 o.w.),
%                        third column indicates number of merges, and 
%                        subsequent columns indicate merge times.
%       splitsInfo     : 2D array where first column indicates track number,
%                        second column indicates track type (1 linear, 0 o.w.),
%                        third column indicates number of splits, and 
%                        subsequence columns indicate split times.
%       mergesInfoSpace: 2D array that is a continuation of mergesInfoTime,
%                        storing the (x,y,[z])-coordinates of each merge.
%                        Every row corresponds to the same row in
%                        mergesInfo. Every merge gets 2 (in 2D) or 3 (in
%                        3D) columns for x, y and z (if 3D).
%       splitsInfoSpace: 2D array that is a continuation of splitsInfoTime,
%                        storing the (x,y,[z])-coordinates of each split.
%                        Every row corresponds to the same row in
%                        splitsInfo. Every split gets 2 (in 2D) or 3 (in
%                        3D) columns for x, y and z (if 3D).
%
%
%REMARKS Plotting implemented for 2D only.
%
%Khuloud Jaqaman, October 2007

%% Input

%check whether correct number of input arguments was used
if nargin < 1
    disp('--findMergesSplits: Incorrect number of input arguments!');
    return
end

if nargin < 2 || isempty(probDim)
    probDim = 2;
end

if nargin < 3 || isempty(removePotArtifacts)
    removePotArtifacts = 1;
end

if nargin < 4 || isempty(plotRes)
    plotRes = 0;
end

%get number of tracks
numTracks = length(tracks);

%get number of segments per track
numSegments = getNumSegmentsPerTrack(tracksFinal);

%estimate track types
trackType = getTrackType(tracks,probDim);

%% Merge/split statistics

[mergesInfo,splitsInfo] = deal(zeros(numTracks,max(numSegments)));
[mergesInfoSpace,splitsInfoSpace] = deal(repmat(mergesInfo,1,3));

%go over all tracks ...
for iTrack = 1 : numTracks
    
    %get track's sequence of events
    seqOfEvents = tracks(iTrack).seqOfEvents;
    
    %get track's coordinates
    trackCoordX = tracks(iTrack).tracksCoordAmpCG(:,1:8:end);
    trackCoordY = tracks(iTrack).tracksCoordAmpCG(:,2:8:end);
    trackCoordZ = tracks(iTrack).tracksCoordAmpCG(:,3:8:end);
    
    %find rows with merging information
    indxMerge = find( seqOfEvents(:,2)==2 & ~isnan(seqOfEvents(:,4)) );
    
    %get the merge times
    mergeTimes = seqOfEvents(indxMerge,1);
    
    %get the track segments that are merged with
    mergeSegment = seqOfEvents(indxMerge,4);
    
    %get the coordinates of each merge
    mergeCoords = [];
    for iMerge = indxMerge'
        mergeCoords = [mergeCoords ...
            trackCoordX(mergeSegment(iMerge),mergeTimes(iMerge)) ...
            trackCoordY(mergeSegment(iMerge),mergeTimes(iMerge)) ...
            trackCoordZ(mergeSegment(iMerge),mergeTimes(iMerge))]; %#ok<AGROW>
    end
    
    %store the merge information for this track
    mergesInfo(iTrack,1:length(mergeTimes)+2) = [trackType(iTrack) ...
        length(mergeTimes) mergeTimes'];
    mergesInfoSpace(iTrack,1:3*length(mergeTimes)) = mergeCoords;
        
    %find rows with splitting information
    indxSplit = find( seqOfEvents(:,2)==1 & ~isnan(seqOfEvents(:,4)) );
    
    %get split times
    splitTimes = seqOfEvents(indxSplit,1);

    %get the track segments that are split from
    splitSegment = seqOfEvents(indxSplit,4);
    
    %get the coordinates of each merge
    splitCoords = [];
    for iSplit = indxSplit'
        splitCoords = [splitCoords ...
            trackCoordX(splitSegment(iSplit),splitTimes(iSplit)-1) ...
            trackCoordY(splitSegment(iSplit),splitTimes(iSplit)-1) ...
            trackCoordZ(splitSegment(iSplit),splitTimes(iSplit)-1)]; %#ok<AGROW>
    end
    
    %store the split information for this track
    splitsInfo(iTrack,1:length(splitTimes)+2) = [trackType(iTrack) ...
        length(splitTimes) splitTimes'];
    splitsInfoSpace(iTrack,1:3*length(splitTimes)) = splitCoords;

end

%remove empty columns
fullIndx = find(sum(mergesInfo(:,2:end))~=0);
mergesInfo = [mergesInfo(:,1) mergesInfo(:,1+fullIndx)];
fullIndx = sum(mergesInfoSpace)~=0;
mergesInfoSpace = mergesInfoSpace(:,fullIndx);
fullIndx = find(sum(splitsInfo(:,2:end))~=0);
splitsInfo = [splitsInfo(:,1) splitsInfo(:,1+fullIndx)];
fullIndx = sum(splitsInfoSpace)~=0;
splitsInfoSpace = splitsInfoSpace(:,fullIndx);

%remove rows without merges or splits
filledRows = find(any(mergesInfo(:,2)~=0,2));
mergesInfo = [filledRows mergesInfo(filledRows,:)];
mergesInfoSpace = mergesInfoSpace(filledRows,:);
filledRows = find(any(splitsInfo(:,2)~=0,2));
splitsInfo = [filledRows splitsInfo(filledRows,:)];
splitsInfoSpace = splitsInfoSpace(filledRows,:);

%% Plotting

if plotRes
    
    %make new figure
    if isempty(figureName)
        figure
    else
        figure('Name',figureName)
    end
    hold on
    
    %plot the image to overlay the spatial map on, if given
    if ~isempty(image)
        imshow(image,[]);
    else
        imshow(ones(maxYCoord,maxXCoord),[]);
    end
    
    %set figure axes limits
    axis([minXCoord maxXCoord minYCoord maxYCoord]);
    
    %show coordinates on axes
    axH = gca;
    set(axH,'visible','on');
    
    %label axes
    xlabel('x-coordinate (pixels)');
    ylabel('y-coordinate (pixels)');
    
    switch probDim
        case 2
            
            %get coordinates of merges
            xCoord = mergesInfoSpace(:,1:2:end);
            xCoord = xCoord(:);
            yCoord = mergesInfoSpace(:,2:2:end);
            yCoord = yCoord(:);
            
            %keep only non-zero entries
            indxKeep = find( xCoord~=0 & yCoord~=0 );
            xCoord = xCoord(indxKeep);
            yCoord = yCoord(indxKeep);
            
        case 3
    end
    
end


%% %%%%% ~~ the end ~~ %%%%%

