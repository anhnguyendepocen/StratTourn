---
output:
  html_document:
    highlight: textmate
    theme: readable
    toc: yes
---
 

Analyzing Cooperation with Game Theory and Simulation
========================================================================
Tutorial for the R package StratTourn
========================================================================
```{r setup, include=FALSE, cache = F}
knitr::opts_chunk$set(error = TRUE)
```
  
**Date: 2014-10-28**

**Author: Sebastian Kranz (sebastian.kranz@uni-ulm.de)**

**with help by Martin Kies (martin.kies@uni-ulm.de)**

## 1. Installing neccessary software

### 1.1 Installing R and RStudio

First you need to install R, which is a very popular and powerful open source statistical programming language. You can download R for Windows, Max or Linux here:
  
  http://cran.r-project.org/

Note: If you have already installed R, you may want to update to the newest version by installing it again. 

I recommend to additionally install RStudio, which is a great open source IDE for R:

http://rstudio.org/

### 1.2 Installing necessary R packages

You need to install several R packages from the internet. To do so, simply run in the R console the following code (you can use copy & paste):
```{r eval=FALSE}
install.packages("devtools")
install.packages("data.table")
install.packages("ggplot2")
install.packages("reshape2")
install.packages("dplyr")
install.packages("shiny")
install.packages("knitr")
install.packages("xtable")
install.packages("shinyBS")
install.packages("googleVis")


library(devtools)
install_github(repo="skranz/restorepoint")
install_github(repo="skranz/sktools")
install_github(repo="skranz/stringtools")
install_github(repo="skranz/dplyrExtras")
install_github(repo="skranz/StratTourn")
install_github(repo="skranz/shinyAce")

```

## 2. Brief Background: The Prisoners' Dilemma Game

In the 'Evolution of Cooperation' Robert Axelrod describes his famous computer tournament that he used to investigate effective cooperation strategies in repeated social dilemma situations. His tournament was based on a repeated *prisoner's dilemma game*, which I will also use as an example in this tutorial.

### 2.1 The one-shot Prisoner's Dilemma
A one-shot prisoner's dilemma (short: PD) is played only once. We can describe a PD by the following *payoff matrix*:

<center><table border="1"><tr>
    <td align='center'>Pl 1. / Pl. 2</td>
    <th align='center'>C</th>
    <th align='center'>D</th>
  </tr><tr>
    <th align='center'>C</th>
    <td align='center'>  1, 1</td>
    <td align='center'> -1, 2</td>
  </tr><tr>
    <th align='center'>D</th>
    <td align='center'>  2,-1</td>
    <td align='center'>  0, 0</td>
</tr></table></center>

Each player can either cooperate *C* or defect *D*, which means not to cooperate. The row shows player 1's action and the column player 2's. The cells show the *payoffs* of player 1 and 2 for each *action profile*. For example, when player 1 cooperates C and player 2 defects D, i.e. the action profile (C,D) is played, then player 1's payoff is -1 and player 2's payoff is 2.

The highest average payoff (1,1) could be achieved if both players cooperate (C,C). Yet, assume that both players decide independently which action they choose, i.e. player 1's action does not influence player 2's action and vice versa. Then no matter which action the other player chooses, a player always maximizes its own payoff by choosing D. In game theoretic terms, choosing D is *strictly dominant* in a PD game that is played only once. (Consequently, the only *Nash equilibrium* of the one-shot PD is (D,D)). 

### 2.2 The repeated Prisoner's Dilemma

In this seminar, we will mostly consider games that are repeated for an uncertain number of periods. Let $\delta \in [0,1)$ be a continuation probability (we will also often refer to $\delta$ as *discount factor*). After each period a random number is drawn and the repeated game ends with probability $1-\delta$, i.e. it continues with probability $\delta$. In the basic version (formally called a PD game with *perfect monitoring*) all players exactly observe the actions that the other players have played in the previous periods. It is then no longer strictly dominant to always play D. For example, player 2's action in period 2 may depend on what player 1 did in period 1: she may only play C if player 1 has played C in period 1 and otherwise play D. A player's optimal strategy now depends on how the other player reacts to her action and cooperation may become rational even for pure egoists.

It turns out that if the continuation probability $\delta$ is large enough, such repeated games often have a very large number of *Nash equilibria*. This means we can have many possible profiles of strategies that are stable in the sense that it is optimal for each player to follow her strategy given the strategies of the other players. In some Nash equilibria players will cooperate a lot, in others very little or not at all.

### 2.3 What will we do in the seminar?

We search for "succesful" cooperative strategy profiles in several strategic interactions and study which factors make cooperation harder and how one best adapts cooperation strategies to such factors.

We do this search by programming strategies in R and let them play against each other in a tournament (more on that below) and then rank strategies against each other.

In different tasks we will use different criteria to rank the strategies into more or less succesful strategies. While we discuss different criteria in detail later, a core idea is that your strategy should achieve high payoffs when playing against itself and against other submitted strategies.

