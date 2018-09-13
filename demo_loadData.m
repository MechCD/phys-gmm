%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Demo Code for GMM Learning for paper:                                   %
%  'A Physically-Consistent Bayesian Non-Parametric Mixture Model for     %
%   Dynamical System Learning.'                                           %
% With this script you can load 2D toy trajectories or even real-world 
% trajectories acquired via kinesthetic taching and test the different    %
% GMM fitting approaches.                                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Step 1 (DATA LOADING): Load Datasets %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all; clear all; clc
%%%%%%%%%%%%%%%%%%%%%%%%% Select a Dataset %%%%%%%%%%%%%%%%%%%%%%%%
% 1:  Concentric Circle Dataset (2D)
% 2:  Snake Dataset (2D)
% 3:  Messy Snake Dataset (2D)
% 4:  Via-Point Dataset (2D)
% 5:  L-shape Dataset (2D)
% 6:  A-shape Dataset (2D)
% 7:  S-shape Dataset (2D)
% 8:  Via-point Dataset (3D)   -- 15 trajectories recorded at 100Hz
% 9:  Sink Dataset (3D)        -- 21 trajectories recorded at 100Hz
% 10: Bumpy Snake Dataset (3D) -- 10 trajectories recorded at 100Hz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pkg_dir         = '/home/nbfigueroa/Dropbox/PhD_papers/CoRL-2018/code/phys-gmm/';
chosen_dataset  = 7; 
sub_sample      = 1; % '>2' for real 3D Datasets, '1' for 2D toy datasets
nb_trajectories = 0; % For real 3D data
Data = load_dataset(pkg_dir, chosen_dataset, sub_sample, nb_trajectories);

% Position/Velocity Trajectories
vel_samples = 5; vel_size = 0.75; 
[h_data, h_vel] = plot_reference_trajectories(Data, vel_samples, vel_size);
axis equal;

% Extract Position and Velocities
M          = size(Data,1)/2;    
Xi_ref     = Data(1:M,:);
Xi_dot_ref = Data(M+1:end,:);       

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Step 2 (GMM FITTING): Fit GMM to Trajectory Data %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%% GMM Estimation Algorithm %%%%%%%%%%%%%%%%%%%%%%
% 0: Physically-Consistent Non-Parametric (Collapsed Gibbs Sampler)
% 1: GMM-EM Model Selection via BIC
% 2: CRP-GMM (Collapsed Gibbs Sampler)
est_options = [];
est_options.type             = 0;   % GMM Estimation Alorithm Type   

% If algo 1 selected:
est_options.maxK             = 15;  % Maximum Gaussians for Type 1
est_options.fixed_K          = [];  % Fix K and estimate with EM for Type 1

% If algo 0 or 2 selected:
est_options.samplerIter      = 100;  % Maximum Sampler Iterations
                                    % For type 0: 20-50 iter is sufficient
                                    % For type 2: >100 iter are needed
                                    
est_options.do_plots         = 1;   % Plot Estimation Statistics
est_options.sub_sample       = 1;   % Size of sub-sampling of trajectories

% Metric Hyper-parameters
est_options.estimate_l       = 1;   % Estimate the lengthscale, if set to 1
est_options.l_sensitivity    = 2;   % lengthscale sensitivity [1-10->>100]
                                    % Default value is set to '2' as in the
                                    % paper, for very messy, close to
                                    % self-interescting trajectories, we
                                    % recommend a higher value
est_options.length_scale     = [];  % if estimate_l=0 you can define your own
                                    % l, when setting l=0 only
                                    % directionality is taken into account

% Fit GMM to Trajectory Data
[Priors, Mu, Sigma] = fit_gmm(Xi_ref, Xi_dot_ref, est_options);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Step 3 (FIT Visualization): Visualize Gaussian Components and labels %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract Cluster Labels
est_K      = length(Priors);
[~, est_labels] =  my_gmm_cluster(Xi_ref, Priors, Mu, Sigma, 'hard', []);

if M == 2
    % Visualize Cluster Parameters Trajectory Data
    plotGMMParameters( Xi_ref, est_labels, Mu, Sigma);
    limits = axis;
    switch est_options.type
        case 0
            title('Physically-Consistent Non-Parametric Mixture Model','Interpreter','LaTex', 'FontSize',15);
        case 1
            title('Best fit GMM with EM-based BIC Model Selection','Interpreter','LaTex', 'FontSize',15);
        case 2
            title('Bayesian Non-Parametric Mixture Model (CRP-GMM)','Interpreter','LaTex', 'FontSize',15);
    end
    
    % Visualize PDF of fitted GMM
    ml_plot_gmm_pdf(Xi_ref, Priors, Mu, Sigma, limits)
    switch est_options.type
        case 0
            title('Physically-Consistent Non-Parametric Mixture Model','Interpreter','LaTex', 'FontSize',15);
        case 1
            title('Best fit GMM with EM-based BIC Model Selection','Interpreter','LaTex', 'FontSize',15);
        case 2
            title('Bayesian Non-Parametric Mixture Model (CRP-GMM)','Interpreter','LaTex', 'FontSize',15);
    end
    
elseif M == 3
    GMM = [];
    GMM.Priors = Priors; GMM.Mu = Mu; GMM.Sigma = Sigma;
    [h_gmm] = plot3DGMMParameters(Xi_ref, GMM, est_labels);
    switch est_options.type
        case 0
            title('Physically-Consistent Non-Parametric Mixture Model','Interpreter','LaTex', 'FontSize',15);
        case 1
            title('Best fit GMM with EM-based BIC Model Selection','Interpreter','LaTex', 'FontSize',15);
        case 2
            title('Bayesian Non-Parametric Mixture Model (CRP-GMM)','Interpreter','LaTex', 'FontSize',15);
    end
    view(-120, 30);
    axis equal
end