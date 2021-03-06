##### Sensitivity analysis Graphs with Slider #####
#### Nebi Yesilekin #####
### Before starting folder structure should be like this ### 
###D:\\Workdata\\Ethiopia\\ETH_MZ_fen_tot\\ETH_MZ_Belg_fen_tot                
###�--ETH_MZ_belg_fen_tot_0                          
###�   �--Maize_irrig_belg_S_season_fen_tot_0        
###�   �--Maize_rf_0N_belg_S_season_fen_tot_0        
###�   �--Maize_rf_highN_belg_S_season_fen_tot_0     
###�   �--Maize_rf_lowN_belg_S_season_fen_tot_0      
###�--ETH_MZ_belg_fen_tot_100                        
###�   �--Maize_irrig_belg_S_season_fen_tot_100      
###�   �--Maize_rf_0N_belg_S_season_fen_tot_100      
###�   �--Maize_rf_highN_belg_S_season_fen_tot_100   
###�   �--Maize_rf_lowN_belg_S_season_fen_tot_100    
###�--ETH_MZ_belg_fen_tot_25                         
###�   �--Maize_irrig_belg_S_season_fen_tot_25       
###�   �--Maize_rf_0N_belg_S_season_fen_tot_25       
###�   �--Maize_rf_highN_belg_S_season_fen_tot_25    
###�   �--Maize_rf_lowN_belg_S_season_fen_tot_25     
###�--ETH_MZ_belg_fen_tot_50                         
###    �--Maize_irrig_belg_S_season_fen_tot_50       
###    �--Maize_rf_0N_belg_S_season_fen_tot_50       
###    �--Maize_rf_highN_belg_S_season_fen_tot_50    
###    �--Maize_rf_lowN_belg_S_season_fen_tot_50     


#### this script help us to create csv files for each management and 
#####       a weighted average for all managements 
### Example output files 
##### Maize_irrig_belg_S_season_fen_tot_50.csv for irrigated management       
####  Maize_rf-0N_belg_S_season_fen_tot_50.csv    for rainfed low input management
####  Maize_rf-highN_belg_S_season_fen_tot_50.csv    for rainfed high input management
####  Maize_rf-lowN_belg_S_season_fen_tot_50.csv   for rainfed low input management
####  Maize_belg_S_season_fen_tot_50.csv for weighted average between all managements



rm(list=ls())
#rm(list=setdiff(ls(), c("Workdir", "Outdir"))) #remove everthing except workdir and outdir
library(plotly)
library(gapminder)
library(stringr)
library(sf)
library(maps)
library(data.table)
library(rgdal)
library(ggplot2)
library(rnaturalearth)
library(raster)
library(gtools)
library(tidyverse)


Workdir <-"D:\\Workdata\\Ethiopia\\Sensitivity_Runs_NewPdatzones\\ETH_ALL_MZ\\ETH_MZ_fen_tot\\ETH_MZ_Meher_fen_tot"
setwd(Workdir)

## creating new output folder automatically in the one upper level of working directory 
outputfname <- "ETH_fen_tot_test_Kelem3"
Outdir1 <- dir.create(file.path(dirname(dirname(Workdir)), outputfname), suppressWarnings(dirname))
Outdir <- file.path(dirname(dirname(Workdir)), outputfname)

## or you can create specific output folder below
Outdir <- "D:\\Workdata\\Ethiopia\\Sensitivity_Runs_NewPdatzones\\ETH_ALL_MZ\\Test2"
####getting aggregated average for each sell


###ISO3 country name 
cntry <- as.character("Ethiopia")

## inputs ### 
nyears <- 34 #####number of years in seasonal analysis

## filtering years, choosing year range 
frstyear <- 1984
lstyear <- 2017
range <- as.character(seq(frstyear, lstyear,1))

#### defining a polygon to clip out 
poly <- "D:\\Workdata\\Ethiopia\\GADM\\Oramia_poly.shp"
poly2 <- st_read(poly)

poly3 <- as_Spatial(poly2)


#### long season special calculation for HDAT average for meher season in Ethiopia ###
lseason <- "meher"
lseasonth <- 135 ### earliest planting date in meher season. 

###Choosing mainfolder Management types only rainfed or only irrigated
#### 1: irrigated 2: rainfed 0N  3: rainfed highN  4: rainfed lowN c(1,2,3,4)
###mainfolder <- mainfolder[][c(1,2,3,4)]



