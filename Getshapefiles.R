#############################
#get shape file
#############################

rm(list=ls())

#setwd("C:/Users/chu.282.ASC/Dropbox/AfricaAdmin2Estimates/")
setwd("~/Dropbox/AfricaAdmin2Estimates/")

# load packages
packages <- c("foreign","devtools","tidyverse","data.table", "readxl"
              ,"rdhs","DHS.rates","readstata13","SUMMER"
              ,"RCurl","XML", "rvest","httr")
new.packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
#load libraries
suppressMessages(lapply(packages, require, character.only = TRUE))


###get country list
region<-read.csv('./Data/downloadedDhsData/dhsCountryCodes.csv', stringsAsFactors = FALSE)[1:2]

###get iso code for needed countries
iso3<-read.csv('./Data/downloadedDhsData/dhsISO3Codes.csv', stringsAsFactors = FALSE)

for (i in 1:nrow(region)) {
  if (region$Country.Name[i] %in% iso3$Country.Name) { 
    region$ISO3[i] <- iso3$ISO3[iso3$Country.Name==region$Country.Name[i]]
  } else {
    print(region$Country.Name[i])
    region$ISO3[i]<-NA
  }
}
# iso3_missing<-region[is.na(region$iso3),] #check if missing any country

### get admin-2 shapefiles from GADM 'https://gadm.org/download_country_v3.html'
  # current version gadm3.6 @20190927
for (i in 1:nrow(region)) {
  region$url[i]<-paste("https://biogeo.ucdavis.edu/data/gadm3.6/shp/gadm36_",region$ISO3[i],"_shp.zip",sep="")
  region$urlcheck[i]<-url.exists(region$url[i])
  if (url.exists(region$url[i])) {
  basename(region$url[i])
  download.file(region$url[i]
                , destfile=paste("./Data/downloadedShapeFiles/",basename(region$url[i]), sep="")
                #, method="auto", quiet = FALSE, mode = "w"
                )
  } else {
    print(paste("no shape file for",region$Country.Name[i]))
  }
}
#list.files(path="./Data/downloadedShapeFiles/", pattern=".zip")

#only extract shape file for ones with downloaded DHS files
region$country<-gsub("[[:space:]]","",region$Country.Name) #folder names have no space
  region$country[region$Country.Name=="Nigeria (Ondo State)"]<-"NigeriaOndoState"
  region$country[region$Country.Name=="Cote d'Ivoire"]<-"CotedIvoire"
for (i in 1:nrow(region)) {
  region$withDHS[i]<-file.exists(paste("./Data/downloadedDhsData/byCountry/",region$country[i],sep="")) # check if file exists

  if (file.exists(paste("./Data/downloadedDhsData/byCountry/",region$country[i],sep=""))) {
    zipname<-paste("./Data/downloadedShapeFiles/gadm36_",region$ISO3[i],"_shp.zip", sep="")
    outdir<-paste("./Data/downloadedDhsData/byCountry/",region$country[i],"/shapeFiles_gadm",sep="")
    unzip(zipname, exdir=outdir)
  } else {
    print(region$Country.Name[i])
  }
}
  

### get admin 1 from  http://spatialdata.dhsprogram.com/boundaries/  

  Sys.Date() #get date for zip file name
## get survey numbers for DHS
#  svyid<-read.csv(file="~/Dropbox/OSU/Research_IPR/AfricaAdmin2MR/Africa.Admin2.taskassignment.csv", stringsAsFactors = FALSE)
  #set rdhs configurations 
  set_rdhs_config(email = "work@samclark.net"
                  , project = "Admin-2 Small-area Estimates of Child Mortality"
                  , cache_path = "~/Dropbox/AfricaAdmin2Estimates/Data"
                  , config_path = "rdhs.json"
                  , password_prompt=TRUE #password:samclark, unmute this when first running the code to enter password
                  , global = FALSE )
  
  datasets <- get_available_datasets(clear_cache = FALSE)
  svyid<-unique(datasets[!is.na(datasets$SurveyNum),c("CountryName","SurveyNum","SurveyId")])
  length(unique(svyid$CountryName))
  write.csv(svyid,file="./Data/downloadedDhsData/SurveyNum.csv")

  svyid$country<-gsub("[[:space:]]","",svyid$CountryName)
    svyid$country[svyid$CountryName=="Nigeria (Ondo State)"]<-"NigeriaOndoState"
    svyid$country[svyid$CountryName=="Cote d'Ivoire"]<-"CotedIvoire"
  
  #find shape file for ones with DHS data
  for (i in 1:nrow(svyid)) { #
    
    if (file.exists(paste("./Data/downloadedDhsData/byCountry/", 
                          gsub("[[:space:]]","",svyid$country[i]),sep=""))) {
      
        svyjob<-paste0("https://gis.dhsprogram.com/arcgis/rest/services/Tools/DownloadSubnationalData/GPServer/downloadSubNationalBoundaries/submitJob?survey_ids="
                       , svyid$SurveyNum[i], "&spatial_format=shp&result=result_zip", sep="")
        results<- read_html(svyjob) %>% html_nodes("h2") %>% html_text(trim=TRUE)
        jobid<-substr(results,14,32+14)
  
        svyid$zipurl[i]<-paste("https://gis.dhsprogram.com/arcgis/rest/directories/arcgisjobs/tools/downloadsubnationaldata_gpserver/"
                               ,jobid,"/scratch/sdr_subnational_boundaries_2019-09-28.zip",sep="")
        svyid$zipname[i]<-paste("./Data/downloadedShapeFiles/",svyid$SurveyId[i],".zip", sep="") # test path: "~/Dropbox/OSU/Research_IPR/AfricaAdmin2MR/"
    }  else {
      print(paste("country without DHS birth data", svyid$SurveyId[i],svyid$CountryName[i],sep=" - "))
    }
  }
  # download zip files from DHS 
   for (i in 1:nrow(svyid)) { #
     if (!is.na(svyid$zipurl[i])) {
       if(url.exists(svyid$zipurl[i])) {
         #download.file(svyid$zipurl[i], destfile=svyid$zipname[i])
       } 
     } else {
        print(paste("shape file not available", svyid$SurveyId[i],svyid$CountryName[i],sep=" - "))
      }
    }
  
#only extract shape file for ones with downloaded DHS files
  for (i in 1:nrow(svyid)) { #
    svyid$withDHS[i]<-file.exists(paste("./Data/downloadedDhsData/byCountry/",svyid$country[i],sep="")) # check if file exists
    if (file.exists(paste("./Data/downloadedDhsData/byCountry/",svyid$country[i],sep=""))) {
      
      zipname<-paste("./Data/downloadedShapeFiles/",svyid$SurveyId[i],".zip", sep="")
      outdir<-paste("./Data/downloadedDhsData/byCountry/",svyid$country[i],"/shapeFiles_",svyid$SurveyId[i],sep="")
      unzip(zipname, exdir=outdir)
    } else {
      print(paste("no DHS birth data", svyid$SurveyId[i],svyid$CountryName[i],sep=" - "))
    }
  }  
 
  

