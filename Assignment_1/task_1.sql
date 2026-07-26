\timing on

-- Scenario (a)
CREATE TABLE lineitem_idx_before (LIKE lineitem);
CREATE INDEX idx_l_quantity_before ON lineitem_idx_before(l_quantity);
INSERT INTO lineitem_idx_before SELECT * FROM lineitem;

-- Scenario (b)
CREATE TABLE lineitem_idx_after (LIKE lineitem);
INSERT INTO lineitem_idx_after SELECT * FROM lineitem;
CREATE INDEX idx_l_quantity_after ON lineitem_idx_after(l_quantity);
