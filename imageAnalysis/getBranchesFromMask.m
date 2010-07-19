function branches = getBranchesFromMask(maskIn,maxRadius,smSig,isoVal)
%GETBRANCHESFROMMASK extracts the location and properties of branches in the input mask by radius criteria 
% 
% branches = getBranchesFromMask(maskIn)
% 
% branches = getBranchesFromMask(maskIn,maxRadius,smSig,isoVal)
% 
% This function is designed to analyze the structure of cells migrating in
% 3D which have been segmented to create a 3D binary mask matrix. The
% basic branch structure is determined via skeletonization. However this
% often returns many false-positive branches which result from small bumps
% on the surface of the mask. These false positives are minimized in
% two ways. First, the tip of every branch is located and the average
% curvature of the surface near this tip is calculated. If the surface is
% too flat near this tip, the branch is removed. Second, the depth of the
% start point of the branch within the cell-body is calculated. If the
% start point is too deep, the branch is removed.
% Additionally, various properties of the branches are calculated and
% returned in the output structure.
%
% Input:
% 
%   maskIn - A 3D, logical matrix containing the cell mask.
% 
%   maxRadius - The maximum radius (in voxels) of an object to consider a
%   branch. Parts of the mask with radius larger than this will be not be
%   considered branches.
% 
%   smoothSigma - The sigma, in voxels, of the gaussian filter to use when
%   smoothing the mask surface for curvature calculations. (The skeleton is
%   calculated from the original, un-smoothed mask).
% 
%   isoVal - The value to threshold the smoothed mask at to extract the
%   smoothed mask surface.1/2 will best preserve size/volume of the
%   original object, though a lower value will better preserve object
%   topology, preventing small branches from being smoothed away.
% 
% 
% Output:
% 
%   branches - A structure containing the locations and properties of the
%   detected branches.
%       Fields include:
% 
%   
%
% Hunter Elliott
% 7/2010
%

%% ---- Input ----- %%

if nargin < 1 || isempty(maskIn) || ~islogical(maskIn) || ndims(maskIn) ~= 3
    error('You must at least input a 3D, binary mask as the first argument!')
end

if nargin <2 || isempty(maxRadius)    
    maxRadius = 10; %Maximum radius (in voxels) of an object to consider a branch.
end

if nargin < 3 || isempty(smSig)
    smSig = 1; %Sigma in pixels of filter used for smoothing mask before 
               %surface curvature calculations.
end

if nargin < 4 || isempty(isoValue)
    isoVal = .25; %Value to use for isosurface of mask. 
                  %1/2 will best preserve size/volume of the original
                  %object, though a lower value will better preserve object
                  %topology, preventing small branches from being smoothed
                  %away.
end

%% ----- Parameters ----- %%

showPlots = true; %Determines whether plots showing the branch locations 
                   %and smoothed mask surface will be shown.
gcThresh = 1/maxRadius^2;%#ok<NASGU> %Gaussian curvature value to threshold 
                         %at for detecting branch ends. This corresponds to
                         %the curvature of a sphere of radius maxRadius
mcThresh = -1/maxRadius; %Mean curvature value to threshold at
searchRad = 5; %radius to allow consideration of surface points for 
               %branch-tip curvature calcs. The curvature of any surface
               %points closer than this will be averaged to calculate the
               %branch-tip curvature.

%% ------- Pre- Processing ------ %%

%Remove mask pixels at the border of the image. These will cause problems
%with skeletonization and surface extraction.
maskIn([1 end],:,:) = false;
maskIn(:,[1 end],:) = false;
maskIn(:,:,[1 end]) = false;

%% ---- Surface Extraction ---- %%
%Calculates a polygonal mesh representing the smoothed mask surface

disp('Extracting smoothed mask surface...')

if smSig > 0
    %Smooth the shit out of the mask
    smMask = fastGauss3D(double(maskIn),smSig);
else
    smMask = maskIn;
end

%Extract isosurface
maskSurf = isosurface(smMask,isoVal);
surfNorms = isonormals(smMask,maskSurf.vertices);

%% ---- Surface Curvature Calculations --- %%
%Calculates the mean and gaussian curvature at each point on the mask
%surface

disp('Calculating mask surface properties...')

%Calculate local gaussian and mean curvature of surface
[K,H] = surfaceCurvature(maskSurf,surfNorms);
nFaces = numel(K);

