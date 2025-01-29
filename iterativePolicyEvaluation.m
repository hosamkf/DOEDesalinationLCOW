% iterativePolicyEvaluation.m
%
% This is a generic piece of code that performs discounted-cost evaluation
% of an infinite-horizon policy. The code can be used as a foundation for
% solving an infinite-horizon stochastic optimal control problem
% (specifically, a discounted-cost, infinite-horizon stochastic dynamic
% programming problem). It can also be used, in the context of marine
% hydrokinetic system techno-economic evaluation, for the purpose of
% computing the levelized cost of water, under different assumptions
% regarding the aging/degradation of the MHK system under consideration. In
% the context of that particular problem domain, this function would need
% to be called twice, once to compute total discounted cost and another
% time to compute total discounted water production. 
%
% Output: valueFunction: value function for each state
%
% Inputs: 
%       markovTransitionTables: set of all Markov transition tables, for
%           all control inputs
%       markovTransitionCosts: set of all transition costs, for all values
%           of the control input
%       nStates: number of states
%       controlPolicy: control policy, i.e., choice of control input for
%           each state
%       interestRate: interest rate (percent) used to determine the
%           discount factor and discounted cost
%       timeStep: time step used for translating interest rate into a
%           discount factor and discounted cost
%       tolerance: tolerance for evaluating value function, defined as a
%           maximum allowable percentage ratio of the RMS change in value
%           function from one iteration to the next for all states divided by
%           the RMS value of the current estimate of the value function for all
%           states
%       initialEstimate: initial estimate of value function
% 
% Created by the University of Maryland DOE MHK research team (H.K. Fathy
% et al). 
%
% Last edit: Jan. 29, 2025

function valueFunction = iterativePolicyEvaluation(markovTransitionTables, markovTransitionCosts,nStates,controlPolicy,interestRate,timeStep,tolerance,initialEstimate)

% Begin by computing a discount factor (note: this code assumes a positive
% interest rate accrued continuously, as well as a fixed time step). 

discountFactor = exp(-interestRate*timeStep/100); 

% Begin by setting initial estimate for value function

valueFunction = initialEstimate; 
newValueFunction = valueFunction;

% Next, construct the overall Markov transition probability table, and
% overall Markov transition cost table

overallMarkovTransitionTable = zeros(nStates,nStates);
overallMarkovTransitionCostTable = zeros(nStates,nStates);

for stateIndex = 1:nStates
    controlIndex = controlPolicy(stateIndex);
    overallMarkovTransitionTable(:,stateIndex) = squeeze(markovTransitionTables(controlIndex,:,stateIndex));
    overallMarkovTransitionCostTable(:,stateIndex) = squeeze(markovTransitionCosts(controlIndex,:,stateIndex));
end;

% Next, perform value iteration

valueError = 10*tolerance;

while valueError > tolerance
    for k = 1:nStates
        newValueFunction(k) = 0;
        for i = 1:nStates
            newValueFunction(k) = newValueFunction(k) + discountFactor*overallMarkovTransitionTable(i,k)*(valueFunction(i)+overallMarkovTransitionCostTable(i,k));
        end;
    end; 
    valueError = (sqrt(sum((newValueFunction-valueFunction).^2))/sqrt(sum(valueFunction.^2)))*100;
    valueFunction = newValueFunction;
end; 