## 3. Getting Started: Developing strategies for the repeated Prisoner's Dilemma in R

Preparations:
 1. Make sure you installed all software and packages as described in Section 1
 2. Download the file *pdgame.r*, save it in some working directory, and open it with RStudio. 
 3. Press the "Source" button above on the right of the editor window to load all functions of this file.
 4. Consider the code inside the function examples.pd, select the following lines and press the "Run" button (or press Ctrl-Enter):
```{r include=FALSE}
  # Load package
  library(StratTourn)
```

```{r eval=TRUE,results='hide', cache=!TRUE}
  # Load package
  library(StratTourn)
  
  # Generate a PD game object
  game = make.pd.game(err.D.prob=0.15)
  # Pick a pair of strategies (strategies are defined below)
  strat = nlist(tit.for.tat,random.action)
  
  # Let the strategies play against each other one repeated PD
  run.rep.game(delta=0.9, game=game, strat = strat)

```
This code simulates a repated PD with continuation probability $\delta=0.9$ in which player 1 follows a strategy called "tit.for.tat" and player 2 follows a strategy called "random.action". The resulting output will look similar to the following:

```
  $rs
        match.id         strat t i  u a obs.i obs.j err.D.i err.D.j strat.state
   1: 1121912743   tit.for.tat 1 1 -1 C     C     C   FALSE   FALSE            
   2: 1121912743 random.action 1 2  2 D     C     C   FALSE   FALSE            
   3: 1121912743   tit.for.tat 2 1  2 D     C     D   FALSE   FALSE            
   4: 1121912743 random.action 2 2 -1 C     D     C   FALSE   FALSE            
   5: 1121912743   tit.for.tat 3 1 -1 C     D     C   FALSE   FALSE            
   6: 1121912743 random.action 3 2  2 D     C     D   FALSE   FALSE 
   ...
```
The table shows the results of one repeated prisoners dilemma game. The column `t` is the period, the column `i` the player and `strat` her strategy. The column `a` is the action player i has chosen in period t and `u` is her resulting payoff.

For example, in period t=1, player 1 (tit.for.tat) has cooperated (C) and player 2 (random.action) has defected (D). Consequently, player 1 got a payoff of u = -1 and player 2 got a payoff of 2.

The columns `obs.i` and `obs.j` show the observations at the beginning of a period, here just the previous actions of player i hersefl (obs.i) and the other player (obs.j). 

Note: we will consider a more interesting variant of the prisoners' dilemma game with the possibility of observation errors. An error can make it look as if a player has defected (D) in the previous round, even when he has cooperated (C). The columns err.D.i and err.D.j indicate whether there was an observation error in obs.i or obs.j.

You see that in t=2, player i=1 correctly observes that the other player (j=2) has played (D) in period (D). As explained below, this causes the tit-for-tat strategy also to play (D) in period 2. 

These tables will be very helpful to understand what your programmed strategy does and to check whether it indeed works as you have planned.

Below the big table you see a small table that shows the average payoffs of each player across all periods.

### 3.1 Tit-for-Tat

Tit-for-Tat was the winning strategy in Axelrod's original tournament. It has a simple structure:

  * Start nice by cooperating (C) in period 1
  * In later periods play that action that the other player has played in the previous period. 

### 3.2 Tit-for-Tat as an R function

Further below in the file pdgame.r you find a definition of tit.for.tat as a R function:
```{r eval=FALSE}
tit.for.tat = function(obs,i,t,...) {
  debug.store("tit.for.tat",i,t)       # Store each call for each player
  debug.restore("tit.for.tat",i=1,t=2) # Restore call for player i in period t
  
  # Cooperate in the first period
  if (t==1)
    return(list(a="C"))
  
  # In later periods, return the other player's previous action
  j = 3-i
  a = obs$a[j]
  return(list(a=a))
}

```

