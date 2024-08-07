
<!-- README.md is generated from README.Rmd. Please edit that file -->

# RmData

An open-source Homeless Management Information System (HMIS) custom
reporting project.

This repository would be helpful to any HUD-designated Continuum of Care
looking for a way to get more out of their HMIS data. While there are
some reports here, this repository’s most important function is getting
data from HMIS to a tidy form that can be used in other projects (and
repositories). Think of it like a staging area for other projects.

## Installation

You can install `{RmData}` with:

``` r
# install.packages("devtools")
devtools::install_github("COHHIO/RmData")
```

## Data Sources

1.  The [HUD CSV
    export](https://files.hudexchange.info/resources/documents/HMIS-CSV-Format-Specifications-2024.pdf) -
    Every HMIS should be able to export this regardless of HMIS vendor.
2.  Other data as necessary, to supplement what is available in the
    Export.

While your reporting needs may be different, this report contains data
we need for our reporting that is not included in the HUD CSVs. These
include but are not limited to:

- SPDAT Scores
- County (Enrollment level)
- Entry Exit Type (specific to ServicePoint)
- Users’ Default Providers
- Full Provider and Organization Names (beyond the 50 character limit)
- Grant Type (specific to ServicePoint)
- Veteran data for Coordinated Entry (Custom fields)
- Housing Offers (Custom fields for Veteran Active List)

You may not need to supplement the data in your HUD CSV export, so
whatever you use from this repository will need to be adjusted to leave
it out. Or you may need a different set of miscellaneous data which will
need to be incorporated to fit your needs. Other CoCs using this
repository would need to work out what other data would be needed and
how that data could be obtained.

If you want to know exactly what data I’m using, see below, and email me
for more specifics if you need it.

# Setup

The \[`clarity.looker`\]{<https://github.com/COHHIO/clarity.looker>}
package provides a setup function for setting up an API connection with
the Clarity Looker instance. An API key & secret will need to be
requested.

<!-- ### The Data I'm Using with the HUD CSV Export -->
<!-- 1. Enrollment-level (at Entry): -->
<!--    a. County Where Served -->
<!--    b. County of Prior Residence -->
<!--    c. Entry Exit Type (a ServicePoint-specific feature) -->
<!--    d. This is all in an ART report named RMisc. I run it in View Mode and download it to .xlsx. -->
<!-- 2. User data: -->
<!--    a. Users' Default Provider (a ServicePoint-specific data element). We need this because we have a shared provider across the entire CoC and we need to be able to show where an Entry came from without listing the User's name. -->
<!--    b. Same as what is in the Export, but currently the WS Export only includes "Active" Users, which doesn't work well for joining to the other data tables using UserCreated. We need this for Data Quality purposes. -->
<!--    c. This is all in an ART report named RMisc. I run it in View Mode and download it to .xlsx. -->
<!-- 3. Project data: -->
<!--    a. Full Project Name (the Export only outputs 50 characters) -->
<!--    b. Full Project Organization Name -->
<!--    c. Grant Type (a ServicePoint-specific data element). We use this to section off certain types of grants, but honestly we could cut this and use the Funder data instead.  -->
<!--    d. Project County. Annoyingly, this is not a HUD-required data element so it is not in the Export and we rely on it HEAVILY, being that we are a Balance of State. -->
<!--    e. This is all in an ART report named RMisc. I run it in View Mode and download it to .xlsx. -->
<!-- 4. Case Manager data: -->
<!--    a. A couple of our workflows require users to enter Case Manager data.  -->
<!--    b. I'm using ReportWriter for this. -->
<!--    c. PersonalID, EEProvider, CMUserCreating, CMProvider, CMStartDate, CMEndDate -->
<!-- 5. Custom Veteran data: -->
<!--    a. I'm using ReportWriter for this. -->
<!--    b. PersonalID, EnrollmentID, DateVeteranIdentified, ExpectedPHDate, HOMESID, ListStatus, MostRecentOfferDate, MostRecentOfferStatus, PHTrack, SSVFIneligible, VAEligible. -->
<!-- 6. Project Evaluation scores for CoC Competition -->
<!--    a. This year for the CoC Competition, the CoC team is entering Housing First scoring and such into each project's custom assessment we created and that data is coming out in the Project Evaluation reporting. -->
<!--    b. This is coming from ReportWriter. -->
<!--    c. ProjectID, ProjectName, ProjectType, CostPerExit, DateReceivedPPDocs, HousingFirstScore, ChronicPrioritizationScore, OnTrackSpendingScoring, UnspentFundsScoring. -->
<!--    c. This is coming from ReportWriter. -->
<!-- 7. Offers (part of custom Veteran data) -->
<!--    a. PersonalID, AcceptDeclineDate, OfferAccepted?, OfferDate, PHTypeOffered -->
<!--    b. This is coming from ReportWriter. -->
<!-- 8. Referrals -->
<!--    a. The Referrals available in the Export are limited to PATH-related ones only. We need all of them. -->
<!--    b. PersonalID, HouseholdID, NeedID, ReferralDate, ProviderCreating, PATHReferralOutcome, PATHReferralType, ReasonReferralCanceledorDeclined, Referred-FromProvider, ReferralOutcome, ReferralsRanking, Referred-ToProvider, RHYMISReferralType, UserCreating -->
<!--    c. This is coming from ReportWriter. -->
<!-- 9. SPDAT Scores -->
<!--    a. This is coming from three different ReportWriter, since the data is split into fam, ind, and tay. -->
<!--    b. PersonalID, ScoreDate, and Score for each report. -->
<!-- 10. Services -->
<!--    a. Like Referrals, the Services in the Export are limited and we need all of them. -->
<!--    b. This is coming from two ReportWriter reports, one for the basic info, and the other for the cost data. -->
<!--    c. The main report contains: PersonalID, HouseholdID, NeedID, ServiceID, ServiceStartDate, ServiceEndDate, Code, Description, ServiceProvider, ProviderCreating. -->
<!--    d. The costing one contains: ServiceID, Fund, Amount. -->

### Security

No HMIS data is ever included in this repository. To make this code
work, you will need to supply your own HMIS data. You are responsible
for securing your HUD CSV export on your computer and ensuring that it
is not compromised using whatever security measures you use for that
locally.
