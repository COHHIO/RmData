% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/00_load_export_utils.R
\name{load_services}
\alias{load_services}
\title{Load Services as Services_enroll_extras}
\usage{
load_services(
  Services,
  Services_extras,
  Enrollment_extra_Client_Exit_HH_CL_AaE,
  app_env = get_app_env(e = rlang::caller_env())
)
}
\arguments{
\item{Services}{\code{(data.frame)} From the HUD CSV Export}

\item{Services_extras}{\code{(data.frame)} From the Clarity Looker API Extras}
}
\value{
\code{(data.frame)} \code{vars$we_want} and \code{Issue} (Issue Name), \code{Type} (Error or Warning), and \code{Guidance} (How to correct the issue)
}
\description{
Load Services as Services_enroll_extras
}
