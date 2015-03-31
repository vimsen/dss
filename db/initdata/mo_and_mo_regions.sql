DELETE FROM market_operators;
DELETE FROM market_regions;

INSERT INTO market_operators(id,name,description,created_at,updated_at) VALUES
(1,'GME - Gestore Mercati Energetici','GME - Gestore Mercati Energetici','2015-03-28','2015-03-28');


INSERT INTO market_regions(id,mo_id,name,created_at,updated_at) VALUES
(1,1,'Greece','2015-03-28','2015-03-28'),
(2,1,'Sardinia','2015-03-28','2015-03-28');
