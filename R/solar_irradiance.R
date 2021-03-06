#' Irradiance decomposition
#'
#' @param x 
#' @param yday day of a year, integer vector
#' @param GHI Global Horizontal Irradiance from MERRA-2 subset (\mjseqn{GHI, W/m^2})
#' @param zenith Zenith angle, degrees
#' @param beam 
#' @param method 
#' @param zenith_max 
#' @param keep.all 
#' @param verbose 
#'
#' @details 
#' \loadmathjax
#' List or data.frame with estimated following solar geometry variables:
#' \itemize{
#'   \item Extraterrestrial irradiance (\mjseqn{G_e})
#'     \mjsdeqn{G_e = G_{sc}\times\big(1+0.033\cos{(\frac{360n}{365})}\big)}
#'     where: \cr
#'     \mjseqn{G_{sc} = 1360.8W/m^2}, is the solar constant based on the latest 
#'     NASA observation (Kopp and Lean, 2011); \cr
#'     \mjseqn{n - } day of the year. \cr
#'     
#'   \item Clearness index (\mjseqn{k_t})
#'     \mjsdeqn{k_t = \frac{GHI}{G_e\cos{(zenith)}}}
#'     
#'   \item Diffuse fraction (\mjseqn{k_d})
#'      \mjsdeqn{k_d = \begin{cases}
#'          1-0.09k_t & & {k_t < 0.22}\newline
#'          0.9511-0.1604k_t+4.388k_t^2-16.638k_t^3+12.336k_t^4 & & {0.22 \leq k_t \leq 0.8}\newline
#'          0.165& & {k_t > 0.8}
#'          \end{cases}
#'          }
#'          
#'   \item Direct Normal Irradiance (\mjseqn{DNI, W/m^2})
#'      \mjsdeqn{DNI = \frac{(1-k_d)}{\cos{(zenith)}}\times{GHI}}
#'          
#'   \item Diffuse Horizontal Irradiance (\mjseqn{DHI, W/m^2})
#'      \mjsdeqn{DHI = k_d\times{GHI}}
#'     where: \cr
#'     \mjseqn{GHI} - Global Horizontal Irradiance (\mjseqn{GHI, W/m^2}) from MERRA-2 dataset.
#'     \mjsdeqn{GHI = DHI + DNI \times{\cos{(zenith)}}}
#' } 
#'     
#' @return
#' 
#' @export
#' @import mathjaxr
#'
#' @examples
#' NA
ghi_decomposition <- function(x, yday = "yday", GHI = "SWGDN", 
                             zenith = "zenith", beam = "beam",
                             method = 0,
                             zenith_max = 89, keep.all = FALSE, 
                             verbose = getOption("merra2.verbose")) {
  # browser()
  # if (is.null(x)) {
  #   stopifnot(!is.null(yday))
  #   stopifnot(!is.null(GHI))
  #   stopifnot(!is.null(zenith))
  #   x <- data.table(
  #     yday = yday,
  #     GHI = GHI,
  #     zenith = zenith
  #   )
  #   rm(yday, GHI, zenith)
  # }
  stopifnot(!is.null(x[[yday]]))
  stopifnot(!is.null(x[[GHI]]))
  stopifnot(!is.null(x[[zenith]]))
  if (verbose) cat("   DNI and DHI decomposition\n")
  zz <- x[[zenith]] <= zenith_max # avoiding excessive values at horizon
  if (!is.null(x[[beam]])) zz <- zz & x[[beam]]
  # the solar constant
  Gsc <- 1360.8
  # Extraterrestrial irradiance
  Ge <- (1 + 0.033 * cos(360 * x[[yday]] / 365)) * Gsc
  # Clearness index
  cos.zenith <- cosd(x[[zenith]])
  k.t <- x[[GHI]] / Ge / cos.zenith
  k.t[!zz] <- 0
  k.t[k.t < 0] <- 0
  k.t[k.t > 1] <- 1
  # Diffuse fraction 
  k.d <- rep(0, nrow(x))
  if (method == 1 || grepl("Erbs", method, ignore.case = TRUE)) {
    ## Erbs model
    ii <- k.t >= 0 & k.t < 0.22
    k.d[ii] <- 1 - 0.09 * k.t[ii]
    ii <- k.t <= 0.8 & k.t >= 0.22
    k.d[ii] <- 0.9511 - 0.1604 * k.t[ii] + 4.388 * k.t[ii]^2 -
      16.638 * k.t[ii]^3 + 12.336 * k.t[ii]^4
    ii <- k.t > 0.8
    k.d[ii] <-  0.165
  } else if (method == 2 || grepl("Orgill", method, ignore.case = TRUE)) {
    # ...
  } else if (method == 3 || grepl("Reindl[|.]1", method, ignore.case = TRUE)) {
    # ...
  } else if (method == 4 || grepl("Reindl[|.]2", method, ignore.case = TRUE)) {
    ## Reindl et al. Decomposition Model 2
    ii <- k.t >= 0 & k.t <= 0.3
    k.d[ii] <- 1.02 - 0.254 * k.t[ii] + 0.0123 * cos.zenith[ii]
    ii <- k.t < 0.78 & k.t > 0.3
    k.d[ii] <- 1.4 - 1.749 * k.t[ii] + 0.177 * cos.zenith[ii]
    ii <- k.t >= 0.78
    k.d[ii] <-  0.486 * k.t[ii] - 0.182 * cos.zenith[ii]
  } else if (method == 0 || grepl("Combined", method, ignore.case = TRUE)) {
    ## Reindl et al. Decomposition Model 2 with adjusted limits from other models
    ii <- k.t >= 0 & k.t <= 0.22
    # k.d[ii] <- 1.02 - 0.254 * k.t[ii] + 0.0123 * cos.zenith[ii]
    k.d[ii] <- 1
    ii <- k.t > 0.22
    k.d[ii] <- 1.4 - 1.749 * k.t[ii] + 0.177 * cos.zenith[ii]
    k.d[k.d < 0.17] <- 0.17 # 0.147...0.177
  } else {
    stop("Unknown method")
  }
  k.d[k.d > 1] <- 1
  k.d[!zz] <- 1
  #
  # Diffuse Horizontal Irradiance
  DHI <- x[[GHI]] * k.d 
  # Direct Normal Irradiance
  DNI <- rep(0, nrow(x))
  DNI[zz] <- (x[[GHI]][zz] - DHI[zz]) / cosd(x[[zenith]][zz])
  # DNI <- x[[GHI]] * (1 - k.d) / cospi(x$zenith_avr / 180)
  # DNI <- rep(0, nrow(x)); DHI <- DNI
  # DNI[zz] <- x[[GHI]][zz] * (1 - k.d[zz]) / cospi(x[[zenith]][zz] / 180)
  # browser()
  if (keep.all) {
    x$ext_irrad <- Ge
    x$clearness_index <- k.t
    x$diffuse_fraction <- k.d
  }
  x$DNI <- DNI
  x$DHI <- DHI
  return(x)
}


