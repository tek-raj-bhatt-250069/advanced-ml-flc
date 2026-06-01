% ============================================================
% PART 1 - Smart Home FLC - fuzzy.m
% Intelligent Assistive Care Environment
% Living Room Controller (Mamdani Type-1)
% ============================================================
close all; clc;

%% CREATE FIS
fis = mamfis('Name', 'SmartHomeFLC');

%% ADD INPUTS
fis = addInput(fis, [0 40],   'Name', 'Temperature');
fis = addInput(fis, [0 1000], 'Name', 'LightLevel');
fis = addInput(fis, [0 24],   'Name', 'TimeOfDay');

%% ADD OUTPUTS
fis = addOutput(fis, [0 100], 'Name', 'HeaterPower');
fis = addOutput(fis, [0 100], 'Name', 'DimmerLevel');

%% TEMPERATURE MEMBERSHIP FUNCTIONS
fis = addMF(fis, 'Temperature', 'trimf', [0   0  10], 'Name', 'VeryCold');
fis = addMF(fis, 'Temperature', 'trimf', [5  12  19], 'Name', 'Cold');
fis = addMF(fis, 'Temperature', 'trimf', [16 21  26], 'Name', 'Comfortable');
fis = addMF(fis, 'Temperature', 'trimf', [22 28  34], 'Name', 'Warm');
fis = addMF(fis, 'Temperature', 'trimf', [30 40  40], 'Name', 'Hot');

%% LIGHT LEVEL MEMBERSHIP FUNCTIONS
fis = addMF(fis, 'LightLevel', 'trimf', [0   0   200], 'Name', 'Dark');
fis = addMF(fis, 'LightLevel', 'trimf', [100 300 500], 'Name', 'Dim');
fis = addMF(fis, 'LightLevel', 'trimf', [400 600 800], 'Name', 'Moderate');
fis = addMF(fis, 'LightLevel', 'trimf', [700 1000 1000], 'Name', 'Bright');

%% TIME OF DAY MEMBERSHIP FUNCTIONS
fis = addMF(fis, 'TimeOfDay', 'trimf', [0   0   7],  'Name', 'Night');
fis = addMF(fis, 'TimeOfDay', 'trimf', [6  10  14],  'Name', 'Morning');
fis = addMF(fis, 'TimeOfDay', 'trimf', [12 15  18],  'Name', 'Afternoon');
fis = addMF(fis, 'TimeOfDay', 'trimf', [17 20  23],  'Name', 'Evening');
fis = addMF(fis, 'TimeOfDay', 'trimf', [22 24  24],  'Name', 'LateNight');

%% HEATER POWER MEMBERSHIP FUNCTIONS
fis = addMF(fis, 'HeaterPower', 'trimf', [0   0   25],  'Name', 'Off');
fis = addMF(fis, 'HeaterPower', 'trimf', [15  30  50],  'Name', 'Low');
fis = addMF(fis, 'HeaterPower', 'trimf', [35  55  75],  'Name', 'Medium');
fis = addMF(fis, 'HeaterPower', 'trimf', [60  80  95],  'Name', 'High');
fis = addMF(fis, 'HeaterPower', 'trimf', [85 100 100],  'Name', 'Maximum');

%% DIMMER LEVEL MEMBERSHIP FUNCTIONS
fis = addMF(fis, 'DimmerLevel', 'trimf', [0   0   25],  'Name', 'Off');
fis = addMF(fis, 'DimmerLevel', 'trimf', [15  30  50],  'Name', 'Low');
fis = addMF(fis, 'DimmerLevel', 'trimf', [35  55  75],  'Name', 'Medium');
fis = addMF(fis, 'DimmerLevel', 'trimf', [65  80  95],  'Name', 'High');
fis = addMF(fis, 'DimmerLevel', 'trimf', [85 100 100],  'Name', 'Full');

%% RULE BASE
ruleList = [
% Heater rules
  1  0  0    5  0    1  1;   % VeryCold    -> Heater Maximum
  2  0  0    4  0    1  1;   % Cold        -> Heater High
  3  0  0    2  0    1  1;   % Comfortable -> Heater Low
  4  0  0    1  0    1  1;   % Warm        -> Heater Off
  5  0  0    1  0    1  1;   % Hot         -> Heater Off
% Dimmer rules
  0  1  0    0  5    1  1;   % Dark        -> Dimmer Full
  0  2  0    0  4    1  1;   % Dim         -> Dimmer High
  0  3  0    0  2    1  1;   % Moderate    -> Dimmer Low
  0  4  0    0  1    1  1;   % Bright      -> Dimmer Off
% Time rules
  0  0  1    0  2    1  1;   % Night       -> Dimmer Low
  0  0  4    0  4    1  1;   % Evening     -> Dimmer High
  0  0  5    0  2    1  1;   % LateNight   -> Dimmer Low
% Combined rules
  2  1  4    4  5    1  1;   % Cold+Dark+Evening    -> High heat, Full light
  1  1  1    5  2    1  1;   % VeryCold+Dark+Night  -> Max heat, Low light
  5  4  2    1  1    1  1;   % Hot+Bright+Afternoon -> Off heat, Off light
  3  2  2    2  3    1  1;   % Comfortable+Dim+Afternoon -> Low, Medium
];
fis = addRule(fis, ruleList);
fprintf('Total rules: %d\n', numel(fis.Rules));

%% MF PLOTS
figure; plotmf(fis, 'input',  1); title('Temperature MFs');
figure; plotmf(fis, 'input',  2); title('Light Level MFs');
figure; plotmf(fis, 'input',  3); title('Time of Day MFs');
figure; plotmf(fis, 'output', 1); title('Heater Power MFs');
figure; plotmf(fis, 'output', 2); title('Dimmer Level MFs');

%% CONTROL SURFACES
figure;
gensurf(fis, [1 2], 1); view(45,30);
xlabel('Temperature (C)'); ylabel('Light Level (lux)'); zlabel('Heater Power (%)');
title('Control Surface - Heater Power');

figure;
gensurf(fis, [1 2], 2); view(45,30);
xlabel('Temperature (C)'); ylabel('Light Level (lux)'); zlabel('Dimmer Level (%)');
title('Control Surface - Dimmer Level');

%% TEST SCENARIOS
fprintf('\n%-30s %5s %6s %5s || %10s %10s\n', ...
    'Scenario','Temp','Light','Time','Heater%','Dimmer%');
fprintf('%s\n', repmat('-',1,75));
scenarios = {
    'Cold dark evening',     8,   50,  20;
    'Hot bright afternoon', 35,  900,  14;
    'Comfortable morning',  21,  400,  10;
    'Very cold dark night',  5,   20,   2;
    'Warm dim evening',     26,  200,  19;
};
for i = 1:size(scenarios,1)
    out = evalfis(fis, [scenarios{i,2}, scenarios{i,3}, scenarios{i,4}]);
    fprintf('%-30s %3d°C %4dlux %4d:00 || %8.1f%% %8.1f%%\n', ...
        scenarios{i,1}, scenarios{i,2}, scenarios{i,3}, scenarios{i,4}, out(1), out(2));
end

%% SAVE
writeFIS(fis, 'SmartHomeFLC');
disp('Saved: SmartHomeFLC.fis');

%% OPEN RULE VIEWER
ruleview(fis);
fuzzyLogicDesigner(fis);