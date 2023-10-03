function [markers] = ctf_read_markerfile(ctf,mrkFile);

% ctf_read_markerfile - load data from MarkerFile.mrk in .ds folder
%
% [markers] = ctf_read_markerfile([ctf],[mrkFile]);
%
% ctf.folder is a .ds path, if it is missing or invalid a gui prompts
% for the folder.  ctf is a struct generated by this and other
% ctf_read_*.m functions.
%
% mrkFile - this can be used to override the default behavior of reading
%   *.ds/MarkerFile.cls, it should be a complete path to a .mrk file; eg:
%   ctf = ctf_read_markerfile([],mrkFile)
%   ctf = ctf_read_markerfile([],'/<completepath>/MarkerFile.mrk')
%
% Returns the 'markers' struct:
%
% markers.number_markers - scalar
% markers.number_samples - column array, number_markers x 1
% markers.marker_names - cell array of strings, number_markers x 1
% markers.trial_times - cell array of matrices, number_markers x 1 each
% containing number_samples x 2 matrix, where column 1 indicates the trial
% number containing the marker and column 2 indicates the offset (in sec).
%
%      <>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
%      <                                                      >
%      <                    DISCLAIMER:                       >
%      <                                                      >
%      < THIS PROGRAM IS INTENDED FOR RESEARCH PURPOSES ONLY. >
%      < THIS PROGRAM IS IN NO WAY INTENDED FOR CLINICAL OR   >
%      <                    OFFICIAL USE.                     >
%      <                                                      >
%      <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>
%

% $Revision: 1.1 $ $Date: 2009-01-30 03:49:27 $

% Copyright (C) 2004  Darren L. Weber
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

% Modified: 12/2003, Darren.Weber_at_radiology.ucsf.edu
%                    - modified from NIH code readmarkerfile.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

markers = [];
ver = '$Revision: 1.1 $';
fprintf('\nCTF_READ_MARKERFILE [v %s]\n',ver(11:15)); tic;

  

if ~exist('mrkFile','var'), mrkFile = ''; end
if isempty(mrkFile), mrkFile = ''; end
if isstruct(mrkFile), mrkFile = ''; end
if mrkFile,
  fid = fopen(mrkFile,'r');
else
  fid = -1;
end

if fid < 0,
  
  % check the ctf.folder
  if ~exist('ctf','var'),
    ctf = ctf_folder;
  else
    ctf = ctf_folder([],ctf);
  end
  %fprintf('...reading from %s\n',ctf.folder);
  
  % use the ctf.folder to find .mrk file
  if isfield(ctf,'folder'),
    if isempty(ctf.folder),
      error('ctf.folder is empty and no mrkFile specified');
    else
      % check for a marker file
      mrkFile = findmrkfile( ctf.folder );
      if exist(mrkFile) == 2,
        fid = fopen(mrkFile,'r');
      else,
        warning('...MarkerFile.mrk does not exist in this .ds folder.');
        ctf.markers = [];
        return
      end
    end
  else
    error('ctf.folder is not a field of the ctf struct');
  end
end




% read the marker file, delimited by carriage returns.  This new array is
% used below to extract relevant information
fprintf('...reading marker file:\n...%s\n', mrkFile);
fprintf('...reading file text, using ''\\n'' delimiter\n');
mrkFileText = textread(mrkFile,'%s','delimiter','\n');

% extract the number of markers
number_markers_index = strmatch('NUMBER OF MARKERS:',mrkFileText,'exact');
number_markers = str2num(mrkFileText{number_markers_index + 1});
fprintf('...found %d marker types:\n',number_markers);

% extract marker names (this can be an array, if number_markers > 1)
marker_names_index = strmatch('NAME:',mrkFileText,'exact');
marker_names = mrkFileText(marker_names_index + 1);
for m = 1:length(marker_names),
    fprintf('   %40s\n',marker_names{m});
end

% replace any '-' with '_' symbols in the marker names
marker_names = strrep(marker_names,'-','_');
fprintf('...replaced any - with _ symbol in marker names\n');

% extract number of marker samples
% (this can be an array, if number_markers > 1)
number_samples_index = strmatch('NUMBER OF SAMPLES:',mrkFileText,'exact');
number_samples = str2num(char(mrkFileText(number_samples_index + 1)));

% check that all the marker samples are defined
if ~all(number_samples),
    disp('One of the markers has no samples and was ignored.');
end


% extract marker trial number and time (sec), eg, find & read:
% LIST OF SAMPLES:
% TRIAL NUMBER            TIME FROM SYNC POINT (in seconds)
%                   +0                                              +0
%                   +1                                              +0
%                   +2                                              +0

fprintf('...reading trial numbers and offset time (sec)\n');

HEADER_LINES = 2;
trial = strmatch('LIST OF SAMPLES:',mrkFileText,'exact') + HEADER_LINES;

for i = find(number_samples)'
    % extract the lines of the samples, where each line contains a trial
    % number in the first column and a time offset (sec) in the 2nd column
    sample_text_rows = mrkFileText( trial(i):[trial(i) + number_samples(i)] );
    trials{i} = str2num(char(sample_text_rows));
    % add 1 to the trial numbers (which start at 0 for CTF software)
    trials{i}(:,1) = trials{i}(:,1) + 1;
end
fprintf('...added 1 to trial numbers for matlab compatibility\n');

% allocate marker information into the marker stucture
markers = struct(...
    'file',mrkFile,...
    'number_markers',number_markers,...
    'number_samples',number_samples,...
    'marker_names',marker_names,...
    'trial_times',trials');

t = toc; fprintf('...done (%6.2f sec)\n\n',t);

return



% -------------------------------------------------------
% find file name if truncated or with uppercase extension
% added by Arnaud Delorme, June 15, 2004
function mrkname = findmrkfile( folder )
    mrkname = dir([ folder filesep '*.mrk' ]);
    if isempty(mrkname)
        mrkname = dir([ folder filesep '*.MRK' ]);
    end;
    if isempty(mrkname)
        fprintf('...no file with extension .mrk or .MRK in .ds folder\n');
        mrkname = [];
    else
        mrkname = [ folder filesep mrkname.name ];
    end;
return