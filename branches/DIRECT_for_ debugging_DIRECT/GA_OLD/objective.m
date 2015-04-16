function obj=objective(x)

% initialize
error=0;
obj=0;

dv_names={'fc_pwr_scale'};
% % update parameter settings

input.modify.param={dv_names{1}}
input.modify.value=num2cell(x)
[error,resp]=adv_no_gui('modify',input);


% run city/hwy test procedure
if ~error

   
   input.cycle.param = {'cycle.name','cycle.soc','cycle.socmenu','cycle.SOCiter'}
   input.cycle.value = {'CYC_FTP','on','zero delta',15}
   [error,resp] = adv_no_gui('drive_cycle', input)
end

% assign objective value
if ~error
   obj=-1*resp.cycle.mpgge; % -1* to maximize objective
%  obj=-1*resp.procedure.mpgge; % -1* to maximize objective

end



return
