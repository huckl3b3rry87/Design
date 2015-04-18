clear
%% lARGE
load large_dist_MECH_555
Ds = 7.45*8; 

iter = small_electric_STEP_optimization.GLOBAL.f_min_hist.iter;
delta_soc = small_electric_STEP_optimization.GLOBAL.f_min_hist.c(:,1);
module_num = small_electric_STEP_optimization.GLOBAL.f_min_hist.x(:,3);
Dist = 1./(abs(delta_soc'))*Ds;

figure(2);
subplot(2,1,1)
plot(iter,Dist,'linewidth',8);
xlabel([]);
ylabel({'Distance', '(miles)'}),grid
set(gca,'FontSize',15,'fontWeight','bold')
set(findall(gcf,'type','text'),'FontSize',16,'fontWeight','bold')
title('Large EV')
subplot(2,1,2)
plot(iter,module_num,'linewidth',8);
xlabel('Iterations');
ylabel({'# of Battery', 'Modules'}),grid

set(gca,'FontSize',15,'fontWeight','bold')
set(findall(gcf,'type','text'),'FontSize',16,'fontWeight','bold')