
#' Irradiance and its components
#'
#' @return
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
#'   \item Diffuse Horizontal Irradiance (\mjseqn{DHI, W/m^2})
#'   
#' } 
#'     
#' @export
#' @import mathjaxr
#'
# @examples
solar_irradiance <- function() {
  
}