diffuse_fraction <- function(yday, zenith, GHI) {
  # the solar constant
  Gsc <- 1360.8
  # Extraterrestrial irradiance
  Ge <- (1 + 0.033 * cos(360 * yday / 365)) * Gsc
  # Clearness index
  k.t <- GHI / Ge / cosd(zenith)
  # Diffuse fraction
  k.d <- rep(0, nrow(x))
  ii <- k.t > 0 & k.t < 0.22
  k.d[ii] <- 1 - 0.09 * k.t[ii]
  ii <- k.t <= 0.8 & k.t >= 0.22
  k.d[ii] <- 0.9511 - 0.1604 * k.t[ii] + 4.388 * k.t[ii]^2 - 
    16.638 * k.t[ii]^3 + 12.336 * k.t[ii]^4
  ii <- k.t > 0.8
  k.d[ii] <-  0.165
  return(k.d)
}

if (F) {
  # system.time(z1 <- ghi_decomposition(y))
  # system.time(z2 <- diffuse_fraction(y$yday, y$zenith, y$GHI))
  # identical(z1, z2)
  
  z <- ghi_decomposition(y, keep.all = T, zenith_max = 85)
  summary(z$DNI)
  summary(z$DHI)
  summary(z$clearness_index)
  summary(z$diffuse_fraction)
}
