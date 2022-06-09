SELECT *
FROM CovidDeaths

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1, 2

--Total Cases vs Total Deaths (likelihood of dying of Covid by country)
SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) AS deathrate
FROM CovidDeaths
ORDER BY 1, 2

--Total Cases vs Population
SELECT location, date, total_cases, population, ((total_cases/population)*100) AS infectionrate
FROM CovidDeaths
--WHERE location LIKE '%states%'
ORDER BY 1, 2

--Countries with highest infection rates
SELECT location, population, MAX(total_cases) AS MaxInfectionCount, 
	MAX((total_cases/population)*100) AS infectionrate
FROM CovidDeaths
GROUP BY location, population
ORDER BY 4 DESC

--Countries with highest death count
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount 
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC

--Continents with highest death count 
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount 
FROM CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC

--Global counts each day
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as deathrate
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2

--Global count total (up to 2021-4-30)
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as deathrate
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1, 2

--JOINING CovidDeaths and CovidVaccinations tables
SELECT *
FROM CovidDeaths as deaths
JOIN CovidVaccinations as vac 
	on deaths.location = vac.location AND deaths.date = vac.date

--World population vs Vaccinations
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as cumulative_vaccinations
FROM CovidDeaths as deaths
JOIN CovidVaccinations as vac 
	on deaths.location = vac.location AND deaths.date = vac.date
	WHERE deaths.continent is not null
ORDER BY 2, 3

--Creating CTE to include cumulative_vaccinations column
WITH PopvsVac (continent, location, date, population, new_vaccinations, cumulative_vaccinations)
AS
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as cumulative_vaccinations
FROM CovidDeaths as deaths
JOIN CovidVaccinations as vac 
	on deaths.location = vac.location AND deaths.date = vac.date
	WHERE deaths.continent is not null
--ORDER BY 2, 3
)
SELECT *, (cumulative_vaccinations/population)*100
FROM PopvsVac

--TEMP TABLE
DROP table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
cumulative_vaccinations numeric,
)

INSERT into #PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as cumulative_vaccinations
FROM CovidDeaths as deaths
JOIN CovidVaccinations as vac 
	on deaths.location = vac.location AND deaths.date = vac.date
	WHERE deaths.continent is not null
--ORDER BY 2, 3

SELECT *, (cumulative_vaccinations/population)*100 as vac_percentage
FROM #PercentPopulationVaccinated

--Creating views to store data for later visualizations
Create View PercentPopulationVaccinated as
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as cumulative_vaccinations
FROM CovidDeaths as deaths
JOIN CovidVaccinations as vac 
	on deaths.location = vac.location AND deaths.date = vac.date
	WHERE deaths.continent is not null

CREATE View DailyGlobalCounts as
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as deathrate
FROM CovidDeaths
WHERE continent is not null
GROUP BY date
--ORDER BY 1, 2

Create View HighestInfectionRates as
SELECT location, population, MAX(total_cases) AS MaxInfectionCount, 
	MAX((total_cases/population)*100) AS infectionrate
FROM CovidDeaths
GROUP BY location, population
--ORDER BY 4 DESC

CREATE View HighestDeathRates as
SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount 
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
--ORDER BY TotalDeathCount DESC