function [dx, ddx] = diffCenterVar(t,x)
% [dx, ddx] = diffCenterVar(t,x);
%
% Computes first and second derivatives of x(t)
% --> Second-order accurate
% --> Works for non-uniform grid
%
% INPUTS:
%   t = [1,m] = time grid
%   x = [n,m] = function values for each point on the grid
%
% OUTPUTS:
%   dx = [n,m] = first derivative of x
%   ddx = [n,m] = second derivative of x
%
% NOTES:
%   This function works by locally fitting a quadratic curve between each
%   set of three points. See Derive_Eqns.m for details.
%

% Copyright (c) 2016, Matthew Kelly
% MIT license, FEX 58287

[nDim, nTime] = size(x);
nTimeCheck = length(t);
if nTime ~= nTimeCheck
    eval('help diffCenterVar');
    error('Invalid input dimensions. See help file above.')
end

h = t(2:end)-t(1:(end-1));
hLow = ones(nDim,1)*h(1:(end-1));
hUpp = ones(nDim,1)*h(2:end);
xLow = x(:,1:(end-2));
xMid = x(:,2:(end-1));
xUpp = x(:,3:(end-0));

vLow = getVelLow(hLow(:,1), hUpp(:,1), xLow(:,1), xMid(:,1), xUpp(:,1));
vMid = getVelMid(hLow, hUpp, xLow, xMid, xUpp);
vUpp = getVelUpp(hLow(:,end), hUpp(:,end), xLow(:,end), xMid(:,end), xUpp(:,end));
dx = [vLow, vMid, vUpp];

if nargout > 1
    accel = getAccel(hLow, hUpp, xLow, xMid, xUpp);
    ddx = [accel(:,1), accel, accel(:,end)];
end

end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

function vLow = getVelLow(hLow, hUpp, xLow, xMid, xUpp)
% This code generated by Derive_Eqns.m
% Velocity (derivative of x) at upper boundary of segment
vLow = (hLow.^2.*xMid - hLow.^2.*xUpp - hUpp.^2.*xLow + hUpp.^2.*xMid - 2.*hLow.*hUpp.*xLow + 2.*hLow.*hUpp.*xMid)./(hLow.*hUpp.*(hLow + hUpp));
end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

function vMid = getVelMid(hLow, hUpp, xLow, xMid, xUpp)
% This code generated by Derive_Eqns.m
% Velocity (derivative of x) at mid-point of segment
vMid = -(hLow.^2.*xMid - hLow.^2.*xUpp + hUpp.^2.*xLow - hUpp.^2.*xMid)./(hLow.*hUpp.*(hLow + hUpp));
end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

function vUpp = getVelUpp(hLow, hUpp, xLow, xMid, xUpp)
% This code generated by Derive_Eqns.m
% Velocity (derivative of x) at upper boundary of segment
vUpp = -(hLow.^2.*xMid - hLow.^2.*xUpp - hUpp.^2.*xLow + hUpp.^2.*xMid + 2.*hLow.*hUpp.*xMid - 2.*hLow.*hUpp.*xUpp)./(hLow.*hUpp.*(hLow + hUpp));
end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

function accel = getAccel(hLow, hUpp, xLow, xMid, xUpp)
% This code generated by Derive_Eqns.m
% Acceleration (second derivative of x) for entire segment
accel = -(2.*(hLow.*xMid - hLow.*xUpp - hUpp.*xLow + hUpp.*xMid))./(hLow.*hUpp.*(hLow + hUpp));
end


