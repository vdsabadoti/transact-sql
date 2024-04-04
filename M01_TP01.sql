/** ------------------------------------------------------------------------------------------ CHAPITRE 1 -- ENONCE 1 **/
DECLARE @noCli INT=1
DECLARE @adresse VARCHAR(30);
DECLARE @cpo VARCHAR(30);
DECLARE @ville VARCHAR(30);
DECLARE @nom VARCHAR(30);
DECLARE @prenom VARCHAR(30);

IF EXISTS(SELECT nom FROM Clients WHERE noCli=@noCli )
BEGIN
	SELECT @nom = nom, @prenom = prenom, @adresse = adresse, @cpo = cpo, @ville = ville FROM Clients
	WHERE noCli = @noCli;
	PRINT @prenom + ' ' + UPPER(@nom)
	PRINT @adresse
	PRINT @cpo
	PRINT @ville
	
	END
ELSE
PRINT 'pas de client n°'+@noCli;

/** --------------------------------------------------------------------------- CHAPITRE 1 -- ENONCE 2 (??)**/
DECLARE @result TABLE(
    noCli NUMERIC(6),
    nom CHAR(11),
    prenom CHAR(11),
    paiement CHAR(155)
);

INSERT INTO @result (noCli, nom, prenom, paiement)
SELECT Clients.noCli, Clients.nom, Clients.prenom, Fiches.etat
FROM Clients
LEFT JOIN Fiches ON Clients.noCli = Fiches.noCli;


SELECT noCli, nom, prenom,
CASE paiement
	WHEN 'RE' THEN '1 fiche à regler'
	ELSE 'à jour dans ses reglements'
END paiement
FROM @result


/**---------------------------------------------------------------------------- CHAPITRE 1 -- ENONCE 2 **/

/** TABLE POUR CONTENR LES CLIENTS ET LE NB DE FICHES A REGLER **/
DECLARE @NbFichesForClient TABLE(
    noCli NUMERIC(6),
	    nom CHAR(11),
    prenom CHAR(11),
    nbFiches INT
);

/** AJOUT DE CHAQUE NO CLIENT DANS LA TABLE **/
INSERT INTO @NbFichesForClient(noCli, nom, prenom)
SELECT noCli, nom, prenom
FROM Clients;

/** ON BOUCLE SUR TOUS LES CLIENTS POUR COMPTER LE NB DE FICHES A REGLER ET ON MET A JOUR LA TABLE**/
DECLARE @nbClients NUMERIC(6);
SELECT @nbClients = MAX(noCli) FROM Clients;

DECLARE @i INT = 1;

WHILE @i <= @nbClients
BEGIN
	IF EXISTS(SELECT noCli FROM @NbFichesForClient WHERE noCli = @i)
		BEGIN	
			UPDATE @NbFichesForClient
			SET nbFiches = (SELECT COUNT(*) FROM Fiches WHERE noCli = @i AND etat = 'EC')
			WHERE noCli = @i;
		END
	SELECT @i = @i + 1;
END


/** AFFICHGE **/

SELECT noCli, nom, prenom,
CASE nbFiches
	WHEN 0 THEN 'à jour dans ses reglements'
	WHEN 1 THEN '1 fiche à payer'
	ELSE CONCAT(nbFiches,'plusieurs fiches à payer')
END paiement
FROM @NbFichesForClient;


/* ----------------------------------------------------------------------------------- CHAPITRE 1 - ENONCE 3*/

IF EXISTS(SELECT * FROM Fiches WHERE DATEDIFF(DAY, dateCrea, GETDATE()) > 14 AND etat = 'EC')
BEGIN
    SELECT 
        Clients.nom, 
        Clients.prenom, 
        CASE 
            WHEN DATEDIFF(DAY, Fiches.dateCrea, GETDATE()) > 14 THEN DATEDIFF(DAY, Fiches.dateCrea, GETDATE())
        END AS dureeEnJours
    FROM 
        Fiches
    LEFT JOIN 
        Clients ON Fiches.noCli = Clients.noCli
    WHERE 
        DATEDIFF(DAY, Fiches.dateCrea, GETDATE()) > 14  AND etat = 'EC';
END
ELSE
BEGIN
    PRINT 'Il ny a pas de location en cours depuis plus de 2 semaines'
END

/*-------------------------------------------------------------------------------- CHAPITRE 1 - ENONCE 4 */

DECLARE @two INT = 2;

WHILE @two <= 10000
BEGIN
	PRINT @two
	SELECT @two =  @two * 2
END

/*---------------------------------------------------------------------------------------- STUDY - CHAPITRE 1 -- ENONCE 2 */
/*CREATION TABLEAU TEMPORAIRE */
WITH FichesRE AS(SELECT * FROM Fiches WHERE etat = 'EC' OR etat='SO')
SELECT c.noCli, c.nom, c.prenom, f.etat,
/*création d'une colonne PAIEMENT conditionné par un CASE => l'emprise du CASE est la ligne du tableau */
CASE COUNT(f.etat)
           WHEN 0 THEN 'à jour de ses règlements'
		   WHEN 1 THEN '1 fiche à régler'
		   ELSE CONCAT(COUNT(f.etat), ' fiches à régler')
       END paiement
	   /* LE TEABLEAU EST UNE JOINTURE ENTRE CLIENTS ET LE TABLEAU TEMPORAIRE FICHES, LES LIGNES SONT REGROUPES PAR c.noCli */
FROM Clients c LEFT JOIN FichesRE f ON c.noCli = f.noCli
/* regle du GROUP BY : on doit afficher tout ce qu'on regroupe*/
GROUP BY c.noCli, c.nom, c.prenom, f.etat;

/*CREATION TABLEAU TEMPORAIRE */
WITH FichesRE AS(SELECT * FROM Fiches WHERE etat = 'EC' OR etat='SO')
SELECT c.noCli, c.nom, c.prenom,
/*création d'une colonne PAIEMENT conditionné par un CASE => l'emprise du CASE est la ligne du tableau */
CASE COUNT(f.etat)
           WHEN 0 THEN 'à jour de ses règlements'
		   WHEN 1 THEN '1 fiche à régler'
		   ELSE CONCAT(COUNT(f.etat), ' fiches à régler')
       END paiement
	   /* LE TEABLEAU EST UNE JOINTURE ENTRE CLIENTS ET LE TABLEAU TEMPORAIRE FICHES, LES LIGNES SONT REGROUPES PAR c.noCli */
FROM Clients c LEFT JOIN FichesRE f ON c.noCli = f.noCli
/* regle du GROUP BY : on doit afficher tout ce qu'on regroupe*/
GROUP BY c.noCli, c.nom, c.prenom;



/*-------------------------------------------------------------------------------- CHAPITRE 1 - ENONCE 5 */

DECLARE @min FLOAT;
SELECT @min = MIN(prixJour) FROM GrilleTarifs;


UPDATE GrilleTarifs
SET prixJour = 90
OUTPUT INSERTED.prixJour
WHERE prixJour = 81


