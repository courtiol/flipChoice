processDesignFile <- function(design.file, attribute.levels.file,
                              choices, questions, subset, weights,
                              n.questions.left.out, seed,
                              input.prior.mean, input.prior.sd,
                              include.choice.parameters)
{
    output <- readDesignFile(design.file, attribute.levels.file)
    design <- output$design
    attribute.levels <- output$attribute.levels

    respondent.data <- processRespondentData(choices, questions)
    choices <- respondent.data$choices
    questions <- respondent.data$questions

    n.attributes <- dim(design)[2] - 3
    n.questions <- dim(questions)[2]
    n.choices <- getNumberOfChoices(choices)
    n.respondents <- dim(questions)[1]

    if (n.attributes != length(attribute.levels))
        stop("The number of attributes in the design file is inconsistent ",
             "with the number of attributes in the attribute levels file.")

    # A "None of these" option is left out from the design
    add.none.of.these <- n.choices == length(unique(design[[3]])) + 1
    # A "None of these" option is included in the design
    none.of.these.included <- any(rowSums(design[-1:-3]) == 0)
    has.none.of.these <- add.none.of.these || none.of.these.included

    n.attribute.parameters <- unlist(lapply(attribute.levels, length)) - 1
    n.parameters <-  sum(n.attribute.parameters)
    par.names <- parameterNamesFromAttributes(attribute.levels)
    all.names <- allNamesFromAttributes(attribute.levels)

    checkPriorParameters(input.prior.mean, input.prior.sd, n.choices,
                         n.attributes, n.parameters, include.choice.parameters)

    ordered.attributes <- orderedAttributes(input.prior.mean, n.attributes,
                                            n.parameters)

    if (any(ordered.attributes) && has.none.of.these)
        stop('Ordered attributes cannot be specified when the "None of these"',
             ' alternative is present in the analysis.')

    n.questions.left.in <- n.questions - n.questions.left.out
    left.out <- LeftOutQuestions(n.respondents, n.questions,
                                 n.questions.left.out, seed)

    X <- array(data = 0, dim = c(n.respondents, n.questions, n.choices,
                                 n.parameters))

    ind.columns <- (1:n.attributes) + 3
    for (i in 1:n.respondents)
    {
        for (j in 1:n.questions)
        {
            question.number <- questions[i, j]
            ind <- which(design[[2]] == question.number)[1]
            for (k in 1:n.choices)
            {
                if (has.none.of.these && k == n.choices)
                    X[i, j, k, ] <- fillXNoneOfThese(n.parameters, n.attributes,
                                                     n.attribute.parameters)
                else
                {
                    question.design <- as.vector(t(design[ind, ind.columns]))
                    X[i, j, k, ] <- fillXAttributes(n.parameters,
                                                    n.attributes,
                                                    n.attribute.parameters,
                                                    ordered.attributes,
                                                    question.design)
                    ind <- ind + 1
                }
            }
        }
    }

    Y <- unname(sapply(choices, as.numeric))

    if (include.choice.parameters)
    {
        output <- addChoiceParameters(X, n.attributes, n.parameters,
                                      n.attribute.parameters, n.choices,
                                      par.names, all.names, has.none.of.these)
        X <- output$X
        n.attributes <- output$n.attributes
        n.parameters <- output$n.parameters
        n.attribute.parameters <- output$n.attribute.parameters
        par.names <- output$par.names
        all.names <- output$all.names
    }

    subset <- CleanSubset(subset, n.respondents)
    weights <- prepareWeights(weights, subset)
    X <- X[subset, , , ]
    Y <- Y[subset, ]
    n.respondents <- sum(subset)

    split.data <- crossValidationSplit(X, Y, n.questions.left.out, seed)

    prior.mean <- processInputPrior(input.prior.mean, n.parameters,
                                    n.attributes, n.attribute.parameters)
    prior.sd <- processInputPrior(input.prior.sd, n.parameters,
                                  n.attributes, n.attribute.parameters)

    result <- list(n.questions = n.questions,
                   n.questions.left.in = n.questions.left.in,
                   n.questions.left.out = n.questions.left.out,
                   n.choices = n.choices,
                   n.attributes = n.attributes,
                   n.respondents = n.respondents,
                   n.parameters = n.parameters,
                   n.attribute.parameters = n.attribute.parameters,
                   par.names = par.names,
                   all.names = all.names,
                   X.in = split.data$X.in,
                   Y.in = split.data$Y.in,
                   X.out = split.data$X.out,
                   Y.out = split.data$Y.out,
                   subset = subset,
                   weights = weights,
                   parameter.scales = rep(1, n.parameters),
                   prior.mean = prior.mean,
                   prior.sd = prior.sd)
    result
}