%Calculate principal curvatures at each face:
k1 = H + sqrt(H .^2 - K);
k2 = H - sqrt(H .^2 - K);

%We have curvature data for the faces, so we want their positions also.    
facePos = zeros(nFaces,3);
facePos(:,1) = arrayfun(@(x)(mean(maskSurf.vertices(maskSurf.faces(x,:),1),1)),1:nFaces);
facePos(:,2) = arrayfun(@(x)(mean(maskSurf.vertices(maskSurf.faces(x,:),2),1)),1:nFaces);
facePos(:,3) = arrayfun(@(x)(mean(maskSurf.vertices(maskSurf.faces(x,:),3),1)),1:nFaces);

%% ----- Skeletonization ----- %%
%Get initial branch structure via skeletonization.

disp('Skeletonizing mask...')

skeleton = skeleton3D(maskIn);

%% ----- Branch Structure Extraction ----- %%
%Convert the skeleton into individual branches, endpoints and junctions.

disp('Extracting skeleton branches...')

%Get the topology of the skeleton
[vertices,edges] = skel2graph(skeleton,26);
nEdges = size(edges,1);
nVert = size(vertices,1);

if showPlots        
    %patch(maskSurf,'FaceColor','none','EdgeAlpha',.1)    
end

%Determine which vertices are end-points (branch tips)
nEdgesPerVert = zeros(nVert,1);
for j = 1:nVert

    %Count the number of edges which this vertex is connected to
    nEdgesPerVert(j) = nnz(edges == j);    
    
end

%Find endpoints (they only connect to one edge)
iEndPt = find(nEdgesPerVert == 1 | nEdgesPerVert == 0); %The endpoints can also have 0 edges because "spurs" can exist in the skeleton - that is, branches of length = 1, where the tip IS the branch
nEndPts = numel(iEndPt);
%Find the start-point of this end-point
iStartPt = zeros(nEndPts,1);
for j = 1:nEndPts
    
    %Get the index of the edge for this point.
    iEdge = find(arrayfun(@(x)(any(edges(x,:) == iEndPt(j))),1:nEdges) );    
    
    if ~isempty(iEdge)
        if edges(iEdge,1) == iEndPt(j)
            iStartPt(j) = edges(iEdge,2);
        else
            iStartPt(j) = edges(iEdge,1);
        end        
    else
       iStartPt(j) = iEndPt(j); 
    end
end

%% ------ Branch Pruning ------ %%
%Uses two different methods to remove unwanted branches from the structure.

disp('Removing false-positive branches...')

% ----- Prune by Checking Surface Curvature of tip ---- %


%Calculate local surface curvature near every endpoint
meanTipCurvature = zeros(nEndPts,1);
gaussTipCurvature = zeros(nEndPts,1);
k1TipCurvature = zeros(nEndPts,1);
k2TipCurvature = zeros(nEndPts,1);
for j = 1:nEndPts

    %Calc the distance from this endpoint to every face of the surface
    %polygon
    dToSurf = arrayfun(@(x)(sqrt(sum((facePos(x,[2 1 3]) - ...
        vertices(iEndPt(j),:)).^2))),1:nFaces);%Vertices are in matrix coord, so we need to rearrange

    %Find points near this tip on the surface
    isCloseEnough = dToSurf < searchRad;

    %Get average mean and gaussian curvature   
    if nnz(isCloseEnough) > 0
        meanTipCurvature(j) = mean(H(isCloseEnough));
        gaussTipCurvature(j) = mean(K(isCloseEnough));
        k1TipCurvature(j) = mean(k1(isCloseEnough));
        k2TipCurvature(j) = mean(k2(isCloseEnough));
        
        if showPlots
            text(vertices(iEndPt(j),2),vertices(iEndPt(j),1),vertices(iEndPt(j),3),num2str(j),'color','r')
            plot3(facePos(isCloseEnough,1),facePos(isCloseEnough,2),facePos(isCloseEnough,3),'b.')
        end
    end

end

%Find endpoints for which the surface mean curvature is below-threshold.
isGoodEP  = (meanTipCurvature < mcThresh);

%Check the depth of the start-point for the branches with endpoints. If
%these are too deep, this is not a "real" branch

%Find "depth" at each point within mask
distX = bwdist(~maskIn);

