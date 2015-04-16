
 clear all
 clc
 SetAdvisorPath;
 
 tic
 
%Pass the small ice vehicle
input.init.saved_veh_file='PARALLEL_defaults_in';
[error_code,resp]=adv_no_gui('initialize',input);

%Modify the vehicle Mass
input.modify.param = {'veh_mass'};
input.modify.value = {1054};
[error_code,resp] = adv_no_gui('modify',input)


% dv_names={'fc_pwr_scale','ess_module_num'};
% resp_names={'MPGGE_STEP_small_parallel'};
%con_names={'delta_soc','delta_trace','vinf.accel_test.results.time(1)','vinf.accel_test.results.time(2)','vinf.accel_test.results.time(3)','vinf.grade_test.results.grade'};

% define the problem
FUN=@objective;
NONLCON= @constraints;

% fc_pwr_scale   mc_trq_scale  ess_module_num   ess_cap_scale   cs_charge_trq   cs_min_trq_frac    cs_off_trq_frac    cs_electric_launch_spd_lo  cs_electric_launch_spd_hi   cs_charge_deplete_bool'};
nvars =1;
LB =[0.5]';
UB =[1.5]';

A=[];
B=[];
Aeq=[];
Beq=[];


options = gaoptimset('PlotFcns',{@gaplotscorediversity,@gaplotbestf,@gaplotstopping},'PopulationSize',10,'Generations',5,'StallGenLimit', 30);

[X,Fval,EXITFLAG,Output]=ga(FUN,nvars,A,B,Aeq,Beq,LB,UB,NONLCON,options)
fprintf('The number of generations was : %d\n', Output.generations);
fprintf('The number of function evaluations was : %d\n', Output.funccount);
fprintf('The best function value found was : %g\n', Fval);


% save the vehicle
input.save.filename='small_parallel_STEP';
[a,b]=adv_no_gui('save_vehicle',input);


toc