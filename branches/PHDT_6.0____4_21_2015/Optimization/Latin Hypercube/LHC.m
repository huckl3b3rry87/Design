% clear; 
close all; 
clc
tic
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%-----------------Check Matlab Version------------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
version -release;
Matlab_ver = str2num(ans(1:4)); %#ok<NOANS,ST2NM>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%-----------------Define the Run Type-------------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
RUN_TYPE.sim = 1;  % RUN_TYPE = 1 - for DIRECT     &    RUN_TYPE = 0 - for DP only
RUN_TYPE.emiss_data = 1; % RUN_TYPE.emiss = 1 - maps have emissions  &   RUN_TYPE.emiss = 0 - maps do not have emissions
% RUN_TYPE.emiss_on = 0;  % This is to turn off and on emissions
RUN_TYPE.plot = 0;  % RUN_TYPE.plot = 1 - plots on  &   RUN_TYPE.plot = 0 - plots off
RUN_TYPE.soc_size = 0.001;
RUN_TYPE.trq_size = 5;  % Nm
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%-----------------Weighing Parameters for DP------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
weight.fuel = 1*1.4776/1.4776;  % These are for a specific engine, we need to change this!
if RUN_TYPE.emiss_data == 1  % This is just saying wheither or not the engine maps have emissions data
    if RUN_TYPE.emiss_on == 0
        weight.NOx = 0*1.4776/0.0560;
        weight.CO = 0*1.4776/0.6835;
        weight.HC = 0*1.4776/0.0177;
        RUN_TYPE.folder_name = '_LHC - no emiss';
    else
        weight.NOx = 2*1.4776/0.0560;
        weight.CO = 0.6*1.4776/0.6835;
        weight.HC = 4*1.4776/0.0177;
        RUN_TYPE.folder_name = '_LHC - emiss';
    end
end

RUN_names = fieldnames(RUN_TYPE);
RUN_data = struct2cell(RUN_TYPE);

weight.shift = 1;
weight.engine_event = 10;
weight.infeasible = 200;
weight.CS = 91000;
weight.SOC_final = 500;

weight_names = fieldnames(weight);
weight_data = struct2cell(weight);
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%----------------------------Load All Data--------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

cd('Components');
%                              ~~ Engine ~~
% Engine_30_kW;
Engine_41_kW_manip;
% Engine_41_kW_smooth;
% Engine_50_kW;
% Engine_73_kW;
% Engine_95_kW;
% Engine_102_kW;
% Engine_186_kW;
% Engine_224_kW;

%                              ~~ Motor ~~
% Motor_int;
% Motor_75_kW;
% Motor_30_kW;
Motor_49_kW;
% Motor_10_kW;
% Motor_8_kW;
% Motor_16_kW;

%                             ~~ Battery ~~
% Battery_int;  % No variation with the number of modules in this battery!!
Battery_ADVISOR;

%                              ~~ Vehicle ~~
Vehicle_Parameters_small_car;
% Vehicle_Parameters_4_HI_AV;
% Vehicle_Parameters_4_HI;
% Vehicle_Parameters_8_HI_AV;
% Vehicle_Parameters_8_HI;

% Low Speed
% Vehicle_Parameters_4_low_AV;
% Vehicle_Parameters_4_low;
% Vehicle_Parameters_1_low_AV;
% Vehicle_Parameters_1_low;

cd ..
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%-------------Put all the data into structures and cells------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
data;
param_names = fieldnames(param);
param_data = struct2cell(param);
vinf_names = fieldnames(vinf);
vinf_data = struct2cell(vinf);
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%---------------------Update the Design Variables-------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~d%
dvar.FD = 5.495;
dvar.G = 1.4;
dvar.fc_trq_scale = 0.78;
dvar.mc_trq_scale = 1.2;
mc_max_pwr_kW =  dvar.mc_trq_scale*vinf.mc_max_pwr_kW;
dvar.module_number = ceil(4*mc_max_pwr_kW*1000*Rint_size/(Voc_size^2));
dvar.module_number = 38;
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%---------------------Update the Data-------------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
Manipulate_Data_Structure;
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%---------------------Select Drive Cycle----------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                              ~~ Standard ~~
% cyc_name = 'HWFET';
% cyc_name = 'UDDS';
% cyc_name = 'US06';
% cyc_name = 'SHORT_CYC_HWFET';
% cyc_name = 'RAMP';
% cyc_name = 'LA92';
% cyc_name = 'CONST_65';
% cyc_name = 'CONST_45';
% cyc_name = 'COMMUTER';

% City
% cyc_name = 'INDIA_URBAN';
% cyc_name = 'MANHATTAN';
% cyc_name = 'Nuremberg';
% cyc_name = 'NYCC';
% cyc_name = 'AA_final';

%                              ~~ AV~~
% cyc_name = 'US06_AV';
% cyc_name = 'HWFET_AV';
% cyc_name = 'AA_final_AV';

[cyc_data] = Drive_Cycle(param, vinf, cyc_name);

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%---------------------Run Optimization------------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

% Identify the Design Variables and their ranges
dv_names={ 'FD', 'G','fc_trq_scale','mc_trq_scale'};
x_L=[    0.5*dvar.FD, 0.5*dvar.G, 0.5*dvar.fc_trq_scale, 0.5*dvar.mc_trq_scale]';
x_U=[    1.5*dvar.FD, 1.5*dvar.G, 1.5*dvar.fc_trq_scale, 1.5*dvar.mc_trq_scale]';

