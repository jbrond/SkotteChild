function [ macc,sdacc,sdmax,incl,angl,turn,mayaxis,vsumhalfed ] = skottepre( accel,type, orientation )
%Skottepre generates the data required in the Skotte algorithm
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% SF = 30; %30Hz is the default sampling frequency

SF = 30;

[B,A]  = butter(4,5/(SF/2));
[B1,A1]  = butter(4,1/(SF/2),'high');

%Window size by default from skotte
wnd2s = 2 * SF; %2 sec window
wndhlf = SF;

%%%% Axis from Gt3x
% y,x,z-
%%%% Axis from Ax3
% x,y,z
%

%default
%omat = [-1,1,1];

%Device mounted on the front of the thigh
xaxis = 1;
yaxis = 2;
zaxis = 3;

%The device is mounted on the side
if type==1
    xaxis = 1;
    yaxis = 3;
    zaxis = 2;
end

%Placement on the front but sideways
if type==2
    xaxis = 2;
    yaxis = 1;
    zaxis = 3;
end

S = size(orientation);
%Filtering the acceleration
if (S(1)<2)
    thff(:,1) = filtfilt(B,A,orientation(1).*accel(:,1));
    thff(:,2) = filtfilt(B,A,orientation(2).*accel(:,2));
    thff(:,3) = filtfilt(B,A,orientation(3).*accel(:,3));
else
    thff(:,1) = filtfilt(B,A,orientation(:,1).*accel(:,1));
    thff(:,2) = filtfilt(B,A,orientation(:,2).*accel(:,2));
    thff(:,3) = filtfilt(B,A,orientation(:,3).*accel(:,3));
end

macc = moving_average(wnd2s,thff);
macc = macc(1:wndhlf:end,:);
%Fixing time lag
macc = macc(3:end,:);

%Estimating the standard deviation
sdacc = movingstd(filtfilt(B1,A1,thff(:,1)),wnd2s,'f');
sdacc(:,2) = movingstd(filtfilt(B1,A1,thff(:,2)),wnd2s,'f');
sdacc(:,3) = movingstd(filtfilt(B1,A1,thff(:,3)),wnd2s,'f');
%Removing the in between data
sdacc = sdacc(1:wndhlf:end,:);

%SDmax feature
sdmax = max(sdacc,[],2);

vsumhalfed = (macc(:,1).^2 + macc(:,2).^2 + macc(:,3).^2).^0.5;

%Angles
incl = 180/pi * acos( macc(:,xaxis) ./ vsumhalfed );

angl = 180/pi * (-asin( macc(:,zaxis) ./ vsumhalfed ));
turn = 180/pi * acos( macc(:,yaxis) ./ vsumhalfed );

mayaxis = moving_average(20*30,thff(:,yaxis));
mayaxis = mayaxis(1:30:end);

end

