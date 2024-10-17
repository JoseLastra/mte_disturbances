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
                              filter(area_sqkm > 0.0027)
                          })
#common_cols <- Reduce(intersect, lapply(escl, colnames))
nombres <- c('CODREG', 'USO', 'area_sqkm')
escl_binded <- escl %>% lapply(FUN = 
                        function(x){
                          x %>% select(all_of(nombres)) %>% 
                            st_transform(32719)
                        }) %>% bind_rows()



sorted <- c('04','05', '13', '06', '07', '16', '08', '09', '14', '10')

tot_region_escl <- escl_binded %>% group_by(CODREG) %>%
  st_drop_geometry() %>% 
  summarise(total = round(sum(area_sqkm, na.rm = T),2)) %>% 
  mutate(CODREG = ifelse(is.na(CODREG), '08', CODREG),sort = fct_relevel(CODREG, sorted), type = 'Evergreen')

### nothofagus ----
roble <- roble %>% lapply(FUN = 
                          function(x){
                            x %>% mutate(area_sqkm = as.numeric(st_area(.)/1000000)) %>% 
                              filter(area_sqkm > 0.0027)
                          })
#common_cols <- Reduce(intersect, lapply(escl, colnames))
nombres <- c('CODREG', 'USO', 'area_sqkm')
roble_binded <- roble %>% lapply(FUN = 
                                 function(x){
                                   x %>% select(all_of(nombres)) %>% 
                                     st_transform(32719)
                                 }) %>% bind_rows()

sorted <- c('05', '13', '06', '07')

tot_region_roble <- roble_binded %>% group_by(CODREG) %>%
  st_drop_geometry() %>% 
  summarise(total = round(sum(area_sqkm, na.rm = T),2)) %>% 
  mutate(CODREG = ifelse(is.na(CODREG), '08', CODREG),sort = fct_relevel(CODREG, sorted), type = 'Deciduos')

## Merged dataset -----
### GPKG data ------
roble_binded <- roble_binded %>% mutate(type = 'Deciduous')
escl_binded <- escl_binded %>% mutate(type = 'Evergreen')

total_forest <- roble_binded %>% bind_rows(escl_binded)
write_sf(total_forest, dsn = 'shp/total_forest_CONAF.gpkg')

### DPA filtering ----
total_forest <- read_sf('shp/total_forest_CONAF.gpkg')
dpa_forest <- total_forest %>% filter(CODREG %in% c('05', '06', '07', '13'))
total_area_dpa <- dpa_forest %>% 
  st_drop_geometry %>% 
  group_by(type) %>% 
  summarise(total_sqkm = sum(area_sqkm, na.rm = T))

### Tabular data -----

sorted_full <- c('04','05', '13', '06', '07', '16', '08', '09', '14', '10') %>% rev()

forest_total <- tot_region_escl %>% bind_rows(tot_region_roble) %>% 
  mutate(sort = fct_relevel(sort, sorted_full))

write.csv(forest_total, file = 'tables/forest_totals_per_reg.csv')

labels <- c('Coquimbo', 'Valparaiso', 'Metropolitana', "O'Higgins", 'Maule', 'Ñuble', 'Biobio', 'Araucania', 'Los Ríos', 'Los Lagos') %>% rev()

a <- forest_total %>% ggplot(aes(x = sort, y = total, fill = type)) +
  geom_bar(stat = 'identity', position = 'dodge') +
  scale_fill_manual(values = c('#de5a25', '#279e16')) +
  labs(x = '', 
       y = expression(
         paste('Total Forest [', km^{2}, ']')
       ),
       fill = 'Forest type'
  ) +
  scale_y_continuous(n.breaks = 11) +
  scale_x_discrete(labels = labels) + 
  theme_minimal() +
  theme(axis.text.x = element_text(face = 'bold', colour = 'white', size = 12),
        axis.text.y = element_text(face = 'bold', colour = 'white', size = 12), 
        legend.text = element_text(face = 'bold', colour = 'white', size = 12),
        legend.title = element_text(face = 'bold', colour = 'white', size = 14),
        axis.title.x = element_text(face = 'bold', colour = 'white', size = 12)) +
  coord_flip() 

a

ggsave(a, filename = 'plots/total_forest_area_regions.png', units = 'in', width = 8, height = 10, dpi = 120, bg = 'transparent')
