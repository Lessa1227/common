function[simav,simmax,simmin]=calculatedIndifference(mpm, sp, mdist, ms)
%calculates "indifference function", i.e. the development of the Ripley 
%clustering parameter over time in a distribution of dividing cells with 
%adhesion indifference - as a comparison with given distribution  
%
%SYNOPSIS [simav,simmax,simmin]=calculatedIndifference(mpm, sp, mdist, ms)
%INPUT  mpm: the original mpm for which this simulation is calculated; the
%               original time series yields both the initial distribtion
%               init which is the starting point for the simulation, and
%               the number of cells (and divisions and losses) which are
%               input into the simulation
%       sp: average displacement of cells frame-to-frame in pixels per frame
%           (appr. diffusion speed in the absence of adhesion or repulsion);
%           this value can be calculated e.g. in Polytrack
%       mdist: appr. minimum distance between object centers (corresponding
%               to cell radius)
%       ms: matrix size= image size in pixels; e.g. [1344 1024];
%OUTPUT simav: average simulated clustering parameter for indifferent
%               function
%       simmax: appr. 90% confidence int. upper margin (second highest of 20)
%       simmin: appr. 90% confidence int. lower margin (second lowest of 20)
%
%DEPENDENCIES: calculatedIndifference uses
%{avRipleySimSpec, SimulateClusterMpmSpec, DeterNearNeigh}
%
%Dinah Loerke, October 21, 2004

%determine nof=number of frames
[z,s]=size(mpm);
nof=s/2;
disp(['number of frames = ',num2str(nof)]);

%determine number of cells from first to last frame (noc)
noc=1:nof;
for i=1:nof
    %take 2*i-1nth column of mpm, find number of nonzero elements and count
    noc(i)=max(size(find(mpm(:,(2*i-1)))));
end

plot(noc,'r.');
axis([1 nof+1 (min(noc)-1) (max(noc)+1)]);
pause(0.1);

%nov=number of divisions (or losses) from frame-to-frame (one point less)
nov=noc;
nov(nof)=[];
for n=1:(nof-1)
   nov(n)=(noc(n+1)-noc(n));
end

%init - first image frame in mpm
init=[nonzeros(mpm(:,1)) nonzeros(mpm(:,2))];

%calculate simulation
[simav,simmin,simmax]=avRipleySimSpec(init,3,mdist,nof,nov,sp,ms);


%calculate original cluster function - if desired, uncomment 
%[pv1]=clusterQuantRipley(mpm,ms(1),ms(2));

%plot results
figure 
plot(simav,'b.');

hold
%plot(pv1,'r.');
plot(simmin);
plot(simmax);
hold

end



