dt = 1e-7;                     % Time step = 100 ns
t = 0:dt:0.3;                  % Time vector (0 to 0.3 s)

fin = 1e4;                     % Reference input frequency = 10 kHz
f0 = 1.1e4;                    % Free-running VCO frequency = 11 kHz
k_vco = 1e2;                   % VCO gain (Hz/V)

phi_in = zeros(size(t));       % Input phase accumulator
fout = zeros(size(t));         % VCO output frequency
phi_out = zeros(size(t));      % VCO phase accumulator
phi_out(1) = 5 * pi/4;         % Initial output phase offset

V_pd = zeros(size(t));         % Phase detector output (binary)
tau = 1e-3;                    % Time constant of 1st-order low-pass filter
V_ctrl = zeros(size(t));       % Control voltage (output of loop filter)

for i = 1:length(t) - 1
    % XOR-like phase detector based on square wave levels
    V_pd(i) = ((phi_in(i) <= pi & phi_out(i) > pi) | ...
               (phi_out(i) <= pi & phi_in(i) > pi));

    % VCO frequency update: base + gain * control voltage
    fout(i) = f0 + k_vco * V_ctrl(i);

    % First-order low-pass filter (discrete-time update)
    V_ctrl(i + 1) = V_ctrl(i) + (V_pd(i) - V_ctrl(i)) * dt / tau;

    % Update input phase
    phi_in(i + 1) = mod(phi_in(i) + 2 * pi * fin * dt, 2 * pi);

    % Update VCO phase
    phi_out(i + 1) = mod(phi_out(i) + 2 * pi * fout(i) * dt, 2 * pi);
end

% Generate final square wave outputs from phase
x = (phi_in >= 0 & phi_in <= pi);    % Input square wave
y = (phi_out >= 0 & phi_out <= pi);  % VCO output square wave
