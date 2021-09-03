# COVID data visualisation

Basic visualisation plots of COVID-19 data

## Has the second wave affected the same or different parts of the UK?

See script *area_deaths_ONS.R*.

This script pulls in data taken from the Office for National Statistics (https://tinyurl.com/y7vefxce) on all-cause and COVID-19 deaths broken down by area (England and Wales only). The proportion of COVID-19 deaths is calculated as COVID-19 deaths over all-cause deaths. The impact of the first wave for each region is calculated as the mean proportion of COVID-19 deaths for the first 30 weeks of 2020. Areas are plotted in order of decreasing impact.

If the first and second waves were in different parts of the country then we would expect to see gaps in the top-right of the plot (low deaths in second wave due to saturation in first wave) and bright colours in the bottom right (high deaths in second wave given naive population).

![COVID-19 deaths by area](https://github.com/bobverity/COVID_datavis/blob/master/output/prop_covid_deaths_by_area.png?raw=true)


## Do pre-existing conditions explain the strong age-gradient in COVID-19 deaths?

*NB - this is an updated version of plot. For original version see output/age_conditions_v1.png*

See script *age_conditions.R*.

We know that both age and the presence of certain underlying conditions (such as Diabetes, heart disease) are risk factors for death from COVID-19. But these two things are highly confounded, as people tend to develop more conditions as they age. This plot attempts to pull this apart in a very basic way by looking at the age-distribution of deaths in those *without* any pre-existing conditions, compared with those with at least one condition.

Results indicate that age still plays an important role even in otherwise-healthy individuals.

![Age-distribution of COVID-19 deaths with and without pre-existing conditions](https://github.com/bobverity/COVID_datavis/blob/master/output/age_conditions.png?raw=true)

## How does age interact with vaccination to explain trends in cases, hospitalisations and deaths?

Last updated: 03 Sep 2021

See script *age_vaccination.R*.

Currently we are seeing a surge in cases but very low hospitalisations and deaths. Many plots circulating online cite these trends as proof that vaccines work. While I'm sure vaccines do work, it's important to take age into consideration when looking at "big picture" trends like this. We know from previous waves that cases tend to seed in the young and slowly track up through the age groups, causing a very long lag between the initial surge in cases and any downstream deaths. In a highly vaccinated population, this means deaths in the elderly vaccinated due to breakthrough infections will not become apparent immediately.

Caveats:

- Does not account for testing, which is why for instance cases appear so low in first wave
- Some age groups are open in the raw data (e.g. 90+), in which case they are shown on the plot in a 5-year age group
- Subject to all the individual caveats of the datasets listed below (follow links for details)

Vaccination data comes from [UK gov data portal](https://coronavirus.data.gov.uk/details/vaccinations?areaType=nation&areaName=England) (go to heatmap at bottom of page and download as json).

Case data comes from [UK gov data portal](https://coronavirus.data.gov.uk/details/download) (in Supplementary Downloads, by specimin date).

Hospitalisation data comes from [NHS](https://www.england.nhs.uk/statistics/statistical-work-areas/covid-19-hospital-activity/) (first two .xlsx files).

Deaths data comes from [ONS](https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/deaths/datasets/weeklyprovisionalfiguresondeathsregisteredinenglandandwales) (downloaded 2020 and 2021 seperately, then combined).

UK population pyramid comes from [ONS](https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/analysisofpopulationestimatestoolforuk)

![Interaction between vaccination and age](https://github.com/bobverity/COVID_datavis/blob/master/output/age_vaccination.png?raw=true)

