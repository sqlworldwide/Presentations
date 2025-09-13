/*
01_BuiltInCopilot

Author: Taiob Ali
Contact: taiob@sqlworldwide.com
https://bsky.app/profile/sqlworldwide.bsky.social
https://sqlworldwide.com/
https://www.linkedin.com/in/sqlworldwide/

Last Modified: September 10, 2025
	
Tested on :
Azure SQL Database
SSMS 21.4.12
*/

/*
Open a query window under testdata database in SSMS and VSCode
and ask this question in the prompt with Context to oepn query window

1. What server and database are you connected to?
2. Can you write tsql query to find customer name who purchased products under category mountain bike by state and total sales?
3. Can you modify the query to search for category like mountain bike
4. Count all customers, group by state, and give the top ten states with the most and least customers order by customer count
5. Create a stored procedure that shows all sales by customer ID, with Customer ID as the input parameter, and raises an error if the customer ID does not exist. Drop the stored procedure if it already exists.
6. (Some metadata fun!!) Show me which tables have consumed the most space in this database


Test code for number six prompt:
Check the stored procedure name given my copilot

EXEC [dbo].[GetSalesByCustomerID]
		@CustomerID= 29847
GO

EXEC [dbo].[GetSalesByCustomerID]
		@CustomerID= 8
GO
*/


