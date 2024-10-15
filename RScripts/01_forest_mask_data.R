# 1.- Summary forest statistics ----------
##------------------------------------------------------------------------#
## @date 2024-10-15
## @project C:/github/mte_disturbances
## @R version R version 4.3.2 (2023-10-31 ucrt)
## @OS system Windows 10 x64
## @author Jose A. Lastra
## @email jose.lastramunoz@wur.nl | jose.lastra@pucv.cl
##------------------------------------------------------------------------#
# 2.- Libraries --------
pacman::p_load(tidyverse, sf)
## Clean environment ----
rm(list = ls(all = T))

##------------------------------------------------------------------------#
# 3.- General Inputs -----
## Vector data ----
### list files per region ----
inpath <- 'C:/PhD_project/Y1/Shp_databases/Catastro_uso_suelo_y_vegetacion/filtered'
escl_ls <- list.files(path = inpath, pattern = glob2rx('*_escl_*.gpkg'), full.names = T)
roble_ls <- list.files(path = inpath, pattern = glob2rx('*_roble_*.gpkg'), full.names = T)

### reading files
escl <- escl_ls %>% lapply(read_sf)
roble <- roble_ls %>% lapply(read_sf)

## Area calculation and filtering -------
## minimum area 3 landsat pixels 0.0009 km2

### Sclerophyllous -----
escl <- escl %>% lapply(FUN = 
                          function(x){
                            x %>% mutate(area_sqkm = as.numeric(st_area(.)/1000000)) %>% 
                              filter(area_sqkm > 0.0009)
                          })
#common_cols <- Reduce(intersect, lapply(escl, colnames))
nombres <- c('CODREG', 'USO', 'area_sqkm')
escl_binded <- escl %>% lapply(FUN = 
                        function(x){
                          x %>% select(all_of(nombres)) %>% 
                            st_transform(32719)
                        }) %>% bind_rows()

escl_binded %>% group_by(CODREG) %>%
  st_drop_geometry() %>% 
  summarise(total = sum(area_sqkm, na.rm = T)) %>% view()

