#' Checks if a file exists
#' 
#' Checks if files exists after converting relative into absolute path based on 
#' current working directory by default.
#' 
#' @param x A filename.
#' @param wd A Path to the file, if not set otherwise the working directory is used.
#' @return TRUE if file exists, FALSE if not.
#' @export
#' @keywords internal
#' @example /inst/examples/file_existsExample.R
#' 
file_exists <- function(file, wd=getwd())
{
  if (!R.utils::isAbsolutePath(file)) 
    noabs.info <- c("\n\n(You supplied a relative path. ",
                    "Note that any relative path is converted ",
                    "to absolute using the current working directory as basis).")
  else
    noabs.info <- NULL
  
  file <- R.utils::getAbsolutePath(file, workDirectory=wd) 
  
  if (!file.exists(file))
    stop("The following file does not exist:\n", file, noabs.info, call.=FALSE)
  else
    TRUE
}


#' Checks if a string is contained in a Word document.
#' 
#' This function checks if a string in contained in a Word document.
#' 
#' @param find A string.
#' @return \code{TRUE} if string is found, \code{FALSE} if not.
#' @export
#' @example /inst/examples/wdSearchStringExample.R
#' 
wdSearchString <- function(find = "", wdapp = .R2wd, warn=TRUE) 
{
  r <- wdapp[["ActiveDocument"]]$Select()   # select whole content
  f <- wdapp[["Selection"]]$Find()          # search in selection
  f$ClearFormatting()                       # Removes text and paragraph formatting 
  success <- f$Execute(FindText=find)       # text becomes selection
  success                                   # return TRUE or FALSE  
}


#' Replaces a string with an image
#' 
#' This function replaces a piece of text with an image.
#' 
#' @param find A string.
#' @param file The path to the image.
#' @return Invisibly returns a pointer to new inlineshape object.
#' @export
#' @example /inst/examples/wdReplaceTextByImageExample.R
#' @section TODO: handle case if text is found multiple times
#' 
wdReplaceTextByImage <- function(find = "", file, wdapp = .R2wd, wd=getwd(), warn=TRUE) 
{
  file <- R.utils::getAbsolutePath(file, workDirectory=wd) 
  file_exists(file)                               # check if image exists
  success <- wdSearchString(find, wdapp=wdapp)    # search string in document and select
  
  # if text was not found
  if (!success) {
    if (warn)
      warning("The find text was not found in document", call. = FALSE)
    return(FALSE)
  } 
  
  # delete and replace
  r <- wdapp[["Selection"]][["Range"]]            # get range of selection
  r$Delete()      
  ishp <- r[["InlineShapes"]]$AddPicture(
    FileName=file, LinkToFile=FALSE, 
    SaveWithDocument=TRUE, Range=r)
  invisible(ishp)                                 # return pointer to inline shape
}


#' Changes the scale of an image
#' 
#' This function change the sclaing of an image in a document.
#' @param i The number of the image inside the document.
#' @param ishp A pointer to the inline shape, as e.g. returned by \code{\link{wdReplaceTextByImage}}.
#' @param width The width of the new image in Percent of the word page.
#' @param height The height of the new image in Percent of the word page.
#' @param units The number of pixel the image should have
#' @param lock.asp Locks the ratio of height and width (aspect ratio).
#' @return invisibly returns pointer to new inlineshape object.
#' @export 
#' @example /inst/examples/wdScaleImageExample.R
#' @section TODO: add example with wdReplaceTextByImage
#' 
wdScaleImage <- function(i, ishp=NULL, width=NULL, height=NULL, 
                         lock.asp=TRUE, units="px", wdapp = .R2wd)
{
  units <- match.arg(units, c("px", "percent", "widthpercent"))
  
  wddoc <- wdapp[["ActiveDocument"]]
  ishps <- wddoc[["InlineShapes"]]                # get inlineshapes
  if (is.null(ishp))
    ishp <- ishps$Item(i)                         # get ith inline shape  
  ishp[["LockAspectRatio"]] <- lock.asp 
  
  # units in pixel 
  w.null <- is.null(width)
  h.null <- is.null(height)
  
  if (units == "px") {
    if (!w.null)
      ishp[["Width"]] <- width
    if (!h.null)
      ishp[["Height"]] <-  height  
  } else if (units == "percent"){
    if (!w.null)
      ishp[["ScaleWidth"]] <- width
    if (!h.null)
      ishp[["ScaleHeight"]] <-  height  
  } else if (units == "widthpercent") {
    avail.width <- wddoc[["PageSetup"]][["TextColumns"]][["Width"]]      # get available width
    if (!w.null)
      ishp[["Width"]] <- avail.width * width / 100    
  }
}


#' Adds a caption to an image.
#' 
#' This function adds a caption to an image.
#' 
#' @param i The number of the image inside the document.
#' @param ishp A pointer to the image. Best used with wdReplaceTextByImage return value.
#' @param title The title of the image.
#' @export
#' @example /inst/examples/wdAddImageCaptionExample.R
#' @section TODO: check if captions exists and replace it.
#
wdAddImageCaption <- function(i, ishp=NULL, title="", sep=":",
                              wdapp = .R2wd)
{
  wddoc <- wdapp[["ActiveDocument"]]
  ishps <- wddoc[["InlineShapes"]]                # get inlineshapes
  if (is.null(ishp))
    ishp <- ishps$Item(i)                         # get ith inline shape 
  ishp$Select()
  wdsel <- wdapp[["Selection"]]
  title <- paste0(sep, " ", title, "\n")
  wdsel$InsertCaption(Label=-1,
                      Title=title,
                      Position=1)        # 1=below
}
