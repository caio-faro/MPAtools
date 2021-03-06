#' turfeffect
#'
#' @param data A data.frame generated by any of the following functions: richness(), density(), trophic(), fish_biomass(), and fish_size().
#' @param reserve A string
#' @param control A string
#'
#' @return An object of class "lm"
#'
#' @export

turfeffect <- function (data, reserve, control){

  library(dplyr)
  library(tidyr)

  columnas <- c("Ano", "Zonificacion", "Sitio", "Transecto", "Indicador")

  colnames(data) <- columnas

  data <- filter(data, Sitio == reserve | Sitio == control) %>%
    group_by(Ano, Zonificacion, Sitio) %>%
    summarize(Indicador = mean(Indicador, na.rm = T))

  dummy.data <- data.frame(Ano = data$Ano,
                           Zona = NA,
                           Sitio = data$Sitio,
                           Indicador = data$Indicador)

  dummy.data$Zona[data$Zonificacion == "Pesca"] <- 0
  dummy.data$Zona[data$Zonificacion == "No Pesca"] <- 1

  model <- lm(Indicador ~ Ano * Zona, data = dummy.data)

  return(model)
}
