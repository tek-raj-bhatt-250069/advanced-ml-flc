warning('off', 'fuzzy:general:evalfis_outOfRangeInput');
warning('off', 'fuzzy:defuzz:emptyFuzzySet');

% ============================================================
% PART 2 - GA Optimization - Part2_GA.m
% ============================================================
close all; clc;
warning('off', 'fuzzy:general:evalfis_outOfRangeInput');

%% Load FIS
fis = readfis('SmartHomeFLC.fis');
fprintf('Loaded: %d inputs, %d outputs, %d rules\n', ...
    numel(fis.Inputs), numel(fis.Outputs), numel(fis.Rules));

%% Generate training data
rng(42);
N = 200;
trainInputs  = [rand(N,1)*40, rand(N,1)*1000, rand(N,1)*24];
trainTargets = zeros(N,2);
for i = 1:N
    trainTargets(i,:) = evalfis(fis, trainInputs(i,:));
end
trainTargets = trainTargets + randn(N,2) * 5;
trainTargets = max(0, min(100, trainTargets));
fprintf('Training data: %d samples\n', N);

%% Extract chromosome
baseChromosome = extractParams(fis);
chromLength    = length(baseChromosome);
fprintf('Chromosome length: %d\n', chromLength);

%% Bounds - small perturbation around base values
perturbation = 3;  % only allow ±3 units from original MF positions
lb = baseChromosome - perturbation;
ub = baseChromosome + perturbation;

% Hard clamp to physical ranges
lb(1:15)  = max(lb(1:15),  0);   ub(1:15)  = min(ub(1:15),  40);
lb(16:27) = max(lb(16:27), 0);   ub(16:27) = min(ub(16:27), 1000);
lb(28:42) = max(lb(28:42), 0);   ub(28:42) = min(ub(28:42), 24);
lb(43:57) = max(lb(43:57), 0);   ub(43:57) = min(ub(43:57), 100);
lb(58:72) = max(lb(58:72), 0);   ub(58:72) = min(ub(58:72), 100);

%% GA settings
popSize=50; maxGen=100; crossRate=0.8; mutRate=0.1; mutScale=0.5;

%% Initialise population NEAR base chromosome
population = zeros(popSize, chromLength);
population(1,:) = baseChromosome;  % keep original as first member
for i = 2:popSize
    noise = randn(1,chromLength) * 1.5;
    population(i,:) = baseChromosome + noise;
    population(i,:) = max(lb, min(ub, population(i,:)));
end

%% Evaluate initial population
fitness = zeros(popSize,1);
for i = 1:popSize
    fitness(i) = fitnessFunc(population(i,:), fis, trainInputs, trainTargets);
end

[bestRMSE, bestIdx] = min(fitness);
bestChrom   = population(bestIdx,:);
bestFitness = zeros(maxGen,1);
meanFitness = zeros(maxGen,1);
fprintf('\nInitial RMSE: %.4f\n\n', bestRMSE);

%% GA Loop
for gen = 1:maxGen
    % Evaluate fitness
    fitness = zeros(popSize,1);
    for i = 1:popSize
        fitness(i) = fitnessFunc(population(i,:), fis, trainInputs, trainTargets);
    end

    % Track best
    [genBest, bestIdx] = min(fitness);
    if genBest < bestRMSE
        bestRMSE  = genBest;
        bestChrom = population(bestIdx,:);
    end
    bestFitness(gen) = bestRMSE;

    % Mean only over valid chromosomes
    validFitness = fitness(fitness < 1e5);
    if ~isempty(validFitness)
        meanFitness(gen) = mean(validFitness);
    else
        meanFitness(gen) = bestRMSE;
    end

    if mod(gen,10)==0
        fprintf('Gen %3d | Best: %.4f | Mean: %.4f | Valid: %d/%d\n', ...
            gen, bestRMSE, meanFitness(gen), sum(fitness<1e5), popSize);
    end

    % Elitism - keep best solution
    newPop = zeros(popSize, chromLength);
    newPop(1,:) = bestChrom;

    % Tournament selection for rest
    for i = 2:popSize
        t1=randi(popSize); t2=randi(popSize);
        if fitness(t1)<fitness(t2)
            newPop(i,:)=population(t1,:);
        else
            newPop(i,:)=population(t2,:);
        end
    end

    % Single-point crossover
    for i = 2:2:popSize-1
        if rand<crossRate
            pt=randi(chromLength-1);
            tmp=newPop(i,pt+1:end);
            newPop(i,pt+1:end)=newPop(i+1,pt+1:end);
            newPop(i+1,pt+1:end)=tmp;
        end
    end

    % Gaussian mutation with clamping
    for i = 2:popSize  % skip elite
        mask=rand(1,chromLength)<mutRate;
        newPop(i,:)=newPop(i,:)+mask.*randn(1,chromLength)*mutScale;
        newPop(i,:)=max(lb,min(ub,newPop(i,:)));
    end

    population = newPop;
