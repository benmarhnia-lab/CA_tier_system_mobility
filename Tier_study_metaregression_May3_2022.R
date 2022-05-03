
install.packages("sf")
install.packages("raster")
install.packages("rgdal")
install.packages("sp")
install.packages("ggmap")
install.packages("summ")
install.packages("unionSpatialPolygons")
install.packages("join")
install.packages("ggplot2")
install.packages("jtools")
install.packages("ggstance")
install.packages("stringr")
install.packages("metafor")
install.packages("broom.mixed")
install.packages("sjPlot")
install.packages("svglite")
library(coefplot)
library(sjPlot)
library(svglite)
library(sf)
library(unionSpatialPolygons)
library(dplyr)
library(ggplot2)
library(ggmap)
library(join)
library(broom)
library(grid.arrange)
library(ggpubr)
library(haven)
library(jtools)
library(stringr)
library(metafor)
library(broom.mixed)
### California Tier System Evaluation study
### Code 2: Meta-regression of mobility results and Maps/Figures
### Version: May 3rd, 2022

## set working directory where files are stored
setwd("D:/Lara/") 

## import shapefile for California counties
california_counties <-  st_read("D:/Lara/CA_tier_study/Map/California shapefile/California_ZCTAS", quiet = TRUE)
plot(california_counties)

## Import results of analysis conducted in STATA looking at mobility
Mobility_tier_higher_byCounty <- read.csv("./CA_tier_study/Results/Mobility_tier_higher_byCounty.csv")
Mobility_tier_lower_byCounty <- read.csv("./CA_tier_study/Results/Mobility_tier_lower_byCounty.csv")

# Renaming results files
data_higher <- left_join(california_counties, Mobility_tier_higher_byCounty, by=c("NAME"= "County"), all=TRUE)
data_lower <- left_join(california_counties, Mobility_tier_lower_byCounty, by=c("NAME"= "county"), all=TRUE)

# Import California Healthy Places Index 
# Data downloaded from https://map.healthyplacesindex.org/
HPI2_MasterFile_2021.11.03 <- read.csv("D:/Lara/CA_tier_study/Updated_analysis_march2022/Data/HPI2_MasterFile_2021-11-03.csv")
 CA_HPI_bycounty_educ <-HPI2_MasterFile_2021.11.03  %>%                                           # Weighted mean by group
  group_by(County_Name) %>% 
  summarise(weighted.mean(education, pop2010, na.rm = TRUE)) 
 
 CA_HPI_bycounty_educ$educ<-CA_HPI_bycounty_educ$`weighted.mean(education, pop2010, na.rm = TRUE)`
 CA_HPI_bycounty_educ<-select(CA_HPI_bycounty_educ, -2)
 
 CA_HPI_bycounty_economic <-HPI2_MasterFile_2021.11.03  %>%                                           # Weighted mean by group
   group_by(County_Name) %>% 
   summarise(weighted.mean(economic, pop2010, na.rm = TRUE)) 
 
 CA_HPI_bycounty_economic$econ<-CA_HPI_bycounty_economic$`weighted.mean(economic, pop2010, na.rm = TRUE)`
 CA_HPI_bycounty_economic<-select(CA_HPI_bycounty_economic, -2)
 
 
 CA_HPI_bycounty_social <-HPI2_MasterFile_2021.11.03  %>%                                           # Weighted mean by group
   group_by(County_Name) %>% 
   summarise(weighted.mean(social, pop2010, na.rm = TRUE)) 
 
 CA_HPI_bycounty_social$social<-CA_HPI_bycounty_social$`weighted.mean(social, pop2010, na.rm = TRUE)`
 CA_HPI_bycounty_social<-select(CA_HPI_bycounty_social, -2)
 
 
CA_HPI_bycounty_employ <-HPI2_MasterFile_2021.11.03  %>%                                           # Weighted mean by group
   group_by(County_Name) %>% 
   summarise(weighted.mean(employed, pop2010, na.rm = TRUE)) 
 
 CA_HPI_bycounty_employ$employ<-CA_HPI_bycounty_employ$`weighted.mean(employed, pop2010, na.rm = TRUE)`
 
 CA_HPI_bycounty_employ<-select(CA_HPI_bycounty_employ, -2)
 
 Age65plus_byCounty <- read.csv("D:/Lara/CA_tier_study/census_data/Age65plus_byCounty.csv")

 
