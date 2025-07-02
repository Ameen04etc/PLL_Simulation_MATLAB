dt = 1e-7;                   % Simulation time step (100 ns)
t = 0:dt:0.01;               % Time vector (0 to 10 ms)

x = zeros(size(t));          % Reference square wave (input clock)
fin = 1e4;                   % Input frequency = 10 kHz
phi_in = zeros(size(t));     % Input phase accumulator
phi_in(1) = 0;               % Initial phase

y = zeros(size(t));          % VCO output square wave
fout = zeros(size(t));       % VCO frequency over time
f0 = 5e3;                    % Initial VCO frequency = 5 kHz
fout(1) = f0;
k_vco = 5e3;                 % VCO gain (Hz/V)
phi_out = zeros(size(t));    % Output phase accumulator
phi_out(2) = 5 * pi / 4;     % Initial phase offset for output

UP = zeros(size(t));         % UP pulse from PFD
DN = zeros(size(t));         % DN pulse from PFD

V_cap = zeros(size(t));      % Voltage across capacitor in loop filter
V_ctrl = zeros(size(t));     % Control voltage applied to VCO

R = 2e3;                     % Loop filter resistance (ohms)
C = 5e-7;                    % Loop filter capacitance (0.5 uF)
I_cp = 1e-3;                 % Charge pump current (1 mA)

for i = 2:length(t) - 1
    % Generate square wave for input and output (HIGH when phase in [0, pi])
    x(i) = (phi_in(i) >= 0 && phi_in(i) <= pi);
    y(i) = (phi_out(i) >= 0 && phi_out(i) <= pi);

    % Detect rising edge of input: generate UP pulse
    if ((x(i) - x(i - 1)) > 0 && UP(i) == 0)
        UP(i + 1) = 1;
    end

    % Detect rising edge of VCO output: generate DN pulse
    if ((y(i) - y(i - 1)) > 0 && DN(i) == 0)
        DN(i + 1) = 1;
    end

    % Reset both pulses when both UP and DN go high (reset condition)
    if (UP(i) == 1 && DN(i) == 1)
        UP(i + 1) = 0;
        DN(i + 1) = 0;
    end

    % Hold UP pulse until reset
    if (UP(i) == 1 && DN(i) == 0)
        UP(i + 1) = 1;
    end

    % Hold DN pulse until reset
    if (UP(i) == 0 && DN(i) == 1)
        DN(i + 1) = 1;
    end

    % Update capacitor voltage using integrator (Euler method)
    V_cap(i + 1) = V_cap(i) + I_cp * (UP(i) - DN(i)) * dt / C;

    % Control voltage includes RC filter output
    % R * I_cp is added only when there's a current pulse (non-zero phase error)
    V_ctrl(i) = V_cap(i) + R * I_cp * ((UP(i) - DN(i)) ~= 0);

    % Update VCO frequency based on control voltage
    fout(i) = f0 + k_vco * V_ctrl(i);

    % Update input and output phase accumulators
    phi_in(i + 1) = mod((phi_in(i) + 2 * pi * fin * dt), 2 * pi);
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