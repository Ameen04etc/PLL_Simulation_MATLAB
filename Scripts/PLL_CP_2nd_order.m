dt = 1e-7;                    % Simulation time step (100 ns)
t = 0:dt:0.005;               % Time vector (0 to 5 ms)

x = zeros(size(t));          % Reference square wave
fin = 1e4;                    % Input frequency = 10 kHz
phi_in = zeros(size(t));     % Phase of input signal
phi_in(1) = 0;

y = zeros(size(t));          % Output square wave from VCO
fout = zeros(size(t));       % VCO frequency
f0 = 5e3;                    % Initial VCO frequency = 5 kHz
fout(1) = f0;
k_vco = 85.2e3;              % VCO gain (Hz/V)
phi_out = zeros(size(t));    % Phase of VCO output
phi_out(3) = 5 * pi / 4;     % Initial offset in output phase

UP = zeros(size(t));         % UP signal from PFD
DN = zeros(size(t));         % DOWN signal from PFD

V_ctrl = zeros(size(t));     % Output of loop filter (control voltage)

I_cp = 5e-6;                 % Charge pump current (5 µA)
R = 10e3;                    % Loop filter resistor (10 kΩ)
C1 = 100e-9;                 % First capacitor in loop filter (100 nF)
C2 = 10e-9;                  % Second capacitor (adds additional pole, 10 nF)
I_lf = zeros(size(t));       % Current into the loop filter

for i = 3:length(t) - 1
    % Generate square waves based on phase (HIGH in [0, pi], else LOW)
    x(i) = (phi_in(i) >= 0 && phi_in(i) <= pi);
    y(i) = (phi_out(i) >= 0 && phi_out(i) <= pi);

    % Detect rising edge of input signal → generate UP pulse
    if ((x(i) - x(i - 1)) > 0 && UP(i) == 0)
        UP(i + 1) = 1;
    end

    % Detect rising edge of VCO output → generate DN pulse
    if ((y(i) - y(i - 1)) > 0 && DN(i) == 0)
        DN(i + 1) = 1;
    end

    % Reset both UP and DN pulses when both are high (PFD reset)
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

    % Compute charge pump output current for present and next time step
    I_lf(i) = I_cp * (UP(i) - DN(i));
    I_lf(i + 1) = I_cp * (UP(i + 1) - DN(i + 1));

    % Loop filter update (2nd-order: RC with parallel capacitor C2)
    % Derived from discretizing the differential equation of the filter
    V_ctrl(i + 1) = ( ...
        (2 * R * C1 * C2 + (C1 + C2) * dt) * V_ctrl(i) ...
        - R * C1 * C2 * V_ctrl(i - 1) ...
        + I_lf(i + 1) * dt^2 ...
        + R * C1 * (I_lf(i + 1) - I_lf(i)) * dt ...
    ) / (R * C1 * C2 + (C1 + C2) * dt);

    % Update VCO frequency from control voltage
    fout(i) = f0 + k_vco * V_ctrl(i);

    % Update phases of input and VCO output
    phi_in(i + 1) = mod(phi_in(i) + 2 * pi * fin * dt, 2 * pi);
    phi_out(i + 1) = mod(phi_out(i) + 2 * pi * fout(i) * dt, 2 * pi);
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
