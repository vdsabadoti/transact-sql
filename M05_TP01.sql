-- 1. Interdire la modification de la designation ou du numéro d'un modèle d'article
-- (niveau 1)
/* Résultat attendu :
Msg 50100, Niveau 16, État 1, Procédure upd_modeles, Ligne 2 [Ligne de départ du lot 13]
Il est interdit de changer le numéro ou la désignation d'un ou de plusieurs modèles
*/

CREATE OR ALTER TRIGGER upd_modeles ON Modeles FOR UPDATE AS
BEGIN
IF UPDATE(noModele)
	THROW 50006, 'Il est interdit de changer le numéro ou la désignation d''un ou de plusieurs modèles', 1
IF UPDATE(designation)
	THROW 50006, 'Il est interdit de changer le numéro ou la désignation d''un ou de plusieurs modèles', 1
END

UPDATE Modeles SET designation = 'Hello' WHERE noModele = 1;

-- 2. (chp4 ex5) La mise à jour automatique de l’état des fiches
--    Mettez en place un déclencheur de base de données pour mettre à jour l’état
--    d’une fiche à rendue (RE) lorsque le dernier article en location de cette fiche
--    est retourné.
-- (niveau 2)

CREATE OR ALTER TRIGGER upd_etat ON LignesFic FOR UPDATE AS
BEGIN
IF UPDATE(retour)
BEGIN
	DECLARE @noFic NUMERIC(6);
	SELECT @noFic = noFic FROM INSERTED; 
	PRINT 'Update RETOUR';
	IF (SELECT COUNT(*) FROM LignesFic WHERE retour IS NULL AND noFic = @noFic) = 0
	BEGIN
		PRINT 'Update RETOUR OK'
		UPDATE Fiches SET etat = 'RE' WHERE noFic = @noFic
	END
END
END

SELECT * FROM LignesFic WHERE noFic = 1013;
SELECT * FROM Fiches WHERE noFic = 1013;
UPDATE LignesFic SET retour = GETDATE() WHERE noFic = 1013;


-- 3. (chp4 ex6) La vérification de la disponibilité des articles pour la location
--    Au moment de la location d’un article, vérifiez que celui-ci n’est pas déjà en
--    location à l’aide d’un déclencheur de base de données.
-- (niveau 3)

CREATE OR ALTER TRIGGER insert_lignes ON LignesFic FOR INSERT AS
BEGIN

	DECLARE @refArt CHAR(3);
	SELECT @refArt = refArt FROM INSERTED;

	SELECT @refArt refArt
	SELECT * FROM LignesFic
	
	SELECT COUNT(*) FROM LignesFic WHERE refArt = @refArt AND retour IS NULL;

	IF (SELECT COUNT(*) FROM LignesFic WHERE refArt = @refArt AND retour IS NULL) > 1
		THROW 50007, 'L''article est encore en cours de location', 1;
		
END

INSERT INTO LignesFic(refArt, noFic, noLig) VALUES ('A01', 1013, 8);