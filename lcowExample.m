% lcowExample.m
%
% Provides an example of computing LCOW for a marine hydrokinetic energy
% harvesting-based water desalination system. In this example, the first
% state in the list of states represents a brand-new system, the final
% state represents end of life, the control input represents a utilization
% use case over a time step (e.g., a water desalination rate), and
% different control policies can be represented if desired by making this
% control input state-dependent. The input- and state-dependent Markov
% transition probabilities represent system aging as a function of
% utilization. There are two input- and state-dependent Markov transition
% "cost" tables: one representing a dollar cost, and one representing water
% production rate (a "reward"). Regardless of the control policy, the final
% state is absorbing, meaning that once the system has reached end of life,
% it is no longer producing water or capable of transitioning to another
% state. The cost of transition from the first state to the second state
% represents Cap-Ex, and all other costs represent Op-Ex. This first
% transition does not involve producing water. Therefore, LCOW can be
% automatically computed by dividing the discounted cost associated with
% the first state by the discounted reward associated with that same state.
% 
% Created by the University of Maryland DOE MHK wave glider desalination
% research team (H.K. Fathy et al). 
% 
% Last edit: Jan. 29, 2025

%% This example computes LCOW assuming constant water production every
% year, for a 30-year span. This computation is performed for different 
% interest rates (i.e., different discount rates). Op-Ex is assumed to not
% change with time or state of health. The end result is a very classical
% computation of LCOW, for different interest rates. The flexibility of
% using a dual Markov chain representation makes it possible to account for
% more sophisticated scenarios (e.g., utilization-dependent aging,
% stochastic aging, state of health-dependent aging, etc.). 

clear all
close all
clc

capEx = 10;  % USD
opEx = 0.3;  % USD per year 
waterProductionRate = 1; % m3 of water per year

nInputs = 1;  % Number of possible use case scenarios (e.g., water production rates)
nStates = 32; % Number of possible states (e.g., years of service + 2, where the first state represents a non-existent system being constructed and the last state represents a "dead" system)

markovTransitionTables = zeros(nInputs,nStates,nStates);  % Table of input-dependent state transition probabilities
markovTransitionCosts = zeros(nInputs,nStates,nStates); % Table of input- and state transition-dependent transition costs (e.g., Cap-Ex, Op-Ex)
markovTransitionRewards = zeros(nInputs,nStates,nStates); % Table of input- and state transition-dependent rewards (e.g., water production rates)

markovTransitionTables(1,2,1) = 1; % A brand-new system always gets constructed
markovTransitionCosts(1,2,1) = capEx; % The cost of construction is Cap-Ex
markovTransitionRewards(1,2,1) = 0; % No water produced during construction

for i = 2:nStates-1
    markovTransitionTables(1,i+1,i) = 1; % In this "deterministic" setting, the system ages by one year of useful life for every year of actual use
    markovTransitionCosts(1,i+1,i) = opEx; % For all transitions up until the last moment of useful life, the transition cost is Op-Ex
    markovTransitionRewards(1,i+1,i) = waterProductionRate; % For all transitions up until the last moment of useful life, the transition reward is water production
end; 

markovTransitionTables(1,nStates,nStates) = 1; % Once the system reaches end of life, it is replaced (this helps account for Cap-Ex)
markovTransitionCosts(1,nStates,nStates) = 0; % This very simple example does not model de-commissioning

controlPolicy = ones(nStates,1); % There is only one control policy in this example: generating water at a constant rate every year
tolerance = 1e-6; % Percent acceptable error in computing Markov value functions iteratively

interestRates = 4:0.01:12; % List of interest rates to explore
timeStep = 1; % One-year time steps

deterministicLCOW = zeros(length(interestRates),1); 

