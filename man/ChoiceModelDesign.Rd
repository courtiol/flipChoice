% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/experimentaldesign.R
\name{ChoiceModelDesign}
\alias{ChoiceModelDesign}
\title{Choice modeling experimental design}
\usage{
ChoiceModelDesign(
  design.algorithm = c("Random", "Shortcut", "Balanced overlap",
    "Complete enumeration", "Efficient", "Partial profiles"),
  attribute.levels = NULL,
  prior = NULL,
  n.questions,
  n.versions = 1,
  alternatives.per.question,
  prohibitions = NULL,
  none.alternatives = 0,
  labeled.alternatives = FALSE,
  n.constant.attributes = NULL,
  output = "Labeled design",
  seed = 54123
)
}
\arguments{
\item{design.algorithm}{The algorithm used to create the
design. One of \code{"Random"}, \code{"Shortcut"},
\code{"Balanced overlap"}, \code{"Complete enumeration"},
\code{"Efficient"} and \code{Partial profiles}.}

\item{attribute.levels}{\code{\link{list}} of \code{\link{vector}}s
containing the labels of levels for each attribute, with names
corresponding to the attribute labels; \emph{or} a character
matrix with first row containing attribute names and subsequent
rows containing attribute levels.}

\item{prior}{Character matrix containing prior values for the model
coefficients; only used for \code{design.algorithm ==
"Efficient"}; see Details.}

\item{n.questions}{Integer; the number of questions asked to each
respondent.}

\item{n.versions}{Integer; the number of versions of the survey to
create.}

\item{alternatives.per.question}{Integer; the number of alternative
products shown in each question. Ignored if
\code{"labeled.alternatives"} is TRUE.}

\item{prohibitions}{Character \code{\link{matrix}} where each row
is a prohibited alternative consisting of the levels of each
attribute. If a level is \code{""} or is \code{"All"} then all
levels of that attribute in combination with the other
specified attribute levels are prohibited.}

\item{none.alternatives}{Integer; the number of 'None' in all
questions.}

\item{labeled.alternatives}{Logical; whether the first attribute
labels the alternatives.}

\item{n.constant.attributes}{Integer; the number of attributes to keep
constant.}

\item{output}{One of \code{"Labeled design"} or \code{"Inputs"}.}

\item{seed}{Integer; random seed to be used by the algorithms.}
}
\value{
A list with components
\itemize{
\item \code{design} - a numeric array of dimensions (number of questions by alternatives per
question by number of attributes) where each value is the index of a level. Ignoring any none
alternatives.
\item \code{design.with.none} - as per \code{design} except one additional row per none alternative
is added to each question with \code{NA} for all attribute levels.
\item \code{labeled.design} - as per \code{design.with.none} except indices of levels are
replaced by their labels.
\item \code{design.algorithm} - as per input.
\item \code{attribute.levels} - as per input.
\item \code{prohibitions} - as per input.
\item \code{n.questions} - as per input.
\item \code{n.versions} - as per input.
\item \code{alternatives.per.question} - as per input.
\item \code{none.alternatives} - as per input.
\item \code{output} - as per input.
\item \code{db.error} - the Db-error of \code{design}.
\item \code{d.error} - the D-error of \code{design}.
\item \code{model.matrix} - the model matrix of dummy coded variables for each alternative
in every choice set.
\item \code{balances.and.overlaps} a list with components
    \itemize{
    \item\code{singles} a \code{list} of the counts of each level per attribute.
    \item\code{pairs} a \code{list} of the counts of pairwise occurences of levels
    for each pair of attributes.
    \item\code{overlaps} a \code{vector} of the percentage of questions that include
    one or more duplicated level per attribute.
    }
}
}
\description{
Creates choice model experimental designs according to a given algorithm.
}
\details{
If \code{prior} is supplied and \code{design.algorithm ==
    "Efficient"}, the number of coefficients must correspond
    to the number of attributes/attribute levels specified in
    \code{attribute.levels}.  If \code{prior} is \code{NULL}, the prior for the
    coefficients is assumed to be identically zero.  If the supplied matrix
    contains two columns, the first column is taken as the prior
    mean for the coefficients and the second is taken to be the
    prior variances.  If only one column is present, the prior for
    the coefficients is assumed to be centered at those values.
}
\examples{
x <- CreateExperiment(c(3, 5, 7, 10), 20)
ChoiceModelDesign("Random", x$attribute.levels, n.questions = 30,
    alternatives.per.question = 4, prohibitions = x$prohibitions)
}
