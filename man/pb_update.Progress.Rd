% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/daily_update_utils.R
\name{pb_update.Progress}
\alias{pb_update.Progress}
\title{S3 Progress Method pb_update}
\usage{
\method{pb_update}{Progress}(
  pbar,
  message = NULL,
  inc = NULL,
  set = NULL,
  ...,
  e = rlang::caller_env()
)
}
\arguments{
\item{pbar}{\code{Progress} object to be updated.}

\item{message}{\code{(character)} New message to display with the progress bar.}

\item{inc}{\code{(numeric)} Amount to increment the progress bar by.}

\item{set}{\code{(numeric)} Value to set the progress bar to.}

\item{...}{Additional arguments passed to the progress bar's update method. Typically used for passing "detail".}

\item{e}{The environment from which to evaluate the function.}
}
\value{
None. This function is called for its side effects.
}
\description{
Update a \link[shiny]{Progress} object with a new message, increment, or set value.
}
