# COVID data visualisation

Basic visualisation plots of COVID-19 data

## Has the second wave affected the same or different parts of the UK?

See script *area_deaths_ONS.R*.

This script pulls in data taken from the Office for National Statistics (https://tinyurl.com/y7vefxce) on all-cause and COVID-19 deaths broken down by area (England and Wales only). The proportion of COVID-19 deaths is calculated as COVID-19 deaths over all-cause deaths. The impact of the first wave for each region is calculated as the mean proportion of COVID-19 deaths for the first 30 weeks of 2020. Areas are plotted in order of decreasing impact.

If the first and second waves were in different parts of the country then we would expect to see gaps in the top-right of the plot (low deaths in second wave due to saturation in first wave) and bright colours in the bottom right (high deaths in second wave given naive population).

![COVID deaths by area](https://github.com/bobverity/COVID_datavis/blob/master/output/prop_covid_deaths_by_area.png?raw=true)
