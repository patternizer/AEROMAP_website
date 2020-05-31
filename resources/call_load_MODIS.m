function [dataA,dataM,rows_to_remove_MODIS]=call_load_MODIS(data,FLAG_run_mode)

    % MODIS DATA HANDLING       
    [filename, pathname, filterindex] = uigetfile({  '*.xlsx'},'Select the MODIS dataset(s) to use','MultiSelect', 'off');
    xfile = fullfile(pathname, filename);
    [~, ~, raw2] = xlsread(xfile,'1');
    raw2=raw2(1:end,:); % strip headers
    % raw=raw(:,[4:end]); % strip date & time
%     non_numeric = cellfun(@(x) ~isnumeric(x) || isnan(x),raw2); % find non-numeric cells
%     raw2(non_numeric) = {888}; % replace non-numeric cells    
    % MAKE MODIS DATA MATRIX EQUAL IN SHAPE TO AERONET DATA MATRIX
    temp0=zeros(size(data,1),size(data,2));    
    temp1=cell2mat(raw2)'; 
    cols_to_remove = any(temp1==888,1);
    temp1(:,cols_to_remove) = [];
%     for k=1:size(temp1,2) % LOOP TO RETAIN FMF=0 CELLS
%         if isequal(temp1(6,k),0)
%             temp1(6,k)=0.000001;            
%         end        
%     end        
    dataM0 = temp1; % store original MODIS data
    MATLAB_dates_0 = x2mdate(dataM0(1,:));
    dataM0(1,:) = MATLAB_dates_0;
    
    if isequal(FLAG_run_mode,3)
        datesM=dataM0(1,:);
        dataM=dataM0;
        dataA=[];
        rows_to_remove_MODIS=[];
    else      
        rows_to_remove_MODIS=ones(size(data,2),1);
        dates_common = intersect(data(1,:),MATLAB_dates_0);
        n_synchronous = numel(dates_common);
%         dataA=zeros(size(data,1),n_synchronous);
%         dataM=zeros(size(dataM0,1),n_synchronous);
        dataA=[];
        dataM=[];
        for i=1:n_synchronous
            rows_to_remove_MODIS(find(data(1,:)==dates_common(i)))=0;
%             dataA(:,i)=data(:,find(data(1,:)==dates_common(i)));
%             dataM(:,i)=dataM0(:,find(dataM0(1,:)==dates_common(i)));
            dataA_temp=data(:,find(data(1,:)==dates_common(i)));
            common_date=find(dataM0(1,:)==dates_common(i));
            dataM_temp=dataM0(:,common_date(1));
            dataA=[dataA,dataA_temp];
            dataM=[dataM,dataM_temp];
        end
        rows_to_remove_MODIS=logical(rows_to_remove_MODIS);
%         [r1,c1] = size(temp0);
%         [r2,c2] = size(temp1);    
%         data_MODIS = zeros(max(r1,r2),max(c1,c2));
%         data_MODIS(1:r1,1:c1) = temp0;                      
%         data_MODIS(1:r2,1:c2) = data_MODIS(1:r2,1:c2)+temp1;     
%         MATLAB_dates = x2mdate(data_MODIS(1,:));
%         data_MODIS(1,:) = MATLAB_dates;
%         % TAG SYNCHRONOUS DATA
%         data0m = zeros(size(data,1),size(data,2));
%         data1m = zeros(5,size(data,2)); % 5 MODIS Inputs
%         for j=1:c1
%             for i=1:c1
%                 if isequal(data_MODIS(1,j)-data(2,i),0)            
%                     data0m(:,j) = data(:,i);
%                     data1m(:,j) = data_MODIS(2:6,j); % MODIS DATA APPENDED TO AERONET DATA    
%                 end            
%             end        
%         end    
%         data0m=[data0m;data1m(1,:);data1m(2,:);data1m(3,:);data1m(4,:);data1m(5,:)];
%         % REMOVE NON-SYNCHRONOUS DATA
%         temp_data=data0m;
%         [rows,cols]=size(temp_data);
%         temp_col=zeros(rows,1);
%         for i=1:cols
%             if temp_data(:,i)==temp_col                     
%                 temp_data(:,i)=999;
%             end        
%         end    
%         cols_to_remove              = any(temp_data==999,1);       
%         rows_to_remove_MODIS        = cols_to_remove';
%         temp_data(:,cols_to_remove) = []; 
%         dataA                      = temp_data([1:148],:);
%         dataM                      = temp_data([149:end],:);
%         datesM                     = temp_data(1,:);
    end % isequal(FLAG_run_mode,3)

end