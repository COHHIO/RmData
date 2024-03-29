% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/aaa_imports.R
\name{must_sp}
\alias{must_sp}
\title{This instance must be using ServicePoint, otherwise throw an error.}
\usage{
must_sp(.call = match.call()[[1]])
}
\value{
\code{(logical)}
}
\description{
Set an option in \code{.Rprofile} using \code{usethis::edit_r_profile('project')} called HMIS which is a list containing two logical values:
\itemize{
\item{\code{Clarity}}{ A logical to indicate whether Clarity is (or has been) used by this CoC}
\item{\code{ServicePoint}}{ A logical to indicate whether Servicepoint is (or has been) used by this CoC}
}
}
