/*COVID 19 DATA EXPLORATION
DATE RANGE: FROM 1st January, 2020 t0 27th November, 2023.
SKILLS USED: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- ANALYSIS OF COVID DATA FROM 1st January, 2020 t0 27th November, 2023.

SELECT *
FROM CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY location, date;

SELECT *
FROM CovidVaccinations$
WHERE continent IS NOT NULL
ORDER BY location, date;

--SELECTING DATA WE ARE GOING TO BE USING
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY iso_code, continent;

--LOOKING AT SUM OF TOTAL CASES VS TOTAL DEATH
--TOTAL CASES
SELECT SUM(new_cases) AS TOTAL_CASES
FROM CovidDeaths$
WHERE continent IS NOT NULL

--TOTAL DEATH
SELECT SUM(CAST(new_deaths as int)) AS TOTAL_DEATHS
FROM CovidDeaths$
WHERE continent IS NOT NULL



--LOOKING AT TOTAL CASES VS TOTAL DEATHS
--shows likelihood of dying if you contact covid in your country

SELECT location, date, total_cases, total_deaths, (total_cases/total_deaths)*100 AS DeathPercentage
FROM CovidDeaths$
WHERE location LIKE '%states'
AND continent IS NOT NULL
ORDER BY iso_code, continent;

SELECT location, date, total_cases, total_deaths, (total_cases/total_deaths)*100 AS DeathPercentage
FROM CovidDeaths$
WHERE location LIKE '%nigeria'
AND continent IS NOT NULL
ORDER BY iso_code, continent;

SELECT location, date, total_cases, total_deaths, (total_cases/total_deaths)*100 AS DeathPercentage
FROM CovidDeaths$
WHERE location LIKE '%china'
AND continent IS NOT NULL
ORDER BY iso_code, continent;

-- LOOKING AT THE TOTAL CASES VS POPULATION
-- Shows Percentage of Population infected with covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths$
WHERE location LIKE '%nigeria'
AND continent IS NOT NULL
ORDER BY iso_code, continent;

SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths$
WHERE location LIKE '%states'
AND continent IS NOT NULL
ORDER BY iso_code, continent;

SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths$
WHERE location LIKE '%china'
AND continent IS NOT NULL
ORDER BY iso_code, continent;

--LOOKING AT HIGHEST COUNTRIES WITH HIGHEST INFECTION RATE COMPARED TO POPULATION

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS percentpopulationinfected
FROM CovidDeaths$
--WHERE location LIKE '%china'
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percentpopulationinfected DESC;

SELECT location, population, continent, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS percentpopulationinfected
FROM CovidDeaths$
--WHERE location LIKE '%china'
WHERE continent IS NOT NULL
GROUP BY location, population, continent
ORDER BY percentpopulationinfected DESC;

--SHOWING COUNTRIES WITH THE HIGHEST CASES
SELECT Location, MAX(total_cases) AS TotalCaseCount
FROM CovidDeaths$
--WHERE Location LIKE '%states'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalCaseCount DESC;

--SHOWING COUNTRIES WITH THE HIGHEST DEATH COUNT
--NB
--The cast function is mainly used to convert the expression from one data type to another data type

SELECT Location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths$
--WHERE Location LIKE '%states'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

--NB:
-- This method kind of gives you the accurate result if you want to break it down to continent
-- We use where continent is null because if you check in the excel sheet, the locations has the names of the continent in them, 
-- instead of the names of the countries.
-- And we will also use this query for now for the sake of visualization.

SELECT Location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths$
--WHERE Location LIKE '%states'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

SELECT Location, MAX(total_cases) AS TotalCaseCount
FROM CovidDeaths$
--WHERE Location LIKE '%states'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalCaseCount DESC;

-- GLOBAL NUMBERS

SELECT Date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths$
--WHERE Location LIKE '%states'
WHERE continent IS NOT NULL
GROUP BY Date
ORDER BY 1, 2;

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths$
--WHERE Location LIKE '%states'
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- ASSESSING VACCINATION DATA
SELECT *
FROM CovidVaccinations$;

-- JOINING THE TWO TABLES TOGETHER FOR VIEW
SELECT *
FROM CovidDeaths$ death
JOIN CovidVaccinations$ vacc
	ON death.location = vacc.location
	AND death.date =vacc.date;

-- LOOKING AT THE TOTAL POPULATION VS VACCINATIONS
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- NB
--	PARTITION BY divides the query result set into partitions. The window funtion is applied to each partition seperately and computation restarts for each
-- partition.if PARTITION BY is not specified, the function treats all rows of the query result set as a single partition.

SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations, SUM(CAST(vacc.new_vaccinations AS bigint)) OVER 
(PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM  CovidDeaths$ death
JOIN CovidVaccinations$ vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3;

-- Getting the percentage of RollingPeopleVaccinated for each location

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVacc (Continent, Location, Date, Population, New_vaccination, RollingPeopleVaccinated)
AS
(
SELECT death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(CAST(vacc.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM  CovidDeaths$ death
JOIN CovidVaccinations$ vacc
	ON death.location = vacc.location
	AND death.date = vacc.date
WHERE death.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population) * 100 AS RollingPeopleVaccinatedPercentage
FROM PopvsVacc;

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS  #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM  CovidDeaths$ death
JOIN CovidVaccinations$ vac
	ON death.location = vac.location
	AND death.date = vac.date
--WHERE death.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population) * 100 AS PercentRollingPeopleVaccinated
FROM #PercentPopulationVaccinated;

-- CREATING VIEW TO STORE DATA FOR DATA VISUALIZATION
CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) OVER 
(PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM  CovidDeaths$ death
JOIN CovidVaccinations$ vac
	ON death.location = vac.location
	AND death.date = vac.date
WHERE death.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated;
