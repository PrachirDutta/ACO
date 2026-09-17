clc;
clear;
close all;

%% Problem Definition

global NFE;

CostFunction = @(x) fitnessfunc(x);

nVar = 1;

VarSize = [1 nVar];

VarMin = [77.4,9.8,0.44,0.470,0.310,0.150, ...
          0.9,2.4/10,0.05,0.90,0,0, ...
          0.9,2.4/10,0.05,0.90,0,0];

VarMax = [77.6,10.1,0.46,0.49,0.320,0.1564, ...
          1.1,2.6/10,0.07,1.1,0,0, ...
          1.1,2.6/10,0.07,1.1,0,0];


%% ACOR Parameters

MaxIt = 1;

nPop = 50;          % Archive size
nSample = 50;       % Number of new ants per iteration

q = 0.5;            % Intensification parameter
zeta = 1.0;         % Deviation-distance ratio


%% Initialization

empty_individual.Position = [];
empty_individual.Cost = [];

pop = repmat(empty_individual,nPop,1);

for i = 1:nPop

 pop(i).Position = unifrnd(VarMin,VarMax);

    pop(i).Cost = CostFunction(pop(i).Position);

end


%% Sort Initial Population

[~, SortOrder] = sort([pop.Cost]);

pop = pop(SortOrder);


%% Best Solution

BestSol = pop(1);

BestCost = zeros(MaxIt,1);


%% Selection Probabilities

w = zeros(nPop,1);

for l = 1:nPop

    w(l) = 1/(q*nPop*sqrt(2*pi)) * ...
        exp(-0.5*((l-1)/(q*nPop))^2);

end

p = w/sum(w);


%% Main ACOR Loop

for it = 1:MaxIt

    newpop = repmat(empty_individual,nSample,1);

    for t = 1:nSample

        newpop(t).Position = zeros(VarSize);

        for i = 1:nVar

            % Select Gaussian kernel
            l = RouletteWheelSelection(p);

            % Mean is selected archive solution
            mu = pop(l).Position(i);

            % Calculate standard deviation
            sigma = 0;

            for r = 1:nPop

                sigma = sigma + ...
                    abs(pop(r).Position(i) - pop(l).Position(i));

            end

            sigma = zeta * sigma/(nPop-1);

            % Generate new candidate
            newpop(t).Position(i) = ...
                mu + sigma*randn;

        end

        % Apply bounds
        newpop(t).Position = ...
            max(newpop(t).Position,VarMin);

        newpop(t).Position = ...
            min(newpop(t).Position,VarMax);

        % Evaluate
        newpop(t).Cost = ...
            CostFunction(newpop(t).Position);

    end


    %% Merge Archive and New Ants

    pop = [pop
           newpop];


    %% Sort

    [~, SortOrder] = sort([pop.Cost]);

    pop = pop(SortOrder);


    %% Keep Best nPop Solutions

    pop = pop(1:nPop);


    %% Update Best

    BestSol = pop(1);

    BestCost(it) = BestSol.Cost;


    %% Display

    fprintf('Iteration %d: Best Cost = %.12f\n', ...
        it, BestCost(it));

end


%% Results

figure;

semilogy(BestCost,'LineWidth',2);

xlabel('Iteration');

ylabel('Best Cost');

grid on;


%% Optimized Parameters

best_Value = BestSol.Position;

fprintf('\n============================================\n');
fprintf(' OPTIMIZED PARAMETERS\n');
fprintf('============================================\n');

fprintf('K   = %.10f\n',best_Value(1));
fprintf('Tw  = %.10f\n',best_Value(2));
fprintf('T1  = %.10f\n',best_Value(3));
fprintf('T2  = %.10f\n',best_Value(4));
fprintf('T3  = %.10f\n',best_Value(5));
fprintf('T4  = %.10f\n',best_Value(6));

fprintf('\nBest Cost = %.12f\n',BestSol.Cost);


%% Save Result

K  = best_Value(1);
Tw = best_Value(2);
T1 = best_Value(3);
T2 = best_Value(4);
T3 = best_Value(5);
T4 = best_Value(6);

BestFitness = BestSol.Cost;

save('optimized_POD_parameters.mat', ...
     'K','Tw','T1','T2','T3','T4', ...
     'BestFitness','best_Value');

fprintf('\nOptimized parameters saved to:\n');
fprintf('optimized_POD_parameters.mat\n');