%%%Genetic Algorithm
clear; % Clear the workspace
close all; % Close all windows
close all
clc
tic
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%-----------------Define the Run Type-------------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
RUN_TYPE.sim = 0;  % RUN_TYPE = 1 - for DIRECT     &    RUN_TYPE = 0 - for DP only
RUN_TYPE.emiss = 1; % RUN_TYPE.emiss = 1 - has emissions  &   RUN_TYPE.emiss = 0 - NO emissions
RUN_TYPE.plot = 0;  % RUN_TYPE.plot = 1 - plots on  &   RUN_TYPE.plot = 0 - plots off
RUN_TYPE.soc_size = 0.1;
RUN_TYPE.trq_size = 20;  % Nm
RUN_names = fieldnames(RUN_TYPE);
RUN_data = struct2cell(RUN_TYPE);
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
Vehicle_Parameters_4_HI;
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
Manipulate_Data_Structure;  % May not have to do this here
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%---------------------Select Drive Cycle----------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                              ~~ Standard ~~

% cyc_name = 'HWFET';
% cyc_name = 'UDDS';
% cyc_name = 'US06';
cyc_name = 'SHORT_CYC_HWFET';
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

[cyc_data] = Drive_Cycle(param, vinf, cyc_name );

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%-----------------Weighing Parameters for DP------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
weight.fuel = 1*1.4776/1.4776;  % These are for a specific engine, we need to change this!
if RUN_TYPE.emiss == 1
    weight.NOx = 0*1.4776/0.0560;
    weight.CO = 0*1.4776/0.6835;
    weight.HC = 0*1.4776/0.0177;
%     weight.NOx = 2*1.4776/0.0560;
%     weight.CO = 0.6*1.4776/0.6835;
%     weight.HC = 4*1.4776/0.0177;
end
weight.shift = 1;
weight.engine_event = 10; 
weight.infeasible = 200;
weight.CS = 91000;
weight.SOC_final = 500;
weight_names = fieldnames(weight);
weight_data = struct2cell(weight);
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%---------------------Run Optimization------------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

% Identify the Design Variables and their ranges    
dv_names={ 'FD', 'G','fc_trq_scale','mc_trq_scale'};
x_L=[    0.5*dvar.FD, 0.5*dvar.G, 0.5*dvar.fc_trq_scale, 0.5*dvar.mc_trq_scale]';
x_U=[    1.5*dvar.FD, 1.5*dvar.G, 1.5*dvar.fc_trq_scale, 1.5*dvar.mc_trq_scale]';
% set number of design variables
nvars=4; % x1, x2, x3, x4 

% Set integer variables
IntCon=[]; % No integers!

% Set the initial guess (Optional) - set the vectors of population size. 
% If you use 100 populations and 4 design variables, 
% initial guess will be 100 x 4 matrix
ini=[dvar.FD,dvar.G,dvar.fc_trq_scale,dvar.mc_trq_scale]; % Please use GOOD and FEASIBLE initial guess if possible.


% Set objective function
vfun=@(dvar)objective(dvar,param_names, param_data, vinf_names, vinf_data, cyc_name, RUN_names, RUN_data, weight_names, weight_data);
% Set constraint function
nonlcon=@(dvar)constraint(dvar,param_names, param_data, vinf_names, vinf_data, cyc_name, RUN_names, RUN_data, weight_names, weight_data );

% [gineq,geq] = nonlcon(ini);

%%
% GA option settings
populations=3; %set population size
generations=2; %set number of generations
time = 300;  % time in (s)
% @gaplotbestfun will show you a convergence plot. Based on this, tune population size and number of generations 
options1 = gaoptimset('InitialPopulation',ini,'PopulationSize',populations,'Generations',generations,'StallGenLimit', 10,'TimeLimit',time,'PlotFcns',{@gaplotscorediversity,@gaplotbestf,@gaplotstopping});

%% Solve problem 
[x,fval,exitflag,output] = ga(vfun,nvars,[],[],[],[],x_L,x_U,nonlcon,IntCon,options1);
fprintf('The number of generations was : %d\n', output.generations);
fprintf('The number of function evaluations was : %d\n', output.funccount);
fprintf('The best function value found was : %g\n', fval);

mkdir('GA_results')
cd('GA_results')
eval(['save(''','output',''',','''output'');'])
eval(['save(''','dv',''',','''x'');'])
cd ..

toc
