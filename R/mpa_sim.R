#' Spatial MPA simulation
#'
#' @description Simulates MPA and surrounding fishing grounds. Growth is modeled with a discrete logistic growth model. This version assumes a closed population and no age structure. Organisms leaving the area through the right margin reincorporate the population through the left margin; same happens for uppper and lower margins.
#'
#' @param area An N by M matrix with harvesting rates for fishing grounds (0 < harvesting rate <= 1) and MPAs (harvesting rate = 0) for the simulated area.
#' @param nsteps Number of steps to run the simulation.
#' @param r Population growth rate.
#' @param pop0 Initial population size. If single, assumes equal population size across all cells in area. If a matrix, it must have the same dimensions as area.
#' @param K Carrying capacity
#' @param mrate Movement rate expressed as a proportion (relative to 1). Indicates the proportion of organisms that will move out of a cell in one timestep.
#' @param op A logical value that indicates if a filled.contour is to be created. WARNING: op = TRUE may make the simulation slow. Alternatively, see closure.vec.
#' @param closure.vec a vector that contains all nsteps in which a closure must occur. For example, closure.vec=c(1,2,3,10) will close the fishery in yers 1,2,3 consecutively, and then again on nstep 10.
#' @param cf A single integer that indicates the frequency (how many n steps) in which a closure to fishing occurs (i.e. no fishing).
#'
#' @return results A list containing pop: a matrix of size N by M (same dimensions as area, above) with population size within each cell; and timeseries: a dataframe with 5 columns and nstep rows. The columns contain time (timeseries$time), population SIZE at each timestep (timeseries$pop), population DENSITY inside the MPA (timeseries$pop.in), population DENSITY outside the MPA (timeseries$pop.out) and yearly total catches (timeseries$total.catches).
#'
#' @author Villasenor-Derbez, J.C.
#'
#'
#' @export


mpa_sim=function(area, nsteps, r, pop0, K, mrate, op=FALSE, cf=NULL, closure.vec=NULL) {

  #Making sure allinputs are correct
  check=mpa_check(area, nsteps, r, pop0, K, mrate)
  if (check$result==0){stop(check$message)}

  u.vec=area

  size=dim(u.vec)

  nrows=size[1]
  ncols=size[2]

  pop <- matrix(nrow=nrows, ncol=ncols)
  popi=array(NA,dim=c(nrows,ncols,nsteps))

  #set starting population in vector pop in each cell equal to K
  pop[]=pop0

  #vector left.cells storing the position of cells to the left
  left.cells=c(ncols, 1:(ncols-1))

  #vector right.cells storing the position of cells to the right
  right.cells=c(2:ncols,1)

  #vector up.cells storing the positon of cells up
  up.cells=c(nrows,1:(nrows-1))

  #vector down.cells storing the position of cells down
  down.cells=c(2:nrows, 1)

  #set the vector where closures occur
  if (!is.null(cf)){
    closure=seq(cf,nsteps, by=cf)
  }

  if (!is.null(closure.vec)){
    closure=closure.vec
  }

  if(is.null(closure.vec)){
    closure=0
  }

  # These keep track of total population size in MPAs (pop.in) and total population size in fishing grounds (pop.out). ones is a matrix of size pop, that is used to normalize population by number of cells (i.e. population size/number of cells) later in the final plot of pop vs time.
  inside=u.vec==0
  outside=u.vec>0
  ones=matrix(1,nrow=nrows, ncol=ncols)
  pop.in=sum(pop[inside], na.rm=TRUE)/sum(ones[inside], na.rm=TRUE)
  pop.out=sum(pop[outside], na.rm=TRUE)/sum(ones[outside], na.rm=TRUE)
  pob=sum(pop, na.rm=TRUE)
  total.catches=sum(u.vec*pop, na.rm=TRUE)

  if (op==TRUE){
    windows()
    filled.contour(pop, color=terrain.colors, asp=1, main="0", key.title=title(main="Density\n(Org/cell)"))
  }

  #loop through the time steps
  for (i in 1:nsteps) {

    #Vector "leaving" of number leaving each cell is population size times diffusion rate
    leaving=pop*mrate

    #The number of immigrants is 1/4 those leaving cells to the
    #left, 1/4 those leaving cells to the right, 1/4 those leaving up
    #and 1/4 those leaving down. This is a complicated expression
    #take a minute to think it through!
    arriving=0.25*leaving[left.cells]+
      0.25*leaving[right.cells]+
      0.25*leaving[up.cells]+
      0.25*leaving[down.cells]

    #surplus production from the logistic model
    surplus=(r*pop)*(1-(pop/K))

    #catches = harvest rate in each cell times the population size
    catches=u.vec*pop

    if (any(closure==i)){
      catches=0
    }

    #update the population numbers
    pop=pop+surplus-catches-leaving+arriving
    popi[,,i]=pop

    #Also save two vectors containing population size inside MPA (pop.in) and population size outside MPA (pop.out), as well as total population size, and total catches.
    pop.in[i+1]=sum(pop[inside], na.rm=TRUE)/sum(ones[inside], na.rm=TRUE)
    pop.out[i+1]=sum(pop[outside], na.rm=TRUE)/sum(ones[outside], na.rm=TRUE)
    pob[i+1]=sum(pop, na.rm=TRUE)
    total.catches[i+1]=sum(catches, na.rm=TRUE)

    #continue plotting pop at time i if op=TRUE
    if (op==TRUE){
      filled.contour(pop, col=rainbow(100), asp=1, main=i, key.title=title(main="Density\n(Org/cell)"))
    }
  }

  #Create a list of results
  results=list(time.series=data.frame(time=seq(0:nsteps)-1,
                                      pop=pob/(nrows*ncols),
                                      pop.in,
                                      pop.out,
                                      catches=total.catches),
               pop=popi)

  return(results)
}
