function stats = skottechild(th,lb,placement,orientation,placementback,orientationback,ageGroup)
%Skotte filter including low back with lying detection
%
%This Matlab implementation includes the classification of
% Sitting, standing, moving, walking, running, lying and biking.
%
%This was based on the original study published as:
%
%Detection of Physical Activity Types using Triaxial Accelerometers
%Skotte J, Korshoj M, Kristiansen J, Hanisch C, Holtermann A, 
%Journal of Physical Activity and Health, 2014, 11, 76-84
%
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

%The different threshold used with specific populations
%              Moving,Biking,Stairs,Run,Sitting,Stading,Lying(low back)
skottethresholds = [ 0.1  , 24.0 , NaN, 0.72, 45, 0.1, 65.0 ]; %Adults Age >17
childyouththresholds = [ 0.1  , 22.5 , NaN, 0.65, 47.5, 0.13, 65.0 ]; %Children age 4-17

thresholds = skottethresholds;

switch(ageGroup)
    case {'default','original','skotte','adults'}
        thresholds = skottethresholds;
    case 'children'
        thresholds = childyouththresholds;
    otherwise
        thresholds = skottethresholds;
end

%We assume a sampling frequency of 30 Hz
%If other sampling frequencies are used it has to either resampled or
%changes might be nessesary to the implementation
SF = 30; 
wndhlf = SF;

N = length(th(:,1));
Nlb = 0;

%Checking the integrity of the back accelerometer
if isempty(lb)==0
    Nlb = length(lb(:,1));
end
%
if (Nlb>0 && N>Nlb)
    N=Nlb;
end

nn = round(N/wndhlf) - 10;
stats = zeros(nn,8);

%enums for the different activity type categories
sit = 1;
move = 2;
stand = 3;
bike = 4;
stairs = 5;
run = 6;
walk = 7;
lying = 8;

%Default orientation of the device:
%Thigh: Front of the thigh, x axis pointing towards the knee and text out
%This is similar to the placement and orientation used in the original
%study
xaxis = 1;
%Orientation should be [-1,1,1]

%Alternative placement and orientation:
%Device mounted on the side - X axis pointing down and text out
if placement==1
    xaxis = 1;
end

%Placement on the front thigh but sideways
%X Axis is pointing to the right and text out
if placement==2
    xaxis = 2;
end

%Generating the features for the thigh
[ ~,sdacc,sdmax,incl,angl,~,~ ] = skottepre( th,placement, orientation );

%Generating the features for the back accelerometer
if (Nlb>0)
    [ ~,lbsdacc,~,lbinc,~,~ ] = skottepre( lb,placementback, orientationback );
end


disp('State');
for n = 1:nn
    
    %Do we move?
    if (sdacc(n,xaxis) > thresholds(1))          
            if (angl(n) > thresholds(2))            
                %Bike
                stats(n,bike) = 1;
                
            else
                if (angl(n) > thresholds(3))
                    %Stairs
                    stats(n,stairs) = 1;
                else
                    if (sdacc(n,xaxis) > thresholds(4))
                        %Run
                        stats(n,run) = 1;
                    else
                        %Walking
                        stats(n,walk) = 1;
                    end
                end 
            end
        
    else    
        if (incl(n) > thresholds(5))
            %Sitting
            stats(n,sit) = 1;
        else
            if (sdmax(n) > thresholds(6))
              %seems like we are moving around
              stats(n,move) = 1;
              
           else
              %standing still
              stats(n,stand) = 1;
           end
           
        end  
        
    end
    
end

if (Nlb>0)        
    %Identify periods of sitting and potentially lying
    
    Nmin = min([nn length(lbinc) length(lbsdacc(:,1)) ]);
    
    Ilying = find( stats(1:Nmin,1) == 1 & lbinc(1:Nmin) > thresholds(7));
    
    if (isempty(Ilying)==0)       
        stats(Ilying,lying) = 1;

        %Remove sitting and indicate lying
        stats(Ilying,sit) = 0;
    end
    
end

%Removing sporadic data
if (1)
    disp('Median filter');
    %Median filtering to remove sporadic classifications
    stats(:,bike) = ceil(medfilt1(stats(:,bike),29)); %29 sec!!!!
    stats(:,walk) = ceil(medfilt1(stats(:,walk),9));
    stats(:,sit) = medfilt1(stats(:,sit),9);
    stats(:,stand) = medfilt1(stats(:,stand),9);
    stats(:,move) = medfilt1(stats(:,move),9);
    stats(:,run) = ceil(medfilt1(stats(:,run),2));
    stats(:,stairs) = ceil(medfilt1(stats(:,stairs),9));
end

%Handling multiple classifications due to median filtering
if (1)
    I = find(sum(stats,2)>1);
    N = length(I);
    for n=1:N
        %If the subject is lying down
        %Then we dont expect enything else
        if (stats(I(n),lying) == 1)
            stats(I(n),1:7) = 0;
        end

        %If we are sitting and biking?
        if (stats(I(n),sit) == 1) % && stats(I(n),bike)==1)
            %We have both biking and sitting
            stats(I(n),2:7) = 0;
        end
        %biking and other types?
        if (stats(I(n),bike)==1 && sum(stats(I(n),:))>1 )
            %We have both biking
            stats(I(n),:) = 0;
            stats(I(n),bike) = 1;
        end
        
        if (stats(I(n),walk)==1 && stats(I(n),move)==1)
            stats(I(n),:) = 0;
            stats(I(n),walk) = 1;
        end
        
        if (stats(I(n),walk)==1 && stats(I(n),stand)==1)
            stats(I(n),:) = 0;
            stats(I(n),walk) = 1;
        end
        
        if (stats(I(n),run)==1 && stats(I(n),move)==1)
            stats(I(n),:) = 0;
            stats(I(n),run) = 1;
        end
        
        if (stats(I(n),run)==1 && stats(I(n),stand)==1)
            stats(I(n),:) = 0;
            stats(I(n),run) = 1;
        end
        
        if (stats(I(n),run)==1 && stats(I(n),walk)==1)            
            stats(I(n),:) = 0;
            stats(I(n),walk) = 1;
        end
    end
end


%Find the periods with no classification

I = find(sum(stats,2)<0.1);     
%This must be standing and moving
stats(I,move) = 1;


disp('done');