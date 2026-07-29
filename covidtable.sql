#covid 19 data exploration

select * from coviddeaths_fixed where continent is not null and TRIM(continent) <> '';

select location, date, total_cases, new_cases, total_deaths, population from coviddeaths_fixed 
order by 1,2; 

#percentage of death cases from covid cases
#shows likelihood of dying if you contract covid in the coutry
select location, date, total_cases, total_deaths, 
(total_deaths/total_cases)* 100 as Deathpercentage from coviddeaths_fixed 
where location = 'Singapore' order by 1,2; 

select location, date, total_cases, total_deaths, 
(total_deaths/total_cases)* 100 as Deathpercentage from coviddeaths_fixed 
where location = 'United States' order by 1,2; 

#percentage of population that got covid 
select location, date, population, total_cases, 
(total_cases/population)* 100 as covidpercentage from coviddeaths_fixed 
where location = 'Singapore' order by 1,2; 

#countries with highest covid percentage
select location, population, MAX(total_cases) as highestcases, 
(MAX(total_cases)/population)* 100 as covidpercentage from coviddeaths_fixed 
where continent is not null and TRIM(continent) <> ''
group by Location, Population order by covidpercentage DESC;

#countries with the highest death percentage 
select location, population, MAX(total_deaths) as totaldeaths, 
(MAX(total_deaths)/population)* 100 as deathpercentage from coviddeaths_fixed 
where continent is not null and TRIM(continent) <> ''
group by Location, Population order by deathpercentage DESC;


#continents with highest death count 
SELECT location, MAX(total_deaths) as totaldeathcount from coviddeaths_fixed 
where continent is null or TRIM(continent) = ''
group by location
order by totaldeathcount desc; 

#global numbers
select SUM(new_cases) as total_cases, sum(new_deaths) as total_deaths, 
(sum(new_deaths)/sum(new_cases)) * 100 as deathpercentage from coviddeaths_fixed
where continent is not null and TRIM(continent) <> '';

#total population vs vaccinations 
#shows percentage of population that has recieved covid vaccine 

WITH PopvsVac AS (
    SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
           SUM(vac.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rolling_ppl_vac
    FROM coviddeaths_fixed death 
    JOIN covidvaccinations_fixed vac 
        ON death.location = vac.location AND death.date = vac.date
    WHERE TRIM(death.continent) <> ''
)
SELECT *, (rolling_ppl_vac/population) * 100  as percent_vac FROM PopvsVac ORDER BY location, date; 


#using temp table 
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATE,
    population BIGINT,
    new_vaccinations BIGINT,
    rolling_ppl_vac BIGINT
);

INSERT INTO PercentPopulationVaccinated
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
       SUM(vac.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rolling_ppl_vac
FROM coviddeaths_fixed death 
JOIN covidvaccinations_fixed vac 
    ON death.location = vac.location AND death.date = vac.date
WHERE TRIM(death.continent) <> '';

SELECT *, (rolling_ppl_vac / population) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;

#creating view 
CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent, death.location, death.date, death.population, vac.new_vaccinations, 
       SUM(vac.new_vaccinations) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rolling_ppl_vac
FROM coviddeaths_fixed death 
JOIN covidvaccinations_fixed vac 
    ON death.location = vac.location AND death.date = vac.date
WHERE TRIM(death.continent) <> '';
