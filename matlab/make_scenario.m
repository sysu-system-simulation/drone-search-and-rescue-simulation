function sc = make_scenario(kind, seed, p, sweepScale)
% MAKE_SCENARIO  Build one search map.
%
%   sc.terrain : H x W, 1=open 2=forest 3=urban 4=water
%   sc.detP    : H x W, probability of detecting the target in ONE pass
%   sc.prior   : H x W, where the target probably is (sums to 1)
%
% kind is one of: 'open', 'forest', 'urban', 'mixed'.
% sweepScale multiplies the baseline sweep width (used by Experiment 3).

if nargin < 4 || isempty(sweepScale)
    sweepScale = 1;
end

rng(seed, 'twister');
H = p.H;  W = p.W;
[rr, cc] = ndgrid(1:H, 1:W);

% ---------- 1. terrain ------------------------------------------------------
switch kind
    case 'open'
        terrain = ones(H, W);
        for k = 1:5                       % a few woodland patches
            r0 = randi([5 H-5]);  c0 = randi([5 W-5]);  rad = randi([3 6]);
            terrain((rr-r0).^2 + (cc-c0).^2 < rad^2) = 2;
        end

    case 'forest'
        terrain = 2*ones(H, W);
        for k = 1:6                       % clearings
            r0 = randi([5 H-5]);  c0 = randi([5 W-5]);  rad = randi([4 7]);
            terrain((rr-r0).^2 + (cc-c0).^2 < rad^2) = 1;
        end
        terrain((rr-32).^2 + (cc-9).^2 < 16) = 4;     % a pond

    case 'urban'
        terrain = 3*ones(H, W);
        terrain(mod(rr-1, 8) == 0) = 1;               % street grid
        terrain(mod(cc-1, 8) == 0) = 1;
        for k = 1:3                                   % parks
            r0 = randi([5 H-5]);  c0 = randi([5 W-5]);
            terrain((rr-r0).^2 + (cc-c0).^2 < 25) = 1;
        end

    case 'mixed'
        terrain = ones(H, W);
        terrain(rr > 24 & cc < 20) = 2;
        terrain(rr < 14 & cc > 24) = 3;
        terrain((rr-28).^2 + (cc-30).^2 < 20) = 4;

    otherwise
        error('make_scenario: unknown map kind "%s"', kind);
end

% ---------- 2. search prior -------------------------------------------------
% A lost person is more likely in forest / urban cover and almost never in
% water, plus two "last seen" hot spots.  This is the ONLY information the
% prior-aware strategy gets; the other strategies ignore it.
% Decouple hotspot RNG from terrain-patch draws so Experiment 2 isolates
% terrain visibility without shifting hotspots relative to the launch base.
rng(seed + 25, 'twister');
baseW = [1.0 1.6 1.2 0.05];
w = baseW(terrain);
hot = zeros(H, W);
for k = 1:2
    r0 = randi([6 H-6]);  c0 = randi([6 W-6]);
    s  = 4 + 2*rand();
    hot = hot + 10*exp(-((rr-r0).^2 + (cc-c0).^2) / (2*s^2));
end
prior = w .* (1 + hot);
prior = prior / sum(prior(:));

% ---------- 3. detection probability ---------------------------------------
% One pass: p = 1 - exp(-W_eff) with W_eff = sweepW * terrain factor.
% Repeated passes compound automatically because every visit is a new
% independent trial:  after k passes P = 1 - (1-p)^k.
detP = 1 - exp(-p.sweepW * sweepScale * p.terrainMult(terrain));

sc.terrain    = terrain;
sc.prior      = prior;
sc.detP       = detP;
sc.name       = kind;
sc.sweepScale = sweepScale;
end
