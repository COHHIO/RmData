# PLEASE NOTE THIS SCRIPT OVERWRITES THE CLIENT.CSV FILE ON YOUR HARD DRIVE!
# IT REPLACES THE NAMES AND SSNS WITH DATA QUALITY SIGNIFIERS!
# IT CAN BE RUN ON A CLEAN CLIENT.CSV FILE OR ONE THAT'S BEEN OVERWRITTEN.

#' @title Load the HUD Export and join extras.
#'
#' @inheritParams R6Classes
#' @param error \code{(logical)} whether to error or send a message via pushbullet when data checks fail
#'
#' @return `app_env` with data dependencies
#' @export


load_export <- function(
  clarity_api = get_clarity_api(e = rlang::caller_env()),
  app_env = get_app_env(e = rlang::caller_env()),
  error = FALSE
) {

  force(clarity_api)

  # Public data
  app_env <- load_public()

  # Client
  app_env <- load_client()

  if (is_app_env(app_env))
    app_env$set_parent(missing_fmls())

  # ProjectCoC
  # Project
  app_env <- load_project(ProjectCoC = clarity_api$ProjectCoC(), app_env = app_env)


  # Disabilities ------------------------------------------------------------

  Disabilities <- clarity_api$Disabilities()



  # Referrals ---------------------------------------------------------------
  app_env <- load_referrals(Referrals = clarity_api$CE_Referrals_new_extras(col_types = list(ReferringPTC = "c", DeniedByType = "c")))


  # Enrollment --------------------------------------------------------------


  app_env <- load_enrollment(Enrollment = clarity_api$Enrollment(),
                             Enrollment_extras = clarity_api$Enrollment_extras() |>
                               dplyr::mutate_all(as.character),
                             Exit = clarity_api$Exit())

  # Funder ------------------------------------------------------------------

  Funder <-
    clarity_api$Funder()

  # HealthAndDV -------------------------------------------------------------

  HealthAndDV <-
    clarity_api$HealthAndDV()

  # IncomeBenefits ----------------------------------------------------------

  IncomeBenefits <-
    clarity_api$IncomeBenefits() |>
    dplyr::mutate(dplyr::across(c(tidyselect::contains("Amount"), tidyselect::all_of("TotalMonthlyIncome")), as.numeric)) |>
    dplyr::mutate(TotalMonthlyIncome = dplyr::if_else(IncomeFromAnySource == 0 & is.na(TotalMonthlyIncome),
                                                      0, TotalMonthlyIncome))

  # Inventory ---------------------------------------------------------------

  Inventory <- clarity_api$Inventory()


  # Contacts ----------------------------------------------------------------
  # only pulling in contacts made between an Entry Date and an Exit Date

  Contacts <- clarity_api$Contact_extras()

  # Scores ------------------------------------------------------------------
  Scores <-  clarity_api$Client_SPDAT_extras() |>
    dplyr::filter(Deleted == "No") |>
    dplyr::mutate(Score = dplyr::if_else(is.na(Score), CustomScore, Score),
                  CustomScore = NULL) |>
    dplyr::mutate(Score = dplyr::if_else(stringr::str_detect(Assessment, "B-PAT"), Total, Score))


  # Users ----
  # Thu Sep 23 14:38:19 2021
  Users <- clarity_api$User()
  Users_link <- clarity_api$UserNamesIDs_extras() |>
    dplyr::mutate(UserCreated = as.character(UserCreated))
  Users <- dplyr::left_join(Users, Users_link, by = c(UserID = "UserCreated"))

  # Services ----------------------------------------------------------------
  app_env <- load_services(Services = clarity_api$Services(),
                Services_extras = clarity_api$Services_extras()
                )

  program_lookup <- load_program_lookup(clarity_api$Program_lookup_extras())




  app_env$gather_deps("everything")
}


