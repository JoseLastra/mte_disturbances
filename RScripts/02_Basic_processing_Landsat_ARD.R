# 1.- Cleaning ARD landsat data ----------
##------------------------------------------------------------------------#
## @date 2024-10-15
## @project C:/github/mte_disturbances
## @R version R version 4.3.2 (2023-10-31 ucrt)
## @OS system Windows 10 x64
## @author Jose A. Lastra
## @email jose.lastramunoz@wur.nl | jose.lastra@pucv.cl
##------------------------------------------------------------------------#
# 2.- Libraries --------
pacman::p_load(tidyverse, terra, sf, foreach, doParallel)
## Clean environment ----
rm(list = ls(all = T))

##------------------------------------------------------------------------#
# 3.- General Inputs -----
## Loading and listing raster data from ARD ------
inpath <- 'c:/GLAD_Workspace/ARD/'

### tile folders ----
folder_tiles <- dir(inpath)

### raster files ----
tiles_path <- paste0(inpath, folder_tiles)

raster_ls <- tiles_path %>% 
  lapply(FUN = list.files, pattern = "^.*\\.tif$", full.names = T) %>% 
  lapply(naturalsort::naturalsort)

names(raster_ls) <- folder_tiles

### Values from QF band September 2023 version ----
rm_values <- c(
  0, # no data
  3, # cloud
  4, # cloud shadow 
  7, # haze
  8 # cloud proximity
)

### Bands -----
index_bands <- 1L:8L
band_names <- c('blue', 'green', 'red', 'nir', 'swir1', 'swir2', 'bt', 'qf')


##------------------------------------------------------------------------#
# 4.- loop extraction and clean -----
## looping images -----
for(a in folder_tiles){
  
  raster_files <- raster_ls[a] %>% unlist()
  
  folder_path <- paste0('01_Landsat_ARD/', a, '/')
  
  if(!dir.exists(folder_path)){
    dir.create(path = folder_path)
  }
  
  nCluster <- detectCores() -5
  cl <- makeCluster(nCluster, type = "PSOCK")
  registerDoParallel(cl)
  
  foreach(i = 1:length(raster_files), .packages = c('magrittr', 'terra')) %dopar% {
    
    r <- raster_files[i] %>% rast
    
    r_bands <- r[[1:7]]
    r_qf <- r[[8]]
    
    r_bands[r_qf %in% rm_values] <- NA
    
    r_export <- c(r_bands, r_qf)
    
    outpath <- paste0(folder_path, varnames(r), '_clean_', band_names, '.tif')
    
  
    writeRaster(r_export, filename = outpath, datatype = 'INT2S', overwrite = T)
    
    unlink(raster_files[i])
    
    rm(r, r_bands, r_qf, r_export); gc()
  }
  stopCluster(cl)
  cat('Tile', a, 'ready')
} 
  



  








