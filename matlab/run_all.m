% RUN_ALL  Verification + the three experiments, in the right order.
%
% Run in MATLAB:  run_all
%
% Produces
%   results/exp1_fleet_size.csv / .mat
%   results/exp2_terrain.csv
%   results/exp3_sweep_width.csv
%   results/exp4_convergence.csv
%   figures/fig1_fleet_size.png, fig2_terrain.png, fig3_sweep_width.png
%   figures/fig4_convergence.png, fig5_prior_sampling.png

clear; clc; close all;

fprintf('\n########## 0. verification ##########\n');
validate_sim();

% NOTE: each experiment script starts with "clear", which also clears the
% variables of the caller, so "here" is recomputed before every run.
fprintf('\n########## 1. fleet-size saturation ##########\n');
here = fileparts(mfilename('fullpath'));
run(fullfile(here, 'run_experiment1.m'));

fprintf('\n########## 2. strategy comparison across terrains ##########\n');
here = fileparts(mfilename('fullpath'));
run(fullfile(here, 'run_experiment2.m'));

fprintf('\n########## 3. sweep-width sensitivity ##########\n');
here = fileparts(mfilename('fullpath'));
run(fullfile(here, 'run_experiment3.m'));

fprintf('\n########## 4. course-method checks ##########\n');
p = config();
run_convergence(10, p.reps);
check_sampling('mixed', 20000);

fprintf('\nAll done. Check results/ and figures/.\n');