end

%% Results
warning('on', 'fuzzy:general:evalfis_outOfRangeInput');
optimisedFIS = applyParams(fis, bestChrom);
writeFIS(optimisedFIS, 'SmartHomeFLC_GA_Optimised');
initialRMSE  = fitnessFunc(baseChromosome, fis, trainInputs, trainTargets);

fprintf('\n=== GA RESULTS ===\n');
fprintf('Chromosome length : %d\n', chromLength);
fprintf('Population size   : %d\n', popSize);
fprintf('Generations       : %d\n', maxGen);
fprintf('Crossover rate    : %.2f\n', crossRate);
fprintf('Mutation rate     : %.2f\n', mutRate);
fprintf('Initial RMSE      : %.4f\n', initialRMSE);
fprintf('Optimised RMSE    : %.4f\n', bestRMSE);
fprintf('Improvement       : %.2f%%\n', 100*(initialRMSE-bestRMSE)/initialRMSE);

%% Convergence plot
figure;
plot(1:maxGen, bestFitness, 'b-', 'LineWidth',2); hold on;
plot(1:maxGen, meanFitness, 'r--','LineWidth',1.5);
xlabel('Generation'); ylabel('RMSE');
title('GA Convergence Curve - FLC Optimisation');
legend('Best RMSE','Mean RMSE'); grid on;

%% Comparison plot
pred_orig=zeros(N,2); pred_opt=zeros(N,2);
for i=1:N
    pred_orig(i,:)=evalfis(fis,trainInputs(i,:));
    pred_opt(i,:) =evalfis(optimisedFIS,trainInputs(i,:));
end
figure;
subplot(2,1,1);
plot(trainTargets(:,1),'k','LineWidth',1.5); hold on;
plot(pred_orig(:,1),'b--'); plot(pred_opt(:,1),'r-.');
legend('Target','Original','GA Optimised');
title('Heater Power: Original vs GA Optimised');
ylabel('Heater Power (%)'); grid on;
subplot(2,1,2);
plot(trainTargets(:,2),'k','LineWidth',1.5); hold on;
plot(pred_orig(:,2),'b--'); plot(pred_opt(:,2),'r-.');
legend('Target','Original','GA Optimised');
title('Dimmer Level: Original vs GA Optimised');
ylabel('Dimmer Level (%)'); grid on;

disp('Part 2 complete! Screenshot convergence and comparison plots.');

% ============================================================
%% LOCAL FUNCTIONS
% ============================================================
function params = extractParams(fis)
    params = [];
    for i = 1:numel(fis.Inputs)
        for j = 1:numel(fis.Inputs(i).MembershipFunctions)
            params = [params, fis.Inputs(i).MembershipFunctions(j).Parameters];
        end
    end
    for i = 1:numel(fis.Outputs)
        for j = 1:numel(fis.Outputs(i).MembershipFunctions)
            params = [params, fis.Outputs(i).MembershipFunctions(j).Parameters];
        end
    end
end

function fis = applyParams(fis, params)
    idx = 1;
    for i = 1:numel(fis.Inputs)
        for j = 1:numel(fis.Inputs(i).MembershipFunctions)
            fis.Inputs(i).MembershipFunctions(j).Parameters = params(idx:idx+2);
            idx = idx+3;
        end
    end
    for i = 1:numel(fis.Outputs)
        for j = 1:numel(fis.Outputs(i).MembershipFunctions)
            fis.Outputs(i).MembershipFunctions(j).Parameters = params(idx:idx+2);
            idx = idx+3;
        end
    end
end

function rmse = fitnessFunc(params, fis, inputs, targets)
    try
        fis = applyParams(fis, params);
        pred = zeros(size(targets));
        for i = 1:size(inputs,1)
            pred(i,:) = evalfis(fis, inputs(i,:));
        end
        rmse = sqrt(mean((pred(:)-targets(:)).^2));
    catch
        rmse = 1e6;
    end
end