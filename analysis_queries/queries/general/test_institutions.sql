SELECT *
FROM works w
LATERAL VIEW EXPLODE(w.institutions) inst AS inst
WHERE size(inst) = 0;
