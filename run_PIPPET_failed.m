function [mu_list, C_list, Pi_list] = run_PIPPET(params)

t_max = params.tmax;
dt = params.dt;
sigma = params.sigma;

t_list = 0:dt:t_max;

mu_list = zeros(size(t_list));
mu_list(1) = params.mu_0;

C_list = zeros(size(t_list));
C_list(1) = params.C_0;

Pi_list = zeros(size(t_list));
Pi_list(1) = params.C_0 + params.mu_0^2;

event_num = ones(1,params.n_streams);
for i=2:length(t_list)
    t = t_list(i);

    t_past = t_list(i-1);
    C_past = C_list(i-1);
    mu_past = mu_list(i-1);
    Pi_past = C_past + mu_past^2;
    
    dmu_sum = 0;
    dPi_sum = 0;
    
    for j = 1:params.n_streams
        dmu_sum = dmu_sum + params.streams{j}.Lambda_bar(mu_past, C_past)*(params.streams{j}.mu_bar(mu_past, C_past)-mu_past);
        dPi_sum = dPi_sum + params.streams{j}.Lambda_bar(mu_past, C_past)*(params.streams{j}.Pi_bar(mu_past, C_past)-Pi_past);
    end
    
    dmu = dt*(1 - dmu_sum);
    dPi = dt*(sigma^2 + 2*mu_past - dPi_sum);
%    dC_1 = dt*(sigma^2 )
    mu = mu_past+dmu;
    Pi = Pi_past+dPi;
    C = Pi - mu^2 + dt^2;
%    dC_2 = C - C_past
    
    for j = 1:params.n_streams
        if event_num(j) <= length(params.streams{j}.event_times) && (t>params.streams{j}.event_times(event_num(j)) & t_past<=params.streams{j}.event_times(event_num(j)))
            mu_tmp = params.streams{j}.mu_bar(mu, C);
            Pi = params.streams{j}.Pi_bar(mu, C);
            mu = mu_tmp;
            C = Pi - mu^2;
            event_num(j) = event_num(j)+1;
        end
    end

    mu_list(i) = mu;
    C_list(i) = C;
end

if params.display
    figure()
    subplot(1,5, [2,3,4,5])
    shadedErrorBar(t_list, mu_list, 2*sqrt(C_list))
    ylim([0, t_max])
    hold on
    for j = 1:params.n_streams
        for i=1:length(params.streams{j}.event_times)
            width = .5;
            linespec = 'r';
            if params.streams{j}.highlight_event_indices(i)==0
                linespec = 'r-.';
            elseif params.streams{j}.highlight_event_indices(i)==2
                width = 1.5;
            end
            plot([1,1]*params.streams{j}.event_times(i), [0,t_max], linespec, 'LineWidth', width);
        end

        for i=1:length(params.streams{j}.e_means)
            width = .5;
            linespec = 'b';
            if params.streams{j}.highlight_expectations(i)==0
                linespec = 'b-.';
            elseif params.streams{j}.highlight_expectations(i)==2
                width = 1.5;
            end
            plot([0,t_max], [1,1]*params.streams{j}.e_means(i), linespec, 'LineWidth', width)
        end
    end
    xlabel('Time (sec)')
    

    subplot(1,5,1)
    for j = 1:params.n_streams
        plot(log(params.streams{j}.expect_func(t_list)), t_list, 'k');
    end
    ylim([0, t_max])
    ylabel('Phase \phi')
    xlabel({'log likelihood';'log(\lambda(\phi))'});
    set(gca,'Yticklabel',[])
    sgtitle(params.title)
    
end