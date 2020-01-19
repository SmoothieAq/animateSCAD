
function nnv(v,d) = v != undef ? v : d;

function sum(v,i=0) = i >= len(v) ? 0 : v[i] + sum(v,i+1);

// scale matrix
function mscale(s) = [ for (i = [0:2]) [ for (j = [0:2]) i == j ? s[i]: 0 ] ];

function unit(v) = v/norm(v);

function transpose(M) = [ for (j = [0:2]) [ for (i = [0:2]) M[i][j] ] ];