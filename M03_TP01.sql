/**/
DECLARE @numero NUMERIC(10) = RAND();
PRINT @numero;
BEGIN TRY
IF (@numero<0.5)
	THROW 5006, 'Erreur', 1
PRINT 'Pas de levée d''exception'
END TRY
BEGIN CATCH
	PRINT 'Récupération de l''exception levée'
END CATCH;
/*------------------------------------------- CHAPITRE 3 ENONCE 1 ---------------------------- */

EXEC sp_addmessage 50666, 17, '%s is dead !', @lang='us_english', @replace='replace'
EXEC sp_addmessage 50666, 17, '%1! est mort !', @lang='Français', @replace='replace'

DECLARE @int INT = 1;
DECLARE @random INT = CAST(CEILING(RAND() * 6) AS INT)
DECLARE @username CHAR(10);
DECLARE @message NVARCHAR(100);

BEGIN TRY
	WHILE @int < 6
	BEGIN
		SELECT @username = 'Vladimir'
		IF @int%2 = 0
			SELECT @username = 'Serguei';
		IF (@random = @int)
		BEGIN 
			SELECT @message = FORMATMESSAGE(50666, @username);
			THROW 50666, @message, 1
		END
		PRINT CONCAT(@username, ' : ', 'clic')
		SELECT @int = @int + 1
		IF @int = 6
		BEGIN
			SELECT @message = FORMATMESSAGE(50666, @username);
			THROW 50666, @message, 1
		END
	END
END TRY
BEGIN CATCH
	PRINT CONCAT(@username, ' : ', 'pan')
	PRINT CONCAT('Msg ', ERROR_NUMBER(), ', Niveau ', ERROR_SEVERITY(), ' , Etat ', ERROR_STATE(), ', Ligne ')
	PRINT ERROR_MESSAGE()
END CATCH

/*-----------------------------CHAPITRE 3 ENONCE 2 --------------------------*/

DECLARE @noCli NUMERIC(6) = 1;

BEGIN TRY
	IF EXISTS(SELECT * FROM Fiches WHERE noCli = @noCli AND etat <> 'SO')
	BEGIN
		DECLARE @nomClient VARCHAR(30);
		SELECT @nomClient = nom FROM Clients WHERE noCli = @noCli;
		DECLARE @prenomClient VARCHAR(30);
		SELECT @prenomClient = prenom FROM Clients WHERE noCli = @noCli;
	
		EXEC sp_addmessage 50666, 17, 'The client n %d %s %s can not make a location cause payement is due', @lang='us_english', @replace='replace'
		EXEC sp_addmessage 50666, 17, 'Le client n %1! %1! %2! ne peut faire une nouvelle location car il a au moins une fiche de location non soldée.', @lang='Français', @replace='replace'

		DECLARE @messages VARCHAR(356) = FORMATMESSAGE(50666, @noCli, @prenomClient, @nomClient);
		THROW 50666, @messages, 1
	END
	PRINT '/INSERT INTO Fiches(noCli) VALUES @noCli /'
END TRY
BEGIN CATCH
	PRINT @nomClient
	PRINT @prenomClient
	PRINT @noCli
	PRINT CONCAT('Msg ', ERROR_NUMBER(), ', Niveau ', ERROR_SEVERITY(), ' , Etat ', ERROR_STATE(), ', Ligne ')
	PRINT CONCAT('Message :', ERROR_MESSAGE());
END CATCH


/*------------------------------------- CHAPITRE 3 ENONCE 3 -------------------------*/

BEGIN TRY
	INSERT INTO Clients(noCli) VALUES (1);
END TRY
BEGIN CATCH
	PRINT CONCAT('Error message :', ERROR_MESSAGE())
	PRINT CONCAT('Etat ', ERROR_STATE())
	PRINT CONCAT('Numero :', ERROR_NUMBER())
	PRINT CONCAT('Sevérité :', ERROR_SEVERITY());
	PRINT CONCAT('Ligne :', ERROR_LINE());
END CATCH


