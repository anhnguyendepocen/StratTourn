examples.againstGivenApp = function() {
  setwd("D:/libraries/StratTourn")
  tourns.dir="D:/libraries/StratTourn/GivenTourn"
  set.restore.point.options(display.restore.point = TRUE)
  set.storing(TRUE)
  app = againstGivenLoginApp(tourns.dir, init.userid="sebastian.kranz@uni-ulm.de", init.password="mzofo")  
  runEventsApp(app)  
  
  runEventsApp(app, launch.browser=rstudio::viewer)
  runEventsApp(app)  
  
  STRATTOURN.GLOB$get.sr.from.app=FALSE
  
  launch.browser=TRUE
  runEventsApp(app, launch.browser=TRUE)  
}

againstGivenLoginApp = function(tourns.dir=getwd(), db.dir = paste0(getwd(),"/db"), init.userid="", init.password="",app.url="http://127.0.0.1:4915", app.title="Battle of Strategies") {
  restore.point("againstGivenApp")
  
  app = eventsApp()

  login.fun = function(app=getApp(),userid,lop,...) {
    sr = app$sr
    sr$userid = userid
    cat("Successfully logged in as ", userid)
    
    sr = init.sr.instance(app = app, userid=userid)

    setUI("mainUI", sr$main.ui)
  }

  check.email.fun = function(email="",...) {
    restore.point("check.email.fun")
    if (!isTRUE(email=="sebastian.kranz@uni-ulm.de" |
                email=="sebkranz@gmail.com")) {
      return(list(ok=FALSE, msg="Please only send to your own email adresses!"))
    }
  list(ok=TRUE,msg="")
  }

  db.arg = list(dbname=paste0(db.dir,"/stratDB.sqlite"),drv=SQLite())

  lop = loginPart(db.arg = db.arg, login.fun=login.fun, check.email.fun=check.email.fun,app.url=app.url, app.title="Battle of Strategies",init.userid=init.userid, init.password=init.password,container.id = "mainUI")
  set.lop(lop)
  lop.connect.db(lop=lop)
  lop$login$ui = lop.login.ui(lop)
  lop$smtp = lop.get.smtp()

  appInitHandler(function(session,...) {
    initLoginDispatch(lop)
  })

  app$ui = fluidPage(uiOutput("mainUI"))
  app$lop = lop
  app
}

init.sr.instance = function(app = getApp(), userid="jondoe") {
  restore.point("init.sr.instance")
  app$glob$ptourns = list()
  
  sr = new.env(parent=globalenv())
  app$sr = sr
  STRATTOURN.GLOB$get.sr.from.app=TRUE
  
  sr$tourns.dir = app$glob$tourns.dir = tourns.dir
  sr$tourn.names = app$glob$tourn.names = list.files(tourns.dir)
  sr$tourn.name = sr$tourn.names[1]
  sr$userid = userid
  sr$main.ui = ag.make.ui()
  
  ag.load.tourn(sr$tourn.name)
  ag.set.user.strat.ui()
  sr
}

againstGivenApp = function(tourns.dir=getwd(),...) {
  restore.point("againstGivenApp")
  
  library(shinyEvents)  
  library(shinyAce)
  library(shinyBS)
  
  app = eventsApp()
  
  app$glob$ptourns = list()
  
  sr = new.env(parent=globalenv())
  app$sr = sr
  STRATTOURN.GLOB$get.sr.from.app=TRUE
  
  sr$tourns.dir = app$glob$tourns.dir = tourns.dir
  sr$tourn.names = app$glob$tourn.names = list.files(tourns.dir)
  sr$tourn.name = sr$tourn.names[1]
  
  if (is.null(loginPart)) {
    ui = ag.make.ui()
    ag.load.tourn(sr$tourn.name)
    ag.set.user.strat.ui()
    
    
    
    appInitHandler(initHandler = function(app,...) {
      restore.point("app.initHandler")
      #penv = parent.env(app$sr)
      #app$sr = as.environment(as.list(app$sr))
      #parent.env(app$sr) <- penv
    }, app=app)
    
    app$ui = ui
    app
  }
}

#' Analyse a tournament interactively in web browser
showAgainstGiven = function(tourn=NULL, tourn.file=NULL, launch.browser=TRUE, file.path=getwd(), strat.shares=NULL) {
  
  app = againstGivenApp(tourn=tourn, tourn.file=tourn.file)
  runEventsApp(app, launch.browser=launch.browser)  
}

