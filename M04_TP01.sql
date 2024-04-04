-- 1. (chp4 ex1) La cr�ation d�une fiche de location et ces lignes associ�es
--    �crivez une proc�dure AjoutFiche qui prend en param�tre le num�ro d�un
--    client et entre un et trois articles. Cette proc�dure cr�e une fiche de location
--    et les lignes de location de cette fiche pour les articles emprunt�s. La date de
--    cr�ation de la fiche et du d�part des articles est la date du jour.
-- (niveau 2)
/* Exemple d'utilisation :
EXEC AjoutFiche 3, 'F50';
EXEC AjoutFiche 4, 'F60', 'P10';
EXEC AjoutFiche 5, 'F05', 'F62', 'F63';
*/

CREATE OR ALTER PROCEDURE ajoutFiche(@noCli NUMERIC(6), @refArtA CHAR(3), @refArtB CHAR(3) = NULL, @refArtC CHAR(3) = NULL) AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

			IF NOT EXISTS(SELECT * FROM Clients WHERE noCli = @noCli)
				THROW 5006, 'Le client n''existe pas', 1;
			IF NOT EXISTS(SELECT * FROM Articles WHERE refArt = @refArtA OR refArt = @refArtB OR refArt = @refArtC)
				THROW 5007, 'L''article n''existe pas', 1;

			/*Cr�ation de la fiche de location*/
			INSERT INTO Fiches(noCli) VALUES (@noCli);
			DECLARE @noFic NUMERIC(6) = @@IDENTITY;
			DECLARE @int INT = 1;
			IF EXISTS(SELECT * FROM Articles WHERE refArt = @refArtA)
			BEGIN
			/*Cr�ation de la ligne pour l'article A*/
			INSERT INTO LignesFic(noFic, noLig, refArt) VALUES (@noFic, @int, @refArtA);
			SELECT @int = @int +1 ;
			END
			
			IF EXISTS(SELECT * FROM Articles WHERE refArt = @refArtB)
			/*Cr�ation de la ligne pour l'article B*/
			BEGIN
			INSERT INTO LignesFic(noFic, noLig, refArt) VALUES (@noFic, @int, @refArtB);
			SELECT @int = @int +1 ;
			END

			IF EXISTS(SELECT * FROM Articles WHERE refArt = @refArtC)
			/*Cr�ation de la ligne pour l'article C*/
			BEGIN
			INSERT INTO LignesFic(noFic, noLig, refArt) VALUES (@noFic, @int, @refArtC);
			SELECT @int = @int +1 ;
			END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT 'Erreur'
		PRINT ERROR_MESSAGE()
	END CATCH
END;

-- 2. (chp4 ex2) Le montant d�une fiche
--    �crivez une fonction MontantFiche qui retourne le montant d�une fiche de
--    location dont le num�ro est pass� en param�tre.
-- (niveau 2)
/* Exemple d'utilisation :
SELECT dbo.MontantFiche(1006) montant;
*/
/* R�sultat attendu :
montant
---------------------------------------
570
*/


CREATE OR ALTER FUNCTION MontantFiche(@noFic NUMERIC(6)) RETURNS NUMERIC(6) AS
BEGIN
IF EXISTS(SELECT * FROM Fiches WHERE noFic = @noFic)
	BEGIN
		DECLARE @montantFiche INT = 0;
		DECLARE @refArt CHAR(3);
		DECLARE @depart DATETIME2;
		DECLARE @retour DATETIME2;	

		DECLARE cLignesFic CURSOR FOR SELECT refArt, depart, retour FROM LignesFic WHERE noFic = @noFic;
		OPEN cLignesFic
		FETCH NEXT FROM cLignesFic INTO @refArt, @depart, @retour;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE @montantLigne INT;
			DECLARE @prixJour INT;
			DECLARE @duree INT;
			
			SELECT @prixJour = prixJour FROM GrilleTarifs g
			JOIN Modeles m ON g.codeGam = m.codeGam AND g.codeCate = m.codeCate
			JOIN Articles a ON m.noModele = a.noModele
			WHERE a.refArt = @refArt
		
			IF @retour IS NOT NULL
				SELECT @duree = DATEDIFF(day, @depart, @retour)
			ELSE
				SELECT @duree = DATEDIFF(day, @depart, GETDATE())

			SELECT @montantLigne = @duree * @prixJour;
			SELECT @montantFiche = @montantFiche + @montantLigne;

			FETCH NEXT FROM cLignesFic INTO @refArt, @depart, @retour;
		END
		CLOSE cLignesFic
		DEALLOCATE cLignesFic

		RETURN @montantFiche;
	END
	RETURN 0;
END

SELECT dbo.MontantFiche(1005) montantFiche;

-- 3. (chp4 ex3) L'enregistrement du paiement d'une fiche
--    �crivez une proc�dure PaiementFiche permettant d�enregistrer le paiement
--    d�une fiche de location dont le num�ro est pass� en param�tre. Si tout se passe
--    bien, la fiche est mise � jour et un message s�affiche. Si la fiche a d�j� �t� pay�e
--    ou si elle est encore en cours de location car des articles n�ont pas �t� restitu�s,
--    alors un message d�erreur s�affiche et la fiche reste inchang�e.
-- (niveau 2)
/* Exemple d'utilisation :
EXEC PaiementFiche 1006;
EXEC PaiementFiche 1002;
*/
/* R�sultat attendu :
(1 ligne affect�e)
Enregistrement du paiement d'un montant de 570 � pour la fiche n�1006 � la date de ce jour
Msg 50201, Niveau 16, �tat 1, Proc�dure PaiementFiche, Ligne 4 [Ligne de d�part du lot 47]
Le paiement d'une fiche n'est possible que si elle est dans l'�tat rendue
*/

