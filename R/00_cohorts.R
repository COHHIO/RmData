# Some definitions:
# PH = PSH + RRH
# household = one or more people who present for housing/homeless services
# served = the Entry to Exit Date range crosses the Report Date range
# entered = the Entry Date is inside the Report Date range
# served_leaver = (regardless of Move-In) the Exit Date is inside the Report
#     Date range
# moved_in_leaver = a subset of served_leaver, these stays include a Move-In Date
#     where that's relevant (PH projects)
# moved_in = any stay in a non-PH project where the Entry to Exit Date range
#     crosses the Report Date range PLUS any stay in a PH project where the
#     Move In Date to the Exit Date crosses the Report Date range
# hohs = heads of household
# adults = all adults in a household
# clients = all members of the household
#' @include app_dependencies.R init_R6.R

cohorts <- function(
  clarity_api = get_clarity_api(e = rlang::caller_env()),
  app_env = get_app_env(e = rlang::caller_env())
) {

  if (is_app_env(app_env))
    app_env$set_parent()
  vars <- list(we_want = c(
    "PersonalID",
    "UniqueID",
    "EnrollmentID",
    "DOB",
    "CountyServed",
    "ProjectName",
    "ProjectID",
    "ProjectType",
    "HouseholdID",
    "AgeAtEntry",
    "RelationshipToHoH",
    "VeteranStatus",
    "EntryDate",
    "EntryAdjust",
    "MoveInDate",
    "MoveInDateAdjust",
    "ExitDate",
    "ExitAdjust",
    "Destination"
  ))


  # Transition Aged Youth
  tay <-  Enrollment_extra_Client_Exit_HH_CL_AaE |>
    dplyr::select(tidyselect::all_of(vars$we_want)) |>
    dplyr::group_by(HouseholdID) |>
    dplyr::mutate(
      TAY = dplyr::if_else(max(AgeAtEntry) < 25 & max(AgeAtEntry) >= 16, 1, 0)
    ) |>
    dplyr::ungroup() |>
    dplyr::filter(TAY == 1 & !is.na(ProjectName))

  #	Leavers and Stayers	who were Served During Reporting Period	All
  co_clients_served <-  Enrollment_extra_Client_Exit_HH_CL_AaE  |>
    chrt_filter_select(served = TRUE,
                       vars = vars$we_want)

  # Leaver and Stayer HoHs who were served during the reporting period
  co_hohs_served <-  co_clients_served  |>
    dplyr::filter(RelationshipToHoH == 1)

  #	Leavers and Stayers	who were Served During Reporting Period	Adults
  co_adults_served <-  co_clients_served |>
    dplyr::filter(AgeAtEntry > 17)

  #	Leavers and Stayers	who	Entered During Reporting Period	HoHs
  co_hohs_entered <-  Enrollment_extra_Client_Exit_HH_CL_AaE |>
    chrt_filter_select(entered = TRUE,
                       vars = vars$we_want) |>
    dplyr::filter(RelationshipToHoH == 1)

  #	Leavers	who were Served During Reporting Period (and Moved In)	All
  co_clients_moved_in_leavers <-  Enrollment_extra_Client_Exit_HH_CL_AaE |>
    chrt_filter_select(exited = TRUE,
                       stayed = TRUE,
                       vars = vars$we_want)

  #	Leaver hohs	who were Served (and Moved In) During Reporting Period	HoHs
  co_hohs_moved_in_leavers <-  co_clients_moved_in_leavers |>
    dplyr::filter(RelationshipToHoH == 1)

  #	Leavers	who were Served During Reporting Period (and Moved In)	Adults
  co_adults_moved_in_leavers <-  co_clients_moved_in_leavers |>
    dplyr::filter(AgeAtEntry > 17)



  # Counties ----------------------------------------------------------------

  bos_counties <- ServiceAreas |>
    dplyr::filter(CoC == "OH-507 Balance of State") |>
    dplyr::pull(County)


  app_env$gather_deps("everything")

}