for i=1:length(interestRates)
    discountedCostList = iterativePolicyEvaluation(markovTransitionTables, markovTransitionCosts,nStates,controlPolicy,interestRates(i),timeStep,tolerance,zeros(nStates,1)); 
    discountedRewardList = iterativePolicyEvaluation(markovTransitionTables, markovTransitionRewards,nStates,controlPolicy,interestRates(i),timeStep,tolerance,zeros(nStates,1)); 
    deterministicLCOW(i) = discountedCostList(1)/discountedRewardList(1); 
end; 

figure
plot(interestRates,deterministicLCOW,'LineWidth',1); 
xlabel('Interest rate (%)')
ylabel('LCOW ($/m3 of water)')
title('LCOW Calculation Results - Deterministic Case')
grid
set(gca,'FontSize',16)

%% Now we explore a more stochastic example, to illustrate the benefits of
% using a dual Markov approach. In this example, water is produced at
% double the rate. However, this comes at a price of doubling the operating
% expenses AND creating a 50-50 probability of seeing one vs. two years of
% effective aging per year of operation. 

capEx = 10;  % USD
opEx = 0.6;  % USD per year 
waterProductionRate = 2; % m3 of water per year

nInputs = 1;  % Number of possible use case scenarios (e.g., water production rates)
nStates = 32; % Number of possible states (e.g., years of service + 2, where the first state represents a non-existent system being constructed and the last state represents a "dead" system)

markovTransitionTables = zeros(nInputs,nStates,nStates);  % Table of input-dependent state transition probabilities
markovTransitionCosts = zeros(nInputs,nStates,nStates); % Table of input- and state transition-dependent transition costs (e.g., Cap-Ex, Op-Ex)
markovTransitionRewards = zeros(nInputs,nStates,nStates); % Table of input- and state transition-dependent rewards (e.g., water production rates)

markovTransitionTables(1,2,1) = 1; % A brand-new system always gets constructed
markovTransitionCosts(1,2,1) = capEx; % The cost of construction is Cap-Ex
markovTransitionRewards(1,2,1) = 0; % No water produced during construction

for i = 2:nStates-2
    markovTransitionTables(1,i+1,i) = 0.5;
    markovTransitionTables(1,i+2,i) = 0.5; 
    markovTransitionCosts(1,i+1,i) = opEx;
    markovTransitionCosts(1,i+2,i) = opEx; 
    markovTransitionRewards(1,i+1,i) = waterProductionRate; 
    markovTransitionRewards(1,i+2,i) = waterProductionRate; 
end; 

markovTransitionTables(1,nStates,nStates-1) = 1; 
markovTransitionCosts(1,nStates,nStates-1) = opEx; 
markovTransitionRewards(1,nStates,nStates-1) = waterProductionRate; 
markovTransitionTables(1,nStates,nStates) = 1; % Once the system reaches end of life, it is replaced (this helps account for Cap-Ex)
markovTransitionCosts(1,nStates,nStates) = 0; % This very simple example does not model de-commissioning

controlPolicy = ones(nStates,1); % There is only one control policy in this example: generating water at a constant rate every year
tolerance = 1e-6; % Percent acceptable error in computing Markov value functions iteratively

stochasticLCOW = zeros(length(interestRates),1); 

for i=1:length(interestRates)
    discountedCostList = iterativePolicyEvaluation(markovTransitionTables, markovTransitionCosts,nStates,controlPolicy,interestRates(i),timeStep,tolerance,zeros(nStates,1)); 
    discountedRewardList = iterativePolicyEvaluation(markovTransitionTables, markovTransitionRewards,nStates,controlPolicy,interestRates(i),timeStep,tolerance,zeros(nStates,1)); 
    stochasticLCOW(i) = discountedCostList(1)/discountedRewardList(1); 
end; 

% figure
% plot(interestRates,stochasticLCOW,'LineWidth',1); 
% xlabel('Interest rate (%)')
% ylabel('LCOW ($/m3 of water)')
% title('LCOW Calculation Results - Stochastic Case')
% grid
% set(gca,'FontSize',16)
