dt = 1e-7;                   % Simulation time step (100 ns)
t = 0:dt:0.05;               % Time vector (0 to 50 ms)

x = zeros(size(t));          % Reference signal (input clock)
fin = 1e4;                   % Input frequency = 10 kHz
phi_in = zeros(size(t));     % Input phase accumulator
phi_in(1) = 0;               % Initial phase of input

y = zeros(size(t));          % Output signal (VCO clock)
fout = zeros(size(t));       % Output frequency of VCO
f0 = 8e3;                    % Initial VCO frequency = 8 kHz
fout(1) = f0;
k_vco = 5e3;                 % VCO gain (Hz/V)
phi_out = zeros(size(t));    % Output phase accumulator
phi_out(2) = 5 * pi / 4;     % Initial phase offset of VCO

UP = zeros(size(t));         % UP signal from PFD
DN = zeros(size(t));         % DOWN signal from PFD

V_ctrl = zeros(size(t));     % Control voltage to VCO

C = 100e-9;                  % Loop filter capacitance (pure integrator)
I_cp = 5e-6;                 % Charge pump current

for i = 2:length(t) - 1
    % Generate input square wave (1 when phase in [0, pi], else 0)
    x(i) = (phi_in(i) >= 0 && phi_in(i) <= pi);

    % Generate output square wave (same logic as input)
    y(i) = (phi_out(i) >= 0 && phi_out(i) <= pi);

    % Detect rising edge on input clock: set UP pulse
    if ((x(i) - x(i - 1)) > 0 && UP(i) == 0)
        UP(i + 1) = 1;
    end

    % Detect rising edge on VCO output: set DN pulse
    if ((y(i) - y(i - 1)) > 0 && DN(i) == 0)
        DN(i + 1) = 1;
    end

    % Reset condition: both UP and DN pulses active → reset both
    if (UP(i) == 1 && DN(i) == 1)
        UP(i + 1) = 0;
        DN(i + 1) = 0;
    end

    % Hold UP pulse if not reset yet
    if (UP(i) == 1 && DN(i) == 0)
        UP(i + 1) = 1;
    end

    % Hold DN pulse if not reset yet
    if (UP(i) == 0 && DN(i) == 1)
        DN(i + 1) = 1;
    end

    % Loop filter: integrator behavior (Euler method)
    V_ctrl(i + 1) = V_ctrl(i) + I_cp * (UP(i) - DN(i)) * dt / C;

    % Update VCO frequency based on control voltage
    fout(i) = f0 + k_vco * V_ctrl(i);

    % Update input phase for next time step
    phi_in(i + 1) = mod((phi_in(i) + 2 * pi * fin * dt), 2 * pi);

    % Update output phase (VCO phase) for next time step
    phi_out(i + 1) = mod((phi_out(i) + 2 * pi * fout(i) * dt), 2 * pi);
end

figure;

% Top subplot: Control Voltage
ax1 = subplot(2,1,1);
plot(t, V_ctrl, 'b');
ylabel('V_{ctrl} (V)');
title('Control Voltage vs Time');
grid on;

% Bottom subplot: Output Frequency
ax2 = subplot(2,1,2);
plot(t, fout, 'r');
xlabel('Time (s)');
ylabel('f_{out} (Hz)');
title('Output Frequency vs Time');
grid on;

% Link x-axes
linkaxes([ax1, ax2], 'x');