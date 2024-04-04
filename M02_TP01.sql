/*------------------------------------------------------- CHAPITRE 2 ENONCE 1 ---------------------------------------------*/
DECLARE cModeles CURSOR FOR SELECT designation FROM Modeles;
OPEN cModeles
DECLARE @designation VARCHAR(80)
FETCH NEXT FROM cModeles INTO @designation
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT @designation
	FETCH NEXT FROM cModeles INTO @designation
END
CLOSE cModeles
DEALLOCATE cModeles

/*---------------------------------------------------- CHAPITRE 2 ENONCE 2 ------------------------------------------------*/

DECLARE @ArticlesCounter TABLE(refArt CHAR(3), counting INT);

INSERT INTO @ArticlesCounter(refArt)
SELECT refArt
FROM Articles;

DECLARE cArticles CURSOR FOR SELECT refArt FROM Articles;

OPEN cArticles
DECLARE @refArt CHAR(3)
DECLARE @nbLocationsArticle INT;
FETCH NEXT FROM cArticles INTO @refArt
WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @nbLocationsArticle = COUNT(*) FROM LignesFic WHERE refArt = @refArt;
	UPDATE @ArticlesCounter SET counting = @nbLocationsArticle WHERE refArt = @refArt;
	FETCH NEXT FROM cArticles INTO @refArt
END

SELECT TOP 3 counting, refArt
FROM @ArticlesCounter 
ORDER BY counting DESC

CLOSE cArticles
DEALLOCATE cArticles

/*---------------------------------------------------- CHAPITRE 2 ENONCE 3 ------------------------------------------------*/

DECLARE cLignesFic2 CURSOR FOR SELECT TOP 3 WITH TIES COUNT(noLig), refArt FROM LignesFic GROUP BY refArt ORDER BY COUNT(noLig) DESC
OPEN cLignesFic2
DECLARE @int INT = 1;
DECLARE @stockCounter INT = 1;
DECLARE @refArt2 CHAR(3);
DECLARE @counter INT;
FETCH NEXT FROM cLignesFic2 INTO @counter, @refArt2
WHILE @@FETCH_STATUS = 0
BEGIN
	IF (@stockCounter != @counter)
		PRINT CONCAT(@int, ' ', @refArt2, ' ', '(',@counter, ' fois)')
	ELSE
		PRINT CONCAT('=', ' ', @refArt2, ' ', '(',@counter, ' fois)')
	SELECT @stockCounter = @counter;
	FETCH NEXT FROM cLignesFic2 INTO @counter, @refArt2
SELECT @int = @int + 1;
END
CLOSE cLignesFic2
DEALLOCATE cLignesFic2

/*---------------------------------------------------- CHAPITRE 2 ENONCE 4 ------------------------------------------------*/
Select * FROM Fiches
DECLARE cFiches CURSOR FOR SELECT noFic, etat, datePaye FROM Fiches WHERE etat = 'RE' AND datePaye IS NOT NULL FOR UPDATE OF etat;
DECLARE @noFic NUMERIC(6)
DECLARE @datePaye DATETIME2(7)
DECLARE @etat CHAR(2)
OPEN cFiches
FETCH NEXT FROM cFiches INTO @noFic, @etat, @datePaye;
WHILE @@FETCH_STATUS = 0
BEGIN
IF @datePaye IS NOT NULL
UPDATE Fiches SET etat = 'SO' WHERE CURRENT OF cFiches;
FETCH NEXT FROM cFiches INTO @noFic, @etat, @datePaye;
END
CLOSE cFiches
DEALLOCATE cFiches
Select * FROM Fiches

/*---------------------------------------------------- CHAPITRE 2 ENONCE 5 ------------------------------------------------*/
SELECT * FROM LignesFic;

DECLARE cFiches CURSOR FOR SELECT noFic FROM Fiches;
DECLARE @noFicFic NUMERIC(6);
DECLARE @int3 NUMERIC(2) = 1;
DECLARE @noLig NUMERIC(2);
DECLARE @noFicLig NUMERIC(6);
OPEN cFiches;
FETCH NEXT FROM cFiches INTO @noFicFic;
WHILE @@FETCH_STATUS = 0
	BEGIN
	
	SELECT @int3 = 1;
	DECLARE cLignesFic CURSOR FOR SELECT noFic, noLig FROM LignesFic WHERE noFic = @noFicFic ORDER BY noLig FOR UPDATE OF noLig;
	OPEN cLignesFic;
	FETCH NEXT FROM cLignesFic INTO @noFicLig, @noLig;

	WHILE @@FETCH_STATUS = 0
		BEGIN
		
		IF (@noLig != @int3)
			BEGIN
			UPDATE LignesFic SET noLig = @int3 WHERE CURRENT OF cLignesFic
			END
		SELECT @int3 = @int3 + 1;
		FETCH NEXT FROM cLignesFic INTO @noFicLig, @noLig;
		END
	
	CLOSE cLignesFic
	DEALLOCATE cLignesFic

	FETCH NEXT FROM cFiches INTO @noFicFic;
	END

CLOSE cFiches
DEALLOCATE cFiches

SELECT * FROM LignesFic;

