DECLARE @Acumuladora MONEY,@salaryE INT, @prueba int
	SET @salaryE = 33945
	SET @prueba = (SELECT COUNT(*) FROM SALARY);
	WHILE @salaryE <= @prueba
	BEGIN
		SET @Acumuladora = (SELECT mon_salary FROM SALARY_EMP SE 
			INNER JOIN EMPLOYEES E ON
			E.int_employee_id_PK=SE.int_employee_id_FK
			INNER JOIN REGISTRATION_HIRES C ON
			C.int_employee_id_FK=E.int_employee_id_PK
			INNER JOIN CONTRACTS CO ON
			C.int_contract_id_FK=CO.int_contract_id_PK
			WHERE SE.int_salary_id_FK=@salaryE AND C.tin_typeRegistration_id_FK=1)
		UPDATE SALARY SET mon_hourSalary = @Acumuladora/160 WHERE SALARY.int_salary_id_PK=@salaryE
		SET @salaryE = @salaryE + 1;
	END

go

DECLARE @Acumuladora MONEY,@salaryE INT, @prueba int
	SET @salaryE = 104385
	SET @prueba = (SELECT COUNT(*) FROM SALARY)
	WHILE @salaryE<=@prueba
	BEGIN
		SET @Acumuladora = (SELECT mon_salary FROM CONTRACTS CO WHERE CO.int_contract_id_PK =(SELECT int_employee_id_FK FROM SALARY_EMP SE WHERE SE.int_salary_id_FK=@salaryE))
		SET @Acumuladora = @Acumuladora + ISNULL((SELECT SUM(EX.tin_amount*SA.mon_hourSalary*(TY.flo_porcent/100)) 
			FROM EXTRA_HOURS EX,SALARY SA,TYPE_HOURS TY 
			WHERE EX.bit_payFactor=1 AND SA.int_salary_id_PK=@salaryE AND EX.int_salary_id_FK=@salaryE
			AND EX.tin_hourType_id_FK=TY.tin_hourType_id_PK AND EX.int_salary_id_FK=SA.int_salary_id_PK),0)
		SET @Acumuladora = @Acumuladora + ISNULL((SELECT SUM(MO.int_factor*MO.mon_amount) 
		FROM SALARY SA,PAYMENT_MOVEMENT PM,MOVEMENT MO
		WHERE PM.int_salary_id_PK_FK=SA.int_salary_id_PK AND PM.int_movement_id_PK_FK = MO.int_movement_id_PK
		AND PM.bit_motionFactor=1 AND SA.int_salary_id_PK=@salaryE AND PM.int_salary_id_PK_FK=@salaryE),0)
		UPDATE SALARY SET mon_netSalary = @Acumuladora WHERE SALARY.int_salary_id_PK=@salaryE;
		SET @salaryE = @salaryE + 1;
	END

go




CREATE PROCEDURE SalaryCalculate 
AS  
	DECLARE @Acumuladora MONEY,@salaryE INT
	SET @salaryE = 1
	WHILE @salaryE<=(SELECT COUNT(*) FROM SALARY)
	BEGIN
		SET @Acumuladora = (SELECT mon_salary FROM SALARY_EMP SE 
			INNER JOIN EMPLOYEES E ON
			E.int_employee_id_PK=SE.int_employee_id_FK
			INNER JOIN REGISTRATION_HIRES C ON
			C.int_employee_id_FK=E.int_employee_id_PK
			INNER JOIN CONTRACTS CO ON
			C.int_contract_id_FK=CO.int_contract_id_PK
			WHERE SE.int_salary_id_FK=@salaryE AND C.tin_typeRegistration_id_FK=1)
		UPDATE SALARY SET mon_hourSalary = @Acumuladora/160 WHERE SALARY.int_salary_id_PK=@salaryE
		SET @Acumuladora = @Acumuladora + ISNULL((SELECT SUM(EX.tin_amount*SA.mon_hourSalary*(TY.flo_porcent/100)) 
			FROM EXTRA_HOURS EX,SALARY SA,TYPE_HOURS TY 
			WHERE EX.bit_payFactor=1 AND SA.int_salary_id_PK=@salaryE AND EX.int_salary_id_FK=@salaryE
			AND EX.tin_hourType_id_FK=TY.tin_hourType_id_PK AND EX.int_salary_id_FK=SA.int_salary_id_PK),0)
		SET @Acumuladora = @Acumuladora + ISNULL((SELECT SUM(MO.int_factor*MO.mon_amount) 
		FROM SALARY SA,PAYMENT_MOVEMENT PM,MOVEMENT MO
		WHERE PM.int_salary_id_PK_FK=SA.int_salary_id_PK AND PM.int_movement_id_PK_FK = MO.int_movement_id_PK
		AND PM.bit_motionFactor=1 AND SA.int_salary_id_PK=@salaryE AND PM.int_salary_id_PK_FK=@salaryE),0)
		UPDATE SALARY SET mon_netSalary = @Acumuladora WHERE SALARY.int_salary_id_PK=@salaryE;
		SET @salaryE = @salaryE + 1;
	END