readDesignFile <- function(design.file, attribute.levels.file)
{
    design <- readExcelFile(design.file)
    n.attributes <- length(design) - 3
    design.is.numeric <- all(sapply(design[4:length(design)], function(x) {
            is.numeric(x) || !any(is.na(suppressWarnings(as.numeric(x))))
        }))
    if (design.is.numeric && (is.null(attribute.levels.file) ||
                              attribute.levels.file == ""))
        stop("A file containing attribute levels is required.")
    else if (!design.is.numeric && !is.null(attribute.levels.file) &&
                                    attribute.levels.file != "")
        warning("The supplied attribute levels will be ignored as levels",
            " are present in the design file.")

    if (design.is.numeric)
    {
        # we apply as.numeric because the design may still contain strings of
        # numbers, e.g. "12"
        design <- data.frame(sapply(design, as.numeric))
        attribute.levels <- processAttributeLevelsFile(attribute.levels.file)
        result <- list(design = design, attribute.levels = attribute.levels)
    }
    else
    {
        nms <- names(design[-1:-3])
        attribute.levels <- list()
        for (i in 1:n.attributes)
        {
            attribute.factor <- as.factor(design[[i + 3]])
            attribute.levels[[nms[i]]] <- levels(attribute.factor)
            design[[i + 3]] <- as.numeric(attribute.factor)
        }
        result <- list(design = design, attribute.levels = attribute.levels)
    }
    result
}

processRespondentData <- function(choices, questions)
{
    choices <- data.frame(sapply(choices, as.numeric))
    ind <- !is.na(rowSums(choices) + rowSums(questions))
    if (sum(!ind) > 0)
        warning(sum(!ind), " respondents with missing data were omitted from",
                " the analysis.")
    list(choices = choices[ind, ], questions = questions[ind, ])
}

# Values for the "None of these" choice
fillXNoneOfThese <- function(n.parameters, n.attributes, n.attribute.parameters)
{
    rep(0, n.parameters)
}

getNumberOfChoices <- function(choices)
{
    first.choices.column <- choices[[1]]
    if (is.numeric(first.choices.column))
        length(unique(first.choices.column))
    else
        length(levels(first.choices.column))
}

# Reads Excel file given local path or URL
#' @importFrom readxl read_excel
#' @importFrom httr GET write_disk
readExcelFile <- function(file.path)
{
    ext <- if (grepl("\\.xls$", file.path))
        ".xls"
    else if (grepl("\\.xlsx$", file.path))
        ".xlsx"
    else
        stop("File name does not end in .xls or .xlsx")

    if (file.exists(file.path)) # local
        read_excel(file.path)
    else # URL
    {
        GET(file.path, write_disk(temp.file <- tempfile(fileext = ext)))
        read_excel(temp.file)
    }
}

orderedAttributes <- function(input.prior.mean, n.attributes, n.parameters)
{
    if (length(input.prior.mean) == 1 ||
        length(input.prior.mean) == n.parameters)
        rep(FALSE, n.attributes)
    else
        input.prior.mean != 0
}
