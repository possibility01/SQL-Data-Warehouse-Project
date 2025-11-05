/*
==========================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
==========================================================================

Script purpose:
	This stored procedure loads data into the bronze schema from external files.
	It performs the following actions:
		-Truncate the bronze table before loading data.
		-Use the BULK INSERT command to load from csv files to bronze tablles.

	Parameters:
		None
	This stored procedures does not accept or ruturn any values

	Usage Example: 
		EXEC bronze.load_bronze ;
	==============================================================================


*/

CREATE OR ALTER  PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @START_TIME DATETIME , @END_TIME DATETIME ,@START_TIME_BRONZE DATETIME , @END_TIME_BRONZE DATETIME;
	BEGIN  TRY 

		SET @START_TIME_BRONZE = GETDATE();
		PRINT'==========================================================';
		PRINT 'Loading" Bronze Layer';

		PRINT'==============================================';
		PRINT 'Loading CRM table';
		PRINT'===============================================';

		SET @START_TIME = GETDATE();

		Print'>> Truncating Table : bronze.crm_cust_info'

		TRUNCATE TABLE bronze.crm_cust_info 

		PRINT '>>Inserting Date Into: bronze.crm_cust_info table';

		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\eBay\Downloads\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR =',',
			TABLOCK
		);

		SET @END_TIME = GETDATE();

		PRINT '>>load duration:bronze.crm_cust_info ' + CAST ( DATEDIFF(SECOND ,@START_TIME,@END_TIME) AS NVARCHAR ) +' seconds';

		Print'>> Truncating Table : bronze.crm_prd_info';

		SET @START_TIME = GETDATE();

		TRUNCATE TABLE bronze.crm_prd_info

		PRINT '>>Inserting Date Into: bronze.crm_prd_info table';

		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\eBay\Downloads\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR =',',
			TABLOCK
		);

		SET @END_TIME = GETDATE();
		PRINT '>>load duration:bronze.crm_prd_info table ' + CAST ( DATEDIFF(SECOND ,@START_TIME,@END_TIME) AS NVARCHAR ) +' seconds';
		

		Print'>> Truncating Table : bronze.crm_sales_details';
		SET @END_TIME = GETDATE();
		TRUNCATE TABLE bronze.crm_sales_details

		PRINT '>>Inserting Date Into: bronze.crm_sales_details';

		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\eBay\Downloads\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR =',',
			TABLOCK
		);

		SET @END_TIME = GETDATE();
		PRINT '>>load duration:bronze.crm_sales_details table ' + CAST ( DATEDIFF(SECOND ,@START_TIME,@END_TIME) AS NVARCHAR ) +' seconds';
		PRINT'=================================';
		PRINT 'Loading ERP table';
		PRINT'=================================';

		Print'>> Truncating Table : bronze.erp_loc_a101 table';
	
		SET @START_TIME = GETDATE()
		TRUNCATE TABLE bronze.erp_loc_a101

		PRINT 'Inserting data into: bronze.erp_loc_a101 table';

		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\eBay\Downloads\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR =',',
			TABLOCK
		);

		SET @END_TIME = GETDATE();
		PRINT '>>load duration:bronze.erp_loc_a101 table ' + CAST ( DATEDIFF(SECOND ,@START_TIME,@END_TIME) AS NVARCHAR ) +' seconds';
	

		Print'>> >> Truncating Table : bronze.erp_loc_az12';
		SET @START_TIME = GETDATE();
		TRUNCATE TABLE bronze.erp_loc_az12

		PRINT 'Inserting data into: bronze.erp_loc_az12 table';

		BULK INSERT bronze.erp_loc_az12
		FROM 'C:\Users\eBay\Downloads\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR =',',
			TABLOCK
		);
		SET @END_TIME = GETDATE();
		PRINT '>>load duration:bronze.erp_loc_az12 table ' + CAST ( DATEDIFF(SECOND ,@START_TIME,@END_TIME) AS NVARCHAR ) +' seconds';
	

		Print'>> >> Truncating Table : bronze.erp_px_cat_giv2';
		SET @START_TIME = GETDATE()
		TRUNCATE TABLE bronze.erp_px_cat_giv2

		PRINT 'Inserting data into:bronze.erp_px_cat_giv2 table';

		BULK INSERT bronze.erp_px_cat_giv2
		FROM 'C:\Users\eBay\Downloads\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR =',',
			TABLOCK
		);

		SET @END_TIME = GETDATE();
		PRINT '>>load duration:bronze.erp_px_cat_giv2 table ' + CAST ( DATEDIFF(SECOND ,@START_TIME,@END_TIME) AS NVARCHAR ) +' seconds';
	

		PRINT'=================================';
		PRINT 'Bronze Layer Loading Completed';

		SET @END_TIME_BRONZE = GETDATE();

		PRINT '>>load duration:bronze.layer tables ' + CAST ( DATEDIFF(SECOND ,@START_TIME_BRONZE,@END_TIME_BRONZE) AS NVARCHAR ) +' seconds';

	END TRY

	BEGIN CATCH 
		PRINT '======================================================';
		PRINT 'Error occured during loading bronze layer';
		PRINT 'Error message' + ERROR_MESSAGE();
		PRINT 'Error number' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error state' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '======================================================';
	END CATCH
END 



EXEC bronze.load_bronze