CREATE OR ALTER PROCEDURE PaiementFiche(@noFic NUMERIC(6)) AS
BEGIN
	BEGIN TRY

		/*v�rifier si la fiche eexiste*/
		IF NOT EXISTS(SELECT * FROM Fiches WHERE noFic = @noFic)
			THROW 5006, 'La fiche n''existe pas', 1;

		/*v�rifier si la fiche est d�j� pay�*/
		IF (SELECT datePaye FROM Fiches WHERE noFic = @noFic) IS NOT NULL
			THROW 5006, 'La fiche est d�j� pay�', 1;

		/*v�rifier si tous les items sont retourn�es*/
		IF (SELECT COUNT(*) FROM LignesFic WHERE noFic = @noFic AND retour IS NULL) <> 0 
			THROW 5006, 'Retours � r�aliser avant', 1;

		BEGIN TRANSACTION

			UPDATE Fiches SET datePaye = GETDATE(), etat = 'SO' WHERE noFic = @noFic;
			DECLARE @montantPaye INT;
			SELECT @montantPaye = dbo.MontantFiche(@noFic);
			PRINT CONCAT('Enregistrement du paiement d''un montant de ', @montantPaye, '� pour la fiche n� ', @noFic, ' � la date de ce jour')

		COMMIT TRANSACTION

	END TRY
	
	BEGIN CATCH
		PRINT ERROR_MESSAGE()
	END CATCH

END

EXEC PaiementFiche 1006;

-- 4. (chp4 ex4) La synth�se des fiches
--    Cr�ez une fonction table SyntheseFiches qui permet de visualiser l��tat des
--    fiches, leurs propri�taires et leurs montants.
-- (niveau 2)
/* Exemple d'utilisation :
SELECT * FROM dbo.SyntheseFiches();
*/
/* R�sultat attendu :
noFic    noCli    nom            prenom        �tat     montant
-------- -------- -------------- ------------- -------- -----------
1001     14       Boutaud        Sabine        sold�e   900
1002     4        Desmoulins     Daniel        en cours 1595
1003     1        Albert         Anatole       sold�e   900
1004     6        Ferdinand      Fran�ois      en cours NULL
1005     3        Dupond         Camille       en cours 870
1006     9        Dupond         Jean          sold�e   570
1007     1        Albert         Anatole       en cours 310
1008     2        Bernard        Barnab�       en cours NULL
1009     20       Dubosc         Frank         sold�e   430
1010     21       Boon           Dany          rendue   2950
1011     22       Elmaleh        Gad           sold�e   1985
1012     23       Dujardin       Jean          sold�e   2465
1013     24       Marceau        Sophie        rendue   4190
1014     25       Merad          Kad           sold�e   2030
1015     26       Seigner        Mathilde      sold�e   2205
1016     27       Reno           Jean          sold�e   3335
1017     28       Lanvin         G�rard        sold�e   995
1018     29       Tautou         Audrey        rendue   340
1019     30       Cotillard      Marion        sold�e   840
1020     31       Duris          Romain        sold�e   555
1021     32       Depardieu      G�rard        rendue   100
1022     33       Youn           Micha�l       sold�e   2900
1023     34       Poelvoorde     Beno�t        sold�e   1015
1024     35       Paradis        Vanessa       rendue   870
1025     36       Wilson         Lambert       rendue   2160
1026     37       Garcia         Jos�          rendue   1450
1027     38       Luchini        Fabrice       sold�e   290
1028     39       Baye           Nathalie      rendue   2110
1029     40       Magimel        Beno�t        rendue   365
1030     41       Cluzet         Fran�ois      sold�e   435
1031     42       Frot           Catherine     sold�e   720
1032     43       Dupontel       Albert        rendue   610
1033     44       Huppert        Isabelle      sold�e   1895
1034     45       Deneuve        Catherine     sold�e   460
1035     3        Dupond         Camille       en cours NULL
1036     4        Desmoulins     Daniel        en cours NULL
1037     5        Ernest         Etienne       en cours NULL
1038     3        Dupond         Camille       en cours NULL
1039     4        Desmoulins     Daniel        en cours NULL
1040     5        Ernest         Etienne       en cours NULL
*/


CREATE OR ALTER FUNCTION SyntheseFiches() RETURNS @table TABLE(noFic NUMERIC(6), noCli NUMERIC(6), nom VARCHAR(20), prenom VARCHAR(20), �tat VARCHAR(10), montant INT) AS
BEGIN
	INSERT INTO @table 
		SELECT f.noFic, f.noCli, c.nom, c.prenom, 
		CASE f.etat
		WHEN 'SO' THEN 'sold�e'
		WHEN 'EC' THEN 'en cours'
		WHEN 'RE' THEN 'rendue'
		ELSE 'en cours'
		END , dbo.MontantFiche(noFic)
		FROM Fiches f
		JOIN Clients c ON f.noCli = c.noCli;
	RETURN;
END

SELECT * FROM SyntheseFiches();