function [ omwav ] = loadomwav( filename, readblock )
%Loading the Axivity WAV file
%Readblock can be used to limit the amount of data read

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

%Make sure readblock is defined if nothing is handed in
if isempty(readblock)
    fe = 0;
else
    fe = readblock(1);
end

omwav.INFO = audioinfo(filename);

if (isempty(readblock))
    data = audioread(filename);
else
    if (length(readblock)==1)
        readblock(2) = omwav.INFO.TotalSamples;
    end
    
    if readblock(2) > omwav.INFO.TotalSamples
        readblock(2) = omwav.INFO.TotalSamples;
    end
    
    data = audioread(filename,readblock);
end
    
%This is default range
range = 8;
%date example
%2015-01-05 09:00:03.870

havestart =  strfind(omwav.INFO.Comment,'Time:');
if (isempty(havestart)==0)
    tokenz = strsplit(omwav.INFO.Comment,'\n');
    fdate = strrep(tokenz(1),'Time: ','');
    
    starttime = datenum(fdate,'yyyy-mm-dd HH:MM:SS.FFF');
    %the matlab time
    omwav.INFO.orgstart = starttime + datenum(0,0,0,0,0,1)/omwav.INFO.SampleRate*fe;
    
    %the posix start time
    omwav.starttime = posixtime(datetime(starttime, 'ConvertFrom', 'datenum'));
    
    frange = strrep(tokenz(3),'Scale-1: ','');
    range = str2double(frange);
end

havestart =  strfind(omwav.INFO.Title,'Session:');
if (isempty(havestart)==0)
    
    tokenz = strsplit(omwav.INFO.Title,{' ','\n',','});
    %tokenz = strsplit(omwav.INFO.Title,'\n');
    
    I = find(strcmp(tokenz,'Session:')==1);
    
    if isempty(I)==0
        omwav.INFO.session = char(tokenz(I+1));
    end
    
    I = find(strcmp(tokenz,'Start:')==1);
    if isempty(I)==0
        fdate = sprintf('%s %s',tokenz{I+1},tokenz{I+2});
        starttime = datenum(fdate,'yyyy-mm-dd HH:MM:SS.FFF');
        %the matlab time
        omwav.INFO.titleStart = starttime;
        omwav.INFO.startDateStr = fdate;
    end
    
    I = find(strcmp(tokenz,'Stop:')==1);
    
    if isempty(I)==0
        fdate = sprintf('%s %s',tokenz{I+1},tokenz{I+2});
        stoptime = datenum(fdate,'yyyy-mm-dd HH:MM:SS.FFF');
        %the matlab time
        omwav.INFO.titleStop = stoptime;
        omwav.INFO.stopDateStr = fdate;
    end
    
    I = find(strcmp(tokenz,'Metadata:')==1);
    omwav.INFO.metadata = "";
    
    if isempty(I)==0 && length(tokenz)>=(I+1)
        
        omwav.INFO.metadata = char(tokenz{I+1});
    end
    
    I = find(strcmp(tokenz,'Config-A:')==1);

    if isempty(I)==0
        omwav.INFO.tsf = str2double(tokenz{I+1});
        omwav.INFO.trange = str2double(tokenz{I+2});
    end
end

havestart =  strfind(omwav.INFO.Artist,'Id:');
if (isempty(havestart)==0)
    tokenz = strsplit(omwav.INFO.Artist,'\n');
    omwav.INFO.ID = char(strrep(tokenz(1),'Id: ',''));
end

havestart =  strfind(omwav.INFO.Artist,'Device:');
if (isempty(havestart)==0)
    tokenz = strsplit(omwav.INFO.Artist,'\n');
    omwav.INFO.device = char(strrep(tokenz(2),'Device: ',''));
end

havestart =  strfind(omwav.INFO.Artist,'Revision:');
if (isempty(havestart)==0)
    tokenz = strsplit(omwav.INFO.Artist,'\n');
    omwav.INFO.revision = char(strrep(tokenz(3),'Revision: ',''));
end

havestart =  strfind(omwav.INFO.Artist,'Firmware:');
if (isempty(havestart)==0)
    tokenz = strsplit(omwav.INFO.Artist,'\n');
    omwav.INFO.firmware = char(strrep(tokenz(4),'Firmware: ',''));
end

omwav.INFO.range = range;
%Converting the acceleration data
omwav.raw = data(:,1:3).*range;
sf = omwav.INFO.SampleRate;

if (omwav.INFO.NumChannels>3)
    data = audioread(filename,'native');
    
    temp = (double(bitand(1023,data(3:sf:end,4))).*75000/256-50000)./1000;
    
    if (isempty(readblock)==0)
        
        wtsec = round(readblock./sf);
        if (wtsec(1) < 1)
            wtsec(1) = 1;
        end
    else
        wtsec = [1 length(temp)];
    end
    
    omwav.temp = temp(wtsec(1):wtsec(2));
    
    temp = double(bitand(1023,data(2:sf:end,4)));
    
    omwav.light = temp(wtsec(1):wtsec(2));
    
    temp = double(bitand(1023,data(1:sf:end,4)));
    omwav.bat = temp(wtsec(1):wtsec(2));
end

end