GO

CREATE PROCEDURE HUMAN_R.SalaryCalculateWithMounthYears @mount int, @year int 
AS  
	DECLARE @Acumuladora MONEY,@salaryE INT
	SET @salaryE = 1
	WHILE @salaryE<=(SELECT COUNT(*) FROM HUMAN_R.SALARY)
	BEGIN
		if (SELECT COUNT(*) FROM HUMAN_R.SALARY SA WHERE MONTH(SA.dat_date) = @mount AND YEAR(SA.dat_date) = @year AND SA.int_salary_id_PK=@salaryE) != 0
			BEGIN
			--SE TRAE EL SALARIO NETO QUE ESTA EN EL CONTRATO DEL EMPLEADO
			SET @Acumuladora = (SELECT mon_salary FROM HUMAN_R.SALARY_EMP SE 
				INNER JOIN HUMAN_R.EMPLOYEES E ON
				E.int_employee_id_PK=SE.int_employee_id_FK
				INNER JOIN HUMAN_R.CONTRACTS C ON
				C.int_contract_id_PK=E.int_contract_id_FK
				WHERE SE.int_salary_id_FK=@salaryE)
		
			--SE ACTUALIZA EL VALOR POR HORA EN UNA CANTIDAD DE HORA LABORAL POR MES DE 160
			UPDATE HUMAN_R.SALARY SET mon_hourSalary = @Acumuladora/160 WHERE SALARY.int_salary_id_PK=@salaryE

			--CALCULA UNA SUMATORIA DE LAS HORAS EXTRAS
			SET @Acumuladora = @Acumuladora + ISNULL((SELECT SUM(EX.tin_amount*SA.mon_hourSalary*(TY.flo_porcent/100)) 
				FROM HUMAN_R.EXTRA_HOURS EX,HUMAN_R.SALARY SA,HUMAN_R.TYPE_HOURS TY 
				WHERE EX.bit_payFactor=1 AND SA.int_salary_id_PK=@salaryE AND EX.int_salary_id_FK=@salaryE
				AND EX.tin_hourType_id_FK=TY.tin_hourType_id_PK AND EX.int_salary_id_FK=SA.int_salary_id_PK),0)

			--CALCULA UNA SUMATORIA DE MOVIMIENTOS DE PAGO
			SET @Acumuladora = @Acumuladora + ISNULL((SELECT SUM(MO.int_factor*MO.mon_amount) 
			FROM HUMAN_R.SALARY SA,HUMAN_R.PAYMENT_MOVEMENT PM,HUMAN_R.MOVEMENT MO
			WHERE PM.int_salary_id_PK_FK=SA.int_salary_id_PK AND PM.int_movement_id_PK_FK = MO.int_movement_id_PK
			AND PM.bit_motionFactor=1 AND SA.int_salary_id_PK=@salaryE AND PM.int_salary_id_PK_FK=@salaryE),0)

			--ACTUALIZA EL VALOR DEL SALARIO
			UPDATE HUMAN_R.SALARY SET mon_netSalary = @Acumuladora WHERE SALARY.int_salary_id_PK=@salaryE
			print @Acumuladora
			SET @salaryE = @salaryE + 1--AUMENTA AL SIGUIENTE SALARIO
			END
		ELSE
			print 'no es un salario que entre en la fecha'
	END
GO