endDepth = arrayfun(@(x)(distX(round(vertices(x,1)),round(vertices(x,2)),round(vertices(x,3)) )),iEndPt);
startDepth = arrayfun(@(x)(distX(round(vertices(x,1)),round(vertices(x,2)),round(vertices(x,3)) )),iStartPt);

%Remove branches whose start point is too deep.
isGoodEP(startDepth > (maxRadius/2)) = false;

%% ---------- Output ---------- %%


%Store all the valid branches and their properties in the output structure.
branches.tipLocation = vertices(iEndPt(isGoodEP),:);
branches.tipAvgCurvature.gaussian = gaussTipCurvature(isGoodEP);
branches.tipAvgCurvature.mean = meanTipCurvature(isGoodEP);
branches.tipAvgCurvature.k1 = k1TipCurvature(isGoodEP);
branches.tipAvgCurvature.k2 = k2TipCurvature(isGoodEP);
branches.tipDepth = endDepth(isGoodEP);
branches.startDepth = startDepth(isGoodEP);
branches.startLocation = vertices(iStartPt(isGoodEP),:);

if showPlots        
    
    %fsFigure(.5);
    clf
    hold on
    patch(maskSurf,'FaceColor','flat','EdgeColor','none','FaceVertexCData',K,'AmbientStrength',.75,'FaceAlpha',.3)
    caxis([mean(K)-2*std(K) mean(K)+2*std(K)])
    hold on             
    spy3d(skeleton,'.k');  
    plot3(vertices(iEndPt(isGoodEP),2),vertices(iEndPt(isGoodEP),1),vertices(iEndPt(isGoodEP),3),'or','MarkerSize',10);
    %arrayfun(@(x)(spy3d(vertices == x,'or','MarkerSize',15)),1:nVerts)
    %
    light
    axis image,axis vis3d    
    view(3)
    title('Branch Tip Detection')           
%     
%     fsFigure(.5);
%     patch(maskSurf,'FaceColor','flat','EdgeColor','none','FaceVertexCData',H,'AmbientStrength',.75)    
%     caxis([mean(H)-2*std(H) mean(H)+2*std(H)])
%     hold on
%     %arrayfun(@(x)(plot3(maskSurf.vertices(x,1),maskSurf.vertices(x,2),maskSurf.vertices(x,3),'kx')),maskSurf.faces(iConv))    
%     title('Mean Curvature')
%     colorbar    
%     light
%     axis image,axis vis3d    
%     view(3)
%     
%     fsFigure(.5);
%     patch(maskSurf,'FaceColor','flat','EdgeColor','none','FaceVertexCData',k1,'AmbientStrength',.75)    
%     caxis([mean(k1)-2*std(k1) mean(k1)+2*std(k1)])
%     hold on
%     %arrayfun(@(x)(plot3(maskSurf.vertices(x,1),maskSurf.vertices(x,2),maskSurf.vertices(x,3),'kx')),maskSurf.faces(iConv))    
%     title('1st Principal Curvature')
%     colorbar    
%     light
%     axis image,axis vis3d    
%     view(3)
%     
%      
%     fsFigure(.5);
%     patch(maskSurf,'FaceColor','flat','EdgeColor','none','FaceVertexCData',k2,'AmbientStrength',.75)    
%     caxis([mean(k2)-2*std(k2) mean(k2)+2*std(k2)])
%     hold on
%     %arrayfun(@(x)(plot3(maskSurf.vertices(x,1),maskSurf.vertices(x,2),maskSurf.vertices(x,3),'kx')),maskSurf.faces(iConv))    
%     title('2nd Principal Curvature')
%     colorbar    
%     light
%     axis image,axis vis3d    
%     view(3)
%     
%     
%     fsFigure(.5);
%     bMeas = (-real(k2))- abs(real(k1));
%     patch(maskSurf,'FaceColor','flat','EdgeColor','none','FaceVertexCData',bMeas,'AmbientStrength',.75)    
%     caxis([mean(bMeas)-2*std(bMeas) mean(bMeas)+2*std(bMeas)])
%     hold on
%     %arrayfun(@(x)(plot3(maskSurf.vertices(x,1),maskSurf.vertices(x,2),maskSurf.vertices(x,3),'kx')),maskSurf.faces(iConv))    
%     title('Branchiness')
%     colorbar    
%     light
%     axis image,axis vis3d    
%     view(3)
    

end

