function [gineq,geq] = constraint(x,varargin)

param =  cell2struct(varargin{2}, varargin{1},1);
vinf =  cell2struct(varargin{4}, varargin{3},1);
cyc_name = varargin{5};
RUN_TYPE = cell2struct(varargin{7},varargin{6},1);
weight = cell2struct(varargin{9},varargin{8},1);


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

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%---------------------Run DP with new Data--------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%    

[FAIL, MPG, emission, delta_SOC, sim] = Dynamic_Programming_func(param, vinf, dvar, cyc_data, RUN_TYPE, weight);

if ~FAIL.final && ~isempty(MPG) && ~isempty(emission.NOx) && ~isempty(emission.CO) && ~isempty(emission.HC)
    obj = -MPG + weight.NOx*emission.NOx + weight.CO*emission.CO + weight.HC*emission.HC; 
else
    obj = 10^10;  % doing something like this may not be appropriate
    FAIL.final = 1; % Make Sure it Fails
end

if ( isnan(emission.NOx) || isnan(emission.CO) || isnan(emission.HC))
    emission.NOx = -1;
    emission.CO = -1;
    emission.HC = -1;  % Will fail it for sure and make sure that the constraints are not gettting passed back as NaN ( which messes DIRECT up)
end
assignin('base','objective',obj);

% Assign Constraints
gineq = [];
geq = [];

gineq(1) = FAIL.final;
gineq(2) = RUN_TYPE.soc_size + abs(delta_SOC);
gineq(3) = MPG;
gineq(4) = -emission.NOx;
gineq(5) = -emission.CO;
gineq(6) = -emission.HC;
 offset = 6;
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%-------------------------Acceleration Tests ------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
cd('Initial Component Sizing')

n = 1;
V_0 = 0;
V_f = 60;
dt_2 = 12;
Acc_Final_new = 100;  % Does not matter
TYPE = 1; % Velocity req.
[ pass_acc_test(n), Sim_Variables ] = Acceleration_Test(V_0,V_f, Acc_Final_new, dt_2, param, vinf, dvar, TYPE);

% dt_2 = 0.0002;
% load V_0;
% load V_f;
% load Acc_Final
% TYPE = 0; % Acceleration req.
% for i = 1:length(V_0)
%     n = n + 1;
%     [ pass_acc_test(n), Sim_Variables ] = Acceleration_Test(V_0(i),V_f(i), Acc_Final(i),dt_2, param, vinf, dvar, TYPE);
% end

fail_acc_test = ~pass_acc_test;
FAIL_ACCEL_TEST = any(fail_acc_test);

if ~isempty(FAIL_ACCEL_TEST)  % &~isempty(z0_60)&~isempty(z0_85)
    gineq(offset+1,1)= FAIL_ACCEL_TEST;
    %    con(offset+2,1)=time40_60;
    %    con(offset+3,1)=time0_85;
else
    %    con(offset+1:offset+3,1)=100;
    gineq(offset+1,1)= 0;
end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%-----------------------------Grade Test----------------------------------%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

%--------------------------Set Requirements--------------------------------
Motor_ON = 1;

% Test 1
r = 1;
V_test(r) = 80*param.mph_mps;
alpha_test(r) = 0*pi/180;

% Test 2
r = 2;
V_test(r) = 55*param.mph_mps;
alpha_test(r) = 5*pi/180;

[Sim_Grade, FAIL_GRADE_TEST] = Grade_Test( param, vinf, dvar, alpha_test, V_test, Motor_ON );

if ~isempty(FAIL_GRADE_TEST)
    gineq(offset+2,1)= FAIL_GRADE_TEST;
else
    gineq(offset+2,1) = 0;
end

cd .. 

return