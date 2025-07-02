dt = 1e-7;
t = 0:dt:0.3;
fin = 1e4;
f0 = 1.1e4;
k_vco = 1e2;
phi_in = zeros(size(t));
fout = zeros(size(t));
phi_out = zeros(size(t));
phi_out(1) = 5 * pi/4;
V_pd = zeros(size(t));
tau = 1e-3;
V_ctrl = zeros(size(t));

for i = 1:length(t) - 1
    V_pd(i) = ((phi_in(i) <= pi & phi_out(i) > pi) | (phi_out(i) <= pi & phi_in(i) > pi));
    fout(i) = f0 + k_vco * V_ctrl(i);
    V_ctrl(i + 1) = V_ctrl(i) + (V_pd(i) - V_ctrl(i)) * dt / tau;
    phi_in(i + 1) = mod((phi_in(i) + 2 * pi * fin * dt), 2 * pi);
    phi_out(i + 1) = mod((phi_out(i) + 2 * pi * fout(i) * dt), 2 * pi);
end

x = (phi_in >= 0 & phi_in <= pi);
y = (phi_out >= 0 & phi_out <= pi);