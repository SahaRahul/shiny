#' Dynamically insert/remove a tabPanel
#'
#' Dynamically insert or remove a \code{\link{tabPanel}} (or a
#' \code{\link{navbarMenu}}) from an existing \code{\link{tabsetPanel}},
#' \code{\link{navlistPanel}} or \code{\link{navbarPage}}.
#'
#' When you want to insert a new tab before or after an existing tab, you
#' should use \code{insertTab}. When you want to prepend a tab (i.e. add a
#' tab to the beginning of the \code{tabsetPanel}), use \code{prependTab}.
#' When you want to append a tab (i.e. add a tab to the end of the
#' \code{tabsetPanel}), use \code{appendTab}.
#'
#' For \code{navbarPage}, you can insert/remove conventional
#' \code{tabPanel}s (whether at the top level or nested inside a
#' \code{navbarMenu}), as well as an entire \code{\link{navbarMenu}}.
#' For the latter case, \code{target} should be the \code{menuName} that
#' you gave your \code{navbarMenu} when you first created it (by default,
#' this is equal to the value of the \code{title} argument).
#'
#' @param inputId The \code{id} of the \code{tabsetPanel} (or
#'   \code{navlistPanel} or \code{navbarPage}) into which \code{tab} will
#'   be inserted/removed.
#'
#' @param tab The item to be added (must be created with \code{tabPanel},
#'   or with \code{navbarMenu}).
#'
#' @param target If inserting: the \code{value} of an existing
#'   \code{tabPanel}, next to which \code{tab} will be added.
#'   If removing: the \code{value} of the \code{tabPanel} that
#'   you want to remove. See Details if you want to insert next to/remove
#'   an entire \code{navbarMenu} instead.
#'
#' @param position Should \code{tab} be added before or after the
#'   \code{target} tab?
#'
#' @param select Should \code{tab} be selected upon being inserted?
#'
#' @param session The shiny session within which to call this function.
#'
#' @seealso \code{\link{showTab}}
#'
#' @examples
#' ## Only run this example in interactive R sessions
#' if (interactive()) {
#'
#' # example app for inserting/removing a tab
#' ui <- fluidPage(
#'   sidebarLayout(
#'     sidebarPanel(
#'       actionButton("add", "Add 'Dynamic' tab"),
#'       actionButton("remove", "Remove 'Foo' tab")
#'     ),
#'     mainPanel(
#'       tabsetPanel(id = "tabs",
#'         tabPanel("Hello", "This is the hello tab"),
#'         tabPanel("Foo", "This is the foo tab"),
#'         tabPanel("Bar", "This is the bar tab")
#'       )
#'     )
#'   )
#' )
#' server <- function(input, output, session) {
#'   observeEvent(input$add, {
#'     insertTab(inputId = "tabs",
#'       tabPanel("Dynamic", "This a dynamically-added tab"),
#'       target = "Bar"
#'     )
#'   })
#'   observeEvent(input$remove, {
#'     removeTab(inputId = "tabs", target = "Foo")
#'   })
#' }
#'
#' shinyApp(ui, server)
#'
#'
#' # example app for prepending/appending a navbarMenu
#' ui <- navbarPage("Navbar page", id = "tabs",
#'   tabPanel("Home",
#'     actionButton("prepend", "Prepend a navbarMenu"),
#'     actionButton("append", "Append a navbarMenu")
#'   )
#' )
#' server <- function(input, output, session) {
#'   observeEvent(input$prepend, {
#'     id <- paste0("Dropdown", input$prepend, "p")
#'     prependTab(inputId = "tabs",
#'       navbarMenu(id,
#'         tabPanel("Drop1", paste("Drop1 page from", id)),
#'         tabPanel("Drop2", paste("Drop2 page from", id)),
#'         "------",
#'         "Header",
#'         tabPanel("Drop3", paste("Drop3 page from", id))
#'       )
#'     )
#'   })
#'   observeEvent(input$append, {
#'     id <- paste0("Dropdown", input$append, "a")
#'     appendTab(inputId = "tabs",
#'       navbarMenu(id,
#'         tabPanel("Drop1", paste("Drop1 page from", id)),
#'         tabPanel("Drop2", paste("Drop2 page from", id)),
#'         "------",
#'         "Header",
#'         tabPanel("Drop3", paste("Drop3 page from", id))
#'       )
#'     )
#'   })
#' }
#'
#' shinyApp(ui, server)
#'
#' }
#' @export
insertTab <- function(inputId, tab, target,
                      position = c("before", "after"), select = FALSE,
                      session = getDefaultReactiveDomain()) {
  force(target)
  force(select)
  position <- match.arg(position)
  inputId <- session$ns(inputId)

  # Barbara -- August 2017
  # Note: until now, the number of tabs in a tabsetPanel (or navbarPage
  # or navlistPanel) was always fixed. So, an easy way to give an id to
  # a tab was simply incrementing a counter. (Just like it was easy to
  # give a random 4-digit number to identify the tabsetPanel). Since we
  # can only know this in the client side, we'll just pass `id` and
  # `tsid` (TabSetID) as dummy values that will be fixed in the JS code.
  item <- buildTabItem("id", "tsid", TRUE, divTag = tab,
    textFilter = if (is.character(tab)) navbarMenuTextFilter else NULL)

  callback <- function() {
    session$sendInsertTab(
      inputId = inputId,
      liTag = processDeps(item$liTag, session),
      divTag = processDeps(item$divTag, session),
      menuName = NULL,
      target = target,
      position = position,
      select = select)
  }
  session$onFlush(callback, once = TRUE)
}

