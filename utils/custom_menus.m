function custom_menus(hFig, path_data)
% Creates Menus from data read from the 'OPTcontrol.txt' file under the MIR_CUSTOM_MENU keyword
%
%	This functions is Callbacked by mirone at each Mirone figure creation time. Than:
%		hFig		handle of the mirone fig
%		path_data	Mirone data dir
%
%	The OPTcontrol.txt, under the MIR_CUSTOM_MENU keyword, has a form of this type (example)
%		Geography,Basins[/sub],dir

%	Copyright (c) 2004-2018 by J. Luis
%
% 	This program is part of Mirone and is free software; you can redistribute
% 	it and/or modify it under the terms of the GNU Lesser General Public
% 	License as published by the Free Software Foundation; either
% 	version 2.1 of the License, or any later version.
% 
% 	This program is distributed in the hope that it will be useful,
% 	but WITHOUT ANY WARRANTY; without even the implied warranty of
% 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
% 	Lesser General Public License for more details.
%
%	Contact info: w3.ualg.pt/~jluis/mirone
% --------------------------------------------------------------------

% $Id$

	% Example1: Geography,Basins[/sub],dir (simple case of directing to the DIR where file lieves)
	% Example2: CustomIsoc,AF-NAM,C:\SVN\mironeWC\data,isochrons_AF.dat,Isochron
	%			Here fourth arg contains the file to open and fifth (optional) one of the selecting OPT2 used by load_xyz()

	fname = [path_data 'OPTcontrol.txt'];
	if (exist(fname,'file') ~= 2),	return,		end
	fid = fopen(fname);
	if (fid < 0),	return,		end

	c = (fread(fid,'*char'))';      fclose(fid);
	lines = strread(c,'%s','delimiter','\n');   clear c fid;

	n = 1;		menus = cell(10,1);
	for (k = 1:numel(lines))
		if (isempty(lines{k}) || lines{k}(1) == '#' || ~strncmp(lines{k},'MIR_CUSTOM_MENU',15))
			continue
		end
		menus{n} = ddewhite(lines{k}(17:end));
		n = n + 1;
	end
	menus(n:end) = [];

	% Parse the file contents
	m = numel(menus);		c = false(m,1);			is_dir = false(m, 1);
	mainMenu = cell(m,1);	subMenu1 = cell(m,1);	OPT = cell(m,1);
	subMenu2 = cell(m,1);	dataDir  = cell(m,1);
	for (k = 1:m)
		ind = strfind(menus{k}, ',');
		mainMenu{k} = menus{k}(1:ind(1)-1);
		subMenu1{k}  = menus{k}(ind(1)+1:ind(2)-1);	% This one must further be parsed for Basins[/sub]
		inds = strfind(subMenu1{k}, '/');
		if (~isempty(inds))
			subMenu2{k} = subMenu1{k}(inds(1)+1:end);
			subMenu1{k}(inds(1):end) = [];
		end
		if (numel(ind) == 2)			% A DIR only menu
			dataDir{k} = menus{k}(ind(2)+1:end);
			if (exist(dataDir{k},'dir') ~= 7),		c(k) = true;	end		% Dir does not exist. Flag for killing
			is_dir(k) = true;
		else							% Load a specific file
			if (numel(ind) == 4)
				OPT{k} = menus{k}(ind(4)+1:end);
				menus{k}(ind(4):end) = [];
			end
			dataDir{k} = [menus{k}(ind(2)+1:ind(3)-1) '/' menus{k}(ind(3)+1:end);];
			if (exist(dataDir{k},'file') ~= 2),		c(k) = true;	end		% File does not exist. Flag for killing
		end
	end
	mainMenu(c) = [];	subMenu1(c) = [];	subMenu2(c) = [];	dataDir(c) = [];	is_dir(c) = [];		OPT(c) = [];
	m = numel(mainMenu);

	for (k = 1:m)
		if (~is_dir(k)),	continue,	end
		hThis = findobj(hFig,'Tag',mainMenu{k});
		if (isempty(hThis))
			% Make a new one on the main toolbar. Allow it?
		end

		if (k == 1)
			hSbub1 = uimenu('Parent',hThis,'Label',['Custom -> ' subMenu1{k}], 'Sep','on');
		elseif (~strcmp(subMenu1{k}, subMenu1{k-1}))		% MUST DO A BETTER ('GLOBAL') REPETITION SEARCHING
			hSbub1 = uimenu('Parent',hThis,'Label',['Custom -> ' subMenu1{k}]);
		end
		if (isempty(subMenu2{k}))
			set(hSbub1, 'Callback',['mirone(''TransferB_CB'',guidata(gcf),''guessType'',''',dataDir{k},''')'])
		else
			uimenu('Parent',hSbub1,'Label',subMenu2{k}, 'Callback', ...
				['mirone(''TransferB_CB'',guidata(gcf),''guessType'',''',dataDir{k},''')']);
		end
	end

	% Here deal with the case where a specific file will be loaded
	for (k = 1:m)
		if (is_dir(k)),		continue,	end
		hThis = findobj(hFig,'Tag',mainMenu{k});
		hSbub1 = uimenu('Parent',hThis,'Label',subMenu1{k});
		if (isempty(OPT{k}))		% Call the generic file loader
			drv = aux_funs('findFileType',dataDir{k});
			if (isempty(drv)),	continue,	end			% MUST print a error message			
			if (isempty(subMenu2{k}))
				set(hSbub1, 'Callback',sprintf('mirone(''gateLoadFile'',guidata(gcbo), ''%s'', ''%s'');', drv, dataDir{k}))
			else
				uimenu('Parent',hSbub1,'Label',subMenu2{k}, 'Callback', ...
					sprintf('mirone(''gateLoadFile'',guidata(gcbo), ''%s'', ''%s'');', drv, dataDir{k}))
			end
		else						% Load vector data with load_xyz()
			if (isempty(subMenu2{k}))
				set(hSbub1, 'Callback',sprintf('load_xyz(guidata(gcbo), ''%s'', ''%s'')', dataDir{k}, OPT{k}))
			else
				uimenu('Parent',hSbub1,'Label',subMenu2{k}, 'Callback', ...
					sprintf('load_xyz(guidata(gcbo), ''%s'', ''%s'')', dataDir{k}, OPT{k}))
			end
		end
	end