CREATE PROCEDURE HUMAN_R.SalaryCalculateWithOnly @salaryE int 
AS  
	DECLARE @Acumuladora MONEY
	
	--SE TRAE EL SALARIO NETO QUE ESTA EN EL CONTRATO DEL EMPLEADO
	SET @Acumuladora = (SELECT mon_salary FROM HUMAN_R.SALARY_EMP SE 
		INNER JOIN HUMAN_R.EMPLOYEES E ON
		E.int_employee_id_PK=SE.int_employee_id_FK
		INNER JOIN HUMAN_R.CONTRACTS C ON
		C.int_contract_id_PK=E.int_contract_id_FK
		WHERE SE.int_salary_id_FK=@salaryE)
		
	--SE ACTUALIZA EL VALOR POR HORA EN UNA CANTIDAD DE HORA LABORAL POR MES DE 160
	UPDATE HUMAN_R.SALARY SET mon_hourSalary = @Acumuladora/160 WHERE SALARY.int_salary_id_PK=@salaryE

	--CALCULA UNA SUMATORIA DE LAS HORAS EXTRAS
	SET @Acumuladora = @Acumuladora + ISNULL((SELECT SUM(EX.tin_amount*SA.mon_hourSalary*(TY.flo_porcent/100)) 
		FROM HUMAN_R.EXTRA_HOURS EX,HUMAN_R.SALARY SA,HUMAN_R.TYPE_HOURS TY 
		WHERE EX.bit_payFactor=1 AND SA.int_salary_id_PK=@salaryE AND EX.int_salary_id_FK=@salaryE
		AND EX.tin_hourType_id_FK=TY.tin_hourType_id_PK AND EX.int_salary_id_FK=SA.int_salary_id_PK),0)

	--CALCULA UNA SUMATORIA DE MOVIMIENTOS DE PAGO
	SET @Acumuladora = @Acumuladora + ISNULL((SELECT SUM(MO.int_factor*MO.mon_amount) 
	FROM HUMAN_R.SALARY SA,HUMAN_R.PAYMENT_MOVEMENT PM,HUMAN_R.MOVEMENT MO
	WHERE PM.int_salary_id_PK_FK=SA.int_salary_id_PK AND PM.int_movement_id_PK_FK = MO.int_movement_id_PK
	AND PM.bit_motionFactor=1 AND SA.int_salary_id_PK=@salaryE AND PM.int_salary_id_PK_FK=@salaryE),0)

	--ACTUALIZA EL VALOR DEL SALARIO
	UPDATE HUMAN_R.SALARY SET mon_netSalary = @Acumuladora WHERE SALARY.int_salary_id_PK=@salaryE
	print @Acumuladora
	SET @salaryE = @salaryE + 1--AUMENTA AL SIGUIENTE SALARIO
	
GO


CREATE PROCEDURE CreateSalaryEmployees 
AS 
	DECLARE @dateEmployee DATE, @employee INT,@dateYear DATE, @ACUM INT,@ACUMM INT;
	SET NOCOUNT OFF;
	SET @ACUM = 1;
	SET @employee = 1;
	SET @ACUMM = (SELECT COUNT(*) FROM CONTRACTS);
	WHILE(@ACUMM>=@employee)
	BEGIN
		SET @dateEmployee = (SELECT dat_hiringDate FROM REGISTRATION_HIRES RE WHERE re.tin_typeRegistration_id_FK=1 AND RE.int_employee_id_FK=@employee);
		SET @dateYear = DATEADD(DAY,30,@dateEmployee);
		WHILE(@dateYear<=ISNULL((SELECT dat_hiringDate FROM REGISTRATION_HIRES RE WHERE RE.tin_typeRegistration_id_FK>1 AND RE.int_employee_id_FK=@employee),'2021-12-31'))
		BEGIN
			INSERT INTO SALARY(mon_netSalary,mon_hourSalary,dat_date,tin_area_id_FK) VALUES (1,0,@dateYear,(SELECT tin_area_id_FK FROM EMPLOYEES WHERE int_employee_id_PK=@employee));
			INSERT INTO SALARY_EMP(bit_pay,int_salary_id_FK,int_employee_id_FK) VALUES (1,@ACUM,@employee);
			SET @dateYear = DATEADD(DAY,30,@dateYear);
			SET @ACUM = @ACUM+1;
		END
		print @dateEmployee;
		SET @employee = @employee+1;
	END
GO

CREATE PROCEDURE HUMAN_R.ModifyAddress
AS
	DECLARE @ADDREES BIGINT,@SUBURN INT, @CITIES INT, @DEPARTAMENT INT, @COUNTRY INT,@CONT BIGINT;
	SET @ADDREES =10;
	SET @CONT = (SELECT COUNT(*) FROM HUMAN_R.LIST_ADDRESS);
	WHILE(@ADDREES<=@CONT)
	BEGIN
		SET @SUBURN = (SELECT big_suburn_id_FK FROM HUMAN_R.LIST_ADDRESS WHERE big_address_id_PK=@ADDREES);
		SET @CITIES = (SELECT big_city_id_FK FROM HUMAN_R.SUBURN WHERE big_suburn_id_PK=@SUBURN);
		SET @DEPARTAMENT = (SELECT big_departament_id_FK FROM HUMAN_R.CITIES WHERE big_city_id_PK=@CITIES);
		SET @COUNTRY = (SELECT int_country_id_FK FROM HUMAN_R.DEPARTAMENT WHERE big_departament_id_PK=@DEPARTAMENT);
		UPDATE HUMAN_R.LIST_ADDRESS SET int_country_id_FK=@COUNTRY,big_departament_id_FK=@DEPARTAMENT,big_city_id_FK=@CITIES WHERE big_address_id_PK=@ADDREES;
		SET @ADDREES = @ADDREES + 1;
	END
