
# The code inside can be used to explore the behavior of strategies for the research agreement game
examples.research.agreement.game = function() {
  #Load package
  library(StratTourn)
   
  
  # Generate a game object
  game = make.research.agreement.game(lower.bound=1, upper.bound=5, multiplier=1.3, delta=0.9)

  # Pick a pair of strategies
  strat = nlist(most.of.it,give.generously)
  # Let the strategies play against each other
  run.rep.game(game=game, strat = strat)
  
  
  getwd()
  # Set working directory in which data is stored
  #setwd("D:/libraries/StratTourn/studies")
  setwd("E:/!Data/!Daten/Work/Promotion/L - Lectures/Kooperation Spieltheorie/WS 2015-16/StratTourn/studies")
  
  # Init and run a tournament of several strategies against each other  
  strat = nlist(most.of.it,give.generously.1, give.generously)
  tourn = init.tournament(game=game, strat=strat)
  
  set.storing(FALSE)  # uncoment to make code run faster
  tourn = run.tournament(tourn=tourn, R = 1000)
  set.storing(TRUE)
  
  tourn
  save.tournament(tourn)
  # Analyse tournament in web browser
  show.tournament(tourn)
}

#'Example strategy: most.of.it
#'
#' An example strategy that always shares n-1 of its know-how in the research agreement game
#'
#' @param obs Observations of current know how and share of previous round as specified in the function make.bargaining.game
#' @param i Number of current player
#' @param t Current period 
most.of.it = function(obs,i,t,...) {
  # Extract variables from obs 
  know.how = obs$know.how #How much know-how have I recieved this period?
  j = 3-i #Whats the number of the other player?
  obs.sj = obs$s[j] #How much has the other player shared last round?
  obs.si = obs$s[i] #How much have I shared last round?
  
  share = max(0,know.how-1)
  
  return(list(s=share))
}

#'Example strategy: give.generously (more=2)
#'
#' Strategy which shares (in the research agreement game) as much as the other firm + more, if possible; in the first period everything
#'
#' @param obs Observations of current know how and share of previous round as specified in the function make.bargaining.game
#' @param i Number of current player
#' @param t Current period
#' @param more How much know how should be given in addition to the shared know how of the other firm in the last period?
give.generously = function(obs,i,t,more=2,...) {
  # Extract variables from obs 
  know.how = obs$know.how #How much know-how have I recieved this period?
  j = 3-i #Whats the number of the other player?
  obs.sj = obs$s[j] #How much has the other player shared last round?
  obs.si = obs$s[i] #How much have I shared last round?
  
  if(t==1){
    share = know.how
  } else {
    share = min(obs.sj+more,know.how)
  }
  
  return(list(s=share, more=more))
}

#'Example strategy: give.generously.1 (more=1)
#'
#' Strategy which shares (in the research agreement game) as much as the other firm + more, if possible; in the first period everything
#'
#' @param obs Observations of current know how and share of previous round as specified in the function make.bargaining.game
#' @param i Number of current player
#' @param t Current period
#' @param more How much know how should be given in addition to the shared know how of the other firm in the last period?
give.generously.1 = function(obs,i,t,more=1,...) {
  # Extract variables from obs 
  know.how = obs$know.how #How much know-how have I recieved this period?
  j = 3-i #Whats the number of the other player?
  obs.sj = obs$s[j] #How much has the other player shared last round?
  obs.si = obs$s[i] #How much have I shared last round?
  
  if(t==1){
    share = know.how
  } else {
    share = min(obs.sj+more,know.how)
  }
  
  return(list(s=share, more=more))
}

#' Waits for Input of Human Player in Research Agreement Game
#' 
#' 
human.player.ra = function(obs,i,t,...){
  restore.point("human.player.ra")
  # Extract variables from obs 
  know.how = obs$know.how #How much know-how have I recieved this period?
  j = 3-i #Whats the number of the other player?
  obs.sj = obs$s[j] #How much has the other player shared last round?
  obs.si = obs$s[i] #How much have I shared last round?
  
  if(t==1){
    cat(paste0("Your know.how: ", know.how,"\n",collapse=""))
    cat("What share do you want to demand in your first round? Write a number or \"Stop\"")
  } else {
    cat(paste0("Your know-how: ",know.how,"\nYour share last round: ",obs.si,"\n","Share of other Strategy: ",obs.sj,"\n",collapse=" "))
    cat("What do you want to do?")
  }
  
  ok <- FALSE
  
  while(!ok){
    line <- readline()
    if(line[1]=="Stop"){
      stop("Player stopped")
    } else if(!is.na(as.numeric(line[1]))){
      my.action = as.numeric(line[1])
      ok <- TRUE
    } else {
      cat("Not a valid number. Please retry.")
    }
  }
  
  return(list(s=my.action))
}

#' Generate a research agreement game
#'
#' We consider two firms which generate a random amount of know how each period. Each firm knows how much know how has been generated by itself, but does not know how much know how has been generated by the other firm. In each period they can decide to share a part of their know how with the other firm.
#' 
#' @param lower.bound At least this much know how is generated from each firm in each period; Non-negative integer value expected
#' @param upper.bound At most this much know how is generated from each firm in each period; positive integer value expected
#' @param multiplier Non-shared know how is multiplied by this value
#' @param delta Probability of playing another round
make.research.agreement.game = function(lower.bound=1, upper.bound=5, multiplier=1.5, delta=0.9, ...) {
    
  run.stage.game = function(a,t,t.obs,game.states,...) {
    restore.point("research.agreement.run.stage.game")
    
    know.hows = game.states$know.hows
    #Take and transform shares to allowed values
    s = unlist(a, use.names=FALSE)
    s <- sapply(1:2,FUN=function(x){
      if(s[x]<0){
        return(0)
      } else if (s[x]>know.hows[x]){
        return(know.hows[x])
      } else {
        return(round(s[x]))
      }
    })
    
    #Calculation of payoff
    payoff <- sapply(1:2,FUN=function(i){
      j = 3-i
      res <- (know.hows[i]-s[i])*multiplier + s[i] + s[j]
      return(res)
    })
    
    #Draw new know.how for next round
    know.hows <- sample(lower.bound:upper.bound, 2, replace=TRUE)

    # private signals: each player sees her cost type
    obs = list(list(know.how=know.hows[1], s=s),
               list(know.how=know.hows[2], s=s))
    round.stats = quick.df(t=c(t,t),i=1:2,know.how=game.states$know.hows,s=s,u=payoff) 
    return(list(payoff=payoff,obs=obs, round.stats=round.stats, game.states=nlist(know.hows)))
  } 
  
  check.action = function(ai,i,t,...) {
    s = ai$s
    if (is.finite(s) & length(s)==1) {
      return()
    }
    stop(paste0("player ",i, "'s strategy in period ",t, " returned an infeasible action: ", ai))
  }
  example.action = function(i=1,t=1,...) {
    list(s=0)
  }
  example.obs = function(i=1,t=1,game.states,...) {
    list(know.how=game.states$know.hows[i], s=c(0,0))
  }
  
  initial.game.states = function() {
    know.hows <- sample(lower.bound:upper.bound, 2, replace=TRUE)
    nlist(know.hows)
  }
  
  nlist(run.stage.game, initial.game.states, check.action,example.action,example.obs, n=2, private.signals=TRUE, params = nlist(lower.bound, upper.bound, multiplier), sym=TRUE, delta=delta, name="research.agreement")
}


