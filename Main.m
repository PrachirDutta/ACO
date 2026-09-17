clc;
clear;
close all;

%% Problem Definition

global NFE;

CostFunction=@(x) fitnessfunc(x);        % Cost Function

nVar=18;             % Number of Decision Variables

VarSize=[1 nVar];   % Size of Decision Variables Matrix

VarMin=[77.4,9.8, 0.44,0.470, 0.310, 0.150,0.9, 2.4/10,0.05,0.90 ,0,0 ,0.9, 2.4/10,0.05,0.90 ,0,0 ];         % Lower Bound of Variables
VarMax=[77.6 ,10.1, 0.46,0.49,0.320,0.1564 ,1.1, 2.6/10,0.07,1.1,0,0,1.1, 2.6/10,0.07,1.1,0,0];         % Upper Bound of Variables


%%  Parameters

MaxIt=3;      % Maximum Number of Iterations

nPop=50;        % Population Size 

% w=1;            % Inertia Weight
% wdamp=0.99;     % Inertia Weight Damping Ratio
% c1=2;           % Personal Learning Coefficient
% c2=2;           % Global Learning Coefficient

% Constriction Coefficients
phi1=2.05;
phi2=2.05;
phi=phi1+phi2;
chi=2/(phi-2+sqrt(phi^2-4*phi));
w=chi;          % Inertia Weight
wdamp=1;        % Inertia Weight Damping Ratio
c1=chi*phi1;    % Personal Learning Coefficient
c2=chi*phi2;    % Global Learning Coefficient

% Velocity Limits
VelMax=0.1*(VarMax-VarMin);
VelMin=-VelMax;

%% Initialization

empty_particle.Position=[];
empty_particle.Cost=[];
empty_particle.Velocity=[];
empty_particle.Best.Position=[];
empty_particle.Best.Cost=[];

particle=repmat(empty_particle,nPop,1);

GlobalBest.Cost=inf;

for i=1:nPop
    
    % Initialize Position
    particle(i).Position=unifrnd(VarMin,VarMax,VarSize);
    
    % Initialize Velocity
    particle(i).Velocity=zeros(VarSize);
    
    % Evaluation
    particle(i).Cost=CostFunction(particle(i).Position);
    
    % Update Personal Best
    particle(i).Best.Position=particle(i).Position;
    particle(i).Best.Cost=particle(i).Cost;
    
    % Update Global Best
    if particle(i).Best.Cost<GlobalBest.Cost
        
        GlobalBest=particle(i).Best;
        
    end
    
end

BestCost=zeros(MaxIt,1);

nfe=zeros(MaxIt,1);


%%  Main Loop

for it=1:MaxIt
    
    for i=1:nPop
        
        % Update Velocity
        particle(i).Velocity = w*particle(i).Velocity ...
            +c1*rand(VarSize).*(particle(i).Best.Position-particle(i).Position) ...
            +c2*rand(VarSize).*(GlobalBest.Position-particle(i).Position);
        
        % Apply Velocity Limits
        particle(i).Velocity = max(particle(i).Velocity,VelMin);
        particle(i).Velocity = min(particle(i).Velocity,VelMax);
        
        % Update Position
        particle(i).Position = particle(i).Position + particle(i).Velocity;
        
        % Velocity Mirror Effect
        IsOutside=(particle(i).Position<VarMin | particle(i).Position>VarMax);
        particle(i).Velocity(IsOutside)=-particle(i).Velocity(IsOutside);
        
        % Apply Position Limits
        particle(i).Position = max(particle(i).Position,VarMin);
        particle(i).Position = min(particle(i).Position,VarMax);
        
        % Evaluation
        particle(i).Cost = CostFunction(particle(i).Position);
        
        % Update Personal Best
        if abs(particle(i).Cost)<abs(particle(i).Best.Cost)
            
            particle(i).Best.Position=particle(i).Position;
            particle(i).Best.Cost=particle(i).Cost;
            
            % Update Global Best
            if abs(particle(i).Best.Cost)<abs(GlobalBest.Cost)
                
                GlobalBest=particle(i).Best;
                
            end
            
        end
        
    end
    
    BestCost(it)=GlobalBest.Cost;
    
    nfe(it)=NFE;
    
    disp(['Iteration ' num2str(it) ': NFE = ' num2str(nfe(it)) ', Best Cost = ' num2str(BestCost(it))]);
    
    w=w*wdamp;
    
end

%% Results

figure;
plot(nfe,BestCost,'LineWidth',2);
semilogy(nfe,BestCost,'LineWidth',2);
xlabel('Iteration');
ylabel('Best Cost');

best_Value = GlobalBest.Position;
fprintf('\n  The best Value for Kp is %f  \n',best_Value(1))
fprintf('\n  The best location for Tw is %f  \n',best_Value(2))
fprintf('\n  The best location for T1 is %f  \n',best_Value(3))
fprintf('\n  The best Value for Kp T2 %f  \n',best_Value(4))
fprintf('\n  The best location for T3 is %f  \n',best_Value(5))
fprintf('\n  The best location for T4 is %f  \n',best_Value(6))


fprintf('\n  The best Value for Kp1 is %f  \n',best_Value(7))
fprintf('\n  The best location for Tw1 is %f  \n',best_Value(8))
fprintf('\n  The best location for T11 is %f  \n',best_Value(9))
fprintf('\n  The best Value for Kp T21 %f  \n',best_Value(10))
fprintf('\n  The best location for T31 is %f  \n',best_Value(11))
fprintf('\n  The best location for T41 is %f  \n',best_Value(12))


fprintf('\n  The best Value for Kp2 is %f  \n',best_Value(13))
fprintf('\n  The best location for Tw2 is %f  \n',best_Value(14))
fprintf('\n  The best location for T12 is %f  \n',best_Value(15))
fprintf('\n  The best Value for Kp T22 %f  \n',best_Value(16))
fprintf('\n  The best location for T32 is %f  \n',best_Value(17))
fprintf('\n  The best location for T42 is %f  \n',best_Value(18))




fprintf('\n  Optimum value for Cost Function is %f ($) \n',BestCost(end))

%% ============================================================
% SAVE OPTIMIZED POD PARAMETERS
% ============================================================

% Use the actual global optimum
best_Value = GlobalBest.Position;

% First POD controller parameters
K  = best_Value(1);
Tw = best_Value(2);
T1 = best_Value(3);
T2 = best_Value(4);
T3 = best_Value(5);
T4 = best_Value(6);

% Save optimum cost as well
BestFitness = GlobalBest.Cost;

% Save to MAT file
save('optimized_POD_parameters.mat', ...
     'K', 'Tw', 'T1', 'T2', 'T3', 'T4', ...
     'BestFitness', 'best_Value');

fprintf('\n============================================\n');
fprintf(' OPTIMIZED POD PARAMETERS SAVED\n');
fprintf('============================================\n');

fprintf('K  = %.10f\n', K);
fprintf('Tw = %.10f\n', Tw);
fprintf('T1 = %.10f\n', T1);
fprintf('T2 = %.10f\n', T2);
fprintf('T3 = %.10f\n', T3);
fprintf('T4 = %.10f\n', T4);

fprintf('\nBest Fitness = %.12f\n', BestFitness);

fprintf('\nSaved to: optimized_POD_parameters.mat\n');