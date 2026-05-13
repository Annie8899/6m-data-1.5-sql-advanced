
--To list all the tables in main:
SHOW TABLES;

--For more details:
SHOW ALL TABLES;

--To view the schema of an individual table:
DESCRIBE address;
DESCRIBE car;
DESCRIBE claim;
DESCRIBE client;

--Summarize Tables
SUMMARIZE address;
SUMMARIZE car;
SUMMARIZE claim;
SUMMARIZE client;
    
    
--Returns only the rows that match in both tables.    
SELECT *
FROM claim
INNER JOIN car ON claim.car_id = car.id;

--Inner join claim and client.
SELECT *
FROM claim
INNER JOIN client ON claim.car_id = client.id;


--Inner join client and address.
SELECT *
FROM client
INNER JOIN address ON client.address_id = address.id;

--Returns all rows from the left table, and the matching rows from the right table.
SELECT *
FROM claim
LEFT JOIN car ON claim.car_id = car.id;

--Returns all rows from the right table, and the matching rows from the left table.
SELECT *
FROM claim
RIGHT JOIN car ON claim.car_id = car.id;


--Returns all rows from both tables.
SELECT *
FROM claim
FULL JOIN car ON claim.car_id = car.id;


--Create a master report of every claim. Include the client's name, their car type, and the city they live in.
SELECT
  cl.id, cl.claim_date, cl.claim_amt,
  c.car_type,
  cli.first_name, cli.last_name,
  a.city, a.state
FROM claim cl
INNER JOIN car c ON cl.car_id = c.id
INNER JOIN client cli ON cl.client_id = cli.id
INNER JOIN address a ON cli.address_id = a.id;


--A running total is a cumulative sum: each row shows the sum of all rows from the start up to that row, in a defined order.
SELECT
  id, claim_amt,
  SUM(claim_amt) OVER (ORDER BY id) AS running_total
FROM claim;

--With PARTITION BY to compute the running total per car_id:
SELECT
  id, car_id, claim_amt,
  SUM(claim_amt) OVER (PARTITION BY car_id ORDER BY id) AS running_total
FROM claim;

--Calculate a running total of insurance payouts over time (ordered by claim_date).
SELECT
  claim_date, claim_amt,
  SUM(claim_amt) OVER (ORDER BY claim_date) AS running_total
FROM claim;


--RANK() gives each row a position (1st, 2nd, 3rd, …) within a group, allowing ties to share the same rank and leaving gaps after ties.
SELECT
  id, car_id, claim_amt,
  RANK() OVER (PARTITION BY car_id ORDER BY claim_amt DESC) AS rank
FROM claim;

--The QUALIFY clause filters rows based on window function results. For example, to find the highest claim per car type:
SELECT
  cl.id,
  c.car_type,
  cl.claim_amt,
  RANK() OVER (
    PARTITION BY car_type
    ORDER BY claim_amt DESC
  ) AS rank
FROM
  claim cl
  JOIN car c ON cl.car_id = c.id
QUALIFY rank = 1
ORDER BY
  cl.claim_amt DESC;
 
 
--A subquery is a query nested inside another query.
--To find the cars that have been involved in a claim:  
  
SELECT id, resale_value, car_type
FROM car
WHERE id IN (
  SELECT DISTINCT car_id
  FROM claim
);

--To find the cars that have been involved in a claim, and the claim amount is greater than 10% of the car's resale value:
SELECT id, resale_value, car_type
FROM car c
WHERE id IN (
  SELECT DISTINCT car_id
  FROM claim
  WHERE claim_amt > 0.1 * c.resale_value
);

--EXISTS operator: - to check if a subquery returns any rows.
--To find the cars that have been involved in a claim:
SELECT id, resale_value, car_type
FROM car c1
WHERE EXISTS (
  SELECT DISTINCT car_id
  FROM claim c2
  WHERE c2.car_id = c1.id
);


--Subquery in FROM (derived table):
SELECT car_id, avg_claim_amt
FROM (
  SELECT car_id, AVG(claim_amt) AS avg_claim_amt
  FROM claim
  GROUP BY car_id
) AS avg_claims
WHERE avg_claim_amt > (
  SELECT AVG(claim_amt)
  FROM claim
);


--Multiple CTEs in one query:
WITH avg_claims AS (
  SELECT car_id, AVG(claim_amt) AS avg_claim_amt
  FROM claim
  GROUP BY car_id
),
overall_avg AS (
  SELECT AVG(claim_amt) AS overall_avg
  FROM claim
)
SELECT car_id, avg_claim_amt
FROM avg_claims
WHERE avg_claim_amt > (SELECT overall_avg FROM overall_avg);

--Create a CTE that finds the total claim amount for each car. Then use this CTE to find the cars with a total claim amount greater than the average.
WITH total_claims AS (
  SELECT car_id, SUM(claim_amt) AS total_claim_amt
  FROM claim
  GROUP BY car_id
)
SELECT car_id, total_claim_amt
FROM total_claims
WHERE total_claim_amt > (SELECT AVG(total_claim_amt) FROM total_claims)
ORDER BY total_claim_amt DESC;



