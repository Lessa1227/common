function [delta_plus, delta_minus, grad_x, grad_y] = lsGradient2o(phi, delta_x, delta_y, i_end, j_end)
% LSFIRSTSECONDDIFFERENCES calculates gradient wit hsecond order accuracy
%    
%
%
% SYNOPSIS   [delta_plus, delta_minus, grad_x, grad_y] = lsGradient2o(phi, delta_x, delta_y, i_end, j_end)
%
%
% INPUT      phi        : phi=f(x,y) function values on a grid
%            delta_x    : x-direction grid spacing
%            delta_y    : y-direction grid spacing
%            i_end      : number of x grid points
%            j_end      : number of y grid points 
%                          
% 
% OUTPUT     delta_plus     :  right side absolute value of the gradient
%            delta_minus    :  left side absolute value of the gradient
%            grad_x         :  x-comp. of the gradient
%            grad_y         :  y-comp. of the gradient
%                           
% DEPENDENCES     lsGradient2o uses {                                
%                                       }
%
%                 lsGradient2o is used by { 
%                                           }
%
% Matthias Machacek 06/22/04

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%% Difference operators %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Dy_minus          =  zeros(i_end, j_end);
Dy_plus           =  zeros(i_end, j_end);
Dy_minus_y_minus  =  zeros(i_end, j_end);
Dy_plus_y_plus    =  zeros(i_end, j_end);
Dy_plus_y_minus   =  zeros(i_end, j_end);

for i=1:i_end
   for j=1:j_end
      if i < 3
         % assume that the value at i=1 is the same as at i=2
         Dy_minus(i,j)          =  (phi(i+1,j)-  phi(i  ,j)           )  / delta_y;
         Dy_plus(i,j)           =  (phi(i+1,j)-  phi(i  ,j)           )  / delta_y;
         Dy_minus_y_minus(i,j)  =  (phi(i+2,j)-2*phi(i+1,j)+phi(i,j)  )  / delta_y^2;
         Dy_plus_y_plus(i,j)    =  (phi(i+2,j)-2*phi(i+1,j)+phi(i,j)  )  / delta_y^2;
         Dy_plus_y_minus(i,j)   =  (phi(i+2,j)-2*phi(i+1,j)+phi(i,j)  )  / delta_y^2;         
      elseif i > i_end-3
         Dy_minus(i,j)          =  (phi(i  ,j)-  phi(i-1,j)             )  / delta_y;
         Dy_plus(i,j)           =  (phi(i  ,j)-  phi(i-1,j)             )  / delta_y;
         Dy_minus_y_minus(i,j)  =  (phi(i  ,j)-2*phi(i-1,j)+phi(i-2,j)  )  / delta_y^2;
         Dy_plus_y_plus(i,j)    =  (phi(i  ,j)-2*phi(i-1,j)+phi(i-2,j)  )  / delta_y^2;
         Dy_plus_y_minus(i,j)   =  (phi(i  ,j)-2*phi(i-1,j)+phi(i-2,j)  )  / delta_y^2;       
      else
         Dy_minus(i,j)          =  (phi(i  ,j)-  phi(i-1,j)             )  / delta_y;
         Dy_plus(i,j)           =  (phi(i+1,j)-  phi(i  ,j)             )  / delta_y;
         Dy_minus_y_minus(i,j)  =  (phi(i  ,j)-2*phi(i-1,j)+phi(i-2,j)  )  / delta_y^2;
         Dy_plus_y_plus(i,j)    =  (phi(i+2,j)-2*phi(i+1,j)+phi(i  ,j)  )  / delta_y^2;
         Dy_plus_y_minus(i,j)   =  (phi(i+1,j)-2*phi(i  ,j)+phi(i-1,j)  )  / delta_y^2;      
      end
      
      if j < 3
         Dx_minus(i,j)          =  (phi(i,j+1)-  phi(i,j  )             )  / delta_x;
         Dx_plus(i,j)           =  (phi(i,j+1)-  phi(i,j  )             )  / delta_x;
         Dx_minus_x_minus(i,j)  =  (phi(i,j+2)-2*phi(i,j+1)+phi(i,j  )  )  / delta_x^2;
         Dx_plus_x_plus(i,j)    =  (phi(i,j+2)-2*phi(i,j+1)+phi(i,j  )  )  / delta_x^2;
         Dx_plus_x_minus(i,j)   =  (phi(i,j+2)-2*phi(i,j+1)+phi(i,j  )  )  / delta_x^2;        
      elseif j > j_end-3
         Dx_minus(i,j)          =  (phi(i,j  )-  phi(i,j-1)             )  / delta_x;
         Dx_plus(i,j)           =  (phi(i,j  )-  phi(i,j-1)             )  / delta_x;
         Dx_minus_x_minus(i,j)  =  (phi(i,j  )-2*phi(i,j-1)+phi(i,j-2)  )  / delta_x^2;
         Dx_plus_x_plus(i,j)    =  (phi(i,j  )-2*phi(i,j-1)+phi(i,j-2)  )  / delta_x^2;
         Dx_plus_x_minus(i,j)   =  (phi(i,j  )-2*phi(i,j-1)+phi(i,j-2)  )  / delta_x^2;    
      else
         Dx_minus(i,j)          =  (phi(i,j  )-  phi(i,j-1)             )  / delta_x;
         Dx_plus(i,j)           =  (phi(i,j+1)-  phi(i,j  )             )  / delta_x;
         Dx_minus_x_minus(i,j)  =  (phi(i,j  )-2*phi(i,j-1)+phi(i,j-2)  )  / delta_x^2;
         Dx_plus_x_plus(i,j)    =  (phi(i,j+2)-2*phi(i,j+1)+phi(i,j  )  )  / delta_x^2;
         Dx_plus_x_minus(i,j)   =  (phi(i,j+1)-2*phi(i,j  )+phi(i,j-1)  )  / delta_x^2;
      end
   end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

