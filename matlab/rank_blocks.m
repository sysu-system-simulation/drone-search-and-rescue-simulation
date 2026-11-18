function blocks = rank_blocks(prior, b)
% RANK_BLOCKS  Split the map into b x b blocks and sort them by how much
% target probability each block contains (highest first).
%
% This is the only piece of "intelligence" the probability-based strategy
% has: it searches the most likely blocks first instead of sweeping the map
% in an arbitrary order.

H = size(prior, 1);
W = size(prior, 2);

scores = [];
paths  = {};
for r0 = 1:b:H
    for c0 = 1:b:W
        r1 = min(r0 + b - 1, H);
        c1 = min(c0 + b - 1, W);
        scores(end+1)   = sum(sum(prior(r0:r1, c0:c1)));
        paths{end+1}    = boustrophedon(r0, r1, c0, c1);
    end
end

[~, order] = sort(scores, 'descend');
blocks = paths(order);
end
