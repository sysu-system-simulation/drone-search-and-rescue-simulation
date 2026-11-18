function path = boustrophedon(r0, r1, c0, c1)
% BOUSTROPHEDON  "Lawn-mower" sweep of a rectangle.
% Visits every cell of rows r0..r1, cols c0..c1 once, alternating the row
% direction so the aircraft never flies a long empty leg.
% Returns a K x 2 list of [row col] cells in visiting order.

rows = r0:r1;
nR = numel(rows);
nC = c1 - c0 + 1;

path = zeros(nR * nC, 2);
k = 1;
for j = 1:nR
    if mod(j-1, 2) == 0
        cols = c0:c1;
    else
        cols = c1:-1:c0;
    end
    path(k:k+nC-1, 1) = rows(j);
    path(k:k+nC-1, 2) = cols';
    k = k + nC;
end
end