ag.make.ui = function(app=getApp(), sr=app$sr) {
  restore.point("ag.make.ui")
  ui = fluidPage(title = "Analyse Tournament with own Strategy",
    sidebarLayout(
      sidebarPanel(
        selectInput("tournSelect","Tournament", sr$tourn.names),
        uiOutput("lhsPanel")
      ),
      mainPanel(
        uiOutput("mainPanel")
#        tabsetPanel(id="rhsPanels",
#          tabPanel("Strategy",uiOutput("stratPanel")),
#          tabPanel("Reports",uiOutput("reportPanel")) 
#        )  
      )
    )
  )
  changeHandler("tournSelect", function(app,value,...) {
    ag.load.tourn(name=value)
    ag.set.user.strat.ui()
  })
  ui
}

ag.set.user.strat.ui = function(app=getApp(), sr=app$sr,...) {
  restore.point("ag.set.strat.ui")
  tourn.name = sr$tourn.name
  init.strat = app$glob$ptourns[[tourn.name]]$example.strat.txt

  ui = list(
    aceEditor("userStratAce", value=init.strat, height="300px"),
    bsAlert("userStratAlert"),
    fluidRow(
      column(3,
            bsButton("setUserStratBtn","Import strategy", size="small")
      )
    )
  )
  buttonHandler("setUserStratBtn", function(app,...) {
    ag.import.user.strat(app=app)
  })
  setUI("mainPanel",ui)
}

is.error <- function(x) inherits(x, "try-error")

get.functions = function(env) {
  restore.point("get.functions")
  vars = ls(env)
  if (length(vars)==0) return(list())
  is.fun <- sapply(vars, function(x) is.function(get(x,env)))
  
  vars = vars[is.fun]
  if (length(vars)==0) return(list())

  funs = lapply(vars, get,envir=env)
  names(funs) = vars
  funs
}


ag.run.active.tourn = function( app=getApp(),sr = app$sr,   R = as.numeric(getInputValue("repTournInput")), ...) {
  restore.point("ag.run.active.tourn")

  if (!is.finite(R)) {
    createAlert(app$session, "userStratAlert", title = "Error: cannot run...", content = "You must specify a correct number of rounds...", style = "warning", append = FALSE)
    return(FALSE)
  }

  if (!is(sr$tourn,"CombinedTournament")) {
    createAlert(app$session, "userStratAlert", title="Error: cannot run...",content = "You have not yet imported a strategy yet...", style = "warning", append = FALSE)
    return(FALSE)
  }
  
  atourn = sr$tourn$tourns[[1]]

  atourn$separate.round.data = FALSE
  withProgress(session=app$session,min=0,max=R+1, expr={
    shiny::setProgress(message = "Running tournament...",
    detail = paste0("Finished 0 / ", R))
    
    do.store = is.storing()
    set.storing(FALSE)
    r = 1
    for (r in 1:R) {
      atourn = try(run.tournament(atourn,R = 1), silent=TRUE)
      if(inherits(atourn, "try-error")) break
      shiny::setProgress(value=r,detail = paste0("Finished ",r," / ", R))
    }
    set.storing(do.store)
  })
  
  #atourn = try(run.tournament(atourn,R = R))
  if (inherits(atourn, "try-error")) {
    restore.point("ag.run.active.tourn.inner")
    msg = paste0(as.character(atourn),collapse="\n")
    msg = paste0(msg,". Correct your own strategy and import it again.")
    createAlert(app$session, "userStratAlert", title = "Error when running tournament.", content = msg , style = "warning", append = FALSE)
    return(FALSE)
  } 


  sr$tourn$tourns[[1]] = atourn
  sr$used.strats = sr$strats = names(sr$tourn$strat)
  set.tourn.data(sr=sr,set.round.data = FALSE)
  ag.set.round.data(sr=sr)
  return(TRUE)
}



ag.import.user.strat = function( app=getApp(),sr = app$sr,...) {
  restore.point("ag.import.user.strat")

  code = isolate(app$session$input$userStratAce)
  res = parse.user.strats(code)
  if (!res$ok) {
    createAlert(app$session, "userStratAlert", title = "Error", content = res$msg, style = "warning", append = FALSE)
    return()
  } 
  strats = res$funs
  sr$user.strats = strats
  strat.name = paste0(names(sr$user.strats), collapse=", ")
  
  sr$tourn = active.passive.tourn(astrat = strats, ptourn = sr$ptourn,separate.round.data=FALSE)
  
  # run imported strategy for one round
  ag.run.active.tourn(app = app,sr=sr, R=1)
  
  #createAlert(app$session, "userStratAlert", title = paste0("Imported strategy ",strat.name), content = "Now run the tournament for some rounds...", style = "success", append = FALSE)

  
}

