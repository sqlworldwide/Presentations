## Title : **Think like the Cardinality Estimator**
### Abstract
SQL Server uses a phase during query optimization, called cardinality estimation (CE). This process makes estimates bases on the statistics as to how many rows flow from one query plan iterator to the next. Knowing how CE generates these numbers will enable you to write better TSQL code and, in turn, influence the type of physical operations during query execution. 

Based on that estimated rows, the query processor decides how to access an object, which physical join to use, how to sort the data. Do you know how the CE generates these numbers? What happens when you have multiple predicates, range predicates, variable values that are 'NOT KNOWN' to the optimizer, or you have predicate values increasing in ascending order? Do you know what will happen if your predicate is using a value that is outside of the histogram range?

In this session, I will show you how CE estimates in all these scenarios, and you will walk out better equipped to tackle those nasty, hard to solve query plans.