%    FAIL.final     fail.acc_test     fail.grade_test
g_eq = [0,               0,               0];

%          delta_soc
c_L = [-RUN_TYPE.soc_size];
c_U =  [RUN_TYPE.soc_size];

% n = 3;
dv = 4;
X_temp = lhsdesign(n,dv);

for nn = 1:n
    for pp = 1:dv
        X(nn,pp) = x_L(pp) + X_temp(nn,pp)*(x_U(pp) - x_L(pp));
    end
end

rr = 1;   % Initialize feasible counter
for nn = 1:n
    geq = [];
    gineq = [];
    
    x = [X(nn,1); X(nn,2); X(nn,3); X(nn,4)];
    
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
    %----------------Update the Design Variables------------------------------%
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
    dvar.FD = x(1);
    dvar.G = x(2);
    dvar.fc_trq_scale = x(3);
    dvar.mc_trq_scale = x(4);
    dvar.module_number = 38;  % Fixed (for now) - should be passing this..
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
    %-----------Manipulate Data Based of Scaling Factors----------------------%
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
    Manipulate_Data_Structure; % Need to recalcualte the Tw for the ne vehicle mass
    
    [cyc_data] = Drive_Cycle(param, vinf, cyc_name );
    
    [FAIL, MPG, emission, delta_SOC, sim] = Dynamic_Programming_func(param, vinf, dvar, cyc_data, RUN_TYPE, weight);
    
    if ( isnan(MPG) || isnan(emission.NOx) || isnan(emission.CO) || isnan(emission.HC) || FAIL.final || isempty(MPG) || isempty(emission.NOx) || isempty(emission.CO) || isempty(emission.HC))
        FAIL_LHC = 1;
        gineq(1) = 1;
        geq(1) = 1;
    else
        FAIL_LHC = 0;
        gineq(1) = -RUN_TYPE.soc_size + abs(delta_SOC);
        geq(1) = FAIL.final;
    end
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
    %-------------------------Acceleration Tests ------------------------------%
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
    cd('Initial Component Sizing')
    V_0 = 0;
    V_f = 60;
    dt_2 = 12;
    Acc_Final_new = [];  % Does not matter TYPE 1
    TYPE = 1; % Velocity req.
    [ pass_acc_test, Sim_Variables ] = Acceleration_Test(V_0,V_f, Acc_Final_new, dt_2, param, vinf, dvar, TYPE);
    
    fail_acc_test = ~pass_acc_test;
    FAIL_ACCEL_TEST = any(fail_acc_test);
    
    if ~isempty(FAIL_ACCEL_TEST)
        geq(2)= FAIL_ACCEL_TEST;
    else
        geq(2)= 1; % Fail it
    end
    
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
    %-----------------------------Grade Test----------------------------------%
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
    
    %--------------------------Set Requirements--------------------------------
    Motor_ON = 1;
    
    % Test 1
    r = 1;
    V_test(r) = 80*param.mph_mps;  % Max Speed
    alpha_test(r) = 0*pi/180;
    
    % Test 2
    r = 2;
    V_test(r) = 55*param.mph_mps;
    alpha_test(r) = 5*pi/180;
    
    [Sim_Grade, FAIL_GRADE_TEST] = Grade_Test( param, vinf, dvar, alpha_test, V_test, Motor_ON );
    
    if ~isempty(FAIL_GRADE_TEST)
        geq(3)= FAIL_GRADE_TEST;
    else
        geq(3) = 1;  % Fail it
    end
    
    % Check equality constraints
    for L = 1:size(geq)
        if (geq(L) ~= g_eq(L))
            fail_eq_con(L) = 1;
        else
            fail_eq_con(L) = 0;
        end
    end
    
    % Check inequality constraints
    for L = 1:size(gineq)
        if ((c_L(L) > gineq(L)) || c_U(L) < gineq(L))
            fail_ineq_con(L) = 1;
        else
            fail_ineq_con(L) = 0;
        end
    end
    
    if FAIL_LHC || any(fail_ineq_con) || any(fail_eq_con)
        FAIL_LHC(nn) = 1;
    else
        FAIL_LHC(nn) = 0;
        X_save(rr,:) = x;
        MPG_save(1,rr) = MPG;
        NOx_save(1,rr) = emission.NOx;
        CO_save(1,rr) = emission.CO;
        HC_save(1,rr) = emission.HC;
        rr = rr + 1;
    end
    cd .. % back into the main folder
   
    
    if FAIL_LHC(nn) == 0
        cd('results')
        
        if Matlab_ver >= 2014
            t = datetime;
            t.Format = 'eeee, MMMM d, yyyy';
            name = strcat(RUN_TYPE.folder_name,char(t));
        else
            name = strcat(RUN_TYPE.folder_name);
        end
        
        check_exist = exist(fullfile(cd,name),'dir');
        if check_exist == 7
            rmdir(name,'s')                 % Delete any left over info
        end
        mkdir(name)
        cd(name)
        eval(['save(''','MPG',''',','''MPG_save'');'])
        eval(['save(''','DV',''',','''X_save'');'])
        eval(['save(''','NOx',''',','''NOx_save'');'])
        eval(['save(''','CO',''',','''CO_save'');'])
        eval(['save(''','HC',''',','''HC_save'');'])
        cd ..
        cd ..  % Back in the main folder
    end

end