function[p,minp,maxp]=avRipleySimSpec(init,bh,cs,np,nov,sd,matsiz)
%avRipleyRand makes average Ripley function of 20 simulations
%Spec meands specific: number of divisions is specified in wave nov
%(alternatively, it is possible to have the cells divide randomly)
ms=matsiz;
for i=1:20
    disp(['simulation run ',num2str(i)]);
    %makes simulation mpm
    [mv1]=SimulateClusterMpmSpec(init,bh,cs,np,nov,sd,ms);
    %calculates corresponding ripley clustering
    [pv1]=clusterQuantRipley(mv1,ms(1),ms(2));
    if(i==1)
       pvall=pv1';
    else
       pvall=[pvall pv1'];
    end
end
%pvall is matrix of all 20 clusterparameter vectors, 20 columns, nof lines
%calculate mean
meanpv=mean(pvall,2);
%make vector (20 points) containing mean of each individual pv1 trace to 
%identify highest and lowest value individual trace
meanwav=mean(pvall,1);
%remove highest and lowest (for 90% confidence interval) 
maxpos=find(meanwav==max(meanwav));
minpos=find(meanwav==min(meanwav));
firsti=max(maxpos,minpos);
lasti=min(maxpos,minpos);
pvall(:,firsti)=[];
pvall(:,lasti)=[];
%find new highest and lowest value
maxpv=meanpv;
minpv=meanpv;
for n=1:np
    maxpv(n)=max(pvall(n,:));
    minpv(n)=min(pvall(n,:));
end
p=meanpv;
minp=minpv;
maxp=maxpv;
end



function[mpm]=SimulateClusterMpmSpec(m1,bh,cs,np,nov,sd,matsiz)
%SimClusterMat simulates different kinds of clustering behaviour,including
%cell division with cell attraction/loss of atrraction/scattering
%cell division at specified planes
% SYNOPSIS   [m2,dr2]=SimClusterMat(m1,bh,cs,np,nov,sd,matsiz);
%       
% INPUT      m1: initial distribution of objects (clustered or
%                non-clustered matrix), nx2 matrix containing the (x,y) 
%                coordinates of n points
%            bh: behaviour parameter denoting kind of behaviour of objects
%                bh=1: adhesion; bh=2 scattering; bh=3 random
%            cs: cell size parameter; in the simulation, objects can't come
%                closer to each other than this distance
%            np: number of planes; this parameter denotes how many times 
%                the simulation is performed and how many planes the final
%                mpm matrix will have
%            nov: wave containing the number of divisions for each time
%                frame (or disappearances)
%            sd:  speed of diffusion= average frame-to-frame displacement
%            matsiz: matrix size, must be a vector of type [xsize, ysize]
%
%
% OUTPUT     mpm: matrix containing all the coordinates over time
%             
%
% DEPENDENCIES   SimClusterMat  uses {MovSingPoint,DetNearNeigh}
%               SimClusterMat  is used by { }
%
% Dinah Loerke, September 13th, 2004

%remove zeros from input matrix; this is needed if the input from another 
%mpm-matrix that contains empty lines
mtemp=[nonzeros(m1(:,1)), nonzeros(m1(:,2)) ];

%plot and initialize - uncomment next lines if you want to see the
%simulation amtrix on screen
%figure
%plot(mtemp(:,1),mtemp(:,2),'r.');
%axis([1 matsiz(1) 1 matsiz(2)]);
%pause(0.001);
mpm=mtemp;
matsizx=matsiz(1);
matsizy=matsiz(2);

%cycle over desired number of planes
for inp=1:(np-1)
    
    %nx number of cells in this plane
    [nx,ny]=size(mtemp);
    
    %calculate average neighbour distance in densest hexagonal packing 
    %for this density (is used later in the nearest neighbour procedure)
    nden=nx/(matsizx*matsizy);
    thnn=sqrt(2/(sqrt(3)*nden));
    
    %make duplicate of mtemp called "nn" which contains the coordinates of the
    %nearest neighbor of each point and, in the third row, the distance.
    %for points close to the edge (within thnn as calculated above), it is 
    %considered possible that that the nearest neighbour is outside of the
    %image. the neighbourhood outside the image is considered to be a copy
    %of the original image, so that the matrix is expanded across that edge
    %for another search, after the points inside the image have been 
    %considered. in other words, if an object is close to the left edge, 
    %its nearest neighbour could be an object close to the right edge of 
    %the image.
    temp=[thnn, matsizx, matsizy];
    [nn]=DeterNearNeigh(mtemp,temp);
    
    %decide if there are any divisions or disappearances in this plane
    divdet=nov(inp);
    celldivp=zeros(nx,1);
    %decide which cells divide or disappear
    rnum=0;
    if(divdet>0)
        %pick cell to divide
        for i=1:divdet
            rnum=ceil(nx*rand(1,1));
            if(celldivp(rnum)==1)
                rnum=ceil(nx*rand(1,1));
            end
            celldivp(rnum)=1;
        end 
    end
    if(divdet<0)
        %pick cell to disappear, choose the one closest to any edge
        %find min distance from edge
        xv=mtemp(:,1);
        rxv=matsizx-xv;
        minx=min(xv,rxv);
        %minx contains minumum of x or matsizx-x
        yv=mtemp(:,2);
        ryv=matsizy-yv;
        miny=min(yv,ryv);
        %miny contains minumum of y or matsizx-y
        minmat=[minx miny];
        %minmat is duplicate of mtemp containing resp minimna of diatnce to
        %left or right, upper or lower edge
        aa=find(minmat==min(min(minmat)));
        rnum=aa(1);
        if(aa(1)>nx)
            rnum=aa(1)-nx;
        end
        %disp(['aa=',num2str(aa(1)),' rnum=',num2str(rnum),' nx=',num2str(nx)])
        %minmat
        celldivp(rnum)=(-1); 
    end
    %disp(['plane ',num2str(inp+1),', no.cells ',num2str(nx),', no. cells div ',num2str(divdet),', cell no. ', num2str(rnum)]);
    
    %mtemp now contains original coordinates, nn contains nearest neighbours
    %celldivp contains the information whether a given cell divides or not
    %or disappears
    
    %cycle over all points
    for k=1:nx
        %determine nearest neighbour distance and direction from nn matrix
        d=sqrt((nn(k,1)-mtemp(k,1))^2+(nn(k,2)-mtemp(k,2))^2);
        %Normalized x and y difference vector components
        dvx=(nn(k,1)-mtemp(k,1))/d;
        dvy=(nn(k,2)-mtemp(k,2))/d;
        %now decide for each point whether to move or divide
        %generate random variable, compare to division probability
        if(celldivp(k)==1)
            %cell divides: create duplicate point approximately at right 
            %angles from the direction of nearest neighbour, at distance 
            %cs/4 from the original point 
            %right angle of (x,y) is (-y,x) or (y,-x)
            newpointx=mtemp(k,1)-round(dvy*cs/4);
            newpointy=mtemp(k,2)+round(dvx*cs/4);
            %if the new points are outside the borders of the image, they
            %are pushed over the edge to the other side
            if(newpointx>matsiz(1))
                 newpointx=mod(newpointx,matsiz(1));
            elseif(newpointx<=0)
                 newpointx=matsiz(1)+newpointx;
            end
            if(newpointy>matsiz(2))
                  newpointy=mod(newpointy,matsiz(2));
            elseif(newpointy<=0)
                 newpointy=matsiz(2)+newpointy;
            end
            newpoint=[newpointx newpointy];
            %add newpoint coordinates to bottom of matrix
            mtemp=[mtemp; newpoint];
        elseif(celldivp(k)==-1)
            %remove point => set point coordinates to zero
            mtemp(k,1:2)=[0 0];
        else
            %cell moves, according to the parameters specified in the
            %input, with cs=cell size (repulsion for distances smaller
            %than this parameter) and bh=behaviour, which may include
            %attraction, repulsion, or indifference
            [newcoord]=MovSingPoint(mtemp(k,:),nn(k,:),matsiz,cs,bh,sd);
            mtemp(k,:)=newcoord;
        end
        %makes sure the moved points are within matrix
         %if beyond boundaries, they flip accros the other border
         
    end
    %plot new plane
    
    %plot(mtemp(:,1),mtemp(:,2),'r.');
    %axis([1 matsiz(1) 1 matsiz(2)]);
    %pause(0.1);
    %add mtemp, the new plane, to mpm; account for the fact that the number
    %of points may have changed due to cell division; thus, add zeros to
    %the bottom of the existing mpm columns if necessary
    [xm2,ym2]=size(mpm);
    [xmt,ymt]=size(mtemp);
    difx=xmt-xm2;
    if(difx>0)
        %add zeros to mpm to bring to same length
        addv=zeros(difx,ym2);
        mpm=[mpm; addv];
    elseif(difx<0)
        %add zeros to mtemp to bring to same dim as mpm
        addv=zeros(abs(difx),2);
        mtemp=[mtemp; addv];
    end
    mpm=[mpm, mtemp];
    %remove zeros disappeared points for next round
    mtemp=[nonzeros(mtemp(:,1)),nonzeros(mtemp(:,2))];
end
end


function[xynn]=DeterNearNeigh(xycor,temp)
%DetNearNeigh uses input matrix xycor which contains point coordinates
%to determine the coordinates of each point's nearest neighbour point 
%and the distance
%
% SYNOPSIS   [xynn]=DetNearNeigh(xycor,temp);
%       
% INPUT      xycor: matrix containing x- and y-coordinates of points
%            temp:  vector containing 3 parameters:
%                   thnn, which is the average neighbour distance for 
%                   densest hexagonal packing of the same point density, 
%                   which is the criterion for flipping the matrix edge for
%                   looking for nearest neighbours;
%                   matsizx: matrix size in x-direction
%                   matsizy: matrix size in y-direction
%   
%
% OUTPUT     xynn: matrix containing the coordinates of each point's nearest 
%                   neighbour             
%
% DEPENDENCIES   DetNearNeigh  uses {,}
%                DetNearNeigh  is used by { }
%
% Dinah Loerke, September 16th, 2004


%initialize
thnn=temp(1);
matsizx=temp(2);
matsizy=temp(3);
[nx,ny]=size(xycor);
xynn=zeros(nx,3);

%loop over all points
for k=1:nx
    %initialize distance rr to high value
    rr=min(matsizx,matsizy);
    %change rr to smallest available nearest neighbour distance
    [xynn,rr]=nearnei_2mat(xycor,xycor,xynn,rr,k);
    
    %if point is close to any edge, check over the edge for closer nearest 
    %neighbour candidates; more than one edge criterion may apply!
    %left edge
    if(xycor(k,1)<thnn)
        %mat2: original matrix transposed by matsizx to left
        mat2=xycor;
        mat2(:,1)=xycor(:,1)-matsizx;
        %checks if there's a point in m2 closer than the previous best
        %value of rr; function nearnei_twomat is added to the bottom of
        %this function
        [xynn,rr2]=nearnei_twomat(xycor,mat2,xynn,rr,k);  
        rr=rr2;
    end
    %same for upper edge
    if(xycor(k,2)<thnn)
        %mat2: original matrix transposed by matsizy to top
        mat2=xycor;
        mat2(:,2)=xycor(:,2)-matsizy;
        [xynn,rr3]=nearnei_twomat(xycor,mat2,xynn,rr,k);
        rr=rr3;
    end
    %same for right edge
    if(xycor(k,1)>(matsizx-thnn))
        %mat2: original matrix transposed by matsizx to right
        mat2=xycor;
        mat2(:,1)=xycor(:,1)+matsizx;
        [xynn,rr4]=nearnei_twomat(xycor,mat2,xynn,rr,k); 
        rr=rr4;
    end
    %same for bottom edge
    if(xycor(k,2)>(matsizy-thnn))
        %mat2: original matrix transposed by matsizy to bottom
        mat2=xycor;
        mat2(:,2)=xycor(:,2)+matsizy;
        [xynn,rr5]=nearnei_twomat(xycor,mat2,xynn,rr,k);
        rr=rr5;
    end
end
end

function[m3,rr]=nearnei_twomat(m1,m2,m3,rr,k)
%makes nearest neighbor matrix
%between two different matrizes of same size
%m1 original, m2 one to compare it to, m3 result (the point in m2 which is
%the nearest neighbour of the corresponding point in m1)
%rr initial value for distance, and result
%assumes a pre-existing value for rr (from a previous estimate) which must
%be improved upon in order to count
xk=m1(k,1);
yk=m1(k,2);
[nx,ny]=size(m2);
for s=1:nx
        r=sqrt((xk-m2(s,1))^2+(yk-m2(s,2))^2);
        if((r<rr)&&(r>0))
            rr=r;
            m3(k,1:2)=m2(s,1:2);
            m3(k,3)=rr;
        end
end 
end