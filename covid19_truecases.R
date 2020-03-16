covid19_trucases <- function(start_date = "2020/1/1", B = 1000, laplace = c(0,0.02), file = "us_deaths.csv", death_days = 24, death_days_sd = 4, cft_bound = c(0.008,0.012),days_to_double = 6){

# start_date: how back in time you want to explore -- depends on the case of first death in each country
# B: number of simulations
# laplace: the Laplace smoothing parameters. A number between the two limits is picked uniformly at random and this is the number of confirmed contractions assumed for days with 0 contractions otherwise
# file: the file that has the death counts (see provided file for format)
# death_days: the average number of days between disease contraction and death
# death_days_sd: the standard deviation of the above time
# cft_bound: the bounds of the case fatality rate (cft is chosen uniformly at random from this range)
# days_to_double: days needed to double the number of cases (this depends on various factors - e.g., small for early in the process, large if appropriate measures are taken etc.)

sims = rep(0,B)

for (s in 1:B){
    us_deaths <- read.csv(file)
    us_deaths$Day = as.Date(us_deaths$Day,format="%m/%d/%y")

    contraction = data.frame(Day = seq(as.Date("2020/1/1"), us_deaths[dim(us_deaths)[1],]$Day, "days"), D=rep(0,length(seq(as.Date(start_date), us_deaths[dim(us_deaths)[1],]$Day, "days"))))

    examined = 0
    deaths = round(rnorm(n=us_deaths[dim(us_deaths)[1],]$Deaths_cum,mean = death_days,sd =death_days_sd))

    for (i in 1:dim(us_deaths)[1]){
        if (us_deaths[i,]$Deaths_daily > 0){
            for (j in 1:us_deaths[i,]$Deaths_daily){
                examined = examined + 1
                contraction[which(contraction$Day == us_deaths[i,]$Day-deaths[examined]),]$D = contraction[which(contraction$Day == us_deaths[i,]$Day-deaths[examined]),]$D+1
            }
        }
    }

    cft = runif(1,cft_bound[1],cft_bound[2])

    # days with 0 confirmed contractions still have instances -- Laplace smoothing
    contraction[which(contraction$D == 0),]$D = runif(length(which(contraction$D == 0)), laplace[1], laplace[2])
    contraction$C = contraction$D/cft
    contraction$Tot = cumsum(contraction$C)
    # find the day of the last "confirmed contraction"
    last_conf_cont = max(which(contraction$D > laplace[2]))
    sims[s] = contraction[last_conf_cont,]$Tot*(2^{(dim(contraction)[1]-last_conf_cont)/days_to_double})
 }

 return(sims)

}
