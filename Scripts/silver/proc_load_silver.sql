/*
==========================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
==========================================================================

Script purpose:
	This stored procedure peform ETL processes (Extract,Load and Transform)  
  to populate the silver schema tables from the bronze schema tables
	It performs the following actions:
		-Truncate the silver table before loading data.
		-Insert and transformed , cleaned from bronze into silver table

	Parameters:
		None
	This stored procedures does not accept or ruturn any values

	Usage Example: 
		EXEC silver.load_silver ;
	==============================================================================


*/
CREATE OR ALTER  PROCEDURE silver.load_silver AS 
BEGIN
	DECLARE @START_TIME DATETIME , @END_TIME DATETIME ,@START_TIME_SILVER DATETIME , @END_TIME_SILVER DATETIME;
	BEGIN  TRY 

		SET @START_TIME_SILVER = GETDATE();
		PRINT'==========================================================';
		PRINT 'Loading" Silver Layer';

		PRINT'==============================================';
		PRINT 'Loading CRM table';
		PRINT'===============================================';

		SET @START_TIME = GETDATE();




		PRINT '>>> Truncating Table :  silver.crm_cust_info'
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '>> Inserting Data Into: silver.crm_cust_info'

		INSERT INTO silver.crm_cust_info ( cst_id,
											cst_key, 
											cst_firstname,  
											cst_lastname,
											cst_marital_status,
											cst_gndr,
											cst_create_date)



		SELECT 
			cst_id,
			cst_key,
			TRIM(cst_firstname) cst_firstname,
			TRIM(cst_lastname) cst_lastname,
			CASE 
				WHEN TRIM(UPPER(cst_marital_status)) = 'M' THEN 'Single'
				WHEN TRIM(UPPER(cst_marital_status)) = 'S' THEN 'Married'
			ELSE 'n/a' END cst_marital_status,
			CASE 
				WHEN TRIM(UPPER(cst_gndr)) = 'M' THEN 'Male'
				WHEN TRIM(UPPER(cst_gndr)) = 'F' THEN 'Female'
			ELSE 'n/a' END cst_gndr,
			cst_create_date

		FROM 
		(
			SELECT 
				* ,
				ROW_NUMBER() OVER (PARTITION  BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM 
			bronze.crm_cust_info

		) t
		WHERE flag_last = 1 AND cst_id IS NOT NULL;

		SET @END_TIME = GETDATE();

		PRINT '>>load duration:silver.crm_cust_info ' + CAST ( DATEDIFF(SECOND ,@START_TIME,@END_TIME) AS NVARCHAR ) +' seconds';

		SET @START_TIME = GETDATE();
		Print'>> Truncating Table : silver.crm_prd_info';

		TRUNCATE TABLE silver.crm_prd_info

		PRINT '>> Inserting Data Into: silver.crm_prd_info'

		INSERT INTO silver.crm_prd_info( prd_id,
											cat_id,
											prd_key,
											prd_nm,
											prd_cost,
											prd_line,
											prd_start_dt,
											prd_end_dt)

		SELECT 
			prd_id,
			REPLACE(SUBSTRING(prd_key,1,5),'-','_') cat_id,
			SUBSTRING(prd_key,7,LEN(prd_key)) prd_key,
			TRIM(prd_nm) prd_nm,
			ISNULL( prd_cost,0) prd_cost,
			CASE UPPER(TRIM(prd_line))
				WHEN  'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN  'S' THEN 'Other Sales'
				WHEN  'T' THEN 'Touring'
			ELSE 'n/a' END  prd_line,
			CAST( prd_start_dt AS DATE)  prd_start_dt,
			CAST (DATEADD(day,-1,LEAD (prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS DATE) prd_end_dt

		FROM bronze.crm_prd_info

		SET @END_TIME = GETDATE();
		PRINT '>>load duration:silver.crm_prd_info table ' + CAST ( DATEDIFF(SECOND ,@START_TIME,@END_TIME) AS NVARCHAR ) +' seconds';

		SET @START_TIME = GETDATE();

		PRINT '>>> Truncating Table :silver.crm_sales_details'
		TRUNCATE TABLE silver.crm_sales_details
		PRINT '>> Inserting Data Into:silver.crm_sales_details'

		INSERT INTO silver.crm_sales_details (  sls_ord_num,
												sls_prd_key,
												sls_cust_id,
												sls_order_dt,
												sls_ship_dt,
												sls_due_dt,
												sls_sales,
												sls_quantity,
												sls_price  )

		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE 
				WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN  NULL
			ELSE CAST(CAST (sls_order_dt AS VARCHAR) AS DATE ) END sls_order_dt,
			CASE 
				WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN  NULL
			ELSE CAST(CAST (sls_ship_dt AS VARCHAR) AS DATE ) END sls_ship_dt,
			CASE 
				WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN  NULL
			ELSE CAST(CAST (sls_due_dt AS VARCHAR) AS DATE ) END sls_due_dt,
			CASE  
				WHEN sls_sales IS NULL OR sls_sales <=0 OR  sls_sales != ABS(sls_price) * sls_quantity  THEN ABS(sls_quantity) * ABS(sls_price)
			ELSE sls_sales END sls_sales ,

				sls_quantity,
			CASE  
				WHEN sls_price IS NULL OR sls_price <= 0  THEN ABS(sls_sales) / NULLIF(sls_quantity,0)
			ELSE sls_price END sls_price

		FROM bronze.crm_sales_details

		SET @END_TIME = GETDATE();
		PRINT '>>load duration:silver.crm_sales_details table ' + CAST ( DATEDIFF(SECOND ,@START_TIME,@END_TIME) AS NVARCHAR ) +' seconds';
		PRINT'=================================';
		PRINT 'Loading ERP table';
		PRINT'=================================';
		
		
		SET @START_TIME = GETDATE()

		PRINT '>>> Truncating Table :silver.erp_loc_az12'
		TRUNCATE TABLE silver.erp_loc_az12
		PRINT '>> Inserting Data Into:silver.erp_loc_az12'


		INSERT INTO silver.erp_loc_az12 (cid,
										cntry)


		SELECT 
			REPLACE (cid,'-','') cid,
			CASE 
				 WHEN cntry = 'DE' THEN 'Germany'
				 WHEN cntry IN ('US','USA') THEN 'United States'
				 WHEN cntry IS NULL THEN 'n/a'
				 WHEN cntry = ' ' THEN 'n/a'
			ELSE cntry END asd
		FROM bronze.erp_loc_az12
		
		SET @END_TIME = GETDATE();
		PRINT '>>load duration:silver.erp_loc_az12 table ' + CAST ( DATEDIFF(SECOND ,@START_TIME,@END_TIME) AS NVARCHAR ) +' seconds';

		SET @START_TIME = GETDATE()
		Print'>> Truncating Table : silver.erp_loc_a101 table';
	
		
		TRUNCATE TABLE silver.erp_loc_a101

		INSERT INTO silver.erp_loc_a101 (cid,
											bdate,
											gen)

		SELECT
			CASE 
				WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4 ,LEN (cid)) 
			ELSE cid END cid,
			CASE 
				WHEN bdate > GETDATE()  THEN NULL
			ELSE bdate END bdate,
			CASE 
				WHEN gen = 'F' THEN 'Female'
				WHEN gen ='M' THEN 'Male'
				WHEN gen IS NULL OR gen = ' ' THEN 'n/a'
			ELSE gen END gen 

		FROM 
		 bronze.erp_loc_a101
		SET @END_TIME = GETDATE();
		PRINT '>>load duration:silver.erp_loc_a101 table ' + CAST ( DATEDIFF(SECOND ,@START_TIME,@END_TIME) AS NVARCHAR ) +' seconds';
	
		Print'>> >> Truncating Table : bronze.erp_px_cat_giv2';
		SET @START_TIME = GETDATE()
		PRINT '>>> Truncating Table :silver.erp_px_cat_giv2'
		TRUNCATE TABLE silver.erp_px_cat_giv2
		PRINT '>> Inserting Data Into:silver.erp_px_cat_giv2'

		INSERT INTO silver.erp_px_cat_giv2 (id,
												cat,
												subcat,
												maintenance)

		SELECT * FROM bronze.erp_px_cat_giv2

		SET @END_TIME = GETDATE();
		PRINT '>>load duration:bronze.erp_px_cat_giv2 table ' + CAST ( DATEDIFF(SECOND ,@START_TIME,@END_TIME) AS NVARCHAR ) +' seconds';
	

		PRINT'=================================';
		PRINT 'Bronze Layer Loading Completed';

		SET @END_TIME_SILVER = GETDATE();

		PRINT '>>load duration:SILVER.layer tables ' + CAST ( DATEDIFF(SECOND ,@START_TIME_SILVER,@END_TIME_SILVER) AS NVARCHAR ) +' seconds';

	END TRY

	BEGIN CATCH 
		PRINT '======================================================';
		PRINT 'Error occured during loading silver layer';
		PRINT 'Error message' + ERROR_MESSAGE();
		PRINT 'Error number' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error state' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '======================================================';
	END CATCH
END 

