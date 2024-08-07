% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/daily_update_utils.R
\name{daily_update}
\alias{daily_update}
\title{Update the Rminor apps}
\usage{
daily_update(
  steps = c(`Update Data` = "update", `Run RmData functions` = "funs",
    `Send Dependencies to Dropbox` = "send"),
  funs = rlang::set_names(c("dates", "load_export", "cohorts", "client_counts",
    "qpr_ees", "qpr_spdats", "vets", "vet_active", "bed_unit_utilization",
    "data_quality", "data_quality_summary", "project_evaluation_mahoning",
    "prioritization", "spms")),
  remote = FALSE,
  backup = FALSE,
  app_env,
  clarity_api,
  session,
  e = rlang::caller_env()
)
}
\arguments{
\item{steps}{\code{(character)} vector of the steps to run. Any of:
\itemize{
\item{\code{ update }}{  Update Data }
\item{\code{ funs }}{  Run RmData functions }
\item{\code{ send }}{  Send Dependencies to Dropbox }
}}

\item{funs}{\code{(character)} vector of functions to run. Any of:
\itemize{
\item{\code{ dates }}
\item{\code{ load_export }}
\item{\code{ cohorts }}
\item{\code{ client_counts }}
\item{\code{ qpr_ees }}
\item{\code{ qpr_spdats }}
\item{\code{ vets }}
\item{\code{ vet_active }}
\item{\code{ prioritization }}
\item{\code{ bed_unit_utilization }}
\item{\code{ data_quality }}
\item{\code{ data_quality_summary }}
}}

\item{remote}{\code{(logical)} Whether to send dependencies to the remote storage.}

\item{backup}{\code{(logical)} Whether to back up all raw dependencies in the dependencies environment.}

\item{app_env}{\code{(app_env)} R6 Object containing dependencies. If all arguments to this function are saved in the \code{app_env}, then they will be called from there and arguments do not need to be specified.}

\item{clarity_api}{\code{(clarity_api)} R6 Object containing the connection to the Clarity Looker instance.}

\item{session}{\code{(shiny session object)}}

\item{e}{\code{(calling environment)}}
}
\value{
Updates the Rminor apps and provides status messages along the way
}
\description{
Update the Rminor apps
}
