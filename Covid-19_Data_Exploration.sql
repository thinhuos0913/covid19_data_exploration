USE Covid19
GO

-- See the first 10 records of tables

SELECT TOP(10) *
FROM CovidDeaths
ORDER BY 3,4

SELECT TOP(10) *
FROM CovidVaccinations
ORDER BY 3,4

-- Extract columns to explore

SELECT location
	,continent
	,date
	,total_cases
	,total_deaths
	,new_cases
	,new_deaths
	,population
FROM CovidDeaths
ORDER BY 1,2

-- Convert data type of [total_cases] & [total_deaths] for calculation

ALTER TABLE CovidDeaths
ALTER COLUMN total_cases float

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths float

-- Check % deaths cases vs total cases

SELECT location
	,date
	,total_cases
	,total_deaths
	,(total_deaths/total_cases)*100 AS death_percentage
FROM CovidDeaths

-- % of death percentage of Vietnam

SELECT location
	,date,total_cases
	,total_deaths
	,(total_deaths/total_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE location = 'Vietnam'
AND continent IS NOT NULL
ORDER BY death_percentage DESC

-- % of population got Covid in Vietnam?

SELECT location
	,date
	,total_cases
	,population
	,(total_cases/population)*100 AS percentage
FROM CovidDeaths
WHERE location = 'Vietnam'
AND continent IS NOT NULL
ORDER BY percentage DESC

-- Which countries have the highest infection rate compared to population?

SELECT TOP (5)
	location
	,population
	,MAX(total_cases) AS highest_infection
	,MAX((total_cases/population))*100 AS percent_population_infected
FROM CovidDeaths
GROUP BY location,population
ORDER BY percent_population_infected DESC

-- Which countries have highest death cases?

SELECT TOP (5)
	location
	,MAX(total_deaths) AS total_death
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

-- Which countries have highest % of death cases?

SELECT TOP(5)
	location
	,MAX((total_deaths/population))*100 AS percent_death
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC

-- Which continents have highest death cases?

SELECT continent
	,MAX(CAST(total_deaths AS int)) AS total_death
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

-- Which continents have highest death percentage?

SELECT continent
	,MAX((total_deaths/population))*100 AS percent_death
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

-- Calculate some new numbers

SELECT SUM(new_cases) AS total_new_cases
	,SUM(new_deaths) total_new_deaths
	,SUM(new_deaths)/SUM(new_cases)*100 AS new_death_percent
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- See numbers by date

SELECT date
	,SUM(new_cases) AS total_new_cases
	,SUM(new_deaths) total_new_deaths
	,SUM(new_deaths)/SUM(new_cases)*100 AS new_death_percent
FROM CovidDeaths
WHERE continent IS NOT NULL
AND new_cases <> 0
GROUP BY date
ORDER BY 1,2 DESC

-- Join 2 tables to looking at total Population vs Vaccinations

SELECT DEA.continent
	,DEA.location
	,DEA.population
	,VAC.new_vaccinations
FROM CovidDeaths DEA
JOIN CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
ORDER BY 1,2,3

-- Convert data type of [new_vaccinations] column for calculation

ALTER TABLE CovidVaccinations
ALTER COLUMN new_vaccinations int

-- Show total vaccinations in Vietnam using new vaccinations day by day

SELECT DEA.continent,DEA.location
	,DEA.date
	,DEA.population
	,VAC.new_vaccinations
	,SUM(VAC.new_vaccinations) OVER (PARTITION BY DEA.location ORDER BY DEA.location,DEA.date)
	AS total_vaccinated
FROM CovidDeaths DEA
JOIN CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
AND DEA.location = 'Vietnam'
ORDER BY 2,3

-- % of population have vaccinated in Vietnam?

WITH PopvsVac (continent,location,date,population,total_vaccinated) 
AS 
(
	SELECT DEA.continent,DEA.location
		,DEA.date
		,DEA.population
		--,VAC.new_vaccinations
		,SUM(VAC.new_vaccinations) OVER (PARTITION BY DEA.location ORDER BY DEA.location,DEA.date)
		AS total_vaccinated
	FROM CovidDeaths DEA
	JOIN CovidVaccinations VAC
		ON DEA.location = VAC.location
		AND DEA.date = VAC.date
	WHERE DEA.continent IS NOT NULL
	AND DEA.location = 'Vietnam'
)

SELECT * 
,(total_vaccinated/population)*100 AS percent_vaccination
FROM PopvsVac

-- Create temp table name PercentVaccinated

CREATE TABLE PercentVaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	total_vaccinated numeric
)

INSERT INTO PercentVaccinated
SELECT DEA.continent,DEA.location
	,DEA.date
	,DEA.population
	,VAC.new_vaccinations
	,SUM(VAC.new_vaccinations) OVER (PARTITION BY DEA.location ORDER BY DEA.location,DEA.date)
	AS total_vaccinated
FROM CovidDeaths DEA
JOIN CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date

SELECT *
	,(total_vaccinated/population)*100 AS percent_vaccinated
FROM PercentVaccinated

-- Create a view to store data for later visualization

CREATE VIEW Percent_Vaccinated
AS
SELECT DEA.continent,DEA.location
	,DEA.date
	,DEA.population
	,VAC.new_vaccinations
	,SUM(VAC.new_vaccinations) OVER (PARTITION BY DEA.location ORDER BY DEA.location,DEA.date)
	AS total_vaccinated
FROM CovidDeaths DEA
JOIN CovidVaccinations VAC
	ON DEA.location = VAC.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL

SELECT *
	,(total_vaccinated/population)*100 AS percent_vaccinated
FROM Percent_Vaccinated
WHERE continent IS NOT NULL
AND location = 'Vietnam'


