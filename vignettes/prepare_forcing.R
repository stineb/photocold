## ----setup, include=FALSE---------------------------------------------------------------------------------------------------
library(ingestr)
library(tidyverse)
library(knitr)
library(ingestr)


## ----warning=FALSE, message=FALSE-------------------------------------------------------------------------------------------
df_sites <- read_csv(file = "../data/df_sites.csv")


## ----eval = FALSE-----------------------------------------------------------------------------------------------------------
## # grab fluxnet data ----
## df_fluxnet <-
##   ingestr::ingest(
##     siteinfo  = df_sites,
##     source    = "fluxnet",
##     getvars   = list(
##       temp = "TA_F_DAY",
##       prec = "P_F",
##       vpd  = "VPD_F_DAY",
##       ppfd = "SW_IN_F",
##       patm = "PA_F",
##       tmin = "TMIN_F"),
##     dir       = "~/data/FLUXNET-2015_Tier1/20191024/DD/",
##     settings  = list(
##       dir_hh = "~/data/FLUXNET-2015_Tier1/20191024/HH/", getswc = FALSE),
##     timescale = "d"
##       )


## ----eval = FALSE-----------------------------------------------------------------------------------------------------------
## df_cru <- ingestr::ingest(
##   siteinfo  = df_sites,
##   source    = "cru",
##   getvars   = "ccov",
##   dir       = "~/data/cru/ts_4.01/"
##   )
## 
## saveRDS(df_cru, file = "../data/df_cru.rds")
## 
## df_meteo <- df_fluxnet %>%
##   tidyr::unnest(data) %>%
##   left_join(
##     df_cru %>%
##       tidyr::unnest(data),
##     by = c("sitename", "date")
##   ) %>%
##   group_by(sitename) %>%
##   tidyr::nest()


## ----eval = FALSE-----------------------------------------------------------------------------------------------------------
settings_modis <- get_settings_modis(
  bundle            = "modis_fpar",
  data_path         = "~/data/modis_subsets/",
  method_interpol   = "loess",
  network = c("fluxnet", "icos"),
  keep              = TRUE,
  overwrite_raw     = FALSE,
  overwrite_interpol= TRUE,
  n_focal           = 0
  )

df_modis_fpar <- ingest(
  df_sites,
  source = "modis",
  settings = settings_modis,
  parallel = FALSE,
  ncores = 1
  )

## renaming the variable
df_modis_fpar <- df_modis_fpar %>%
  mutate(
    data = purrr::map(data, ~rename(., fapar = modisvar_filled))
    )

saveRDS(df_modis_fpar, file = "~/photocold/data/df_modis_fpar.rds")


## ----eval = FALSE-----------------------------------------------------------------------------------------------------------
## # . grab CO2 data ----
## df_co2 <- ingestr::ingest(
##   fluxnet_sites,
##   source  = "co2_mlo",
##   verbose = FALSE
##   )


## ----eval = FALSE-----------------------------------------------------------------------------------------------------------
## # . set soil parameters ----
## df_soiltexture <- bind_rows(
##   top    = tibble(
##     layer = "top",
##     fsand = 0.4,
##     fclay = 0.3,
##     forg = 0.1,
##     fgravel = 0.1
##     ),
##   bottom = tibble(
##     layer = "bottom",
##     fsand = 0.4,
##     fclay = 0.3,
##     forg = 0.1,
##     fgravel = 0.1)
## )


## ----eval = FALSE-----------------------------------------------------------------------------------------------------------
## params_siml <- list(
##   spinup             = TRUE,
##   spinupyears        = 10,
##   recycle            = 1,
##   soilmstress        = TRUE,
##   tempstress         = TRUE,
##   calc_aet_fapar_vpd = FALSE,
##   in_ppfd            = TRUE,
##   in_netrad          = FALSE,
##   outdt              = 1,
##   ltre               = FALSE,
##   ltne               = FALSE,
##   ltrd               = FALSE,
##   ltnd               = FALSE,
##   lgr3               = TRUE,
##   lgn3               = FALSE,
##   lgr4               = FALSE
## 	)


## ----eval = FALSE-----------------------------------------------------------------------------------------------------------
## p_model_fluxnet_drivers <- rsofun::collect_drivers_sofun(
##   site_info      = df_sites,
##   params_siml    = params_siml,
##   meteo          = df_meteo,
##   fapar          = df_modis_fpar,
##   co2            = df_co2,
##   params_soil    = df_soiltexture
##   )


## ---------------------------------------------------------------------------------------------------------------------------
# run the model for these parameters
# optimized parameters from previous work (Stocker et al., 2020 GMD)
params_modl <- list(
    kphio           = 0.09423773,
    soilm_par_a     = 0.33349283,
    soilm_par_b     = 1.45602286,
    tau_acclim_tempstress = 10,
    par_shape_tempstress  = 0.0
  )

output <- rsofun::runread_pmodel_f(
  p_model_fluxnet_drivers,
  par = params_modl
  )

output$data[[1]] %>% 
  ggplot(aes(date, gpp)) +
  geom_line()

