% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/00_load_export_utils.R
\name{load_public}
\alias{load_public}
\title{Load public data pre-requisites for \code{load_export}}
\usage{
load_public(app_env = get_app_env(e = rlang::caller_env()))
}
\arguments{
\item{app_env}{\code{(app_env)} R6 Object containing dependencies. If all arguments to this function are saved in the \code{app_env}, then they will be called from there and arguments do not need to be specified.}
}
\value{
\code{app_env} with data dependencies
}
\description{
Load public data pre-requisites for \code{load_export}
}
