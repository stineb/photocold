df <- ddf %>% 
  filter(sitename == "US-Ha1")

f_dehardening <- function(temp, param){
  
  xx <- (-1) * temp # * ppfd
  xx <- param["b"] * (xx - param["a"])
  yy <- 1 / (1 + exp(xx))
  return(yy)  
}

f_hardening <- function(temp, param){
  
  xx <- (-1) * temp # * ppfd
  xx <- param["b"] * xx + param["a"]
  yy <- 1 / (1 + exp(xx))
  return(yy)  
}


param_harden <- c("a" = 0, "b" = 0.5)
param_deharden <- c("a" = -50, "b" = 0.1)
level_hard <- 1.0  # start without hardening
gdd <- 0
df$f_stress <- rep(NA, nrow(df))

for (idx in seq(nrow(df))){
  
  ## determine hardening level
  level_hard_new <-  f_hardening(df$tmin[idx], param_harden)
  
  if (level_hard_new < level_hard){
    
    ## entering deeper hardening
    level_hard <- level_hard_new
    
    ## re-start recovery
    gdd <- 0
    
    # print(paste("Hardening to", level_hard, "on", df$date[idx]))
  }
  
  ## accumulate growing degree days (GDD)
  gdd <- gdd + max(0, (df$temp[idx] - 5.0))
  
  ## de-harden based on GDD. f_stress = 1: no stress
  level_hard <- level_hard + (1-level_hard) * f_dehardening(gdd, param_deharden)
  df$f_stress[idx] <- level_hard
}
