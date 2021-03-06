#' Trace Plots For Hierarchical Bayes Samples
#'
#' Takes a Hierarchical Bayes (Stan) output and produces trace plots
#' of the mean and standard deviation parameters for the distribution
#' from which individual coefficients are sampled.
#' @param fit An object of class \code{"FitChoice"} produced by a call
#'     to \code{FitChoiceModel} with \code{algorithm = "HB-Stan"}.
#' @seealso \url{https://www.displayr.com/convergence-hb-maxdiff/},
#'     \code{\link{FitChoiceModel}} for an example, \code{\link[rstan]{traceplot}},
#' \code{\link{ExtractParameterStats}}, \code{\link{PlotPosteriorIntervals}}
#' @importFrom rstan traceplot
#' @family HB diagnostics
#' @return A \code{ggplot} object that can be further customized using the
#' \code{ggplot2} package.
#' @export
TracePlots <- function(fit)
{
    checkValidFit(fit)

    is.multi.class <- fit$n.classes > 1L
    if (is.multi.class && fit$class.match.fail)
        stop("Traceplots are not available as classes from ",
             "different chains could not be matched.")

    trace.plot <- rstan::traceplot(fit$stan.fit, pars = c('theta', 'sigma'),
                                   inc_warmup = TRUE)
    levels(trace.plot$data$parameter) <- makeLabels(fit, FALSE)
    trace.plot$plot_env <- new.env()
    trace.plot
}

