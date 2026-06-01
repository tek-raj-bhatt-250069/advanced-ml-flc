% ============================================================
% PART 3 - CEC 2005 Benchmark Comparison
% GA vs PSO on F1 (Shifted Sphere) and F6 (Shifted Rosenbrock)
% D=2 and D=10, 15 runs each
% ============================================================
close all; clc;

%% Settings
nRuns   = 15;
maxEval = 10000;
dims    = [2, 10];
funcs      = {'F1','F6'};
optimizers = {'GA','PSO'};

fprintf('CEC 2005 Benchmark: GA vs PSO\n');
fprintf('F1=Shifted Sphere, F6=Shifted Rosenbrock\n');
fprintf('D=2 and D=10, %d runs each\n\n', nRuns);

%% Fixed shift vectors
rng(1);
o_F1 = rand(1,10)*100 - 50;
o_F6 = rand(1,10)*100 - 50;

%% Run all experiments
results = struct();

for fi = 1:2
    for di = 1:length(dims)
        D = dims(di);
        for oi = 1:2
            key = sprintf('%s_D%d_%s', funcs{fi}, D, optimizers{oi});
            fprintf('Running %s ...\n', key);

            scores = zeros(nRuns,1);
            lastConv = [];

            for r = 1:nRuns
                rng(r*10 + fi*100 + oi);

                if fi == 1
                    objFunc = @(x) cec_f1(x, o_F1(1:D));
                else
                    objFunc = @(x) cec_f6(x, o_F6(1:D));
                end

                if oi == 1
                    [scores(r), conv] = run_GA(objFunc, D, maxEval);
                else
                    [scores(r), conv] = run_PSO(objFunc, D, maxEval);
                end

                if r == nRuns
                    lastConv = conv;
                end
            end

            results.(key).scores     = scores;
            results.(key).mean       = mean(scores);
            results.(key).std        = std(scores);
            results.(key).best       = min(scores);
            results.(key).worst      = max(scores);
            results.(key).convergence = lastConv;
        end
    end
end

%% Print results table
fprintf('\n%s\n', repmat('=',1,75));
fprintf('%-25s %10s %10s %12s %12s\n','Experiment','Mean','StdDev','Best','Worst');
fprintf('%s\n', repmat('-',1,75));
for fi = 1:2
    for di = 1:length(dims)
        D = dims(di);
        for oi = 1:2
            key = sprintf('%s_D%d_%s', funcs{fi}, D, optimizers{oi});
            r = results.(key);
            fprintf('%-25s %10.4f %10.4f %12.4f %12.4f\n', ...
                key, r.mean, r.std, r.best, r.worst);
        end
    end
    fprintf('%s\n', repmat('-',1,75));
end

%% Convergence plots - F1
figure('Name','F1 Shifted Sphere Convergence');
subplot(1,2,1); hold on; title('F1 Shifted Sphere D=2');
plot(results.F1_D2_GA.convergence,  'b-',  'LineWidth',2);
plot(results.F1_D2_PSO.convergence, 'r--', 'LineWidth',2);
legend('GA','PSO'); xlabel('Iteration'); ylabel('Best Fitness');
grid on; set(gca,'YScale','log');

subplot(1,2,2); hold on; title('F1 Shifted Sphere D=10');
plot(results.F1_D10_GA.convergence,  'b-',  'LineWidth',2);
plot(results.F1_D10_PSO.convergence, 'r--', 'LineWidth',2);
legend('GA','PSO'); xlabel('Iteration'); ylabel('Best Fitness');
grid on; set(gca,'YScale','log');

%% Convergence plots - F6
figure('Name','F6 Shifted Rosenbrock Convergence');
subplot(1,2,1); hold on; title('F6 Shifted Rosenbrock D=2');
plot(results.F6_D2_GA.convergence,  'b-',  'LineWidth',2);
plot(results.F6_D2_PSO.convergence, 'r--', 'LineWidth',2);
legend('GA','PSO'); xlabel('Iteration'); ylabel('Best Fitness');
grid on; set(gca,'YScale','log');

subplot(1,2,2); hold on; title('F6 Shifted Rosenbrock D=10');
plot(results.F6_D10_GA.convergence,  'b-',  'LineWidth',2);
plot(results.F6_D10_PSO.convergence, 'r--', 'LineWidth',2);
legend('GA','PSO'); xlabel('Iteration'); ylabel('Best Fitness');
grid on; set(gca,'YScale','log');

%% Box plots
figure('Name','Box Plots - GA vs PSO');
subplot(2,2,1);
boxplot([results.F1_D2_GA.scores, results.F1_D2_PSO.scores], {'GA','PSO'});
title('F1 D=2'); ylabel('Fitness'); grid on;

