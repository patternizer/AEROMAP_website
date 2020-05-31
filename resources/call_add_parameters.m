function [data0,str_inputs]=call_add_parameters(data_AERONET,str_AERONET,FLAG_direct_sun)
  
    %% SECONDARY PARAMETERS
    if isequal(FLAG_direct_sun,1)
        n_points = size(data_AERONET,2);
        % No inversion-derived products 
        S_438   = ones(1,n_points)*NaN;                                         % [N,130]
        S_669   = ones(1,n_points)*NaN;                                         % [N,131]
        S_871   = ones(1,n_points)*NaN;                                         % [N,132]
        S_1022  = ones(1,n_points)*NaN;                                         % [N,133]
        FMF     = data_AERONET(90,:)./(data_AERONET(90,:)+data_AERONET(94,:));  % [N,142]: Fine Fraction    
    else        
        % Inversion-derived products: LIDAR ratios & FMF
        S_438   = 4*pi./(data_AERONET(34,:).*data_AERONET(120,:));              % [N,130]: LR(438nm): VIS 
        S_669   = 4*pi./(data_AERONET(35,:).*data_AERONET(121,:));              % [N,131]: LR(669nm): VIS 
        S_871   = 4*pi./(data_AERONET(36,:).*data_AERONET(122,:));              % [N,132]: LR(871nm): IR 
        S_1022  = 4*pi./(data_AERONET(37,:).*data_AERONET(123,:));              % [N,133]: LR(1022nm): IR 
        FMF     = data_AERONET(90,:)./(data_AERONET(90,:)+data_AERONET(94,:));  % [N,142]: Fine Fraction
    end
    
    % Angstrom Parameters(lambda2,lamdba1)
    a_675_440   = -log(data_AERONET(7,:)./data_AERONET(16,:))/log(675/440);     % [N,134]: AE(675,440): VIS 
    a_870_440   = -log(data_AERONET(6,:)./data_AERONET(16,:))/log(870/440);     % [N,135]: AE(870,440): IR/VIS 
    a_1020_440  = -log(data_AERONET(5,:)./data_AERONET(16,:))/log(1020/440);    % [N,136]: AE(1020,440): IR/VIS 
    a_1020_675  = -log(data_AERONET(5,:)./data_AERONET(7,:))/log(1020/675);     % [N,137]: AE(1020,675): IR/VIS 
        
    % Interpolated AODs
    
    AOD_470     = data_AERONET(16,:).*((470/440).^(-a_675_440));                % [N,139]: AOD(470nm): 
%     AOD_500     = data_AERONET(16,:).*((500/440).^(-a_675_440));                % [N,140]: AOD(500nm): 
    AOD_550     = data_AERONET(16,:).*((550/440).^(-a_675_440));                % [N,140]: AOD(550nm): 
    AOD_660     = data_AERONET(16,:).*((660/440).^(-a_675_440));                % [N,141]: AOD(660nm): 
    
    % Interpolated Angstrom Exponent(550,870)
    a_550_870   = -log(AOD_550./data_AERONET(6,:))/log(550/870);                % [N,138]: AE(550,870)
        
    % Angstrom Exponents(lambda1,lamdba2)
    a_440_675   = -log(data_AERONET(16,:)./data_AERONET(7,:))/log(440/675);     % [N,143]: AE(440,675): VIS 
    a_440_870   = -log(data_AERONET(16,:)./data_AERONET(6,:))/log(440/870);     % [N,144]: AE(440,870): VIS/IR 
    a_440_1020  = -log(data_AERONET(16,:)./data_AERONET(5,:))/log(440/1020);    % [N,145]: AE(440,1020): VIS/IR 
    a_675_1020  = -log(data_AERONET(7,:)./data_AERONET(5,:))/log(675/1020);     % [N,146]: AE(675,1020): VIS/IR 
    a_675_870   = -log(data_AERONET(7,:)./data_AERONET(6,:))/log(675/870);      % [N,147]: AE(675,870): VIS/IR 
    a_870_1020  = -log(data_AERONET(6,:)./data_AERONET(5,:))/log(870/1020);     % [N,148]: AE(870,1020): VIS/IR 

    %% Append new parameters to AERONET Dataset
    data_AERONET    = [data_AERONET;S_438;S_669;S_871;S_1022;a_675_440;a_870_440;a_1020_440;a_1020_675;a_550_870;AOD_470;AOD_550;AOD_660;FMF;a_440_675;a_440_870;a_440_1020;a_675_1020;a_675_870;a_870_1020]; % Add new AEs, LRs, AODs & FMF to data matrix [N,179]
    str_inputs      = [str_AERONET,{'LR 438'},{'LR 669'},{'LR 871'},{'LR 1022'},{'AE 675/440'},{'AE 870/440'},{'AE 1020/440'},{'AE 1020/675'},{'AE 550/870'},{'Extrap AOT 470'},{'Extrap AOT 550'},{'Extrap AOT 660'},{'FMF'},{'AE 440/675'},{'AE 440/870'},{'AE 440/1020'},{'AE 675/1020'},{'AE 675/870'},{'AE 870/1020'}];

%     data_AERONET    = [data_AERONET;S_438;S_669;S_871;S_1022;a_675_440;a_870_440;a_1020_440;a_1020_675;a_500_870;AOD_470;AOD_500;AOD_660;FMF;a_440_675;a_440_870;a_440_1020;a_675_1020;a_675_870;a_870_1020]; % Add new AEs, LRs, AODs & FMF to data matrix [N,179]
%     str_inputs      = [str_AERONET,{'LR 438'},{'LR 669'},{'LR 871'},{'LR 1022'},{'AE 675/440'},{'AE 870/440'},{'AE 1020/440'},{'AE 1020/675'},{'AE 500/870'},{'Extrap AOT 470'},{'Extrap AOT 500'},{'Extrap AOT 660'},{'FMF'},{'AE 440/675'},{'AE 440/870'},{'AE 440/1020'},{'AE 675/1020'},{'AE 675/870'},{'AE 870/1020'}];
    data0           = data_AERONET;
    str_inputs2     = [];
    for i=1:length(str_inputs)
        str_temp    = char(str_inputs{i});
        str_inputs2 = [str_inputs2,{str_temp}];
    end
    str_inputs      = str_inputs2;
    
end % function