A =             zeros(i_end, j_end);
B =             zeros(i_end, j_end);
C =             zeros(i_end, j_end);
D =             zeros(i_end, j_end);
grad_x =        zeros(i_end, j_end);
grad_y =        zeros(i_end, j_end);
delta_plus  =   zeros(i_end, j_end);
delta_minus =   zeros(i_end, j_end);

for i=1:i_end
   for j=1:j_end
      A(i,j) = Dx_minus(i,j) + delta_x/2 * switch_m(Dx_minus_x_minus(i,j), Dx_plus_x_minus(i,j));
      B(i,j) = Dx_plus(i,j)  - delta_x/2 * switch_m(Dx_plus_x_plus(i,j),   Dx_plus_x_minus(i,j));
      C(i,j) = Dy_minus(i,j) + delta_y/2 * switch_m(Dy_minus_y_minus(i,j), Dy_plus_y_minus(i,j));
      D(i,j) = Dy_plus(i,j)  - delta_y/2 * switch_m(Dy_plus_y_plus(i,j),   Dy_plus_y_minus(i,j));
      
      grad_x(i,j) = max(A(i,j),0) + min(B(i,j),0);
      grad_y(i,j) = max(C(i,j),0) + min(D(i,j),0);
      
      delta_plus(i,j)  =  sqrt(max(A(i,j),0)^2 + min(B(i,j),0)^2+...
                               max(C(i,j),0)^2 + min(D(i,j),0)^2);
      
      delta_minus(i,j) =  sqrt(max(B(i,j),0)^2 + min(A(i,j),0)^2+...
                               max(D(i,j),0)^2 + min(C(i,j),0)^2);      
   end
end



function m = switch_m(D1, D2)

if (D1 * D2) < 0
   m=0; 
elseif abs(D1) <= abs(D2)
   m = D1;
else
   m = D2;
end