Select * from dbo.CovidDeaths
where continent is not null
order by 3,4

/*Select * from dbo.CovidVaccinations
order by 3,4*/

/*Select data to use for the project*/

Select [location],[date],total_cases,new_cases,total_deaths,population
from dbo.CovidDeaths
where continent is not null
order by 1,2

/*Examine total case vs. total deaths*/
/*Likelihood of dying from COVID if contracted in the U.S.*/

Select [location],[date],total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPct
from dbo.CovidDeaths
Where location like '%states%' and continent is not null
order by 1,2

/*Examine the Total cases vs. Population*/
/* What percentage of the population contracted COVID*/

Select [location],[date],population,total_cases, (total_cases/population)*100 as CovidPct
from dbo.CovidDeaths
Where location like '%states%' and continent is not null
order by 1,2

/*What countries have the highest infection rates compared to population?*/

Select [location],[population],MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as CovidPct
from dbo.CovidDeaths
/*Where location like '%states%'*/
where continent is not null
GROUP by [location], population
order by CovidPct desc

/*What countries have the highest death count compared to population?*/

Select [location], MAX(cast(total_deaths as int)) as TotalDeaths
from dbo.CovidDeaths
/*Where location like '%states%'*/
where continent is not null
GROUP by [location]
order by TotalDeaths desc

/*Break down by continent*/

/*Looking at continents with the highest death count per population*/

Select [continent], MAX(cast(total_deaths as int)) as TotalDeaths
from dbo.CovidDeaths
/*Where location like '%states%'*/
where continent is not null
GROUP by [continent]
order by TotalDeaths desc

/*Global metrics*/

Select date,SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPct
from dbo.CovidDeaths
/*Where location like '%states%'*/
Where continent is not null
group by date
order by 1,2

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPct
from dbo.CovidDeaths
/*Where location like '%states%'*/
Where continent is not null
/*group by date*/
order by 1,2

/* Joining the two COVID tables together*/

Select * 
from dbo.CovidVaccinations vac
Join dbo.CovidDeaths death
    on vac.[location] = death.[location]
    and vac.[date] = death.[date]

/*Total population vs. vaccination status*/

Select death.continent, death.location, death.date, death.population, vac.new_vaccinations 
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by death.location Order by death.location, death.date) 
as RollingNumberVaccinated, /*(RollingNumberVaccinated/population)*100*/
from dbo.CovidVaccinations vac
Join dbo.CovidDeaths death
    on vac.[location] = death.[location]
    and vac.[date] = death.[date]
where death.continent is not null
order by 2,3

/*Use CTE */

With PopvsVac (Continent, location, date, population, New_Vaccinations, RollingNumberVaccinated)
AS
(Select death.continent, death.location, death.date, death.population, vac.new_vaccinations 
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by death.location Order by death.location, death.date) 
as RollingNumberVaccinated /*(RollingNumberVaccinated/population)*100*/
from dbo.CovidVaccinations vac
Join dbo.CovidDeaths death
    on vac.[location] = death.[location]
    and vac.[date] = death.[date]
where death.continent is not null
/*order by 2,3 */)

Select *, (RollingNumberVaccinated/population)*100
from PopvsVac

/* Use Temp Table */

/*Drop table if EXISTS #PercentPopulationVaccinated*/

Create Table #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population numeric, 
    new_vaccinations NUMERIC, 
    RollingNumberVaccinated NUMERIC
)

Insert into #PercentPopulationVaccinated
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations 
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by death.location Order by death.location, death.date) 
as RollingNumberVaccinated /*(RollingNumberVaccinated/population)*100*/
from dbo.CovidVaccinations vac
Join dbo.CovidDeaths death
    on vac.[location] = death.[location]
    and vac.[date] = death.[date]
where death.continent is not null
/*order by 2,3 */
Select *, (RollingNumberVaccinated/population)*100
from #PercentPopulationVaccinated

/* Creating a view to store data for Tableau*/

Create VIEW PercentPopulationVaccinated as
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations 
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by death.location Order by death.location, death.date) 
as RollingNumberVaccinated /*(RollingNumberVaccinated/population)*100*/
from dbo.CovidVaccinations vac
Join dbo.CovidDeaths death
    on vac.[location] = death.[location]
    and vac.[date] = death.[date]
where death.continent is not null
/*order by 2,3*/


Select * from PercentPopulationVaccinated