GO

CREATE PROCEDURE MOVEMENT_PAY_PRUEBA
AS
	DECLARE @salary int, @Hours bit, @dateS DATE,@cant int,@prueba int;
	SET @salary = 298022;
	SET @cant = (SELECT COUNT(*) FROM SALARY)
	WHILE (@salary<=@cant)
	BEGIN
		SET @dateS = (SELECT dat_date FROM SALARY WHERE int_salary_id_PK=@salary)
		INSERT INTO PAYMENT_MOVEMENT(bit_motionFactor,int_movement_id_PK_FK,int_salary_id_PK_FK) VALUES (1,FLOOR(( SELECT rnd FROM vwRandom ) *(4-1)+1),@salary);
		INSERT INTO PAYMENT_MOVEMENT(bit_motionFactor,int_movement_id_PK_FK,int_salary_id_PK_FK) VALUES (1,FLOOR(( SELECT rnd FROM vwRandom ) *(9-5)+5),@salary);
		SET @prueba = FLOOR(( SELECT rnd FROM vwRandom ) *(10-1)+1);
		IF (@prueba<=5)
		BEGIN
			INSERT INTO EXTRA_HOURS(dat_date,tin_amount,bit_payFactor,tin_hourType_id_FK,int_salary_id_FK) VALUES (DATEADD(DAY,(-1*FLOOR(( SELECT rnd FROM vwRandom ) *(30-1)+1)),@dateS),FLOOR(( SELECT rnd FROM vwRandom ) *(4-1)+1),1,FLOOR(( SELECT rnd FROM vwRandom ) *(9-1)+1),@salary);
			INSERT INTO EXTRA_HOURS(dat_date,tin_amount,bit_payFactor,tin_hourType_id_FK,int_salary_id_FK) VALUES (DATEADD(DAY,(-1*FLOOR(( SELECT rnd FROM vwRandom ) *(30-1)+1)),@dateS),FLOOR(( SELECT rnd FROM vwRandom ) *(4-1)+1),1,FLOOR(( SELECT rnd FROM vwRandom ) *(9-1)+1),@salary);
		END
		ELSE IF (@prueba<=8)
			INSERT INTO EXTRA_HOURS(dat_date,tin_amount,bit_payFactor,tin_hourType_id_FK,int_salary_id_FK) VALUES (DATEADD(DAY,(-1*FLOOR(( SELECT rnd FROM vwRandom ) *(30-1)+1)),@dateS),FLOOR(( SELECT rnd FROM vwRandom ) *(4-1)+1),1,FLOOR(( SELECT rnd FROM vwRandom ) *(9-1)+1),@salary);
		SET @salary= @salary + 1;
	END
GO 


CREATE PROCEDURE DATEREGIS
AS
	DECLARE @dateCon DATE,@Registra INT;
	SET @Registra =1
	WHILE (@Registra<(SELECT COUNT(*) FROM REGISTRATION_HIRES WHERE tin_typeRegistration_id_FK = 1))
	BEGIN
		SET @dateCon = ISNULL((SELECT dat_hiringDate FROM REGISTRATION_HIRES WHERE tin_typeRegistration_id_FK = 1 AND int_contract_id_FK = @Registra),'1999-01-01');
		IF(@dateCon != '1999-01-01')
		BEGIN 
			UPDATE REGISTRATION_HIRES SET dat_hiringDate = (dbo.getRandomDate(@dateCon, '2021-12-30')) WHERE tin_typeRegistration_id_FK > 1 AND int_contract_id_FK = @Registra;
		END
		SET @Registra = @Registra+1;
	END

GO

EXEC HUMAN_R.SalaryCalculate
GO

EXEC HUMAN_R.SalaryCalculateWithMounthYears 1,2021
GO

EXEC HUMAN_R.SalaryCalculateWithOnly 5
GO

EXEC CreateSalaryEmployees
GO

EXEC HUMAN_R.ModifyAddress
GO

EXEC MOVEMENT_PAY
GO

SELECT * FROM HUMAN_R.SALARY