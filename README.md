# COVID data visualisation

Basic visualisation plots of COVID-19 data

## Has the second wave affected the same or different parts of the UK?

See script *area_deaths_ONS.R*.

This script pulls in data taken from the Office for National Statistics (https://tinyurl.com/y7vefxce) on all-cause and COVID-19 deaths broken down by area (England and Wales only). The proportion of COVID-19 deaths is calculated as COVID-19 deaths over all-cause deaths. The impact of the first wave for each region is calculated as the mean proportion of COVID-19 deaths for the first 30 weeks of 2020. Areas are plotted in order of decreasing impact.

If the first and second waves were in different parts of the country then we would expect to see gaps in the top-right of the plot (low deaths in second wave due to saturation in first wave) and bright colours in the bottom right (high deaths in second wave given naive population).

![COVID-19 deaths by area](https://github.com/bobverity/COVID_datavis/blob/master/output/prop_covid_deaths_by_area.png?raw=true)


## Do pre-existing conditions explain the strong\nage-gradient in COVID-19 deaths?

See script *age_conditions.R*.

We know that both age and the presence of certain underlying conditions (such as Diabetes, heart disease) are risk factors for death from COVID-19. But these two things are highly confounded, as people tend to develop more conditions as they age. This script attempts to pull this apart in a very basic way by looking at the age-distribution of deaths in those *without* any pre-existing conditions.

Results indicate that age still plays an important role even in otherwise health individuals.

![Age-distribution of COVID-19 deaths with and without pre-existing conditions](https://github.com/bobverity/COVID_datavis/blob/master/output/age_conditions.png?raw=true)
