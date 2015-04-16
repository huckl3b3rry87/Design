function [con, con_e]=constraints(x)


% % Define Constraints
% c_L=[-0.005; -2; 0; 0; 0; 5];
% c_U=[0.005; 2; 11.2; 4.4; 20; 6]; 

%   delta_soc   delta_trace   vinf.accel_test.results.time(1)    vinf.accel_test.results.time(2)   vinf.accel_test.results.time(3)   vinf.grade_test.results.grade
%c_L=[   0;         0;                    0;                                  0;                                  0;                            5];
c_U=[ 0.005;       2;                    10.5;                                5.6;                                 24.6;                             6.5];

% Run the test
   
   input.cycle.param = {'cycle.name','cycle.soc','cycle.socmenu','cycle.SOCiter'}
   input.cycle.value = {'CYC_FTP','on','zero delta',15}
   [error,resp] = adv_no_gui('drive_cycle', input)

   % Assign Constraints
   if ~error
  con(1,1)= max(abs(resp.cycle.delta_soc)) - c_U(1);
  con(2,1)= max(resp.cycle.delta_trace) - c_U(2);
   else
   fprintf('\n Did not make the cycle speed of SOC requirements')
   end
   
   offset = 2;
%con=evalin('base','con');  % Getting this from the objective function

%offset=length(con);

% Run Acceleration Test
input.accel.param={'spds','disable_systems','disp_results'};
input.accel.value={[0 60; 40 60; 0 85],0,1};
[error, resp]=adv_no_gui('accel_test',input);

if ~error&~isempty(resp.accel.times)
   con(offset+1,1)=resp.accel.times(1) - c_U(3);  %Leaving room for the first constraints
   con(offset+2,1)=resp.accel.times(2)- c_U(4);
   con(offset+3,1)=resp.accel.times(3)- c_U(5);
else
   con(offset+1:offset+3,1) = 1;
   fprintf('\n Did not make the acceleration test!')
end

% Run the Grade Test
input.grade.param={'duration','speed','grade','disable_systems','ess_init_soc','ess_min_soc'};
input.grade.value={100,55,6.5,0,0.6,0.4};
[error, resp]=adv_no_gui('grade_test',input);

if ~error&~isempty(resp.grade.grade)
   con(offset+4,1)=resp.grade.grade - c_U(6);
else
   con(offset+4,1)= 1; 
   fprintf('\n Did not make the grade test!')

end
  
con_e=0;
% ****
con
return
