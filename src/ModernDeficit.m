clc
clear
close all
tic

%% Soil Parametr
% Define Type of Soil
soil.type = 'Loamy Sand';

% Upadet Characteristic of Soil
soilchar = xlsread('soil_characteristics','Soil Data','A2:H6');
soil = updatesoil(soil,soilchar);

% Define Modern Irrigation Parameter
soil.s_tild = soil.s_star*0.8;

%% Crop Parameter
% Define Type of Crop
crop.type = 'Pistachios';
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
crop.ET_0 = xlsread('all_data','ET_o','B2:B151');     %mm/day

% Import Data of Rainfall Daily
Rain = xlsread('all_data','Climate Data','E2:E151');          %mm/day

% Revise Rainfall
for i = 1:crop.T
    if Rain(i)>0
        Rain(i) = max(Rain(i) - 2,0);
    end
end

% Determine Potential of ET
ET_p = crop.k_c .* crop.ET_0;                           %mm/day

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

%% Main Loop
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
%% Calculate Acyual Yield and Price
Ya = Yp*(1-ky*(1-ET_total/sum(ET_p)));      %ton/hec
Total_Price = pe * Ya * 1000;               %Toman/hec

%% Results
% Determine Final Time
for i=1:300
    if (Time(i) == crop.T)
        finalt = i;
    end
end

% Display Value of Yield and Price
disp(['S_tild = ' num2str(soil.s_tild)]);
disp(['Water Stress = ' num2str(1-ET_total/sum(ET_p))]);
disp(['Actual Yield per Hectar (ton) = ' num2str(Ya)]);
disp(['Total Price per Hectar (Toman) = ' num2str(Total_Price)]);
disp(['Total Volume of Irrigation (m^3) = ' num2str(sum(Irrigation)*10)]);

% Ploting Actual ET, Soil Moisture and Irrigation
figure;
plot(Time(1:finalt),ET_a(1:finalt),'k');
grid on;
title('Actual ET - Modern: Deficit Irrigation');
xlabel('Time (Day)');
ylabel('Actual ET (mm/day)');
axis ([1 crop.T 0 4.2]);

figure;
plot(Time(1:finalt),soil.moisture(1:finalt),'k');
title('Soil Moisture - Modern: Deficit Irrigation');
grid on;
hold on;
xlabel('Time (Day)');
ylabel('Soil Moisture');
axis ([1 crop.T 0.3 0.6]);
plot(1:crop.T,linspace(soil.s_star,soil.s_star,crop.T),'--k');
hold off;

figure;
plot(1:crop.T,Irrigation,'k');
title('Irrigation - Modern: Deficit Irrigation');
grid on;
xlabel('Time (Day)');
ylabel('Irrigation (mm/day)');
toc