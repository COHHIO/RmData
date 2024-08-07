% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/aaa_imports.R
\name{hmis_option}
\alias{hmis_option}
\title{Retrieve an HMIS option set via \code{setup_RmData}}
\usage{
hmis_option(opt, default = FALSE)
}
\arguments{
\item{opt}{\code{(character)} Option name to retrieve}

\item{default}{if the specified option is not set in the options list,
    this value is returned.  This facilitates retrieving an option and
    checking whether it is set and setting it separately if not.}
}
\description{
Retrieve an HMIS option set via \code{setup_RmData}
}
