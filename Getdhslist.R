
rm(list=ls())
setwd("~/Dropbox/OSU/Research_IPR/AfricaAdmin2MR/")

# load packages
packages <- c("foreign","devtools","tidyverse","data.table", "readxl"
              ,"rdhs","DHS.rates","readstata13","SUMMER"
              ,"RCurl","XML", "rvest","httr")
new.packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
#load libraries
suppressMessages(lapply(packages, require, character.only = TRUE))

# Get available list of DHS datasets using rdhs
set_rdhs_config(email = "work@samclark.net"
                , project = "Admin-2 Small-area Estimates of Child Mortality"
                , cache_path = "~/Dropbox/OSU/Research_IPR/AfricaAdmin2MR/" #C:/Users/chu.282.ASC/Dropbox/AfricaAdmin2Estimates/Data
                , config_path = "rdhs.json"
                 , password_prompt=TRUE #unmute this when first running the code to enter password
                , global = FALSE )

datasets <- get_available_datasets(clear_cache = FALSE)
datasets<-datasets[!is.na(datasets$SurveyId),] # drop missing survey id
surveylist <- unique(datasets$SurveyId)
country_all <- as.data.frame(unique(datasets[,c('CountryName', 'DHS_CountryCode')]))

region<-read.csv('~/Dropbox/OSU/Research_IPR/AfricaAdmin2Estimates/Data/downloadedDhsData/dhsCountryCodes.csv')[,1:2]

'%!in%' <- function(x,y)!('%in%'(x,y))

#flag all African surveys needed for the project
datasets$Africa<-0
for (i in 1:nrow(datasets)) {
  if (datasets$CountryName[i] %in% region$Country.Name) { 
        datasets$Africa[i]<-1
        } 
} 

datasets_Africa<-datasets[datasets$Africa==1 
                          & ( ( datasets$FileFormat=="Stata dataset (.dta)" & datasets$FileType=="Births Recode" )
                          | ( datasets$FileFormat=="Flat ASCII data (.dat)" & datasets$FileType=="Geographic Data" ) )
                          & (datasets$SurveyType=="DHS" ) # | datasets$SurveyType=="MIS"
                          ,] #with . data and birth records
datasets_Africa$avail<-"publicly available"

#save as csv table
write.csv(datasets_Africa,file="~/Dropbox/OSU/Research_IPR/AfricaAdmin2Estimates/Data/downloadedDhsData/SurveyList_BR_GE.csv")

#############################
#download data
#get actual data - rds format
#data_birth<-get_datasets(datasets_Africa$FileName, download_option = "rds") #clear_cache = TRUE

