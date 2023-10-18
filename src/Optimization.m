clc
clear
close all
tic

%% Soil Parametr
% Define Type of Soil
soil.type = "Loamy Sand";

% Upadet Characteristic of Soil
soilchar = xlsread('soil_characteristics','Soil Data','A2:H6');
soil = updatesoil(soil,soilchar);

%% Crop Parameter
% Define Type of Crop
crop.type = "Pistachios";
Yp = 1.1;                   %ton/ha
ky = 0.8;
pe = 75000;                 %Toman per Kg
crop.Zr = 1500;             %mm

% Crop K_c Parameter
crop.L_ini = 20;
crop.L_dev = 60;
crop.L_mid = 30;
crop.L_late = 40;
crop.T = crop.L_ini + crop.L_dev + crop.L_mid + crop.L_late;

crop.k_cini = 0.4;
crop.k_cmid = 1.1;
crop.k_cend = 0.45;

crop.k_c = zeros(crop.T,1);
crop.k_c(1:crop.L_ini,1) = crop.k_cini;
crop.k_c(crop.L_ini+1:crop.L_ini+crop.L_dev,1) = linspace(crop.k_cini,crop.k_cmid,crop.L_dev)';
crop.k_c(crop.L_ini+crop.L_dev+1:crop.L_ini+crop.L_dev+crop.L_mid,1) = crop.k_cmid;
crop.k_c(crop.L_ini+crop.L_dev+crop.L_mid+1:crop.T,1) = linspace(crop.k_cmid,crop.k_cend,crop.L_late)';

% Import ET Refrence from Cropwat Daily
crop.ET_0 = xlsread('All Data','Sheet2','B2:B151');     %mm/day

% Import Data of Rainfall Daily
Rain = xlsread('All Data','Sheet1','E2:E151');          %mm/day

% Revise Rainfall
for i = 1:crop.T
    if Rain(i)>0
        Rain(i) = max(Rain(i) - 2,0);
    end
end

% Determine Potential of ET
ET_p = crop.k_c .* crop.ET_0;                           %mm/day


%% Main Loop
step = 100;
Total_Price = zeros(step,1);
Irr = zeros(step,1);
alls_tild = linspace(soil.s_star*0.8,soil.s_star*1.2,step);
for k = 1:step
    soil.s_tild = alls_tild(k);
    
    % Pre-allocation
    soil.moisture = zeros(crop.T*2,1);
    Irrigation = zeros(crop.T,1);
    ET_a = zeros(crop.T*2,1);
    Time = zeros(crop.T*2,1);

    % Initial Parameter
    soil.moisture (1) = soil.s_fc;
    Time(1) = 1;
    crop.ET_p = ET_p(1);
    ET_a(1) = ET(soil.moisture (1),soil,crop);
    ET_total = ET_a(1);
    i = 2;
    
    while(Time(i-1) < crop.T)
    % Update Value of ET_p
    crop.ET_p = ET_p(Time(i-1)+1);
    
    % Calculate Soil Moisture Next Step
   	s = soilmoisture(soil.moisture(i-1),soil,crop);
    
    % Compare New S with S_tild
    if (s<soil.s_tild)
        % Calculate Delta t
        delta_t = (soil.moisture(i-1) - soil.s_tild)/(soil.moisture(i-1)-s);
        
        % Update Value of Between of two day
        Time(i) = Time(i-1) + delta_t;
        soil.moisture(i) = soil.s_tild;
        ET_total = ET_total + ET(soil.s_tild,soil,crop)*0.5;
        ET_a(i) = ET(soil.s_tild,soil,crop);
        
        i = i + 1;
        
        % Update Value of secend day
        Time(i) = Time(i-2) + 1;
        soil.moisture(i) = soil.s_tild;
        ET_total = ET_total + ET(soil.s_tild,soil,crop)*0.5;
        ET_a(i) = ET(soil.s_tild,soil,crop);
        
        % Calculate Value of Irrigation
        Irrigation(Time(i)) =  ET(soil.s_tild,soil,crop) * (1-delta_t);
    else
        soil.moisture(i) = s;
        ET_total = ET_total + ET(s,soil,crop);
        ET_a(i) = ET(s,soil,crop);
        Time(i) = Time(i-1) + 1;
    end
    
    % Determine effect of Rainfall
    if (Rain(Time(i)) > 0)
        i = i + 1;
        Time(i) = Time(i-1);
        soil.moisture(i) = soil.moisture(i-1) + Rain(Time(i))/(soil.phi * crop.Zr);
        ET_a(i) = ET(soil.moisture(i),soil,crop);
        
        % Revise Total ET
        ET_total = ET_total - ET_a(i-1)*0.5;
        ET_total = ET_total + ET_a(i)*0.5;

    end    
    i = i + 1;
    end
    % Calculate Acyual Yield and Price
    Ya = Yp*(1-ky*(1-ET_total/sum(ET_p)));      %ton/hec
    Total_Price(k) = pe * Ya * 1000;               %Toman/hec
    Irr (k) = sum(Irrigation)*10;
end

%% Results
plot(Irr,Total_Price,'k');
grid on;
title('Irrigation - Total Price');
xlabel('Irrigation (m^3)');
ylabel('Total Price (Toman)');

toc