#' Wind power curve function. Estimates power output based on the speed of wind.
#'
#' @param mps wind speed, meters per second
#' @param cutin minimal speed of production
#' @param cutoff maximum speed of wind
#' @param data data frame or list with two power curve data, columns `speed` and `af`
#'
#' @return estimated capacity factor of a wind turbine
#'
#' @examples
#' fWPC(0:30)
#' plot(0:35, WindPowerCurve(0:35), type = "l", col = "red", lwd = 2)
fWindPowerCurve <- function(mps, cutin = 3, cutoff = 25, data = NULL, ...) {
  # browser()
  if (is.null(data)) {
    data <- data.frame(
      # averaged data from "WindCurves" package
      speed = c(1:25, 30),
      af = c(
        0, 0, 0, 0.017, 0.066, 0.138, 0.235, 0.362, 0.518, 0.688,
        0.84, 0.941, 0.983, 0.995, 0.999, 1, 1, 1, 1, 1, 1, 1, 1,
        1, 1, 1
      )
    )
  }
  f <- approxfun(data$speed, data$af)
  y <- rep(0, length(mps))
  y[is.na(mps)] <- NA
  ii <- mps >= cutin & mps <= cutoff & !is.na(mps)
  y[ii] <- f(mps[ii])
  return(y)
}

#' @rdname fWindPowerCurve
#' @export
fWPC <- fWindPowerCurve

if (F) {
  fWPC(0:30)
  plot(0:35, fWPC(0:35),
    type = "l", col = "red", lwd = 2,
    xlab = "Wind speed, m/s"
  )
}

#' Hellmann function to extrapolate wind speed from 10 and 50 meters to higher altitudes
#'
#' @param W10M wind speed (m/s) at 10 meters altitude
#' @param W50M wind speed (m/s) at 50 meters altitude
#' @param na values to return in the case of NA
#' @param inf values to return instead of infinite
#' @param lo lower limit, zero by default to control negative values
#' @param up lower limit, 0.6 by default to control excessive values
#'
#' @return
#' a numeric vector with estimated Hellmann exponent.
#' @export
#'
#' @seealso \code{\link{fWindSpeedExtrapolation}} (\code{\link{fWSE}}) for wind speed extrapolation
#'
#' @examples
#' fH(5, 10)
fHellmann <- function(W10M, W50M, na = 0, inf = 0, lo = 0, up = 0.6, ...) {
  # checks
  if (length(W10M) > 1 & length(W50M) > 1) {
    stopifnot(length(W50M) == length(W10M))
  }
  stopifnot(length(W10M) > 0)
  stopifnot(length(W50M) > 0)

  h <- log(W50M / W10M) / log(50 / 10)
  h[is.na(h)] <- na
  h[is.infinite(h)] <- inf
  h[h < lo] <- lo
  h[h > up] <- up
  return(h)
}

#' @rdname fHellmann
#' @export
fH <- fHellmann

#' Hellmann-constant-based extrapolation of wind speed for higher altitudes
#'
#' @param m height (in meters) for which wind speed will be estimated;
#' @param W10M wind speed at height of 10 meters (from MERRA2 database);
#' @param hellmann Hellmann exponent (calculated with fHellmann function)
#'
#' @seealso \code{\link{fHellmann}} (\code{\link{fH}}) for estimation of Hellmann exponent
#' @return
#'  a numeric vector of estimated wind speed (m/s) at the \code{m} height (meters).
#' @export
#' @references
#' <https://en.wikipedia.org/wiki/Wind_gradient>
#'
#' @examples
#' h <- fH(5, 7)
#' fWSE(50, 5, h)
#' fWSE(100, 5, h)
#' fWSE(seq(50, 200, 50), 5, h)
fWindSpeedExtrapolation <- function(m, W10M, hellmann) {
  W10M * (m / 10)^hellmann
}

#' @rdname fWindSpeedExtrapolation
#' @export
fWSE <- fWindSpeedExtrapolation

#' Title
#'
#' @param x data frame with MERRA-2 subset
#' @param height height over ground
#' @param mps name of wind speed variable available in `x` or will be extrapolated using `fHellmann` and `fWSE` functions
#' @param return_name name of the variable, which will be added (or overwritten) to `x`
#' @param hellmann name of the variable with Hellmann constant, either available in `x` or will be calculated using `fHellmann` function
#' @param W10M name of the variable with wind speed at 10 meters height
#' @param W50M name of the variable with wind speed at 10 meters height
#' @param WPC name of the wind power capacity function
#' @param verbose if TRUE, the process will be reported
#' @param ... additional parameters for `fHellmann`, `fWSE`, `WPC` functions
#'
#' @return `x` with added (or overwritten) column of wind power capacity factors; the name of the column is given by `return_name` parameter.
#' 
#' @export
#'
#' @examples
#' NA
fWindCF <- function(x, height = 50, 
                    mps = paste0("W", height, "M"),
                    return_name = paste0("win", height, "af"),
                    hellmann = "hellmann", W10M = "W10M", W50M = "W50M",
                    WPC = fWindPowerCurve, #keep.all = TRUE, 
                    verbose = TRUE, ...) {
  # browser()
  if (is.null(x[[mps]])) {
    # Extrapolating wind speed
    stopifnot(!is.null(x[[W10M]]))
    stopifnot(!is.null(x[[W50M]]))
    if (is.null(x[[hellmann]])) {
      # Hellmann constant
      if (verbose) cat("")
      x[[hellmann]] <- fHellmann(W10M = x[[W10M]], W50M = x[[W50M]], ...)
    }
    x[[mps]] <- fWSE(m = height, W10M = x[[W10M]], hellmann = x[[hellmann]])
  }
  # Applying wind power curve
  x[[return_name]] <- WPC(mps = x[[mps]], ...)
  return(x)
}