# Map of mobility
  ggplot(data_higher)+
  geom_sf(aes(fill= coef))+
  xlab("Longitude") + ylab("Latitude") +
  scale_fill_gradient(low= "#56B1F7", high = "#132B43")+
  ggtitle("California Mobility")
  
  
  ## To make background blank in map:
  #theme(panel.background = element_rect(fill = "transparent", colour = NA)) +
  
  require(gridExtra)
  plot1 <- ggplot(data_higher)+
    geom_sf(aes(fill= coef))+
    labs(fill="Persons/100")+
    xlab("Longitude") + ylab("Latitude") +
    ggtitle("More Restrictive Tier")+
    scale_fill_gradient2(low = "darkblue",
                         mid = "wheat",
                         midpoint = 0, na.value = "gray95")+
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
  
  # low= "#56B1F7", high =  "darkblue", na.value = "gray95", trans="reverse")+
  
  plot2 <- ggplot(data_lower)+
    geom_sf(aes(fill= coef))+
    labs(fill="Persons/100")+
    xlab("Longitude") + ylab("Latitude") +
    scale_fill_gradient2(low = "darkblue",
                        mid = "Wheat",
                        high = "firebrick4",
                        midpoint = 0, na.value = "gray95") +
    theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())+
    ggtitle("Less Restrictive Tier") 
    
  
  grid.arrange(plot1, plot2, nrow=2)
  
  plot3<- ggarrange(plot1, plot2, ncol = 1, labels = c("a)","b)"))
  
  annotate_figure(plot3, top = text_grob("Change in Population not staying at home", face = "bold", size = 14))

## forest plot
  
  res_trips_tier_lower <- read_stata("./CA_tier_study/Code/res_trips_tier_lower.dta")
  res_trips_tier_higher <- read_stata("./CA_tier_study/Code/res_trips_tier_higher.dta")

    
    order<-c("<1", "1-3", "3-5", "5-10", "10-25", "25-50", "50-100", "100-250", "250-500", ">500")
    
  fp1 <-  ggplot(res_trips_tier_lower, aes(x = coef, y = trip)) + 
      geom_vline(aes(xintercept = 0), size = .25, linetype = "dashed") + 
      geom_errorbarh(aes(xmax = ci_upper, xmin = ci_lower), size = 0.2 , height =.2, color = "gray50") +
      geom_point(size = 2.5, color = "darkblue") +
      theme_bw() +
      theme(panel.grid.minor = element_blank()) +
      ylab("Distance of trip (miles)") +
      xlab("Change in trips/100 persons")+
    scale_x_continuous(name="Change in trips/100 persons", limits=c(-6, 10)) +
    scale_y_discrete(limits = order)+
      ggtitle("Less Restrictive Tier")
  
  fp2 <-  ggplot(res_trips_tier_higher, aes(x = coef, y = trip)) + 
    geom_vline(aes(xintercept = 0), size = .25, linetype = "dashed") + 
    geom_errorbarh(aes(xmax = ci_upper, xmin = ci_lower), size = 0.2 , height =.2, color = "gray50") +
    geom_point(size = 2.5, color = "firebrick4") +
    theme_bw() +
    theme(panel.grid.minor = element_blank()) +
    ylab("Distance of trip (miles)") +
    xlab("Change in trips/100 persons")+
    scale_y_discrete(limits = order)+
    scale_x_continuous(name="Change in trips/100 persons", limits=c(-27, 5)) +
    ggtitle("More Restrictive Tier")
  
  grid.arrange(fp1, fp2)
  
  
  ## election voting Yes
  
  mob_tier_higher_byCOunty <- Mobility_tier_higher_byCounty
  
  
  mob_tier_higher_byCOunty <- Mobility_tier_higher_byCounty[which(Mobility_tier_higher_byCounty$coef!="NA"), ]
  
  ## for figure- manually changed labels to 0.15 more (less in negative direction) to be right above point.
  
  #    stat_smooth(method = "loess",  color="red", size = 1)+

  
  ggplot(mob_tier_higher_byCOunty, aes(x=Yes, y=coef)) + 
    geom_point() + 
    geom_smooth(method=lm , color="red", se=TRUE) +
        geom_label(label="Kern", 
               x=58.0,
               y=-5.8528448,
               label.size = 0.02,
               color = "black") +
    geom_label(label="Sacramento", 
               x=37.0,
               y=	-5.7387262,
               label.size = 0.02,
               color = "black") +
    geom_label(label="Riverside", 
               x=49.0,
               y=	-2.8488859, 
               label.size = 0.02,
               color = "black") +
    geom_label(label="San Diego", 
               x=42.0,
               y=-6.4054748,
               label.size = 0.02,
               color = "black") +
    
    geom_label(label="San Francisco", 
               x=14.0,
               y=	-2.5553745,
               label.size = 0.02,
               color = "black") +
    
    geom_label(label="Modoc", 
               x=78.0,
               y= -2.1120885,
               label.size = 0.02,
               color = "black") +
    geom_label(label="Marin", 
               x=16.0,
               y=-7.1373142,
               label.size = 0.02,
               color = "black") +
    xlab("Percentage of County voted Yes") +
    ylab("Change in mobility (population not staying at home)")
  
 
## Merging HPI data with results of Tier system change
  
  mob_tier_higher_byCOunty$County_Name<- mob_tier_higher_byCOunty$County
  
  mob_tier_higher_byCOunty <- merge( mob_tier_higher_byCOunty, CA_HPI_bycounty_economic, by="County_Name")  
  mob_tier_higher_byCOunty <- merge( mob_tier_higher_byCOunty, CA_HPI_bycounty_educ, by="County_Name")  
  mob_tier_higher_byCOunty <- merge( mob_tier_higher_byCOunty, CA_HPI_bycounty_social, by="County_Name")  
  mob_tier_higher_byCOunty <- merge( mob_tier_higher_byCOunty, CA_HPI_bycounty_employ, by="County_Name")  
  mob_tier_higher_byCOunty <- merge( mob_tier_higher_byCOunty, Age65plus_byCounty, by="County_Name", all.x  = TRUE)  
  