subplot(2,2,2);
boxplot([results.F1_D10_GA.scores, results.F1_D10_PSO.scores], {'GA','PSO'});
title('F1 D=10'); ylabel('Fitness'); grid on;

subplot(2,2,3);
boxplot([results.F6_D2_GA.scores, results.F6_D2_PSO.scores], {'GA','PSO'});
title('F6 D=2'); ylabel('Fitness'); grid on;

subplot(2,2,4);
boxplot([results.F6_D10_GA.scores, results.F6_D10_PSO.scores], {'GA','PSO'});
title('F6 D=10'); ylabel('Fitness'); grid on;

disp('Part 3 complete! Screenshot all figures and results table.');

% ============================================================
%% BENCHMARK FUNCTIONS
% ============================================================
function f = cec_f1(x, o)
    % F1: Shifted Sphere
    % Global optimum = 0 at x = o
    z = x - o;
    f = sum(z.^2);
end

function f = cec_f6(x, o)
    % F6: Shifted Rosenbrock
    % Global optimum = 0 at x = o+1
    z = x - o + 1;
    f = 0;
    for i = 1:length(z)-1
        f = f + 100*(z(i+1) - z(i)^2)^2 + (z(i) - 1)^2;
    end
end

% ============================================================
%% OPTIMIZERS
% ============================================================
function [bestVal, convCurve] = run_GA(objFunc, D, maxEval)
    popSize   = 50;
    maxGen    = floor(maxEval / popSize);
    crossRate = 0.8;
    mutRate   = 0.1;
    lb = -100; ub = 100;
    convCurve = zeros(1, maxGen);

    % Initialise population
    pop = lb + rand(popSize, D) * (ub - lb);
    fitness = zeros(popSize, 1);
    for i = 1:popSize
        fitness(i) = objFunc(pop(i,:));
    end

    [bestVal, bestIdx] = min(fitness);
    bestChrom = pop(bestIdx,:);

    for gen = 1:maxGen
        newPop = zeros(popSize, D);
        newPop(1,:) = bestChrom;

        % Tournament selection
        for i = 2:popSize
            t1 = randi(popSize);
            t2 = randi(popSize);
            if fitness(t1) < fitness(t2)
                newPop(i,:) = pop(t1,:);
            else
                newPop(i,:) = pop(t2,:);
            end
        end

        % Single point crossover
        for i = 2:2:popSize-1
            if rand < crossRate
                pt = randi(D-1);
                tmp = newPop(i, pt+1:end);
                newPop(i, pt+1:end)   = newPop(i+1, pt+1:end);
                newPop(i+1, pt+1:end) = tmp;
            end
        end

        % Adaptive Gaussian mutation
        mutScale = (ub - lb) * 0.1 * (1 - gen/maxGen);
        for i = 2:popSize
            mask = rand(1, D) < mutRate;
            newPop(i,:) = newPop(i,:) + mask .* randn(1,D) * mutScale;
            newPop(i,:) = max(lb, min(ub, newPop(i,:)));
        end

        pop = newPop;
        for i = 1:popSize
            fitness(i) = objFunc(pop(i,:));
        end

        [genBest, idx] = min(fitness);
        if genBest < bestVal
            bestVal   = genBest;
            bestChrom = pop(idx,:);
        end
        convCurve(gen) = bestVal;
    end
end

function [bestVal, convCurve] = run_PSO(objFunc, D, maxEval)
    popSize = 50;
    maxIter = floor(maxEval / popSize);
    lb = -100; ub = 100;
    w  = 0.729;
    c1 = 1.494;
    c2 = 1.494;
    convCurve = zeros(1, maxIter);

    % Initialise
    pos      = lb + rand(popSize, D) * (ub - lb);
    vel      = zeros(popSize, D);
    pBest    = pos;
    pBestVal = zeros(popSize, 1);

    for i = 1:popSize
        pBestVal(i) = objFunc(pos(i,:));
    end

    [bestVal, idx] = min(pBestVal);
    gBest = pBest(idx,:);

    for iter = 1:maxIter
        r1 = rand(popSize, D);
        r2 = rand(popSize, D);

        % Update velocity
        vel = w * vel ...
            + c1 * r1 .* (pBest - pos) ...
            + c2 * r2 .* (repmat(gBest, popSize, 1) - pos);

        % Update position
        pos = pos + vel;
        pos = max(lb, min(ub, pos));

        % Evaluate and update personal bests
        for i = 1:popSize
            val = objFunc(pos(i,:));
            if val < pBestVal(i)
                pBestVal(i) = val;
                pBest(i,:)  = pos(i,:);
            end
        end

        % Update global best
        [iterBest, idx] = min(pBestVal);
        if iterBest < bestVal
            bestVal = iterBest;
            gBest   = pBest(idx,:);
        end
        convCurve(iter) = bestVal;
    end
end