parent <- basename(Workdir)
firstup <- function(x) {
  substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  x
}
parentname <- firstup(unlist(strsplit(parent, "_", fixed = TRUE))[3]) ### 3 season name
parentfolder <- dir()
#####Choosing Parent Folders ####
#parentfolder[][c(1,2,3,4,5,6,7,8)]
numpar <- length(parentfolder)
resultssens <- c()
for (j in 1:numpar){
#Locations each parent folders
kc <- paste0(Workdir, "\\", parentfolder[j])
kc
list.dirs(kc)
main <- list.dirs(kc)[1]
split_path <- function(x) if (dirname(x)==x) x else c(basename(x),split_path(dirname(x)))
main <- split_path(main)[1]
main
# counting number of first folders
mainfolder<-dir(kc)
mainfolder
###Choosing mainfolder Management types only rainfed or only irrigated
#### 1: irrigated 2: rainfed 0N  3: rainfed highN  4: rainfed lowN c(1,2,3,4)
mainfolder <- mainfolder[][c(1,2,3,4)]
mainfoldername <- unlist(strsplit(mainfolder, "_", fixed = TRUE))[1] ###Crop name 
#mainfolder <- mainfolder [sapply(mainfolder, function(x) length(list.files(x))>0)]
#mainfolder
number3 <- length(mainfolder)


results3 <- c()
result<-c()
resultsw <- c()
for (k in 1:number3) {
  klm <- c()
  #matrix for reading csv colums
  cd <-paste0(kc, '\\', mainfolder[k])
  cd
  filename <- dir(cd)
  filename
  csvpath <- paste0(cd,'\\', filename)
  print(csvpath)
  content <- read.csv(csvpath, header = T, sep = ',', row.names = NULL)
  if(grepl("row.names", colnames(content)[1])==TRUE){
    colnames(content) <-c(colnames(content)[-1], NULL)
  }else{
    
  }
  content <-content[,1:(length(content)-1)]
  
  ### choosing single year #### 
  ##grabbing years from SDAT
  years <- seq(frstyear, frstyear+max(content[,"RUNNO"])-1,1)

  if(!length(grep(paste(range,collapse="|"), gsub(".{3}$", "", content[,"HDAT"])))==0){
    rowsofyears <- grep(paste(range,collapse="|"), gsub(".{3}$", "", content[,"HDAT"]))
    content <- content[][rowsofyears,]
  }else{
    
  }
 
  
  ### spatial querry #####
  ### this part helps us to clip area of interest
  content <- st_as_sf(content, coords =c("LONGITUDE", "LATITUDE"), crs = 4326)
  content <- st_intersection(content, st_set_crs(st_as_sf(as(poly3, "SpatialPolygons")), st_crs(content)))

  
  
  content <- content %>%
    mutate( LONGITUDE= unlist(map(content$geometry,1)),
            LATITUDE = unlist(map(content$geometry,2)))

  content<- content%>%
  select(LATITUDE, LONGITUDE, everything())
  
  
  content <- st_set_geometry(content,NULL)

#####excluding rows with unwanted years for analysis ####
#### examples for excluding year of 2019 
  ##if(!length(grep("2019", gsub(".{3}$", "", content[,"SDAT"])))==0){
##  rowsof2019 <- grep("2019", gsub(".{3}$", "", content[,"SDAT"]))
##  content <- content[-rowsof2019,]
##}else{
##    
##}
  
  
  ## change all -99 to NA 
  content[,"HWAM"][content[,"HWAM"]== -99] <- NA
  
    
## grep application, crop, managements name here 
  
  cropname <- unlist(strsplit(as.character(content[1,"RUN_NAME"]),"_", fixed=TRUE))[1]
  mngname <- unlist(strsplit(as.character(content[1,"RUN_NAME"]),"_", fixed=TRUE))[2]
  sname <- unlist(strsplit(as.character(content[1,"RUN_NAME"]),"_", fixed=TRUE))[3]
  cname <- unlist(strsplit(as.character(content[1,"RUN_NAME"]),"_", fixed=TRUE))[4]
  sensappname <- unlist(strsplit(as.character(content[1,"RUN_NAME"]),"_", fixed=TRUE))[5]
  offsetn <- unlist(strsplit(as.character(content[1,"RUN_NAME"]),"_", fixed=TRUE))[6]
  
  ### for meher season hdat 
  if(grepl(lseason, sname)){
     for ( c in 1:nrow(content)){
     if(gsub("^.{4}", "", content[c,"HDAT"])<lseasonth){
     content[c,"HDAT"] <- content[c,"HDAT"]+365
     }
       else{
         next}
     }}else{
       
     }
    
 
  averagecell <- data.frame(aggregate(as.numeric(content[,"LATITUDE"]),by= list(content$LATITUDE, content$LONGITUDE),mean, na.rm=TRUE)[-c(1,2)],  ###Latitude
                            aggregate(as.numeric(content[,"LONGITUDE"]),by= list(content$LATITUDE, content$LONGITUDE),mean, na.rm=TRUE)[-c(1,2)],  ### Longitude
                            aggregate(as.numeric(content[,"HARVEST_AREA"]),by= list(content$LATITUDE, content$LONGITUDE),mean,na.rm=TRUE)[-c(1,2)],   ##Harvest Area each cell 
                
                            aggregate(as.numeric(gsub("^.{4}", "", content[,"SDAT"])),by= list(content$LATITUDE, content$LONGITUDE),mean,na.rm=TRUE)[-c(1,2)],  ###SDAT 
                             
                            aggregate(as.numeric(gsub("^.{4}", "", content[,"PDAT"])),by= list(content$LATITUDE, content$LONGITUDE), mean,na.rm=TRUE)[-c(1,2)], #### PDAT 
                            aggregate(as.numeric(gsub("^.{4}", "", content[,"HDAT"])),by= list(content$LATITUDE, content$LONGITUDE), mean,na.rm=TRUE)[-c(1,2)], #### HDAT 
                            aggregate(as.numeric(content[,"HWAM"]),by= list(content$LATITUDE, content$LONGITUDE),mean,na.rm=TRUE)[-c(1,2)],   ##### HWAM, Average_yield
                            aggregate(as.numeric(content[,"TMAXA"]),by= list(content$LATITUDE, content$LONGITUDE),mean,na.rm=TRUE)[-c(1,2)],    ### TMAXA 
                            aggregate(as.numeric(content[,"TMINA"]),by= list(content$LATITUDE, content$LONGITUDE),mean,na.rm=TRUE)[-c(1,2)],    ###TMINA
                            aggregate(as.numeric(content[,"PRCP"]),by= list(content$LATITUDE, content$LONGITUDE),mean,na.rm=TRUE)[-c(1,2)],      ####PRCP
                            aggregate(as.numeric(gsub("^.{4}", "", content[,"MDAT"])),by= list(content$LATITUDE, content$LONGITUDE), mean,na.rm=TRUE)[-c(1,2)],   ### MDAT
                            aggregate(as.numeric(content[,"CWAM"]),by= list(content$LATITUDE, content$LONGITUDE),mean,na.rm=TRUE)[-c(1,2)],  ###CWAM
                            aggregate(as.numeric(content[,"HWAH"]),by= list(content$LATITUDE, content$LONGITUDE),mean,na.rm=TRUE)[-c(1,2)], ### HWAH 
                            aggregate(as.numeric(content[,"GNAM"]),by= list(content$LATITUDE, content$LONGITUDE),mean,na.rm=TRUE)[-c(1,2)], ###GNAM 
                            aggregate(as.numeric(content[,"CNAM"]),by= list(content$LATITUDE, content$LONGITUDE),mean,na.rm=TRUE)[-c(1,2)], ###CNAM
                            aggregate(as.numeric(content[,"NICM"]),by= list(content$LATITUDE, content$LONGITUDE),mean,na.rm=TRUE)[-c(1,2)], ### NICM
                            aggregate(as.numeric(gsub("^.{4}", "", content[,"EDAT"])),by= list(content$LATITUDE, content$LONGITUDE), mean,na.rm=TRUE)[-c(1,2)], ### EDAT 
                            aggregate(as.numeric(gsub("^.{4}", "", content[,"ADAT"])),by= list(content$LATITUDE, content$LONGITUDE), mean,na.rm=TRUE)[-c(1,2)] ##### ADAT
                            )
  
  
  
  names(averagecell) <- c("LATITUDE", "LONGITUDE", "HARVEST_AREA", "SDAT", "PDAT", 
                          "HDAT", "HWAM", "TMAXA", "TMINA", "PRCP", "MDAT", "CWAM", "HWAH", "GNAM", "CNAM", "NICM","EDAT","ADAT")
 print(nrow(averagecell))
  ###for meher season 
  if(grepl(lseason, sname)){
   for (t in 1:nrow(averagecell)){
     if(averagecell[t,"HDAT"]>365){
       averagecell[t,"HDAT"] <- averagecell[t,"HDAT"] - 365
     }else{
       next
     }
   }}else{
     
   }
   ### getting the results for each management
  resultfiles <- paste0(Outdir, "\\", content[1,"RUN_NAME"], ".csv")
  write.csv(averagecell,resultfiles)
  result <- rbind(result, averagecell)
  print(nrow(result))
  
}
# Create values for harvested area


deneme2 <- data.frame(result$LATITUDE, result$LONGITUDE, result$HARVEST_AREA, result$PDAT*result$HARVEST_AREA, 
                      result$HDAT*result$HARVEST_AREA, result$HWAM*result$HARVEST_AREA, result$TMAXA*result$HARVEST_AREA,
                      result$TMINA*result$HARVEST_AREA, result$PRCP*result$HARVEST_AREA, result$MDAT*result$HARVEST_AREA,
                      result$CWAM*result$HARVEST_AREA, result$HWAH*result$HARVEST_AREA, result$GNAM*result$HARVEST_AREA,
                      result$CNAM*result$HARVEST_AREA,
                      result$NICM*result$HARVEST_AREA, result$EDAT*result$HARVEST_AREA, result$ADAT*result$HARVEST_AREA)
deneme4 <- data.frame(aggregate(list(deneme2$result.HARVEST_AREA, 
                                     deneme2$result.PDAT...result.HARVEST_AREA,
                                     deneme2$result.HDAT...result.HARVEST_AREA,
                                     deneme2$result.HWAM...result.HARVEST_AREA,
                                     deneme2$result.TMAXA...result.HARVEST_AREA,
                                     deneme2$result.TMINA...result.HARVEST_AREA,
                                     deneme2$result.PRCP...result.HARVEST_AREA,
                                     deneme2$result.MDAT...result.HARVEST_AREA,
                                     deneme2$result.CWAM...result.HARVEST_AREA,
                                     deneme2$result.HWAH...result.HARVEST_AREA,
                                     deneme2$result.GNAM...result.HARVEST_AREA,
                                     deneme2$result.CNAM...result.HARVEST_AREA,
                                     deneme2$result.NICM...result.HARVEST_AREA,
                                     deneme2$result.EDAT...result.HARVEST_AREA,
                                     deneme2$result.ADAT...result.HARVEST_AREA), 
                                by=list(deneme2$result.LATITUDE, deneme2$result.LONGITUDE), 
                                FUN=sum))
colnames(deneme4) <- c("LATITUDE", "LONGITUDE", "HARVEST_AREA",
                       "PDAT", "HDAT", "HWAM", "TMAXA", "TMINA", 
                       "PRCP", "MDAT", "CWAM", "HWAH", "GNAM", "CNAM","NICM","EDAT","ADAT")

###Getting weighted average #####
deneme3 <- data.frame(deneme4$LATITUDE, deneme4$LONGITUDE, deneme4$HARVEST_AREA,
                      deneme4$PDAT/deneme4$HARVEST_AREA,
                      deneme4$HDAT/deneme4$HARVEST_AREA,
                      deneme4$HWAM/deneme4$HARVEST_AREA,
                      deneme4$TMAXA/deneme4$HARVEST_AREA,
                      deneme4$TMINA/deneme4$HARVEST_AREA,
                      deneme4$PRCP/deneme4$HARVEST_AREA,
                      deneme4$MDAT/deneme4$HARVEST_AREA,
                      deneme4$CWAM/deneme4$HARVEST_AREA,
                      deneme4$HWAH/deneme4$HARVEST_AREA,
                      deneme4$GNAM/deneme4$HARVEST_AREA,
                      deneme4$CNAM/deneme4$HARVEST_AREA,
                      deneme4$NICM/deneme4$HARVEST_AREA,
                      deneme4$EDAT/deneme4$HARVEST_AREA,
                      deneme4$ADAT/deneme4$HARVEST_AREA)
colnames(deneme3) <- c("LATITUDE", "LONGITUDE", "HARVEST_AREA", "PDAT",
                       "HDAT", "HWAM", "TMAXA", "TMINA", "PRCP","MDAT", "CWAM", "HWAH", "GNAM", "CNAM","NICM",
                       "EDAT","ADAT")
### converting integer for decimal date average ###
deneme3$PDAT <- as.integer(deneme3$PDAT)
deneme3$HDAT <- as.integer(deneme3$HDAT)
deneme3$MDAT <- as.integer(deneme3$MDAT)
deneme3$EDAT <- as.integer(deneme3$EDAT)
deneme3$ADAT <- as.integer(deneme3$ADAT)
deneme3["TOT_PROD"] <- (deneme3$HARVEST_AREA * deneme3$HWAM)/1000
deneme3["TOT_NICM"] <- (deneme3$HARVEST_AREA * deneme3$NICM)
deneme3["VWAM"] <- deneme3$CWAM-deneme3$HWAM   ### 
deneme3["VNAM"] <- deneme3$CNAM-deneme3$GNAM
print(nrow(deneme3))


assign(gsub(" ","", paste("name", j)), deneme3)
##if(!length(name1)==0){
##excl <- data.frame(LATITUDE= c(name1$LATITUDE), LONGITUDE=name1$LONGITUDE)
##deneme3 <- semi_join(deneme3, excl, by = c("LATITUDE", "LONGITUDE"))
##}else{
##  
##}


resultssens <- rbind(resultssens, deneme3)



###Giving mainfolder names to csv files #####
resultsfiles2 <- paste0(Outdir, "\\", paste(unlist(strsplit(as.character(content[1,"RUN_NAME"]),"_", fixed=TRUE))[-2], collapse = "_"), ".csv")
write.csv(deneme3, resultsfiles2)


}