The first line
```{r eval=FALSE}
tit.for.tat = function(obs,i,t,...) {
```
says that tit.for.tat is a function with the following arguments:

  * obs: this is a [list](http://cran.r-project.org/doc/manuals/R-intro.html#Lists) that contains a player's observations about behavior from the previous period. The exact structure of observations will depend on the specification of the game that is played. In our basic PD game obs contains an element obs$a that is a vector with the two actions that the players have chosen in the previous period.
  * i: this is simply the number of the player, either 1 or 2
  * t: this is the number of the current period
  * ...: these are some arguments, we don't use for now. Please, always add the ... when defining your strategies. Otherwise, the code may not run correctly. 

Every strategy must have these 4 arguments. There may be additional aguments if a strategy uses states to pass additional information between periods. This is explained further below.

The function run.rep.game now calls this function tit.for.tat in every period and provides the corresponding values of i,t,obs. E.g. if it is called in the third period for player 1 and in the previous round (D,C) was played, we have 
```
    i==1, t==3, obs$a[1]=="D" and obs$a[2]=="C".
```
Based on the values of obs, t, i the function must return the action that the player chooses.

The lines 
```{r eval=FALSE}
  debug.store("tit.for.tat",i,t) # Store each call for each player
  debug.restore("tit.for.tat",i=1,t=2) # Restore call for player i in period t
```
are useful for debugging a strategy and can be ignored for the moment (you can also remove them without changing the behavior of the strategy).

The lines
```{r eval=FALSE}
  if (t==1)
    return(list(a="C"))
```
state that in the first period, i.e. t==1, the player cooperates. That the player cooperates means that the function returns a list

```{r eval=FALSE}
  list(a="C")
```

where the element a is "C". In more complex games, a function may return more than a single action. The exact structure of the list of actions that a function has to return will be explained in the corresponding exercises.

Side remark: we ommitted the "{" brackets of the 'if' condition. We can do that whenever there follows exactly one statement after the condition.

The lines
```{r eval=FALSE}
  j = 3-i
  a = obs$a[j]
  return(list(a=a))
```
describe the behavior in periods t>1. The variable j will be the index of the other player (if i=1 then j=2 and if i=2 then j=1). Lines 2-3 say that the player choses that action that the other player has played in the previous period, i.e. `obs$a[j]`.


### 3.3 Strategies that use states. Example: strange.defector

Many strategies rely not only on the most recent observations which are saved in obs. Consider for example this self-developed (not very clever) strategy:

 * "Strange Defector":  In the first round cooperates with 70% probability, otherwise defects. As long as the player cooperates, he continues in this random fashion. Once the player defects, he plays 4 additional times "defect" in a row. Afterwards, he plays again as in the first period (randomizing, and after defection, 4 defects in a row).
 
Here is an R implementation of this strategy:

```{r}
strange.defector <- function(obs, i, t, still.defect=0, ...){
  debug.store("strange.defector",i,t) # Store each call for each player
  debug.restore("strange.defector",i=1,t=2) # Restore call for player i in period t
  
  # Randomize between C and D
  if (still.defect==0) {
    do.cooperate = (runif(1)<0.7) 
    # With 60% probability choose C
    if (do.cooperate){
      return(list(a="C", still.defect=0))
    } else {
      return(list(a="D", still.defect=4))
    }
  }
  
  # still.defect is bigger 0: play D and reduce still.defect by 1
  still.defect = still.defect -1
  return(list(a="D",still.defect=still.defect))
}
```
Compared to the tit.for.tat function, the strange.defector function has an additional argument, namely `still.defect` which in the first round t=1 has the value 0.
Also the returned lists contain an additional field named `still.defect`.  The variable still.defect is a  manually generated *state variable*.


#### How state variables transfer information between periods:
```
The value of a state variable that is passed to your function in period t is the value of the state that your function has returned in period t-1. (The value of a state in period 1 is the value you specify in the function definition).
```
#### Name and number of state variables
```
You can freely pick the name of a state variable (except for the reserved names ops,i,t and a) and you can have more than one state variable.
```
#### Which values can state variables take?
```
States can take all sort of values: numbers (e.g 4.5), logical values (TRUE or FALSE), strings (e.g. "angry"), or even vectors. You just should not store a list in a state variable.
```

#### Back to the example:
In our example, the state variable *still.defect* captures the information how many rounds the streak of defection should still last.

Let us have a more detailed look at the code of the example. The line
```{r eval=FALSE}
  strange.defector <- function(obs, i, t, still.defect=0,...){
```
initializes the function with a state still.defect that has in the first period a value of 0. 
The lines
```{r eval=FALSE}
  if (still.defect==0) {
    do.cooperate = runif(1)<0.7 
    # With 60% probability choose C
    if (do.cooperate){
      return(list(a="C", still.defect=0))
    } else {
      return(list(a="D", still.defect=4))
    }
  }

```
first check whether we are in the initial state (still.defect==0), in which we randomize between C and D. If this is the case, we draw with the command
```{r eval=FALSE}
  do.cooperate = (runif(1)<0.7) 
```
a logical random variable that is TRUE with 70% probability and otherwise FALSE. (To see this, note that runif(1) draws one uniformely distributed random variable between 0 and 1). The lines
```{r eval=FALSE}
    if (do.cooperate){
      return(list(a="C", still.defect=0))
```
state that if the random variable says that we should cooperate, we return the action "C" and keep the state still.defect=0. The lines 
```{r eval=FALSE}
    } else {
      return(list(a="D", still.defect=4))
    }
```
say that otherwise, we return the action "D" and set the state still.defect = 4. This means that we will defect for the next 4 periods. In the next period the value of still.defect will be 4 and the code at the bottom of the function will be called:
```{r eval=FALSE}
  still.defect = still.defect -1
  return(list(a="D",still.defect=still.defect))
```
The first line reduces still.defect by 1. (Hence, after 4 periods, we will again be in the state still.defect =0 and choose a random action). The second line returns our action a="D" and the new value of our state still.defect.


If you run a single repeated game the result table also shows in each row, the values of the strategies' states at the *end* of the period:
```{r eval=FALSE, cache=!TRUE}
  run.rep.game(game=game, 
               strat = nlist(strange.defector,tit.for.tat))
```
The output will look similar to

```
$rs
      match.id            strat  t i  u a obs.i obs.j err.D.i err.D.j    strat.state
 1: 1492717910 strange.defector  1 1  2 D     C     C   FALSE   FALSE still.defect=4
 2: 1492717910      tit.for.tat  1 2 -1 C     C     C   FALSE   FALSE               
 3: 1492717910 strange.defector  2 1  0 D     D     C   FALSE   FALSE still.defect=3
 4: 1492717910      tit.for.tat  2 2  0 D     C     D   FALSE   FALSE               
 ...
```

#### Important: always return a list with all strategy states
```
Every return statement of your strategy must return a list that has values for all actions
and all strategy states. Even if you don't currently use some strategy state, you have to 
return a value.
```

### 3.4 Exercise:

Implement the following strategy in R.

  - tit3tat: The player starts with C and plays like tit-for-tat in period t=2 and t=3. In period t>3 the player plays with 60% probability like tit-for-tat and with 30% probability he plays the action that the other player played in the pre-previous period, i.e. in t-2 and with 10% probability he plays the action the other player played in t-3.
  
  Hints:
  1. To do something with 60% probability, you can draw a random variable x with the command x=runif(1) that is uniformely distributed between 0 and 1 and then check whether x<=0.6. To do something else with 30 probability, you can check 0.6 < x & x <= 0.9 and so on...
  2. To save a longer history you can either use a function that has more than one state or store a vector in a state variable.

## 4. Running a tournament between strategies

The following lines run a tournament between 4 specified strategies
```{r include=FALSE}
  set.storing(FALSE)
  options(width=100)
```
```{r eval=FALSE, cache=TRUE}
  # Init game
  game = make.pd.game(err.D.prob=0.15)

  getwd()
  # Set working directory in which data is stored
  
  # Adapt directory. Note: use / instead of \ to seperate folders
  setwd("D:/libraries/StratTourn/studies") 

  # Init and run a tournament of several strategies against each other  
  strat = nlist(tit.for.tat,always.defect, always.coop, random.action)  
  tourn = init.tournament(game=game, strat=strat)
  
  #set.storing(FALSE)  # uncomment to make code run faster
  tourn = run.tournament(tourn=tourn, R = 5)
  set.storing(TRUE)  
  tourn

  # save data
  save.tournament(tourn)

  # Analyse tournament in web browser
  show.tournament(tourn)
```

```{r include=FALSE}
  set.storing(TRUE)
  options(width=80)
```
The tournament consists of R rounds (here R=15). In every round, every strategy plays against each other strategy in a repeated game. Every strategy also plays against itself. For every pairing of two strategies, we then compute the average payoff of the strategies over all R rounds.

The `show.tournament` command in the last line opens a window in your webbrowser that allows to interactively analyse the results of the tournament. I will explain the different statistics and graphs in class.


## 5 Criteria for winning

There are different ways how one can evaluate the performance of the submitted strategies and assign scores. I want to present the basic idea of some approaches. The exact scoring rules will differ in different tasks of the seminar and will be explained in the task descriptions during the course.


### 5.1 Average performance against all strategies

In his original tournament Axelrod let each strategy play against each other several repeated games and the score of each strategy was simply its average payoff over all its matches. 

### 5.2 Evolutionary dynamic and performance in weighted population

Imagine we have a society that lasts for several generations and in each generation it has a big population. Each member of society has a strategy that it plays in the repeated game. So we can think of each strategy `s` having a share `share[s]` in the total population. Imagine individuals randomly meet each other and play the repeated game. The average score of a strategy shall be the average payoff of a strategy across all matches. Let $S$ be the set of all strategies. The score of a strategy s in a symmetric two player game in an infinitely large population is then given by

\[
U[s] = \sum_{r \in S} \bar{u}[s,r] * share[r]
\]  
where $\bar{u}[s,r]$ shall be the average payoff of strategy s when playing against strategy r. This means the score is an weighted average payoff of all matches of a strategy, where payoffs are weighted by the population weight of the other player's strategy. If all strategies have the same population shares then the score is computed in the same fashion as in Axelrod's original rule (see 5.1).

Instead of assuming that all strategies have the same population shares, it seems sensible that individuals are more likely to adopt strategies that are successful while dismissing unsuccessful strategies. We model this process with a simple "evolutionary" dynamic in which strategy shares evolve over generations. A strategy `s` grows from one generation to the next generation essentially by the following simple linear population dynamics formula:
  
```
  size.next[s] = size[s] + alpha * (U[s]-U.mean) * size[s]
``` 
`U.mean` is the weighted average of the scores `U[s]` of all strategies, weighted with the population shares of each strategy. Hence a strategy's size in the population grows if and only if it has a higher average payoff than the weighted average payoff in the population. Otherwise, the strategy shrinks. The shares of each strategy in the next generation are obtained by normalizing the resulting sizes to 1.

\[
  share.next[s] = \frac {size.next[s]} {\sum_{r \in S} size.next[r]}
\]

The parameter `alpha` controls the speed of evolution. We get smoother dynamics if we pick lower values of alpha but run for more generations. In the limit of `alpha -> 0` we have the popular replicator dynamics (see http://en.wikipedia.org/wiki/Replicator_equation). In practice, setting alpha too small has the drawback that computation will take longer.

We will determine the strategies' scores as follows: we will specify in the task a number of generations and an alpha and then run the evolutionary dynamic to get resulting population shares of each strategy. The scores of each strategy will then be computed using these population shares as weights.

The main motivation for adding this evolutionary dynamic before computing scores is that it gives you incentives to design strategies that shall perform well against well-performing strategies (including itself). Your strategy's score is now less affected by its perfomance against weird, low-performing strategies because those strategies will quickly shrink to low population shares.

We may also give bonus points directly for being successful in the evolutionary process, e.g. for being the strategy with the highest population share, or for strategies whose population share converges to 100% in the long run. 


### Scoring based on the performance and stability as a society's social norm


What would be a **"good social norm"** that one could teach to all people and which describes how they should behave in their interactions? More compactly:

** We search for strategies that would be efficient and evolutionary stable social norms if initially almost everybody would follow these strategies**

... to be continued ...

## 6. Guidelines for your Strategies

### Keep it sufficiently simple, intuitive, clean and fast

Your strategies and the implementation as R should be intuitively understandable. It is not the goal to develop extremely complex strategies with a large number of states that nobody understands and that require extremely complicated computations. Also take into account that for the simulations we may run your strategy on the order of a million times, so don't make any complicated computations that need very long to run. That being said your strategy does not have to be as simple as tit-for-tat.

### Don't cheat

If you are a hacker, you may think of many ways to cheat. For example, it might be really useful to find out whether your strategy plays against itself, but the rules of the basic PD game don't give you an effective way to communicate (you can only choose C or D). So you may think of exchanging information by writing information into a global R variable which the other player can read out. Such things are considered cheating and **not allowed**.

  * You are only allowed to use the information that is passed to the function as parameters (including the states you returned in earlier periods).
  * You are not allowed to modify any external objects.
  
As a rule of thumb: if you wonder whether something is cheating it probably is; if you are not sure ask us.

## 7. Debugging a strategy

When you first write a strategy or other R function, it often does not work correctly: your function is likely to have bugs. Some bugs make your programm stop and throw an error message, other bugs are more subtle and make your strategy behave in a different fashion than you expected. *Debugging* means to find and correct bugs in your code. There are different tools that help debugging. I want to illustrate some debugging steps with an example.

Consider the following strategy, which I call "exploiter":

  * Exploiter: In the first period cooperate. If the other player cooperates for two or more times in a row defect. Otherwise play with 70% probability tit-for-tat and with 30% probability play defect. 

Here is a first attempt to implement this strategy as an r function (it contains a lot of bugs):
```{r eval=FALSE}
exploiter = function(obs,i,t,game, otherC) {
  debug.store("exploiter",i,t) # Store each call for each player
  debug.restore("exploiter",i=1,t=2) # Restore call for player i in period t

  # Start nice in first period
  if (t=1) {
    return(list(a="C",otherC=0))
  }
  # If the other player has chosen C two or more times in a row play D
  if (obs$a[[j]]=="C") otherC= otherC + 1
  
  if (otherC > 2) return(list(a="D"))
  
  # Play tit for tat with probability 70% and with prob. 30% play D
  if (runif(1)<70) {
    a = obs$a[[j]]
  } else {
    a = "D"
  }
  return(nlist(a=a,otherC))
}

```

### Step 1: Run function definition in R console and correct errors

As a first step select the whole function in the RStudio editor and press the run button. You should see something similar to the following in the R console.
```
> exploiter = function(obs,i,t, other.weakness, ...) {
+  debug.store("exploiter",i,t) # Store each call for each player
+  debug.restore("exploiter",i=1,t=2) # Restore call for player i in period t
+  if (t=1) {
Error: unexpected '=' in:
"exploiter = function(obs,i,t,game, other.weakness) {
  if (t="
>     return(list(a="C",other.weakness=0))
Error: no function to return from, jumping to top level
>   }
Error: unexpected '}' in "  }"
>   if (obs$a[[j]]=="C") {
+     other.weakness = other.weakness + 1
+   }
Error: object 'j' not found
>   if (other.weakness > 2) {
+     return(list(a="D"))
+   }
Error: object 'other.weakness' not found
>   # Follow tit for tat with probability 70% otherwise play D
>   a = ifelse(runif(1)<0.7,obs$a[[j]],"D")
Error in ifelse(runif(1) < 0.7, obs$a[[j]], "D") : object 'j' not found
>   return(nlist(a=a,other.weakness))
Error in nlist(a = a, other.weakness) : object 'other.weakness' not found
> }
Error: unexpected '}' in "}"
```

There are a lot of error messages. It is best to start with the first error message and try to correct the corresponding code.

```
  if (t=1) {
  Error: unexpected '=' in:
  "exploiter = function(obs,i,t,game, other.weakness) {if (t="
```

This is a typical beginner error. If we want to check whether t is 1, we need to write `t==1` instead of `t=1`. (The expression `t=1` means that the value 1 is assigned to the variable t, expression `t==1` is a boolean expression that is TRUE if t is 1 and FALSE otherwise.)  A corrected version of the function is
```{r eval=TRUE}
exploiter = function(obs,i,t, otherC,...) {
  debug.store("exploiter",i,t) # Store each call for each player
  debug.restore("exploiter",i=1,t=2) # Restore call for player i in period t


  # Start nice in first period
  if (t==1) {
    return(list(a="C",otherC=0))
  }
  # If the other player has chosen C two or more times in a row play D
  if (obs$a[[j]]=="C") otherC= otherC + 1
  
  if (otherC > 2) return(list(a="D"))
  
  # Play tit for tat with probability 70% and with prob. 30% play D
  if (runif(1)<70) {
    a = obs$a[[j]]
  } else {
    a = "D"
  }
  return(nlist(a=a,otherC))
}

```

If you run this new version in the console, no error is shown. Unfortunately, this does not mean that there

### Step 2: Check whether run.rep.game yields errors and debug such errors by stepping trough function

As next step let us run run.rep.game with the strategy and check whether some errors are shown.
```{r eval=TRUE, cache=!TRUE}
  run.rep.game(delta=0.95, game=game, strat = nlist(exploiter,random.action))
```
We get an error message and learn that an error occurred when calling exploiter for player i=1 in period t=2. We also get the error message "object 'j' not found". Probably you see the problem directly from that message. Nevertheless, let us pretend we have not found the problem yet and let us step through our function.
Go to the function code and run the line
```{r}
debug.restore("exploiter",i=1,t=2) # Restore call for player i in period t
```
in the R console by selecting the line and pressing the "Run" button or Ctrl-Enter. This call now restores now the arguments with which the strategy has been called  for player i=1 in period t=2. You can examine the function arguments by typing them in the R console:
```{r}
obs
i
t
```
You can also run some further lines of code inside the function to see where exactly the error has occured:
```{r}
  # Start nice in first period
  if (t==1) {
    return(list(a="C",otherC=0))
  }
  # If the other player has chosen C two or more times in a row play D
  if (obs$a[[j]]=="C") otherC= otherC + 1
```
We can also run parts of the last line to narrow down the error...
```{r}
  obs$a[[j]]
  j
```
Ok, clearly we forgot to define the variable j, which shall be the index of the other player. We can add the line j = 3-i and run again the code inside the corrected function:
```{r}
  debug.restore("exploiter",i=1,t=2) # Restore call for player i in period t
  # Start nice in first period
  if (t==1) {
    return(list(a="C",otherC=0))
  }
  j = 3-i # index of other player
  
  # If the other player has chosen C two or more times in a row play D
  if (obs$a[[j]]=="C") otherC= otherC + 1
  if (otherC > 2) return(list(a="D"))
  
  # Play tit for tat with probability 70% and with prob. 30% play D
  if (runif(1)<70) {
    a = obs$a[[j]]
  } else {
    a = "D"
  }
  return(nlist(a=a,otherC))
```
You probably will see an error message after the last line that there is no function to return from, but we can ignore that one. Otherwise we see no more error. Yet, that does not mean that our function has no more bug.
Before proceeding we copy the whole corrected function definition into the R console:
```{r eval=TRUE}
exploiter = function(obs,i,t, otherC,...) {
  debug.store("exploiter",i,t) # Store each call for each player
  debug.restore("exploiter",i=1,t=2) # Restore call for player i in period t

  # Start nice in first period
  if (t==1) {
    return(list(a="C",otherC=0))
  }
  j = 3-i # index of other player

  # If the other player has chosen C two or more times in a row play D
  if (obs$a[[j]]=="C") otherC= otherC + 1
  if (otherC > 2) return(list(a="D"))
  
  # Play tit for tat with probability 70% and with prob. 30% play D
  if (runif(1)<70) {
    a = obs$a[[j]]
  } else {
    a = "D"
  }
  return(nlist(a=a,otherC))
}

```

### Step 3: Running run.rep.game again and debugging the next error

Copy the corrected function in your R console and then call run.rep.game again. (Note I now call the function run.rep.game with the parameters game.seed and strat.seed, which ensure that the random generator always returns the same results. That is just for the reason that it is easier to write this documentation if the error always occures in the same period).
```{r eval=TRUE, cache=!TRUE}
  run.rep.game(delta=0.95, game=game, strat = nlist(exploiter,random.action), game.seed=12345, strat.seed=12345)
```
We find an error in period t=10 . Let us investigate the call to our strategy in that period by setting t=10 in the call to debug.restore
```{r eval=TRUE, cache=!TRUE}
  debug.restore("exploiter",i=1,t=10) # Restore call for player i in period t
```
The call tells me that the state variable otherC was not provided as an argument to this function. This basically means that in period t=9 the function did not return the variable otherC. Let us check where this problem happened by exploring in more detail the function call in period 9.
```{r eval=TRUE, cache=!TRUE}
  debug.restore("exploiter",i=1,t=9) # Restore call for player i in period t

  # Start nice in first period
  if (t==1) {
    return(list(a="C",otherC=0))
  }
  j = 3-i # index of other player

  # If the other player has chosen C two or more times in a row play D
  if (obs$a[[j]]=="C") otherC= otherC + 1
  if (otherC > 2) return(list(a="D"))
  
```
```
Error: no function to return from, jumping to top level
```
We see that the function returned in the last line of the code above. And of course, we forgot to add otherC in the list of returned variables. So this variable was missing in period t=10. The last line is easy to fix and we again paste into the R console a corrected version of our strategy:
```{r eval=TRUE}
exploiter = function(obs,i,t, otherC,...) {
  debug.store("exploiter",i,t) # Store each call for each player
  debug.restore("exploiter",i=1,t=2) # Restore call for player i in period t

  # Start nice in first period
  if (t==1) {
    return(list(a="C",otherC=0))
  }
  j = 3-i # index of other player

  # If the other player has chosen C two or more times in a row play D
  if (obs$a[[j]]=="C") otherC= otherC + 1
  if (otherC > 2) return(list(a="D",otherC=otherC))
  
  # Play tit for tat with probability 70% and with prob. 30% play D
  if (runif(1)<70) {
    a = obs$a[[j]]
  } else {
    a = "D"
  }
  return(nlist(a=a,otherC))
}

```

###  Step 4: Call run.rep.game again and remove remaining bugs
```{r eval=TRUE, cache=!TRUE}
  run.rep.game(delta=0.95, game=game, strat = nlist(exploiter,random.action), game.seed=12345, strat.seed=12345)
```
There is no more error message but there are still 2 bugs left in the function such that the programmed strategy does not work as verbally described. (Remember that the strategy shall only automatically defect if at last two times **in a row** the other player has played C). I will leave the debugging of the last function as an exercise. I just end with a little debugging hint. It can be useful to define additional helper states so that one gets better information in the result table. For example, I add a state "played.tit.for.tat" that is TRUE if the function exploiter indeed played tit.for.tat in the current round and otherwise will be shown as FALSE: (For the state to appear in the table, it must be returned in the first period)

```{r eval=TRUE}
exploiter = function(obs,i,t, otherC, played.tit.for.tat=FALSE,...) {
  debug.store("exploiter",i,t) # Store each call for each player
  debug.restore("exploiter",i=1,t=2) # Restore call for player i in period t

  # Start nice in first period
  if (t==1) {
    return(nlist(a="C",otherC=0, played.tit.for.tat))
  }
  j = 3-i # index of other player

  # If the other player has chosen C two or more times in a row play D
  if (obs$a[[j]]=="C") otherC= otherC + 1
  if (otherC > 2) return(nlist(a="D",otherC=otherC, played.tit.for.tat))
  
  # Play tit for tat with probability 70% and with prob. 30% play D
  if (runif(1)<70) {
    a = obs$a[[j]]
    played.tit.for.tat = TRUE
  } else {
    a = "D"
    played.tit.for.tat = FALSE
  }
  return(nlist(a=a,otherC, played.tit.for.tat))
}

run.rep.game(delta=0.95, game=game, strat = nlist(exploiter,random.action), game.seed=12345, strat.seed=12345)

```

### Exercise: Correct the remaining bugs in exploiter

That was the tutorial. Take at the look at the upcoming problem sets that will describe the tournament tasks...




## 8 Studying candidates for good strategies: fine-tuning the parameters 

(Section will be revised)

The package StratTourn contains the function `study.strats.and.answers` that can help to find promising strategies. 

The development of strategies (or best answers) often involves two steps:

  1. You develop a general idea of a strategy, which often involes some numeric parameters that affect the probability to cooperate or defect in certain situations.
  2. You fine-tune the parameters of your strategy for the given scenarios

Fine tuning means in the first stage that you want to find parameters that increase efficiency and stability of your strategy. In the second stage you want to find parameters for your answer strategy that allow the biggest stabilization of the original strategy. The function study.strats.and.answers can be helpful for both tasks.

## study.strats.and.answers
```{r include=FALSE}
  library(StratTourn)
  library(compiler)
```

To illustrat, the function, we define a simple strategy called **mix** which randomly chooses "C" or "D".
```{r tidy=FALSE}
  mix = function(obs,t,i, probC = 0.5, ...) {
    if (runif(1)<=probC) return(nlist(a="C"))
    return(nlist(a="D"))
  }
```
The function has parameter **probC** that specifies the probability to cooperate. W now graphically analyze the mean efficiency of this simple strategy class for different values of probC.

```{r eval=FALSE,cache=TRUE, tidy=FALSE, fig.height=4, fig.width=4}
  library(StratTourn)
   
  # A PD game 
  game = make.pd.game()
  
  sim = NULL
  # Study efficiency of mix for different values of probC 
  sim = study.strats.and.answers(
    strats = nlist(mix),
    strat.par = list(probC = seq(0,1,length=11)),
    R=10, delta=0.95, sim=sim,game=game
  )
  plot(sim)

```
You can call the function one more time to get more simulations, which will be added to the earlier simulations stored in sim. This reduces the sampling uncertainty. We also increase R from 10 to 50 to add 50 additional simulations instead of only 10.

```{r eval=FALSE,cache=TRUE, tidy=FALSE,fig.height=4, fig.width=4}
  # Study efficiency of mix for different values of probC 
  sim = study.strats.and.answers(
    strats = nlist(mix),
    strat.par = list(probC = seq(0,1,length=11)),
    R=50, delta=0.95, sim=sim,game=game
  )
  plot(sim)
```

Non-surprisingly, our strategy **mix** has the highest efficiency if probC=1, i.e. when it always cooperates. Yet, not only efficiency matters but also stability. Consider the following code:
```{r eval=FALSE,cache=TRUE,fig.height=4, fig.width=4}
  sim = NULL # reset sim
 
  # Study which mix variant is a best answer against mix with probC=1
  sim = study.strats.and.answers(
    strats = nlist(mix),answers=nlist(mix),
    strat.par = list(probC = 1),
    answer.par = list(probC = seq(0,1,length=11)),
    R=50, delta=0.95, sim=sim,game=game
  )
  plot(sim)
```
The blue line shows the payoff of our strategy mix with probC=1. The red line shows the payoffs of candidates for best answers against the strategy mix with probC=1. Here the considered answer strategies are variants of mix with 11 different mixing probabilities between 0 and 1 (provided in the argument answer.par in the function call and shown on the x-axis of the plot.). Non-surprisingly, the strategy with mix=0 (i.e. always defect) achieves the highest payoff against our always.coop strategy and highly destabilizes it.

The following code studies payoffs and answer payoffs for 4 different mix-variants with probC = 0,0.1, 0.5 and 1.
```{r eval=FALSE,cache=TRUE, fig.height=4, fig.width=9}
  sim = NULL # reset sim
 
  # Study which mix variant is a best answer against mix with probC=1
  sim = study.strats.and.answers(
    strats = nlist(mix),answers=nlist(mix),
    strat.par = list(probC = c(0,0.1,0.5,1)),
    answer.par = list(probC = seq(0,1,length=11)),
    R=50, delta=0.95, sim=sim,game=game
  )
  plot(sim)

```

The plot shows the payoffs and answer payoff for all 4 variants of mix. In the plots for probC=0 and probC=0.1, you also see a green line. This is the **score** of the strategy computed from its efficiency and instability (see the rules of the tournament described earlier in this tutorial). For probC=0.5 and probC=1 the score is so strongly negative that it is not shown anymore in the plot. (Note that we don't have yet confidence intervals for the score.)

Our analysis confirms the idea that among different variants of mix, the variant with probC=0 (always defect) gets the highest score if we search for best answers also among different variants of mix.

Of course, "mix" is not a very clever class of strategies in the repeated prisoners' dilemma game. For example, tit.for.tat has the same efficiency as always.coop (mix for probC=1) while being much more stable. In the first problem set, you will be asked to consider a variant of the prisoners' dilemma where with probability err.D.prob an action "C" is wrongly observed as "D". This will make cooperation much harder to sustain and tit.for.tat loses its appeal quite quickly. We can also use the function study.strats.and.answers to explore the effect of changes in parameters of the game:

```{r eval=FALSE,cache=TRUE, fig.height=4, fig.width=9}
  sim = NULL # reset sim
 
  # Study which mix variant is a best answer against mix with probC=1
  sim = study.strats.and.answers(
    strats = nlist(tit.for.tat),answers=nlist(mix),
    answer.par = list(probC = seq(0,1,length=11)),
    R=50, delta=0.95, sim=sim,game.fun=make.pd.game,
    game.par = list(err.D.prob=c(0,0.1,0.3))
  )
  plot(sim)
```

We see that tit-for-tat becomes less efficient and quite instable once we introduce the observation error. Interestingly, it is most strongly destabilized by the very cooperative variant of mix with probC=1.

Hope you enjoyed the tutorial. Have fun in the challenge that lie ahead! 
