-- ==============================================================================
-- PROJECT: Airline Operations Financial Impact & Operational Risk Analysis
-- AUTHOR: BADMUS OLAMIDE
-- DATE: August 2026
-- DESCRIPTION: End-to-end analytical script translating raw aviation delay 
--              records into high-impact operational and financial metrics.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- SECTION 1: GLOBAL OPERATIONAL BASELINE (Page 1 KPI Summary Cards)
-- ------------------------------------------------------------------------------
-- Generates total flight volume, total official delays, and baseline delay rate.
USE [Aircraft data];
GO

SELECT 
    COUNT(*) AS Total_Flights,
    COUNT(CASE WHEN ArrDelay > 15 THEN 1 END) AS Total_Delayed_Flights,
    ROUND(COUNT(CASE WHEN ArrDelay > 15 THEN 1 END) * 100.0 / COUNT(*), 2) AS System_Delay_Percentage
FROM DelayedFlights;



-- SECTION 2: TOTAL OPERATIONAL LOSS LOGIC (Financial Overview)
-- ------------------------------------------------------------------------------
-- Calculates total financial drain using the $75/minute operational cost factor.
-- Slices the data uniformly across Airlines, Airports, and Time dimensions.

-- A. Financial Loss by Airline Carrier
SELECT 
    UniqueCarrier AS Airline_Code,
    SUM(CASE WHEN ArrDelay > 0 THEN ArrDelay ELSE 0 END) * 75 AS Estimated_Financial_Impact_USD
FROM DelayedFlights
GROUP BY UniqueCarrier
ORDER BY Estimated_Financial_Impact_USD DESC;

-- B. Financial Loss by Origin Airport Hub
SELECT 
    Origin AS Airport_Code,
    SUM(CASE WHEN ArrDelay > 0 THEN ArrDelay ELSE 0 END) * 75 AS Estimated_Financial_Impact_USD
FROM DelayedFlights
GROUP BY Origin
ORDER BY Estimated_Financial_Impact_USD DESC;

-- C. Financial Loss Trend Over Time (Monthly Analysis)
SELECT 
    Month,
    SUM(CASE WHEN ArrDelay > 0 THEN ArrDelay ELSE 0 END) * 75 AS Monthly_Financial_Impact_USD
FROM DelayedFlights
GROUP BY  Month
ORDER BY  Month ASC;


-- SECTION 3: AIRPORT INFRASTRUCTURE RISK (Severe Delays & Tarmac Congestion)
-- Aggregates incident counts (>60 mins) and tarmac idling durations.
-- Metrics scaled (/1000.0) to match the "Units in Thousands" dashboard axes.
SELECT TOP 10
    Origin AS Airport_Code,
    SUM(CASE WHEN ArrDelay > 60 THEN 1 ELSE 0 END) / 1000.0 AS Severe_Delays_Thousands,
    SUM(ISNULL(TaxiIn, 0) + ISNULL(TaxiOut, 0)) / 1000.0 AS Tarmac_Congestion_Mins_Thousands
FROM DelayedFlights
GROUP BY Origin
ORDER BY Severe_Delays_Thousands DESC;


-- SECTION 4: AIRLINE SCHEDULE VULNERABILITY (Cascading Network Delays)
-- Isolates domino-effect schedule breakdowns where late inbound flights caused 
-- more than 50% of the downstream arrival delay duration.
SELECT 
    UniqueCarrier AS Airline_Code,
    SUM(CASE WHEN ArrDelay > 60 THEN 1 ELSE 0 END) / 1000.0 AS Severe_Delays_Thousands,
    SUM(CASE WHEN LateAircraftDelay > (ArrDelay / 2.0) THEN 1 ELSE 0 END) / 1000.0 AS Cascading_Failures_Thousands
FROM DelayedFlights
GROUP BY UniqueCarrier
ORDER BY Severe_Delays_Thousands DESC;



-- SECTION 5: ROOT CAUSE BREAKDOWN (Delay Reasons)----
-- Safe summation of industry-standard delay attributes using ISNULL handling.
SELECT 
    UniqueCarrier AS Airline_Code,
    SUM(ISNULL(CarrierDelay, 0)) AS Total_Carrier_Delay_Minutes,
    SUM(ISNULL(WeatherDelay, 0)) AS Total_Weather_Delay_Minutes,
    SUM(ISNULL(NASDelay, 0)) AS Total_NAS_Delay_Minutes,
    SUM(ISNULL(SecurityDelay, 0)) AS Total_Security_Delay_Minutes,
    SUM(ISNULL(LateAircraftDelay, 0)) AS Total_Late_Aircraft_Minutes
FROM DelayedFlights
GROUP BY UniqueCarrier
ORDER BY Total_Carrier_Delay_Minutes DESC;
