% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/uglify.R
\name{uglify.function}
\alias{uglify.function}
\title{Makes a function hard to read}
\usage{
uglify.function(f, keep.funs = NULL, keep.vars = names(formals(f)),
  uglify.strings = TRUE)
}
\description{
Purpose: This way we can give strategies to students
who can test their strategies against them. While in principle
one can write some code to make the functions easier readable
again, this is not straightforward. The effort seems fairly 
large. If students do that
}