## meta regression of coefficients to demographic characteristics 

mob_tier_higher_byCOunty$PerMillion<-(mob_tier_higher_byCOunty$GrossDomesticProduct2018/1000000000)
mob_tier_higher_byCOunty$VotedYes<-(mob_tier_higher_byCOunty$Yes)
mob_tier_higher_byCOunty$Per10000<-(mob_tier_higher_byCOunty$medianincome/10000)
mob_tier_higher_byCOunty$Economic<-(mob_tier_higher_byCOunty$econ)
mob_tier_higher_byCOunty$Social<-(mob_tier_higher_byCOunty$social)
mob_tier_higher_byCOunty$Education<-(mob_tier_higher_byCOunty$educ)
mob_tier_higher_byCOunty$Age65over<-(mob_tier_higher_byCOunty$age65over)
mob_tier_higher_byCOunty$Per1000<-(mob_tier_higher_byCOunty$farmsper1000)

## for easier interpretation of results

mob_tier_higher_byCOunty$coef<-(mob_tier_higher_byCOunty$coef)*(-1)


IQR(mob_tier_higher_byCOunty$PerMillion)
IQR(mob_tier_higher_byCOunty$VotedYes)
IQR(mob_tier_higher_byCOunty$Per10000, na.rm=TRUE)
IQR(mob_tier_higher_byCOunty$Economic)
IQR(mob_tier_higher_byCOunty$Social)
IQR(mob_tier_higher_byCOunty$Education)
IQR(mob_tier_higher_byCOunty$Age65over, na.rm=TRUE)
IQR(mob_tier_higher_byCOunty$Per1000)

mob_tier_higher_byCOunty$PerMillion<-mob_tier_higher_byCOunty$PerMillion/IQR(mob_tier_higher_byCOunty$PerMillion)
mob_tier_higher_byCOunty$VotingYes<-mob_tier_higher_byCOunty$VotedYes/IQR(mob_tier_higher_byCOunty$VotedYes)
mob_tier_higher_byCOunty$Per10000<-mob_tier_higher_byCOunty$Per10000/IQR(mob_tier_higher_byCOunty$Per10000, na.rm=TRUE)
mob_tier_higher_byCOunty$Economic<-mob_tier_higher_byCOunty$Economic/IQR(mob_tier_higher_byCOunty$Economic)
mob_tier_higher_byCOunty$Social<-mob_tier_higher_byCOunty$Social/IQR(mob_tier_higher_byCOunty$Social)
mob_tier_higher_byCOunty$Education<-mob_tier_higher_byCOunty$Education/IQR(mob_tier_higher_byCOunty$Education)
mob_tier_higher_byCOunty$Age65over<-mob_tier_higher_byCOunty$Age65over/IQR(mob_tier_higher_byCOunty$Age65over, na.rm=TRUE)
mob_tier_higher_byCOunty$Per1000<-mob_tier_higher_byCOunty$Per1000/IQR(mob_tier_higher_byCOunty$Per1000)


reg_income <- rma(yi = coef, vi = stderr , mods = ~ Per10000, data = mob_tier_higher_byCOunty)
reg_GDP <- rma(yi = coef, vi = stderr , mods = ~ PerMillion, data = mob_tier_higher_byCOunty)
reg_recall <- rma(yi = coef, vi = stderr , mods = ~ VotingYes, data = mob_tier_higher_byCOunty)
reg_HPI_econ <- rma(yi = coef, vi = stderr , mods = ~ Economic, data = mob_tier_higher_byCOunty)
reg_HPI_social <- rma(yi = coef, vi = stderr , mods = ~ Social, data = mob_tier_higher_byCOunty)
reg_HPI_educ <- rma(yi = coef, vi = stderr , mods = ~ Education, data = mob_tier_higher_byCOunty)
age65 <- rma(yi = coef, vi = stderr , mods = ~ Age65over, data = mob_tier_higher_byCOunty)
reg_farms <- rma(yi = coef, vi = stderr , mods = ~ Per1000, data = mob_tier_higher_byCOunty)


## Figure of meta-regression results
p<-plot_summs(reg_recall, reg_income, reg_HPI_econ, reg_HPI_social, reg_HPI_educ, reg_GDP, reg_farms, age65,model.names = c("Gov Recall", "Median income", "Economic", "Social", "Education", "GDP",  "Farming", "Age"),  colors = "Paired",  omit.coefs = "intercept", scale="TRUE")
p <- p + ggtitle("Mobility decrease from tier restriction") 
p

ggsave(file="D:/Lara/CA_tier_study/Results/mobility_decrease.svg", plot=p, width=8, height=8)

saveRDS(p, file = "mobility_change.rds")

save(mob_tier_higher_byCOunty, file = "Mobility_data.RData")
