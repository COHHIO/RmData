
min_na <- function(...) {
  x <- data.frame(...)
  if (any(!purrr::map_lgl(x$ExpectedPHDate, is.na))) {
    idx <- which.max(x$ExpectedPHDate)
  } else {
    idx <- which.min(apply(x, 1, rlang::as_function(~sum(is.na(.x)))))
  }
  x[idx,]
}

#' @title Find a valid maximum from the input values, or if none is present, return the values
#'
#' @param x \code({numeric/real})
#'
#' @return Maximum value
#' @export

valid_max = function(x) {
  out <- na.omit(x)
  if (UU::is_legit(out)) {
    out2 <- max(out)
    if (!is.infinite(out2))
      out <- out2
  } else {
    out <- x
  }
  out
}

#' @title Return a valid Move-In Date
#'
#' @param MoveInDateAdjust \code{(Date)} See `Enrollment_add_Household`
#' @param EntryDate \code{(Date)} Date of Entry for Enrollment
#'
#' @return
#' @export

valid_movein_max = function(MoveInDateAdjust, EntryDate) {
  if ((valid_max(MoveInDateAdjust)[1] > valid_max(EntryDate)[1]) %|% FALSE)
    out <- valid_max(MoveInDateAdjust)
  else
    out <- lubridate::NA_Date_
  out
}