#' @param menuName This argument should only be used when you want to
#'   prepend (or append) \code{tab} to the beginning (or end) of an
#'   existing \code{\link{navbarMenu}} (which must itself be part of
#'   an existing \code{\link{navbarPage}}). In this case, this argument
#'   should be the \code{menuName} that you gave your \code{navbarMenu}
#'   when you first created it (by default, this is equal to the value
#'   of the \code{title} argument). Note that you still need to set the
#'   \code{inputId} argument to whatever the \code{id} of the parent
#'   \code{navbarPage} is. If \code{menuName} is left as \code{NULL},
#'   \code{tab} will be prepended (or appended) to whatever
#'   \code{inputId} is.
#'
#' @rdname insertTab
#' @export
prependTab <- function(inputId, tab, select = FALSE, menuName = NULL,
                       session = getDefaultReactiveDomain()) {
  force(select)
  force(menuName)
  inputId <- session$ns(inputId)

  item <- buildTabItem("id", "tsid", TRUE, divTag = tab,
    textFilter = if (is.character(tab)) navbarMenuTextFilter else NULL)

  callback <- function() {
    session$sendInsertTab(
      inputId = inputId,
      liTag = processDeps(item$liTag, session),
      divTag = processDeps(item$divTag, session),
      menuName = menuName,
      target = NULL,
      position = "after",
      select = select)
  }
  session$onFlush(callback, once = TRUE)
}

#' @rdname insertTab
#' @export
appendTab <- function(inputId, tab, select = FALSE, menuName = NULL,
                      session = getDefaultReactiveDomain()) {
  force(select)
  force(menuName)
  inputId <- session$ns(inputId)

  item <- buildTabItem("id", "tsid", TRUE, divTag = tab,
    textFilter = if (is.character(tab)) navbarMenuTextFilter else NULL)

  callback <- function() {
    session$sendInsertTab(
      inputId = inputId,
      liTag = processDeps(item$liTag, session),
      divTag = processDeps(item$divTag, session),
      menuName = menuName,
      target = NULL,
      position = "before",
      select = select)
  }
  session$onFlush(callback, once = TRUE)
}

#' @rdname insertTab
#' @export
removeTab <- function(inputId, target,
                      session = getDefaultReactiveDomain()) {
  force(target)
  inputId <- session$ns(inputId)

  callback <- function() {
    session$sendRemoveTab(
      inputId = inputId,
      target = target)
  }
  session$onFlush(callback, once = TRUE)
}


#' Dynamically hide/show a tabPanel
#'
#' Dynamically hide or show a \code{\link{tabPanel}} (or a
#' \code{\link{navbarMenu}})from an existing \code{\link{tabsetPanel}},
#' \code{\link{navlistPanel}} or \code{\link{navbarPage}}.
#'
#' For \code{navbarPage}, you can hide/show conventional
#' \code{tabPanel}s (whether at the top level or nested inside a
#' \code{navbarMenu}), as well as an entire \code{\link{navbarMenu}}.
#' For the latter case, \code{target} should be the \code{menuName} that
#' you gave your \code{navbarMenu} when you first created it (by default,
#' this is equal to the value of the \code{title} argument).
#'
#' @param inputId The \code{id} of the \code{tabsetPanel} (or
#'   \code{navlistPanel} or \code{navbarPage}) in which to find
#'   \code{target}.
#'
#' @param target The \code{value} of the \code{tabPanel} to be
#'   hidden/shown. See Details if you want to hide/show an entire
#'   \code{navbarMenu} instead.
#'
#' @param select Should \code{target} be selected upon being shown?
#'
#' @param session The shiny session within which to call this function.
#'
#' @seealso \code{\link{insertTab}}
#'
#' @examples
#' ## Only run this example in interactive R sessions
#' if (interactive()) {
#'
#' ui <- navbarPage("Navbar page", id = "tabs",
#'   tabPanel("Home",
#'     actionButton("hideTab", "Hide 'Foo' tab"),
#'     actionButton("showTab", "Show 'Foo' tab"),
#'     actionButton("hideMenu", "Hide 'More' navbarMenu"),
#'     actionButton("showMenu", "Show 'More' navbarMenu")
#'   ),
#'   tabPanel("Foo", "This is the foo tab"),
#'   tabPanel("Bar", "This is the bar tab"),
#'   navbarMenu("More",
#'     tabPanel("Table", "Table page"),
#'     tabPanel("About", "About page"),
#'     "------",
#'     "Even more!",
#'     tabPanel("Email", "Email page")
#'   )
#' )
#'
#' server <- function(input, output, session) {
#'   observeEvent(input$hideTab, {
#'     hideTab(inputId = "tabs", target = "Foo")
#'   })
#'
#'   observeEvent(input$showTab, {
#'     showTab(inputId = "tabs", target = "Foo")
#'   })
#'
#'   observeEvent(input$hideMenu, {
#'     hideTab(inputId = "tabs", target = "More")
#'   })
#'
#'   observeEvent(input$showMenu, {
#'     showTab(inputId = "tabs", target = "More")
#'   })
#' }
#'
#' shinyApp(ui, server)
#' }
#'
#' @export
showTab <- function(inputId, target, select = FALSE,
                    session = getDefaultReactiveDomain()) {
  force(target)

  if (select) updateTabsetPanel(session, inputId, selected = target)
  inputId <- session$ns(inputId)

  callback <- function() {
    session$sendChangeTabVisibility(
      inputId = inputId,
      target = target,
      type = "show"
    )
  }
  session$onFlush(callback, once = TRUE)
}

#' @rdname showTab
#' @export
hideTab <- function(inputId, target,
                    session = getDefaultReactiveDomain()) {
  force(target)
  inputId <- session$ns(inputId)

  callback <- function() {
    session$sendChangeTabVisibility(
      inputId = inputId,
      target = target,
      type = "hide"
    )
  }
  session$onFlush(callback, once = TRUE)
}
