/*
Script Name: 00_MiscellaneousUpdate.sql
				
SSMS 18.0 is the first release that is fully aware of SQL Server 2019 (compatLevel 150).
SSMS 18.0 isn't supported on Windows 8 due minimum version of .Net Framework. 
          Windows 10 and Windows Server 2016 require version 1607 
SSMS 18.0 Azure data studio integration
SSMS 18.0 New menu and key bindings to creates files (CTRL+ALT+N), CTRL+N still works
SSMS 18.0 Qeury Store -Added a new Query Wait Statistics report
SSMS 18.1 Databae diagrams were added back into SSMS
SSMS 18.1 SSBDIAGNOSE.EXE	The SQL Server Diagnose (command line tool) 
          was added back into the SSMS package
SSMS 18.2 Added a new attribute in QueryPlan when inline scalar UDF feature is enabled 
          (ContainsInlineScalarTsqludfs)
SSMS 18.3 Added data classificaiton information to column properties UI
SSMS 18.4 Added the Max Plan per query value in the dialog properties
SSMS 18.4 Added support for the new Custom Capture Policies
SSMS 18.4 Added error_reported event to XEvent Profiler sessions
SSMS 18.5 Added Notebook as a destination for Generate Scripts wizard
SSMS 18.5 Added support for sensitivity rank in Data Classification
SSMS 18.5 Improved how SSMS displays estimated row counts for operators with multiple executions: 
		  (1) Modified Estimated Number of Rows in SSMS to "Estimated Number of Rows Per Execution"; 
		  (2) Added a new property Estimated Number of Rows for All Executions; 
		  (3) Modify the property Actual Number of Rows to Actual Number of Rows for All Executions.
SSMS 18.6 Fixed long outstanding issue with Database Diagrams, 
					causing both the corruption of existing diagrams and SSMS to crash. 
					If you created or saved a diagram using SSMS 18.0 through 18.5.1, 
					and that diagram includes a Text Annotation, 
					you won't be able to open that diagram in any version of SSMS. With this fix, 
					SSMS 18.6 can open and save a diagram created by SSMS 17.9.1 and prior
					SSMS 17.9.1 and previous releases can also open the diagram after being saved by SSMS 18.6
SSMS 18.7 Beginning with SQL Server Management Studio (SSMS) 18.7, Azure Data Studio is automatically installed alongside SSMS
          Added PREDICT operator
SSMS 18.9 Added support for greatest and least in IntelliSense
					Always show Estimated Number of Rows for All Executions property
SSMS 18.10 Support for peer to peer publication with Last Writer Win (LWW) conflict detection
           Support for Ledger syntax in XEvents interface
					 Support for rich data types in Import Flat File wizard, including money
SSMS 18.11 Added a dialog box to display the status of an extended open transaction check when closing a T-SQL Query Editor tab.
SSMS 18.11.1 Link feature for Azure SQL Managed Instance
*/