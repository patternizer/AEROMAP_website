function [names_AERONET,data_AERONET,str_AERONET]=call_load_AERONET_data(FLAG_P,FLAG_sampling_rate)
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SIZES: .Dubovik(150),P180(4) + 6 spatial parameters --> [n x 160] 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% INITIALISE matrices & strings 
    data_AERONET                = [];
    names_AERONET               = {};
    str_inputs                  = {};
    C                           = [];
    CP                          = [];
    D                           = [];
    DP                          = [];
    E                           = [];
    F                           = {};
    row_pointerD                = 0;
    row_pointerP                = 0;
    row_pointerE                = 0;
    row_pointerF                = 0;
    n_pointer                   = 0;
    file_count                  = 0;
    
    %% LOAD AERONET raw data & append P(180,lambda)
    if isequal(FLAG_sampling_rate,1)
        [files,path] = uigetfile({'*.dubovik'},'Select the AERONET <L2 Inversion> combined file(s):','MultiSelect', 'on'); % all points data
    elseif isequal(FLAG_sampling_rate,2)
        [files,path] = uigetfile({'*.dubovikday'},'Select the AERONET <L2 Inversion> combined file(s):','MultiSelect', 'on'); % daily averages
    elseif isequal(FLAG_sampling_rate,3)
        [files,path] = uigetfile({'*.dubovikmon'},'Select the AERONET <L2 Inversion> combined file(s):','MultiSelect', 'on'); % monthly averages
    end
    files = cellstr(files);
    for n = 1:length(files)    
        n_pointer = n_pointer + 1;
        % Open *.Dubovik file
        fid=fopen(fullfile(path,files{n}),'r');
        n_lines = 0; 
        while (fgets(fid) ~= -1),
            n_lines = n_lines+1;
        end
        frewind(fid);
        n_linesD = n_lines-4;
        disp(num2str(n_linesD));
        if isequal(n_linesD,0) % daily averages    
            D(row_pointerD+1,:)     = ones(1,119)*NaN;            
            DP(row_pointerP+1,:)    = ones(1,670)*NaN; 
            E(row_pointerE+1,:)     = ones(1,6)*NaN;
            F(row_pointerF+1,:)     = NaN;                                                
            continue % go to next loop index if file is empty
        else   
        end        
        % Extract: Logitude & Latitude (and convert to integers) and assign to matrix E        
        C_headersE          = textscan(fid, '%s',8, 'delimiter',',', 'HeaderLines',0)';        
        frewind(fid);        
        C_headersE          = C_headersE(1)';        
        str_name2           = regexp(C_headersE{1}(2), '\=', 'split');                                     
        str_name3           = regexp(C_headersE{1}(3), '\=', 'split');         
        str_name4           = regexp(C_headersE{1}(4), '\=', 'split');         
        str_name5           = regexp(C_headersE{1}(5), '\=', 'split');                     
        site_name           = str_name2{1}(2);          
        Longitude_Dubovik   = str2double(str_name3{1}(2));        
        Latitude_Dubovik    = str2double(str_name4{1}(2));                    
        Elevation           = str2double(str_name5{1}(2));                              
        CE_temp             = zeros(1,6);        
        CE                  = zeros(n_linesD,6);         
        CE_temp(1,1)        = int8(Elevation);                        
        CE_temp(1,2)        = Longitude_Dubovik;                        
        CE_temp(1,3)        = Latitude_Dubovik;                        
        CE_temp(1,4)        = 180+CE_temp(1,2); %longitude [0,360]                        
        CE_temp(1,5)        = 90-CE_temp(1,3);  %latitute  [0,180]                             
        if isequal(round(CE_temp(1,5)),0) && isequal(round(CE_temp(1,4)),0)                        
            CE_temp(1,6) = 1;                               
        elseif isequal(round(CE_temp(1,5)),0) && ~isequal(round(CE_temp(1,4)),0)                        
            CE_temp(1,6) = round(CE_temp(1,4));                               
        elseif ~isequal(round(CE_temp(1,5)),0) && isequal(round(CE_temp(1,4)),0)                          
            CE_temp(1,6) = 360*(round(CE_temp(1,5))-1)+1;                                              
        else            
            CE_temp(1,6) = 360*(round(CE_temp(1,5))-1)+round(CE_temp(1,4));            
        end        
        for i=1:n_linesD % Fill columns with Elevation, Longitude(Dobovik), Latitude(Dubovik), Longitude(MODIS), Latitude(MODIS), Pixel Number        
            E(row_pointerE+i,:)  = CE_temp;            
            F(row_pointerF+i,:)  = site_name;                                                   
        end        
        row_pointerE = row_pointerE+n_linesD;        
        row_pointerF = row_pointerF+n_linesD;                                                              
        % Extract dobovik data to matrix D              
        if isequal(FLAG_sampling_rate,1)        
            C_data = textscan(fid, '%s',n_lines, 'delimiter','\n', 'HeaderLines',4); % all points data            
            C=zeros(length(C_data),150); % all points data              
        elseif isequal(FLAG_sampling_rate,2)        
            C_data = textscan(fid, '%s',n_lines, 'delimiter','\n', 'HeaderLines',4); % daily averages            
            C=zeros(length(C_data),238); % daily averages             
        elseif isequal(FLAG_sampling_rate,3)        
            C_data = textscan(fid, '%s',n_lines, 'delimiter','\n', 'HeaderLines',4); % monthly averages            
            C=zeros(length(C_data),118); % monthly averages            
        end        
        for i=1:length(C_data)        
            str_C_data = regexp(C_data{i}, ',', 'split');            
        end        
        for i=1:n_linesD        
            date_raw             = datenum(str_C_data{i}(1),'dd:mm:yyyy')';            
            time_raw             = datenum(str_C_data{i}(2),'HH:MM:SS')';            
            date_corrected       = date_raw+time_raw-datenum('00:00','HH:MM');            
            C(i,1)               = date_corrected;            
            C(i,2)               = date_raw;                   
            C(i,3:end)           = str2double(str_C_data{i}(3:end));               
            D(row_pointerD+i,:)   = C(i,:);            
        end        
        row_pointerD = row_pointerD+n_linesD;        
        fclose(fid);                   
        if isequal(FLAG_P,1)                  
            for i=1:n_linesD                
                DP(row_pointerP+i,:) = ones(1,670)*NaN;                  
            end            
            row_pointerP=row_pointerP+n_linesD;  
            % SAVE EVERY 10 FILES
            if isequal(n_pointer,10)   
                file_count = file_count + 1;
                data_temp  = [];
                str_inputs = {};
                names_temp = {};
                D_temp = D(:,1:119); % daily averages            
                data_temp = [D_temp,DP(:,86),DP(:,169),DP(:,252),DP(:,335),E(:,1),E(:,2),E(:,3),E(:,4),E(:,5),E(:,6)]'; % daily averages                
                str_temp = {'Date(dd-mm-yyyy)','Time(hh:mm:ss)','Julian_Day','AOT 1640','AOT 1020','AOT 870','AOT 675','AOT 667','AOT 555','AOT 551','AOT 532','AOT 531','AOT 500','AOT 490','AOT 443','AOT 440','AOT 412','AOT 380','AOT 340','Water(cm)','AOTExt439-T','AOTExt673-T','AOTExt870-T','AOTExt1018-T','AOTExt439-F','AOTExt673-F','AOTExt870-F','AOTExt1018-F','AOTExt439-C','AOTExt673-C','AOTExt870-C','AOTExt1018-C','870-440AngstromParam.[AOTExt]-Total','SSA439-T','SSA673-T','SSA870-T','SSA1018-T','AOTAbsp439-T','AOTAbsp673-T','AOTAbsp870-T','AOTAbsp1018-T','870-440AngstromParam.[AOTAbsp]','REFR(439)','REFR(673)','REFR(870)','REFR(1018)','REFI(439)','REFI(673)','REFI(870)','REFI(1018)','ASYM439-T','ASYM673-T','ASYM870-T','ASYM1018-T','ASYM439-F','ASYM673-F','ASYM870-F','ASYM1018-F','ASYM439-C','ASYM673-C','ASYM870-C','ASYM1018-C','0.050000','0.065604','0.086077','0.112939','0.148184','0.194429','0.255105','0.334716','0.439173','0.576227','0.756052','0.991996','1.301571','1.707757','2.240702','2.939966','3.857452','5.061260','6.640745','8.713145','11.432287','15.000000','Inflection_Point[um]','VolCon-T','EffRad-T','VolMedianRad-T','StdDev-T','VolCon-F','EffRad-F','VolMedianRad-F','StdDev-F','VolCon-C','EffRad-C','VolMedianRad-C','StdDev-C','Altitude(BOA)(km)','Altitude(TOA)(km)','DownwardFlux(BOA)','DownwardFlux(TOA)','UpwardFlux(BOA)','UpwardFlux(TOA)','RadiativeForcing(BOA)','RadiativeForcing(TOA)','ForcingEfficiency(BOA)','ForcingEfficiency(TOA)','DownwardFlux439-T','DownwardFlux673-T','DownwardFlux870-T','DownwardFlux1018-T','UpwardFlux439-T','UpwardFlux673-T','UpwardFlux870-T','UpwardFlux1018-T','DiffuseFlux439-T','DiffuseFlux673-T','DiffuseFlux870-T','DiffuseFlux1018-T','P(180)[438nm]','P(180)[669nm]','P(180)[871nm]','P(180)[1022nm]','Elevation','Longitude(Dubovik)','Latitude(Dubovik)','Longitude(MODIS)','Latitude(MODIS)','Pixel Scan Number'}; % daily averages            
                names_temp = F;                     
                temp_file = ['DATA','.mat'];    
                save(temp_file,'data_temp','str_temp','names_temp','n');
                n_pointer = 0;                    
            end                  
            continue % go to next loop index if file is empty            
        else            
        end                
        % Open *.Pfn file and extract data to matrix DP        
        [path_name,file_name,file_ext] = fileparts(files{n});        
        if isequal(FLAG_sampling_rate,1)        
            fidP=fopen(fullfile(path,[file_name '.pfn']),'r');    % all points data            
        elseif isequal(FLAG_sampling_rate,2)        
            fidP=fopen(fullfile(path,[file_name '.pfnday']),'r'); % daily averages            
        elseif isequal(FLAG_sampling_rate,3)        
            fidP=fopen(fullfile(path,[file_name '.pfnmon']),'r'); % monthly averages            
        end        
        n_linesP = 0;        
        while (fgets(fidP) ~= -1),        
            n_linesP = n_linesP+1;            
        end        
        frewind(fidP);        
        if isequal(FLAG_sampling_rate,1)        
            n_lines_header=4;            
        elseif isequal(FLAG_sampling_rate,2)        
            n_lines_header=5;            
        elseif isequal(FLAG_sampling_rate,3)        
            n_lines_header=4;            
        end        
        n_linesPD = n_linesP-n_lines_header;        
        if isequal(n_linesPD,0)     
            for i=1:n_linesD                            
                DP(row_pointerP+i,:) = ones(1,670)*NaN;                                  
            end            
            row_pointerP=row_pointerP+n_linesD;            
            continue % go to next loop index if file is empty            
        else            
        end        
        % Extract P(180,lambda) data to matrix DP [4 columns]           
        if isequal(FLAG_sampling_rate,1)        
            C_dataP = textscan(fidP, '%s',n_linesP, 'delimiter','\n', 'HeaderLines',4);  % all points data                                
            CP=zeros(length(C_dataP),366); % all points            
        elseif isequal(FLAG_sampling_rate,2)        
            C_dataP = textscan(fidP, '%s',n_linesP, 'delimiter','\n', 'HeaderLines',5); % daily averages            
            CP=zeros(length(C_dataP),670); % daily averages            
        elseif isequal(FLAG_sampling_rate,3)        
            C_dataP = textscan(fidP, '%s',n_linesP, 'delimiter','\n', 'HeaderLines',4);  % monthly averages            
            CP=zeros(length(C_dataP),1329); % monthly averages            
        end        
        for i=1:length(C_dataP)        
            str_C_dataP = regexp(C_dataP{i}, ',', 'split');            
        end        
        for i=1:n_linesPD % convert date and time columns [1 & 2] to serial number format        
            date_rawP                = datenum(str_C_dataP{i}(1),'dd:mm:yyyy')';            
            time_rawP                = datenum(str_C_dataP{i}(2),'HH:MM:SS')';            
            date_correctedP          = date_rawP+time_rawP-datenum('00:00','HH:MM');            
            CP(i,1)                  = date_correctedP;            
            CP(i,2)                  = date_rawP;                   
            CP(i,3:end)              = str2double(str_C_dataP{i}(3:end));               
            DP(row_pointerP+i,:)     = CP(i,:);            
        end        
        row_pointerP=row_pointerP+n_linesPD;        
        fclose(fidP);                                                               
        if isequal(n_linesD,n_linesPD)        
        else                    
            for i=1:n_linesD                            
                DP(row_pointerP+i,:) = ones(1,670)*NaN;                                  
            end            
            row_pointerP=row_pointerP+n_linesD;            
            continue % go to next loop index if file is empty 
        end                   
    end %for n = 1:length(files)    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % STORE DATA
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    names_AERONET   = F;    
    if isequal(FLAG_sampling_rate,1)
        D               = D(:,1:119); % all points data
        data_AERONET    = [D,DP(:,86),DP(:,169),DP(:,252),DP(:,335),E(:,1),E(:,2),E(:,3),E(:,4),E(:,5),E(:,6)]'; % all points
        str_AERONET     = {'Date(dd-mm-yyyy)','Time(hh:mm:ss)','Julian_Day','AOT 1640','AOT 1020','AOT 870','AOT 675','AOT 667','AOT 555','AOT 551','AOT 532','AOT 531','AOT 500','AOT 490','AOT 443','AOT 440','AOT 412','AOT 380','AOT 340','Water(cm)','AOTExt439-T','AOTExt673-T','AOTExt870-T','AOTExt1018-T','AOTExt439-F','AOTExt673-F','AOTExt870-F','AOTExt1018-F','AOTExt439-C','AOTExt673-C','AOTExt870-C','AOTExt1018-C','870-440AngstromParam.[AOTExt]-Total','SSA439-T','SSA673-T','SSA870-T','SSA1018-T','AOTAbsp439-T','AOTAbsp673-T','AOTAbsp870-T','AOTAbsp1018-T','870-440AngstromParam.[AOTAbsp]','REFR(439)','REFR(673)','REFR(870)','REFR(1018)','REFI(439)','REFI(673)','REFI(870)','REFI(1018)','ASYM439-T','ASYM673-T','ASYM870-T','ASYM1018-T','ASYM439-F','ASYM673-F','ASYM870-F','ASYM1018-F','ASYM439-C','ASYM673-C','ASYM870-C','ASYM1018-C','0.050000','0.065604','0.086077','0.112939','0.148184','0.194429','0.255105','0.334716','0.439173','0.576227','0.756052','0.991996','1.301571','1.707757','2.240702','2.939966','3.857452','5.061260','6.640745','8.713145','11.432287','15.000000','Inflection_Point[um]','VolCon-T','EffRad-T','VolMedianRad-T','StdDev-T','VolCon-F','EffRad-F','VolMedianRad-F','StdDev-F','VolCon-C','EffRad-C','VolMedianRad-C','StdDev-C','Altitude(BOA)(km)','Altitude(TOA)(km)','DownwardFlux(BOA)','DownwardFlux(TOA)','UpwardFlux(BOA)','UpwardFlux(TOA)','RadiativeForcing(BOA)','RadiativeForcing(TOA)','ForcingEfficiency(BOA)','ForcingEfficiency(TOA)','DownwardFlux439-T','DownwardFlux673-T','DownwardFlux870-T','DownwardFlux1018-T','UpwardFlux439-T','UpwardFlux673-T','UpwardFlux870-T','UpwardFlux1018-T','DiffuseFlux439-T','DiffuseFlux673-T','DiffuseFlux870-T','DiffuseFlux1018-T','P(180)[438nm]','P(180)[669nm]','P(180)[871nm]','P(180)[1022nm]','Elevation','Longitude(Dubovik)','Latitude(Dubovik)','Longitude(MODIS)','Latitude(MODIS)','Pixel Scan Number'}; % all point data 
    elseif isequal(FLAG_sampling_rate,2)
        D               = D(:,1:119); % daily averages
        data_AERONET    = [D,DP(:,86),DP(:,169),DP(:,252),DP(:,335),E(:,1),E(:,2),E(:,3),E(:,4),E(:,5),E(:,6)]'; % daily averages    
        str_AERONET     = {'Date(dd-mm-yyyy)','Time(hh:mm:ss)','Julian_Day','AOT 1640','AOT 1020','AOT 870','AOT 675','AOT 667','AOT 555','AOT 551','AOT 532','AOT 531','AOT 500','AOT 490','AOT 443','AOT 440','AOT 412','AOT 380','AOT 340','Water(cm)','AOTExt439-T','AOTExt673-T','AOTExt870-T','AOTExt1018-T','AOTExt439-F','AOTExt673-F','AOTExt870-F','AOTExt1018-F','AOTExt439-C','AOTExt673-C','AOTExt870-C','AOTExt1018-C','870-440AngstromParam.[AOTExt]-Total','SSA439-T','SSA673-T','SSA870-T','SSA1018-T','AOTAbsp439-T','AOTAbsp673-T','AOTAbsp870-T','AOTAbsp1018-T','870-440AngstromParam.[AOTAbsp]','REFR(439)','REFR(673)','REFR(870)','REFR(1018)','REFI(439)','REFI(673)','REFI(870)','REFI(1018)','ASYM439-T','ASYM673-T','ASYM870-T','ASYM1018-T','ASYM439-F','ASYM673-F','ASYM870-F','ASYM1018-F','ASYM439-C','ASYM673-C','ASYM870-C','ASYM1018-C','0.050000','0.065604','0.086077','0.112939','0.148184','0.194429','0.255105','0.334716','0.439173','0.576227','0.756052','0.991996','1.301571','1.707757','2.240702','2.939966','3.857452','5.061260','6.640745','8.713145','11.432287','15.000000','Inflection_Point[um]','VolCon-T','EffRad-T','VolMedianRad-T','StdDev-T','VolCon-F','EffRad-F','VolMedianRad-F','StdDev-F','VolCon-C','EffRad-C','VolMedianRad-C','StdDev-C','Altitude(BOA)(km)','Altitude(TOA)(km)','DownwardFlux(BOA)','DownwardFlux(TOA)','UpwardFlux(BOA)','UpwardFlux(TOA)','RadiativeForcing(BOA)','RadiativeForcing(TOA)','ForcingEfficiency(BOA)','ForcingEfficiency(TOA)','DownwardFlux439-T','DownwardFlux673-T','DownwardFlux870-T','DownwardFlux1018-T','UpwardFlux439-T','UpwardFlux673-T','UpwardFlux870-T','UpwardFlux1018-T','DiffuseFlux439-T','DiffuseFlux673-T','DiffuseFlux870-T','DiffuseFlux1018-T','P(180)[438nm]','P(180)[669nm]','P(180)[871nm]','P(180)[1022nm]','Elevation','Longitude(Dubovik)','Latitude(Dubovik)','Longitude(MODIS)','Latitude(MODIS)','Pixel Scan Number'}; % daily averages
    elseif isequal(FLAG_sampling_rate,3)
        D               = D(:,1:118); % monthly averages
        data_AERONET    = [D,DP(:,86),DP(:,169),DP(:,252),DP(:,335),E(:,1),E(:,2),E(:,3),E(:,4),E(:,5),E(:,6)]'; % monthly averages
        str_AERONET     = {'','yyyy-mm','Data Type','AOT 1640','AOT 1020','AOT 870','AOT 675','AOT 667','AOT 555','AOT 551','AOT 532','AOT 531','AOT 500','AOT 490','AOT 443','AOT 440','AOT 412','AOT 380','AOT 340','Water(cm)','AOTExt439-T','AOTExt673-T','AOTExt870-T','AOTExt1018-T','AOTExt439-F','AOTExt673-F','AOTExt870-F','AOTExt1018-F','AOTExt439-C','AOTExt673-C','AOTExt870-C','AOTExt1018-C','870-440AngstromParam.[AOTExt]-Total','SSA439-T','SSA673-T','SSA870-T','SSA1018-T','AOTAbsp439-T','AOTAbsp673-T','AOTAbsp870-T','AOTAbsp1018-T','870-440AngstromParam.[AOTAbsp]','REFR(439)','REFR(673)','REFR(870)','REFR(1018)','REFI(439)','REFI(673)','REFI(870)','REFI(1018)','ASYM439-T','ASYM673-T','ASYM870-T','ASYM1018-T','ASYM439-F','ASYM673-F','ASYM870-F','ASYM1018-F','ASYM439-C','ASYM673-C','ASYM870-C','ASYM1018-C','0.050000','0.065604','0.086077','0.112939','0.148184','0.194429','0.255105','0.334716','0.439173','0.576227','0.756052','0.991996','1.301571','1.707757','2.240702','2.939966','3.857452','5.061260','6.640745','8.713145','11.432287','15.000000','Inflection_Point[um]','VolCon-T','EffRad-T','VolMedianRad-T','StdDev-T','VolCon-F','EffRad-F','VolMedianRad-F','StdDev-F','VolCon-C','EffRad-C','VolMedianRad-C','StdDev-C','Altitude(BOA)(km)','Altitude(TOA)(km)','DownwardFlux(BOA)','DownwardFlux(TOA)','UpwardFlux(BOA)','UpwardFlux(TOA)','RadiativeForcing(BOA)','RadiativeForcing(TOA)','ForcingEfficiency(BOA)','ForcingEfficiency(TOA)','DownwardFlux439-T','DownwardFlux673-T','DownwardFlux870-T','DownwardFlux1018-T','UpwardFlux439-T','UpwardFlux673-T','UpwardFlux870-T','UpwardFlux1018-T','DiffuseFlux439-T','DiffuseFlux673-T','DiffuseFlux870-T','DiffuseFlux1018-T','P(180)[438nm]','P(180)[669nm]','P(180)[871nm]','P(180)[1022nm]','Elevation','Longitude(Dubovik)','Latitude(Dubovik)','Longitude(MODIS)','Latitude(MODIS)','Pixel Scan Number'}; % monthly averages
    end      

end % function