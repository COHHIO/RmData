# COHHIO_HMIS
# Copyright (C) 2020  Coalition on Homelessness and Housing in Ohio (COHHIO)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details at
# <https://www.gnu.org/licenses/>.
prioritization <- function(
  co_clients_served,
  co_currently_homeless,
  covid19,
  Disabilities,
  Enrollment_extra_Exit_HH_CL_AaE,
  HealthAndDV,
  IncomeBenefits,
  Project,
  Scores,
  clarity_api = get_clarity_api(e = rlang::caller_env()),
  app_env = get_app_env(e = rlang::caller_env())
) {
force(clarity_api)
if (is_app_env(app_env))
  app_env$set_parent(missing_fmls())
# clients currently entered into a homeless project in our system

co_currently_homeless <- co_clients_served |>
  dplyr::filter((is.na(ExitDate) |
            ExitDate > lubridate::today()) &
           (ProjectType %in% c(4, lh_project_types) |
              (
                ProjectType %in% c(ph_project_types) &
                  is.na(MoveInDateAdjust)
              ))) |>
  dplyr::select(
    PersonalID,
    UniqueID,
    ProjectName,
    ProjectType,
    HouseholdID,
    EnrollmentID,
    RelationshipToHoH,
    VeteranStatus,
    EntryDate,
    AgeAtEntry
  )

# Check Whether Each Client Has Income ---------------------------------

# getting income-related data and data collection stages. this will balloon
# out the number of rows per client, listing each yes/no update, then, using
# DateCreated, it picks out the most recent answer, keeping only that one

income_data <- co_currently_homeless |>
  dplyr::left_join(
    dplyr::select(
      IncomeBenefits,
      PersonalID,
      EnrollmentID,
      IncomeFromAnySource,
      DateCreated,
      DataCollectionStage
    ),
    by = c("PersonalID", "EnrollmentID")
  ) |>
  dplyr::mutate(IncomeFromAnySource = dplyr::if_else(
    is.na(IncomeFromAnySource),
    dplyr::if_else(AgeAtEntry >= 18L |
                     is.na(AgeAtEntry), 99L, 0L),
    IncomeFromAnySource
  )) |>
  dplyr::group_by(PersonalID, EnrollmentID) |>
  dplyr::arrange(dplyr::desc(DateCreated)) |>
  dplyr::slice(1L) |>
  dplyr::ungroup() |>
  dplyr::select(PersonalID,
                EnrollmentID,
                IncomeFromAnySource)

# Check Whether Each Client Has Any Indication of Disability ------------

# this checks the enrollment's 1.3 and 4.02 records to catch potential
# disabling conditions that may be used to determine PSH eligibility but
# were not reported in 3.08. If any of these three data elements (1.3,
# 4.02, 3.08) suggest the presence of a disabling condition, this section
# flags that enrollment as belonging to a disabled client. Otherwise,
# the enrollment is marked not disabled.


extended_disability <- co_currently_homeless |>
  dplyr::left_join(
    dplyr::select(
      Disabilities,
      EnrollmentID,
      DisabilityResponse,
      IndefiniteAndImpairs),
    by = c("EnrollmentID"))  |>
  dplyr::group_by(EnrollmentID) |>
  dplyr::mutate(
    D_Disability = dplyr::if_else(DisabilityResponse == 1 &
                                    IndefiniteAndImpairs != 0, 1, 0),
    D_Disability = max(D_Disability)
  ) |>
  dplyr::select(EnrollmentID, D_Disability) |>
  dplyr::left_join(
    dplyr::select(
      IncomeBenefits,
      EnrollmentID,
      SSDI,
      VADisabilityService,
      VADisabilityNonService,
      PrivateDisability),
    by = c("EnrollmentID")) |>
  dplyr::mutate(
    I_Disability = dplyr::if_else(
      SSDI == 1 |
        VADisabilityService == 1 |
        VADisabilityNonService == 1 |
        PrivateDisability == 1,
      1,
      0
    ),
    I_Disability = max(I_Disability)
  ) |>
  dplyr::select(EnrollmentID, D_Disability, I_Disability) |>
  dplyr::ungroup() |>
  dplyr::distinct() |>
  dplyr::left_join(
    dplyr::select(Enrollment,
                  EnrollmentID,
                  DisablingCondition),
                   by = c("EnrollmentID")) |>
  dplyr::mutate(
    any_disability = dplyr::case_when(
      D_Disability == 1 |
        I_Disability == 1 |
        DisablingCondition == 1 ~ 1,
      TRUE ~ 0
    )
  ) |>
  dplyr::select(EnrollmentID, any_disability)

# adding household aggregations into the full client list
co_currently_homeless <- co_currently_homeless |>
  dplyr::left_join(income_data,
                   by = c("PersonalID", "EnrollmentID")) |>
  dplyr::left_join(extended_disability, by = "EnrollmentID") |>
  dplyr::left_join(
    dplyr::select(
      Enrollment_extra_Exit_HH_CL_AaE,
      EnrollmentID,
      PersonalID,
      HouseholdID,
      LivingSituation,
      DateToStreetESSH,
      TimesHomelessPastThreeYears,
      ExitAdjust,
      MonthsHomelessPastThreeYears,
      DisablingCondition
    ),
    by = c("PersonalID",
           "EnrollmentID",
           "HouseholdID")
  ) |>
  dplyr::mutate(SinglyChronic =
                  dplyr::if_else(((
                    DateToStreetESSH + lubridate::years(1) <= EntryDate &
                      !is.na(DateToStreetESSH)
                  ) |
                    (
                      MonthsHomelessPastThreeYears %in% c(112, 113) &
                        TimesHomelessPastThreeYears == 4 &
                        !is.na(MonthsHomelessPastThreeYears) &
                        !is.na(TimesHomelessPastThreeYears)
                    )
                  ) &
                    DisablingCondition == 1 &
                    !is.na(DisablingCondition), 1, 0)) |>
  dplyr::group_by(PersonalID) |>
  dplyr::mutate(SinglyChronic = max(SinglyChronic)) |>
  dplyr::ungroup() |>
  dplyr::group_by(HouseholdID) |>
  dplyr::mutate(
    HouseholdSize = length(unique(PersonalID)),
    IncomeInHH = max(
      dplyr::if_else(IncomeFromAnySource == 1, 100L, IncomeFromAnySource)
    ),
    IncomeInHH = dplyr::if_else(IncomeInHH == 100, 1L, IncomeInHH),
    DisabilityInHH = max(dplyr::if_else(any_disability == 1, 1, 0)),
    ChronicStatus = dplyr::if_else(max(SinglyChronic) == 1, "Chronic", "Not Chronic")
  ) |>
  dplyr::ungroup() |>
  dplyr::select(
    "PersonalID",
    "UniqueID",
    "ProjectName",
    "ProjectType",
    "HouseholdID",
    "EnrollmentID",
    "RelationshipToHoH",
    "VeteranStatus",
    "EntryDate",
    "AgeAtEntry",
    "DisablingCondition",
    "HouseholdSize",
    "IncomeInHH",
    "DisabilityInHH",
    "ChronicStatus"
  )

# Account for Multiple EEs -------------------------------------------------

prioritization <- co_currently_homeless |>
  dplyr::group_by(PersonalID) |>

  # label all program as either literally homeless or a housing program
  dplyr::mutate(PTCStatus = dplyr::case_when(
    ProjectType %in% c(lh_project_types, 4) ~ "LH",
    ProjectType %in% c(ph_project_types) ~ "PH"
  ),
  PTCStatus = factor(
    PTCStatus,
    levels = c(
      "LH", "PH"
    )),

  # label all clients as literally homeless or in a housing program
  client_status = dplyr::if_else(PTCStatus == "LH", 0, 1),
  client_status = max(client_status)
  ) |>

  # if the client has at least one literally homeless entry, keep the most recent
  # otherwise, keep the most recent housing program entry
  dplyr::arrange(PTCStatus, dplyr::desc(EntryDate)) |>
  dplyr::slice(1L) |>

  # apply human-readable status labels
  dplyr::mutate(PTCStatus = dplyr::if_else(
    client_status == 1,
    "Has Entry into RRH or PSH",
    "Currently Has No Entry into RRH or PSH"
  )) |>
  dplyr::ungroup() |>
  dplyr::select(-client_status)

# correcting for bad hh data (while also flagging it) ---------------------

# what household ids exist in the data?
ALL_HHIDs <- prioritization |> dplyr::select(HouseholdID) |> unique()

# marking who is a hoh (accounts for singles not marked as hohs in the data)
prioritization <- prioritization |>
  dplyr::mutate(
    RelationshipToHoH = dplyr::if_else(is.na(RelationshipToHoH), 99L, RelationshipToHoH),
    hoh = dplyr::if_else(stringr::str_detect(HouseholdID, stringr::fixed("s_")) |
                    RelationshipToHoH == 1, 1L, 0L))

# what household ids exist if we only count those with a hoh?
HHIDs_in_current_logic <- prioritization |>
  dplyr::filter(hoh == 1) |>
  dplyr::select(HouseholdID) |>
  unique()

# which hh ids did not have a hoh?
HHIDs_with_bad_dq <-
  dplyr::anti_join(ALL_HHIDs, HHIDs_in_current_logic,
            by = "HouseholdID")

# what household ids have multiple hohs?
mult_hohs <- prioritization |>
  dplyr::group_by(HouseholdID) |>
  dplyr::summarise(hohs = sum(hoh)) |>
  dplyr::filter(hohs > 1) |>
  dplyr::select(HouseholdID)

# give me ALL household ids with some sort of problem
HHIDs_with_bad_dq <- rbind(HHIDs_with_bad_dq, mult_hohs)

# let's see those same household ids but with all the needed columns
HHIDs_with_bad_dq <-
  dplyr::left_join(HHIDs_with_bad_dq, prioritization, by = "HouseholdID")

rm(ALL_HHIDs, HHIDs_in_current_logic, mult_hohs)

# assigning hoh status to the oldest person in the hh
Adjusted_HoHs <- HHIDs_with_bad_dq |>
  dplyr::group_by(HouseholdID) |>
  dplyr::arrange(dplyr::desc(AgeAtEntry)) |> # picking oldest hh member
  dplyr::slice(1L) |>
  dplyr::mutate(correctedhoh = 1L) |>
  dplyr::select(HouseholdID, PersonalID, EnrollmentID, correctedhoh) |>
  dplyr::ungroup()

# merging the "corrected" hohs back into the main dataset with a flag, then
# correcting the RelationshipToHoH
hohs <- prioritization |>
  dplyr::left_join(Adjusted_HoHs,
            by = c("HouseholdID", "PersonalID", "EnrollmentID")) |>
  dplyr::mutate(RelationshipToHoH = dplyr::if_else(correctedhoh == 1L, 1L, RelationshipToHoH)) |>
  dplyr::select(PersonalID, HouseholdID, correctedhoh)


prioritization <- prioritization |>
  dplyr::left_join(hohs, by = c("HouseholdID", "PersonalID")) |>
  dplyr::group_by(HouseholdID) |>
  dplyr::mutate(correctedhoh = dplyr::if_else(is.na(correctedhoh), 0L, 1L),
         HH_DQ_Issue = as.logical(max(correctedhoh))) |>
  dplyr::ungroup()

# COVID-19 ----------------------------------------------------------------



covid_hhs <- prioritization |>
  dplyr::left_join(dplyr::select(c19priority, PersonalID, C19Priority), by = "PersonalID") |>
  dplyr::mutate(
    C19Priority = dplyr::if_else(
      is.na(C19Priority),
      "Not Assessed Recently", # "Not Assessed Recently"
      as.character(C19Priority)
    ),
    C19Priority = factor(
      C19Priority,
      levels = c(
        "No Known Risks or Exposure",
        "Not Assessed Recently",
        "Has Health Risk(s)",
        "Needs Isolation/Quarantine"
      ),
      ordered = TRUE
    )
  ) |>
  dplyr::group_by(HouseholdID) |>
  dplyr::mutate(C19Priority = max(C19Priority)) |>
  dplyr::ungroup() |>
  dplyr::select(PersonalID, HouseholdID, C19Priority)

# adding COVID19Priority to active list
prioritization <- prioritization |>
  dplyr::left_join(covid_hhs, by = c("PersonalID", "HouseholdID"))

# Adding in TAY, County, PHTrack ----------------------

# getting whatever data's needed from the Enrollment data frame, creating
# columns that tell us something about each household and some that are about
# each client
prioritization <- prioritization |>
  dplyr::left_join(
      dplyr::select(
        Enrollment_extra_Exit_HH_CL_AaE,
        PersonalID,
        HouseholdID,
        CountyServed,
        PHTrack,
        ExpectedPHDate
      ),
    by = c("PersonalID", "HouseholdID")
  ) |>
  dplyr::group_by(HouseholdID) |>
  dplyr::mutate(
    CountyServed = dplyr::if_else(is.na(CountyServed), "MISSING County", CountyServed),
    TAY = max(AgeAtEntry) < 25 & max(AgeAtEntry) >= 16,
    PHTrack = dplyr::if_else(
      !is.na(PHTrack) &
        !is.na(ExpectedPHDate) &
        ExpectedPHDate >= lubridate::today(), PHTrack, NA_character_)
  ) |>
  dplyr::ungroup() |>
  dplyr::select(-AgeAtEntry)




# County Guessing ---------------------------------------------------------

# replacing non-Unsheltered-Provider missings with County of the provider
prioritization <- prioritization |>
  dplyr::left_join(Project |>
              dplyr::select(ProjectName, ProjectCounty), by = "ProjectName") |>
  dplyr::mutate(
    CountyGuessed = CountyServed == "MISSING County",
    CountyServed = dplyr::if_else(
      CountyGuessed &
        ProjectName != "Unsheltered Clients - OUTREACH",
      ProjectCounty,
      CountyServed
    ),
    ProjectCounty = NULL
  )


# Add in Score ------------------------------------------------------------

# taking the most recent score on the client, but this score cannot be over a
# year old.

  prioritization <- prioritization |>
  dplyr::left_join(
    Scores |>
      dplyr::filter(ScoreDate > lubridate::today() - lubridate::years(1)) |>
      dplyr::group_by(PersonalID) |>
      dplyr::arrange(dplyr::desc(ScoreDate)) |>
      dplyr::slice(1L) |>
      dplyr::ungroup() |>
      dplyr::select(-ScoreDate, -UniqueID),
    by = "PersonalID"
  )

# Add Additional Chronic Statuses ---------------------------------------------

# adds current days in ES or SH projects to days homeless prior to entry and if
# it adds up to 365 or more, it marks the client as AgedIn
agedIntoChronicity <- prioritization |>
  dplyr::left_join(
    Enrollment_extra_Exit_HH_CL_AaE |>
      dplyr::select(
        EnrollmentID,
        PersonalID,
        HouseholdID,
        LivingSituation,
        DateToStreetESSH,
        TimesHomelessPastThreeYears,
        ExitAdjust,
        MonthsHomelessPastThreeYears
      ),
    by = c("PersonalID",
           "EnrollmentID",
           "HouseholdID")
  ) |>
  dplyr::mutate(
    DaysHomelessInProject = difftime(ExitAdjust,
                                     EntryDate,
                                     units = "days"),
    DaysHomelessBeforeEntry = difftime(EntryDate,
                                       dplyr::if_else(
                                         is.na(DateToStreetESSH),
                                         EntryDate,
                                         DateToStreetESSH
                                       ),
                                       units = "days"),
    ChronicStatus = dplyr::if_else(
      ProjectType %in% c(1, 8) &
        ChronicStatus == "Not Chronic" &
        DateToStreetESSH + lubridate::days(365) > EntryDate &
        !is.na(DateToStreetESSH) &
        DaysHomelessBeforeEntry + DaysHomelessInProject >= 365,
      "Aged In",
      ChronicStatus
    )
  ) |>
  dplyr::select(-DaysHomelessInProject,-DaysHomelessBeforeEntry)

# adds another ChronicStatus of "Nearly Chronic" which catches those hhs with
# almost enough times and months to qualify as Chronic
nearly_chronic <- agedIntoChronicity |>
  dplyr::mutate(
    ChronicStatus = dplyr::if_else(
      ChronicStatus == "Not Chronic" &
        ((
          DateToStreetESSH + lubridate::days(365) <= EntryDate &
            !is.na(DateToStreetESSH)
        ) |
          (
            MonthsHomelessPastThreeYears %in% c(110:113) &
              TimesHomelessPastThreeYears%in% c(3, 4) &
              !is.na(MonthsHomelessPastThreeYears) &
              !is.na(TimesHomelessPastThreeYears)
          )
        ) &
        DisablingCondition == 1 &
        !is.na(DisablingCondition),
      "Nearly Chronic",
      ChronicStatus
    )
  )

prioritization <- prioritization |>
  dplyr::select(-ChronicStatus) |>
  dplyr::left_join(
    dplyr::select(
      nearly_chronic,
      "PersonalID",
      "HouseholdID",
      "EnrollmentID",
      "ChronicStatus"
    ),
    by = c("PersonalID", "HouseholdID", "EnrollmentID")
  ) |>
  dplyr::mutate(ChronicStatus = factor(
    ChronicStatus,
    levels = c("Chronic",
               "Aged In",
               "Nearly Chronic",
               "Not Chronic")
  ))

# THIS IS WHERE WE'RE SUMMARISING BY HOUSEHOLD (after all the group_bys)

prioritization <- prioritization |>
  dplyr::mutate(
    HoH_Adjust = dplyr::case_when(HH_DQ_Issue == 1L ~ correctedhoh,
                           HH_DQ_Issue == 0L ~ hoh)
  ) |>
  dplyr::filter(HoH_Adjust == 1) |>
  dplyr::select(-correctedhoh, -RelationshipToHoH, -hoh, -HoH_Adjust)

# Add Referral Status -----------------------------------------------------

# thinking maybe it makes the most sense to only look at referrals that have
# been accepted for the purposes of the Active List. Because who cares if
# there's an open referral on a client who needs housing? That doesn't mean
# anything because we haven't really assigned a meaning to that. But an
# accepted referral does supposedly mean something, and it would add context
# to know that a household on this list has been accepted into (if not entered
# into) another project.

# also thinking the Refer-to provider should be an RRH or PSH? Maybe? Because
# referrals to a homeless project wouldn't mean anything on an Active List,
# right?



# isolates hhs with an Accepted Referral into a PSH or RRH project in the past month


prioritization <- dplyr::left_join(
  prioritization,
  Referrals,
  by = c(
    "PersonalID",
    "UniqueID",
    EnrollmentID = "R_ReferredEnrollmentID",
    HouseholdID = "R_ReferredHouseholdID"
  )
)



  # Referral Situation ----
  # Tue Nov 09 12:49:51 2021
  prioritization <- dplyr::mutate(
    prioritization,
    Situation = dplyr::case_when(
      PTCStatus == "Has Entry into RRH or PSH" ~ dplyr::if_else(
        R_ReferralConnectedProjectType %in% c(lh_project_types, 4),
        paste("Has Entry into",
              R_ReferralConnectedProjectName),
        PTCStatus
      ),
      PTCStatus == "Currently Has No Entry into RRH or PSH" &
        !is.na(R_ReferralConnectedProjectName) ~
        paste(
          "No current Entry into RRH or PSH but",
          R_ReferredProjectName,
          "accepted this household's referral on",
          R_ReferredDate
        ),
      PTCStatus == "Currently Has No Entry into RRH or PSH" &
        is.na(R_ReferralConnectedProjectName) &
        !is.na(PHTrack) ~ paste("Permanent Housing Track:",
                                PHTrack,
                                "by",
                                ExpectedPHDate),
      PTCStatus == "Currently Has No Entry into RRH or PSH" &
        is.na(R_ReferralConnectedProjectName) &
        is.na(PHTrack) ~
        "No Entry or accepted Referral into PSH/RRH, and no current Permanent Housing Track"
    )
  )


# Fleeing DV --------------------------------------------------------------
prioritization <- prioritization |>
  dplyr::left_join(
    HealthAndDV |>
      # get most recent DV information for those on the list
      dplyr::group_by(PersonalID) |>
      dplyr::arrange(dplyr::desc(InformationDate)) |>
      dplyr::slice(1L) |>
      # pull variables we want
      dplyr::select(EnrollmentID,
             PersonalID,
             CurrentlyFleeing,
             WhenOccurred),
    by = c("EnrollmentID", "PersonalID")
  ) |>
  dplyr::mutate(
    CurrentlyFleeing = dplyr::if_else(is.na(CurrentlyFleeing), 99L, CurrentlyFleeing),
    WhenOccurred = dplyr::if_else(is.na(WhenOccurred), 99L, WhenOccurred),
    CurrentlyFleeing = dplyr::case_when(
      CurrentlyFleeing %in% c(0L, 99L) &
        WhenOccurred %in% c(4L, 8L, 9L, 99L) ~ "No",
      CurrentlyFleeing == 1L |
        WhenOccurred %in% c(1L:3L) ~ "Yes",
      CurrentlyFleeing %in% c(8L, 9L) ~ "Unknown"
    )
  ) |>
  dplyr::select(-WhenOccurred)

# Clean the House ---------------------------------------------------------
prioritization <- prioritization |>
  dplyr::mutate(
    dplyr::across(dplyr::all_of(c("VeteranStatus", "DisabilityInHH")), hud.extract::hud_translations$`1.8 No_Yes_Reasons for Missing Data`),
    IncomeFromAnySource = hud.extract::hud_translations$`1.8 No_Yes_Reasons for Missing Data`(IncomeInHH),
    TAY = dplyr::case_when(TAY == 1 ~ "Yes",
                    TAY == 0 ~ "No",
                    is.na(TAY) ~ "Unknown"),
    ProjectName = dplyr::if_else(
      ProjectName == "Unsheltered Clients - OUTREACH",
      paste("Unsheltered in",
            CountyServed,
            "County"),
      ProjectName
    )
  ) |>
  dplyr::select(-IncomeInHH)

# landing_data <- prioritization |>
#   select(PersonalID, CountyServed, COVID19Priority, ShortSituation) |>
#   # filter(CountyServed == "Lorain") |>
#   # mutate(COVID19Priority = as.character(COVID19Priority),
#   #        ShortSituation = as.character(ShortSituation)) |>
#   group_by(COVID19Priority, ShortSituation) |>
#   summarise(HHs = n()) |>
#   ungroup() |>
#   as.data.frame()
#
# landing <- treemap(
#   landing_data,
#   title = "Currently Literally Homeless Households",
#   index = c("ShortSituation", "COVID19Priority"),
#   border.lwds = c(4, .5),
#   border.col = c("#FFFFFF", "#D2B48C"),
#   palette = "RdBu",
#   vSize = "HHs",
#   vColor = "COVID19Priority",
#   type = "categorical",
#   position.legend = "bottom",
#   fontsize.labels = c(17, 12),
#   fontcolor.labels = c("white", "black"),
#   fontface.labels = c(2, 1),
#   bg.labels = "transparent",
#   # position.legend = "none",
#   align.labels = list(c("center", "center"),
#                       c("left", "top"))
# )

# rowsum(plotly_attempt$HHs, group = plotly_attempt$COVID19Priority)

# plot_ly(
#   b,
#   parents = ~ COVID19Priority,
#   labels = ~ ShortSituation,
#   values = ~ HHs,
#   type = 'treemap'
# )
app_env$gather_deps(prioritization)
}