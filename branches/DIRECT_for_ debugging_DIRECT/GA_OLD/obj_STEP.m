function obj=objective(x,varargin)

% initialize
error=0;
obj=0;

% update parameter settings
input.modify.param=varargin{1}; % parameter names are stored in the first optional argument
input.modify.value=num2cell(x); % assign corresponding values
[error,resp]=adv_no_gui('modify',input);

% run city/hwy test procedure
if ~error
%    input.procedure.param={'test.name'};
%    input.procedure.value={'TEST_CITY_HWY'};
%    [error,resp]=adv_no_gui('test_procedure',input);
   
   input.cycle.param = {'cycle.name','cycle.soc','cycle.socmenu','cycle.SOCiter'}
   input.cycle.value = {'CYC_FTP','on','zero delta',15}
   [error,resp] = adv_no_gui('drive_cycle', input)
end

% assign objective value
if ~error
   obj=-1*resp.cycle.mpgge; % -1* to maximize objective
%  obj=-1*resp.procedure.mpgge; % -1* to maximize objective

end

% % assign constraint value
% if ~error
%    assignin('base','con',[max(abs(resp.cycle.delta_soc)); max(resp.cycle.delta_trace)])
% end

return