ag.set.lhs.ui = function(rep.li=sr$rep.li,app=getApp(), sr=app$sr) {
  restore.point("ag.set.lhs.ui")

  strats = sr$strats
  
  buttons = lapply(rep.li, function(rep) {
    bsButton(rep$button.id,rep$label, size="small")
  })
  names(buttons)=NULL
  report.buttons = buttons
  for (rep in rep.li) {
    buttonHandler(rep$button.id, ag.click.report.btn)
  }

  
  
  ui = list(
    #bsButton("update_strat_btn","update", size="small"),
    #selectizeInput("used_strats", label = "Used strategies:",
    #choices = strats, selected = strats, multiple=TRUE,width="100%"),
    #aceEditor("sizes_string", sizes.str, height = "50px", fontSize = 12, debounce = 10, wordWrap=TRUE,showLineNumbers = FALSE, highlightActiveLine = FALSE),
    fluidRow(
      column(3,bsButton("stratBtn","Edit")),
      column(2,bsButton("runTournBtn","Run")),
      column(4,numericInput("repTournInput",NULL,value = 20,min = 1,max=1000,step = 1))
    ),
    hr(),
    report.buttons,
    uiOutput("ui.custom.parameters")
  )
  buttonHandler("stratBtn",ag.set.user.strat.ui)

  buttonHandler("runTournBtn",function(app,...) {
    ag.run.active.tourn(app=app,...)
    sr$report = sr$rep.li[[1]]
    ag.set.report()    
  })

  setUI( "lhsPanel", ui)
}


ag.set.report = function( app=getApp(), sr=app$sr) {
  restore.point("ag.set.report")

  # Custom parameter settings
  ui = make.ui.custom.parameters(sr=sr)
  setUI("ui.custom.parameters",ui)

  # Report window
  html=compile.report(sr$report,session=app$session, sr=sr)
  setUI("mainPanel",HTML(html))
}


load.first.tourn.from.dir = function(dir) {
  restore.point("load.first.tourn.from.dir")
  files = list.files(dir,pattern = ".*\\.tou$")
  file=files[1]
  load.tournament(file = file, path = dir)
}

ag.load.global.ptourn = function(name,app, tourn.dir=paste0(app$glob$tourns.dir,"/",name)) {
  restore.point("ag.load.global.ptourn")
  
  ptourn = load.first.tourn.from.dir(tourn.dir)
  rs.file = paste0(tourn.dir,"/", ptourn$rs.file)
  ptourn$ard = import.round.data(file=rs.file, tourn=ptourn, store.in.sr = FALSE)
  
  example.file = paste0(tourn.dir,"/example_strat.r")
  if (file.exists(example.file)) {
    ptourn$example.strat.txt = paste0(readLines(example.file),collapse="\n")
  } else {
    ptourn$example.strat.txt = "# Insert your strategy below 
# my.strat = function(obs,t,i,...) {
#    ...
# }"
  }
  
  app$glob$ptourns[[name]] = ptourn
  invisible(ptourn)
}

ag.load.tourn = function(name,app=getApp(),sr=app$sr) {
  restore.point("ag.load.tourn")

  sr$tourn.name = name
  sr$tourn.dir = paste0(sr$tourns.dir,"/",sr$tourn.name)
  if (is.null(app$glob$ptourns[[name]])) {
    ag.load.global.ptourn(name=name,app=app)    
  }
  
  sr$tourn=sr$ptourn=app$glob$ptourns[[name]]
  
  sr$ard = sr$ptourn$rd
  sr$used.strats = sr$strats = names(sr$tourn$strat)
  set.tourn.data(tourn = sr$tourn, sr=sr)
  
  sr$rep.li = make.rep.li(sr=sr)
  sr$report = sr$rep.li[[1]]
  sr$strats = sr$tourn$strats  
  
  ag.set.lhs.ui()
  ag.set.report()
}


ag.set.round.data = function( tourn=sr$tourn, app=getApp(), sr=sr) {
  restore.point("ag.set.round.data")
  if (!is(tourn,"CombinedTournament")) {
    import.round.data(tourn=tourn,sr=sr)
    return()
  }

  atourn = tourn$tourns[[1]]
  ptourn = tourn$tourns[[2]]
  
  # Transform active tournament round data
  rd = as.tbl(as.data.frame(atourn$rd))
  ard = add.other.var(rd,c("strat","u"))
  
  sr$ard = rbind(ard, ptourn$ard)
  
  adapt.round.data(sr=sr)
}

ag.click.report.btn = function(id,..., app=getApp(), sr=app$sr) {
  restore.point("ag.click.report.btn")
  cat("ag.click.report.btn")
  #browser()
  id = str.left.of(id,"_report_btn")
  sr$report = sr$rep.li[[id]]
  used.strats = sr$used.strats
  #sizes.string = isolate(app$session$input$sizes_string)
  #set.tourn.data()
  set.tourn.data(sr=sr)
  
  # Report window
  html=compile.report(sr$report, session=app$session, sr=sr)
  setUI("mainPanel",HTML(html))
  updateTabsetPanel(app$session, "rhsPanels", selected = "Reports")
}
