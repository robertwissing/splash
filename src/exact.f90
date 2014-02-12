!-----------------------------------------------------------------
!
!  This file is (or was) part of SPLASH, a visualisation tool
!  for Smoothed Particle Hydrodynamics written by Daniel Price:
!
!  http://users.monash.edu.au/~dprice/splash
!
!  SPLASH comes with ABSOLUTELY NO WARRANTY.
!  This is free software; and you are welcome to redistribute
!  it under the terms of the GNU General Public License
!  (see LICENSE file for details) and the provision that
!  this notice remains intact. If you modify this file, please
!  note section 2a) of the GPLv2 states that:
!
!  a) You must cause the modified files to carry prominent notices
!     stating that you changed the files and the date of any change.
!
!  Copyright (C) 2005-2013 Daniel Price. All rights reserved.
!  Contact: daniel.price@monash.edu
!
!-----------------------------------------------------------------

!
! This module handles all of the settings relating to the exact solution
! plotting and calls the appropriate routines to change these settings and
! plot the actual solutions.
!
! The only thing to do with exact solutions that is not entirely handled
! by this module is the toy star AC plane solution (because
! it is called under different circumstances to the other solutions).
!
module exact
  implicit none
  !
  !--options used to plot the exact solution line
  !
  integer :: maxexactpts, iExactLineColour, iExactLineStyle,iPlotExactOnlyOnPanel
  logical :: iApplyTransExactFile,iCalculateExactErrors,iPlotResiduals
  real :: fracinsetResiduals,residualmax
  !
  !--declare all of the parameters required for the various exact solutions
  !
  !--toy star
  integer :: iACplane ! label position of toy star AC plane plot
  integer :: norder,morder ! for toy star
  real, public :: atstar,ctstar,sigma
  real :: htstar,alphatstar,betatstar,ctstar1,ctstar2
  real :: sigma0,totmass
  !--sound wave
  integer :: iwaveploty,iwaveplotx ! linear wave
  real :: ampl,lambda,period,xzero
  !--sedov blast wave
  real :: rhosedov,esedov
  !--polytrope
  real :: polyk
  !--mhd shock solutions
  integer :: ishk
  real :: xshock
  !--density profiles
  integer :: iprofile,icolpoten,icolfgrav
  real, dimension(2) :: Msphere,rsoft
  !--from file
  integer :: iexactplotx, iexactploty
  !--shock tube
  real :: rho_L, rho_R, pr_L, pr_R, v_L, v_R
  !--rho vs h
  real :: hfact
  !--read from file
  integer :: ixcolfile,iycolfile
  character(len=120) :: filename_exact
  !--equilibrium torus
  real :: Mstar,Rtorus,distortion
  !--ring spreading
  real :: Mring,Rring,viscnu
  !--dusty waves
  real :: cs,Kdrag,rhozero,rdust_to_gas
  !--arbitrary function
  integer :: nfunc
  character(len=120), dimension(10) :: funcstring
  !--Roche potential
  real :: semi,ecc,mprim,msec
  !
  !--sort these into a namelist for input/output
  !
  namelist /exactopts/ iexactplotx,iexactploty,filename_exact,maxexactpts, &
       iExactLineColour,iExactLineStyle,iApplyTransExactFile,iCalculateExactErrors, &
       iPlotResiduals,fracinsetResiduals,residualmax,iPlotExactOnlyOnPanel

  namelist /exactparams/ ampl,lambda,period,iwaveploty,iwaveplotx,xzero, &
       htstar,atstar,ctstar,alphatstar,betatstar,ctstar1,ctstar2, &
       polyk,sigma0,norder,morder,rhosedov,esedov, &
       rho_L, rho_R, pr_L, pr_R, v_L, v_R,ishk,hfact, &
       iprofile,Msphere,rsoft,icolpoten,icolfgrav,Mstar,Rtorus,distortion, &
       Mring,Rring,viscnu,nfunc,funcstring,cs,Kdrag,rhozero,rdust_to_gas, &
       semi,ecc,mprim,msec,ixcolfile,iycolfile,xshock,totmass

  public :: defaults_set_exact,submenu_exact,options_exact,read_exactparams
  public :: exact_solution
  public :: exactopts,exactparams

contains
  !----------------------------------------------------------------------
  ! sets default values of the exact solution parameters
  !----------------------------------------------------------------------
  subroutine defaults_set_exact
    implicit none

    lambda = 1.0    ! sound wave exact solution : wavelength
    ampl = 0.005    ! sound wave exact solution : amplitude
    period = 1.0
    iwaveploty = 7
    iwaveplotx = 1
    xzero = 0.
    htstar = 1.     ! toy star crap
    atstar = 1.
    ctstar = 1.
    alphatstar = 0.
    betatstar = 0.
    ctstar1 = 0.
    ctstar2 = 0.
    totmass = 1.
    norder = -1
    morder = 0
    sigma0 = 0.
    rhosedov = 1.0  ! sedov blast wave
    esedov = 1.0    ! blast wave energy
    polyk = 1.0     ! polytropic k
!   shock tube (default is sod problem)
    rho_L = 1.0
    rho_R = 0.125
    pr_L = 1.0
    pr_R = 0.1
    v_L = 0.0
    v_R = 0.0
    iexactplotx = 0
    iexactploty = 0
    ishk = 1
    xshock = 0.
    hfact = 1.2
    filename_exact = ' '
    ixcolfile = 1
    iycolfile = 2
!   density profile parameters
    iprofile = 1
    rsoft(1) = 1.0
    rsoft(2) = 0.1
    Msphere(1) = 1.0
    Msphere(2) = 0.0
    icolpoten = 0
    icolfgrav = 0
!   equilibrium torus
    Mstar = 1.0
    Rtorus = 1.0
    distortion = 1.1
!   ring spreading
    Mring = 1.0
    Rring = 1.0
    viscnu = 1.e-3
!   dusty waves
    Kdrag = 1.0
    cs    = 1.0
    rhozero = 1.0
    rdust_to_gas = 0.0
!   Roche lobes
    semi  = 1.
    ecc   = 0.
    mprim = 1.
    msec  = 1.

!   arbitrary function
    nfunc = 1
    funcstring = ' '

    maxexactpts = 1001      ! points in exact solution plot
    iExactLineColour = 1    ! foreground
    iExactLineStyle = 1     ! solid
    iApplyTransExactFile = .true. ! false if exact from file is already logged
    iCalculateExactErrors = .true.
    iPlotResiduals = .false.
    fracinsetResiduals = 0.15
    residualmax = 0.0
    iPlotExactOnlyOnPanel = 0

    return
  end subroutine defaults_set_exact

  !----------------------------------------------------------------------
  ! sets which exact solution to calculate + parameters for this
  !----------------------------------------------------------------------
  subroutine submenu_exact(iexact)
    use settings_data, only:ndim
    use prompting,     only:prompt
    use filenames,     only:rootname,ifileopen
    use exactfunction, only:check_function
    use mhdshock,      only:nmhdshocksolns,mhdprob
    use asciiutils,    only:get_ncolumns,string_replace
    implicit none
    integer, intent(inout) :: iexact
    integer :: ierr,itry,i,ncols,nheaderlines
    logical :: ians,iexist
    character(len=len(filename_exact)) :: filename_tmp

    print 10
10  format(' 0) none ',/,               &
           ' 1) ANY function f(x,t)',/, &
           ' 2) read from file ',/,       &
           ' 3) shock tube ',/,           &
           ' 4) sedov blast wave ',/,     &
           ' 5) polytrope ',/,            &
           ' 6) toy star ',/,             &
           ' 7) gresho vortex ',/,          &
           ' 8) mhd shock tubes (tabulated) ',/,  &
           ' 9) h vs rho ',/, &
           '10) Plummer/Hernquist spheres ',/, &
           '11) torus ',/, &
           '12) ring spreading ',/, &
           '13) special relativistic shock tube', /, &
           '14) dusty waves', /, &
           '15) Roche lobes/potential ',/, &
           '16) C-shock ')
    call prompt('enter exact solution to plot',iexact,0,16)
    print "(a,i2)",'plotting exact solution number ',iexact
    !
    !--enter parameters for various exact solutions
    !
    select case(iexact)
    case(1)
       call prompt('enter number of functions to plot ',nfunc,1,size(funcstring))
       print "(/,a,6(/,11x,a))",' Examples: sin(2*pi*x - 0.1*t)','sqrt(0.5*x)','x^2', &
             'exp(-2*x**2 + 0.1*t)','log10(x/2)','exp(y),y=sin(pi*x)','cos(z/y),z=acos(y),y=x^2'
       overfunc: do i=1,nfunc
          ierr = 1
          itry = 0
          do while(ierr /= 0 .and. itry.lt.10)
             if (nfunc.gt.1) print "(/,a,i2,/,11('-'),/)",'Function ',i
             call prompt('enter function f(x,t) to plot ',funcstring(i),noblank=.true.)
             call check_function(funcstring(i),ierr)
             if (ierr /= 0 .and. len(funcstring(i)).eq.len_trim(funcstring(i))) then
                print "(a,i3,a)",&
                     ' (errors are probably because string is too long, max length = ',&
                     len(funcstring(i)),')'
             endif
             itry = itry + 1
          enddo
          if (itry.ge.10) then
             print "(a)",' *** too many tries, aborting ***'
             ierr = i-1
             exit overfunc
          endif
       enddo overfunc
       if (ierr /= 0) nfunc = ierr
       if (nfunc.gt.0) then
          print*
          call prompt('enter y axis of exact solution (0=all plots)',iexactploty,0)
          if (iexactploty.gt.0) then
             call prompt('enter x axis of exact solution ',iexactplotx,1)
          endif
       endif
    case(2)
       iexist = .false.
       do while(.not.iexist)
          print "(a)",'Use %f to represent current dump file, e.g. %f.exact looks for dump_000.exact'
          call prompt('enter filename ',filename_exact)
          !--substitute %f for filename
          filename_tmp = filename_exact
          call string_replace(filename_tmp,'%f',trim(rootname(ifileopen)))
          !--check the first file for errors
          inquire(file=filename_tmp,exist=iexist)
          if (iexist) then
             open(unit=33,file=filename_tmp,status='old',iostat=ierr)
             if (ierr.eq.0) then
                call get_ncolumns(33,ncols,nheaderlines)
                if (ncols.gt.2) then
                   print "(a,i2,a)",' File '//trim(filename_tmp)//' contains ',ncols,' columns of data'
                   call prompt('Enter column containing x data ',ixcolfile,1,ncols)
                   call prompt('Enter column containing y data ',iycolfile,1,ncols)
                elseif (ncols.eq.2) then
                   print "(a,i2,a)",' OK: got ',ncols,' columns from '//trim(filename_tmp)
                else
                   iexist = .false.
                   call prompt('Error: file contains < 2 readable columns: try again?',ians)
                   if (.not.ians) return
                endif
                close(33)
             else
                iexist = .false.
                call prompt('Error opening '//trim(filename_tmp)//': try again?',ians)
                if (.not.ians) return
             endif
          else
             ians = .true.
             call prompt('file does not exist: try again? ',ians)
             if (.not.ians) return
          endif
       enddo
       call prompt('enter x axis of exact solution ',iexactplotx,1)
       call prompt('enter y axis of exact solution ',iexactploty,1)
       print "(a)",'apply column transformations to exact solution?'
       call prompt(' (no if file contains e.g. log y vs log x)',iApplyTransExactFile)
    case(3,13)
       !
       !--read shock parameters from the .shk file
       !
       call read_exactparams(iexact,trim(rootname(1)),ierr)
       if (ierr.ne.0) then
          call prompt('enter density to left of shock   ',rho_L,0.0)
          call prompt('enter density to right of shock  ',rho_R,0.0)
          call prompt('enter pressure to left of shock  ',pr_L,0.0)
          call prompt('enter pressure to right of shock ',pr_R,0.0)
          if (iexact.eq.13) then
             call prompt('enter velocity to left of shock  ',v_L,max=1.0)
             call prompt('enter velocity to right of shock ',v_R,max=1.0)
          else
             call prompt('enter velocity to left of shock  ',v_L)
             call prompt('enter velocity to right of shock ',v_R)
             call prompt('enter dust-to-gas ratio ',rdust_to_gas,0.)             
          endif
       endif      
    case(4)
       call prompt('enter density of ambient medium ',rhosedov,0.0)
       call prompt('enter blast wave energy E ',esedov,0.0)
    case(5)
       call prompt('enter polytropic k ',polyk)
       call prompt('enter total mass ',totmass)
    case(6)
       print "(a)",' toy star: '
       call read_exactparams(iexact,trim(rootname(1)),ierr)
       call prompt('enter polytropic k ',polyk)
       call prompt('enter total mass   ',totmass)
       call prompt('enter central density rho_0 (rho = rho_0 - cr^2)',htstar)
       call prompt('enter parameter c (rho = rho_0 - cr^2)',ctstar,0.0)
       sigma = 0.
       call prompt('enter parameter sigma (By = sigma*rho)',sigma0)
       sigma = sigma0
       ians = .false.
       call prompt('linear oscillations?',ians)
       if (ians) then
          call prompt('enter order of radial mode',norder,0)
          if (ndim.ge.2) call prompt('enter order of angular mode',morder,0)
          call prompt('enter velocity amplitude a (v = a*r) ',atstar)
       else
          print "(a)",'using exact non-linear solution:'
          ians = .true.
          if (norder.lt.0 .and. morder.lt.0) ians = .false.
          if (ndim.ge.2) call prompt('axisymmetric?',ians)
          if (ians .or. ndim.eq.1) then
             norder = -1
             morder = 0
             call prompt('enter v_r amplitude ',alphatstar)
             if (ndim.ge.2) call prompt('enter v_phi amplitude ',betatstar)
          else
             norder = -1
             morder = -1
             call prompt('enter vxx amplitude ',alphatstar)
             call prompt('enter vyy amplitude ',betatstar)
             call prompt('enter vxy amplitude ',ctstar1)
             call prompt('enter vyx amplitude ',ctstar2)
          endif
       endif
    !case(7)
    !   call prompt('enter y-plot to place sine wave on',iwaveploty,1)
    !   call prompt('enter x-plot to place sine wave on',iwaveplotx,1)
    !   call prompt('enter starting x position',xzero)
    !   call prompt('enter wavelength lambda ',lambda,0.0)
    !   call prompt('enter amplitude ',ampl,0.0)
    !   call prompt('enter period ',period)
    case(8)
       print "(a)",' MHD shock tube tables: '
       if (ishk.le.0) ishk = 1
       do i=1,nmhdshocksolns
          print "(i2,') ',a)",i,trim(mhdprob(i))
       enddo
       call prompt('enter solution to plot ',ishk,1,7)
       call prompt('enter initial x position of shock ',xshock)
    case(9)
       call prompt('enter hfact [h = hfact*(m/rho)**1/ndim]',hfact,0.)
    case(10)
       print 20
20     format(' 1) Plummer sphere  [ rho = 3M r_s**2 /(4 pi (r**2 + r_s**2)**5/2) ]',/, &
              ' 2) Hernquist model [ rho =     M r_s /(2 pi r (r_s + r)**3        ]')
       call prompt('enter density profile to plot',iprofile,1,2)
       call prompt('enter total mass of sphere M',Msphere(1),0.)
       call prompt('enter scale length length r_s,',rsoft(1),0.)
       ians = .false.
       if (icolpoten.gt.0) ians = .true.
       call prompt('Are the gravitational potential and/or force dumped?',ians)
       if (ians) then
          call prompt('enter column containing grav. potential',icolpoten,0)
          call prompt('enter column containing grav. force',icolfgrav,0)
       endif
       call prompt('enter mass of 2nd component',Msphere(2),0.)
       call prompt('enter scale length r_s for 2nd component,',rsoft(2),0.)
    case(11)
       call prompt('enter mass of central object',Mstar,0.)
       call prompt('enter radius of torus centre',Rtorus,0.)
       call prompt('enter distortion parameter ',distortion,1.,2.)
       if (abs(polyk-1.0).lt.tiny(polyk)) polyk = 0.0764
       call prompt('enter K in P= K*rho^gamma',polyk,0.)
    case(12)
       call prompt('enter mass of ring',Mring,0.)
       call prompt('enter radius of ring centre R0',Rring,0.)
       call prompt('enter viscosity parameter nu',viscnu,0.)
    case(14)
       call prompt('enter starting x position',xzero)
       call prompt('enter wavelength lambda ',lambda,0.)
       call prompt('enter amplitude of perturbation',ampl,0.)
       call prompt('enter sound speed in gas ',cs,0.)
       call prompt('enter initial gas density ',rhozero,0.)
       call prompt('enter dust-to-gas ratio ',rdust_to_gas,0.)
       call prompt('enter drag coefficient K ',Kdrag,0.)
    case(15)
       call prompt('enter semi-major axis of binary',semi,0.)
       call prompt('enter mass of primary star ',mprim,0.)
       call prompt('enter mass of secondary star ',msec,0.,mprim)
    end select

    return
  end subroutine submenu_exact

  !---------------------------------------------------
  ! sets options relating to exact solution plotting
  !---------------------------------------------------
  subroutine options_exact
    use prompting, only:prompt
    use plotlib,   only:plotlib_maxlinestyle,plotlib_maxlinecolour
    implicit none

    call prompt('enter number of exact solution points ',maxexactpts,10,1000000)
    call prompt('enter line colour ',iExactLineColour,1,plotlib_maxlinecolour)
    call prompt('enter line style  ',iExactLineStyle,1,plotlib_maxlinestyle)
    call prompt('calculate error norms? ',iCalculateExactErrors)
    if (iCalculateExactErrors) then
       call prompt('plot residuals (as inset in main plot)?',iPlotResiduals)
       if (iPlotResiduals) then
          call prompt('enter fraction of plot to use for inset', &
                      fracinsetResiduals,0.1,0.9)
          call prompt('enter max residual (0 for adaptive)',residualmax,0.)
       endif
    endif
    print "(/,'  0 : plot exact solution (where available) on every panel ',/,"// &
           "' -1 : plot exact solution on first row only ',/,"// &
           "' -2 : plot exact solution on first column only ',/,"// &
           "'  n : plot exact solution on nth panel only ')"

    call prompt('Enter selection ',iPlotExactOnlyOnPanel,-2)


    return
  end subroutine options_exact

  !-----------------------------------------------------------------------
  ! read exact solution parameters from files
  ! (in ndspmhd these files are used in the input to the code)
  !
  ! called after main data read and if exact solution chosen from menu
  !-----------------------------------------------------------------------
  subroutine read_exactparams(iexact,rootname,ierr)
    use settings_data,  only:ndim
    use prompting,      only:prompt
    use exactfunction,  only:check_function
    use filenames,      only:fileprefix
    use asciiutils,     only:read_asciifile
    implicit none
    integer, intent(in) :: iexact
    character(len=*), intent(in) :: rootname
    integer, intent(out) :: ierr

    integer :: idash,nf,i,j,idrag,idum
    character(len=len_trim(rootname)+8) :: filename

    idash = index(rootname,'_')
    if (idash.eq.0) idash = len_trim(rootname)+1

    select case(iexact)
    case(1)
       !
       !--read functions from file
       !
       !
       filename=trim(rootname)//'.func'
       call read_asciifile(trim(filename),nf,funcstring,ierr)
       if (ierr.eq.-1) then
          print "(a)",' no file '//trim(filename)
          filename = trim(fileprefix)//'.func'
          call read_asciifile(trim(filename),nf,funcstring,ierr)
          if (ierr.eq.-1) then
             print "(a)",' no file '//trim(filename)
             return
          endif
       endif

       if (nf.gt.0) then
          i = 0
          do while(i.lt.nf)
             i = i + 1
             call check_function(funcstring(i),ierr,verbose=.false.)
             if (ierr /= 0) then
                print "(a)",' error parsing function '//trim(funcstring(i))//', skipping...'
                do j=i+1,nf
                   funcstring(j-1) = funcstring(j)
                enddo
                funcstring(nf) = ' '
                nf = nf - 1
                i = i - 1
             endif
          enddo
          nfunc = nf
          print "(a,i2,a)",' read ',nfunc,' functions from '//trim(filename)
       else
          print "(a)",' *** NO FUNCTIONS READ: none will be plotted ***'
          ierr = 2
       endif

    case(3,13)
       !
       !--shock tube parameters from .shk file
       !
       filename = trim(rootname(1:idash-1))//'.shk'
       open(UNIT=19,ERR=7701,FILE=filename,STATUS='old')
       read(19,*,ERR=7777) rho_L, rho_R
       read(19,*,ERR=7777) pr_L, pr_R
       read(19,*,ERR=7777) v_L, v_R
       close(UNIT=19)
       print*,'>> read ',filename
       print*,' rhoL, rho_R = ',rho_L,rho_R
       print*,' pr_L, pr_R  = ',pr_L, pr_R
       print*,' v_L,  v_R   = ',v_L, v_R
       return
7701   print*,'no file ',filename
       ierr = 1
       return
7777   print*,'error reading ',filename
       close(UNIT=19)
       ierr = 2
       return

    case(6)
       !
       !--read toy star file for toy star solution
       !
       select case(ndim)
       case(1)
          filename = trim(rootname(1:idash-1))//'.tstar'
          open(unit=20,ERR=8801,FILE=filename,STATUS='old')
          read(20,*,ERR=8888) Htstar,Ctstar,Atstar
          read(20,*,ERR=8888) sigma0
          read(20,*,ERR=8888) norder
          close(UNIT=20)
          print*,' >> read ',filename
          print*,' H,C,A,sigma,n = ',Htstar,Ctstar,Atstar,sigma0,norder
          return
8801      continue
          print*,'no file ',filename
          ierr = 1
          return
8888      print*,'error reading ',filename
          close(UNIT=20)
          ierr = 2
          return
       case(2)
          filename = trim(rootname(1:idash-1))//'.tstar2D'
          open(unit=20,ERR=9901,FILE=filename,STATUS='old')
          read(20,*,ERR=9902) Htstar,Ctstar,Atstar
          read(20,*,ERR=9902) alphatstar,betatstar,ctstar1,ctstar2
          read(20,*,ERR=9902) norder,morder
          close(UNIT=20)
          print*,' >> read ',filename
          print*,' j,m = ',norder,morder
          print*,' rho_0 = ',Htstar,' - ',Ctstar,' r^2'
          if (norder.ge.0 .and. morder.ge.0) then
             print*,' v = ',Atstar,' r'
          else
             print*,' vx = ',alphatstar,'x +',ctstar1,'y'
             print*,' vy = ',ctstar2,'x +',betatstar,'y'
          endif
          return
9901      continue
          print*,'no file ',filename
          ierr = 1
          return
9902      print*,'error reading ',filename
          close(UNIT=20)
          ierr = 2
          return
       end select
    case(8)
       !
       !--attempt to guess which MHD shock tube has been done from filename
       !
          !read(rootname(5:5),*,iostat=ios) ishk
          !if (ios.ne.0) ishk = 1
       !
       !--prompt for shock type if not set
       !
       if (ishk.le.0) then ! prompt
          ishk = 1
          call prompt('enter shock solution to plot',ishk,1,7)
       endif
       return
    case(14)
       !
       !--dustywave parameters from ndspmhd input file
       !
       filename = trim(rootname(1:idash-1))//'.in'
       open(unit=19,file=filename,status='old',iostat=ierr)
       if (ierr.eq.0) then
          do i=1,23
             read(19,*,iostat=ierr)
          enddo
          if (ierr.eq.0) then
             read(19,*,iostat=ierr) idrag, idum, idum, Kdrag
             print*,'>> read Kdrag = ',Kdrag,' from '//trim(filename)
          else
             print*,'>> error reading Kdrag from '//trim(filename)
          endif
       endif
       close(unit=19)
       return

    end select

    return
  end subroutine read_exactparams

  !-----------------------------------------------------------------------
  ! this subroutine drives the exact solution plotting using the
  ! parameters which have been set
  !
  ! acts as an interface between the main plotting loop and the
  ! exact solution calculation subroutines
  !
  ! The exact solution is returned from the calculation via the arrays
  ! xexact and yexact. This means that the appropriate transformations
  ! can be applied (e.g. if the graph is logarithmic) and also ensures
  ! that the line style and colour settings are applied properly.
  !
  ! Note that we attempt to space the solution evenly in the transformed
  ! space (ie. in the current plot window), but this can be overwritten
  ! in the subroutines (for example if an uneven sampling is desired or
  ! the plotting is via some similarity variable as in the Sedov solution).
  ! In these cases the resulting arrays are then transformed, possibly leading
  ! to poor sampling in some regions (e.g. an evenly spaced array will become
  ! highly uneven in logarithmic space).
  !
  ! Note that any subroutine could in principle do its own plotting,
  ! provided that it returns ierr > 0 which means that the generic line
  ! is not plotted. Obviously transformations could not be applied in
  ! this case.
  !
  !-----------------------------------------------------------------------

  subroutine exact_solution(iexact,iplotx,iploty,itransx,itransy,igeom, &
                            ndim,ndimV,time,xmin,xmax,gamma,xplot,yplot, &
                            pmassmin,pmassmax,npart,imarker,unitsx,unitsy,irescale,iaxisy)
    use labels,          only:ix,irad,iBfirst,ivx,irho,ike,iutherm,ih,ipr,iJfirst,&
                              irhorestframe,is_coord,ideltav,idustfrac
    use filenames,       only:ifileopen,rootname
    use asciiutils,      only:string_replace
    use prompting,       only:prompt
    use exactfromfile,   only:exact_fromfile
    use mhdshock,        only:exact_mhdshock
    use polytrope,       only:exact_polytrope
    use rhoh,            only:exact_rhoh
    use sedov,           only:exact_sedov
    use shock,           only:exact_shock
    use shock_sr,        only:exact_shock_sr
    use torus,           only:exact_torus
    use toystar1D,       only:exact_toystar1D  !, exact_toystar_ACplane
    use toystar2D,       only:exact_toystar2D
    use wave,            only:exact_wave
    use densityprofiles, only:exact_densityprofiles
    use exactfunction,   only:exact_function
    use ringspread,      only:exact_ringspread
    use dustywaves,      only:exact_dustywave
    use rochelobe,       only:exact_rochelobe
    use gresho,          only:exact_gresho
    use Cshock,          only:exact_Cshock
    use transforms,      only:transform,transform_inverse
    use plotlib,         only:plot_qci,plot_qls,plot_sci,plot_sls,plot_line
    implicit none
    integer, intent(in) :: iexact,iplotx,iploty,itransx,itransy,igeom
    integer, intent(in) :: ndim,ndimV,npart,imarker,iaxisy
    real, intent(in) :: time,xmin,xmax,gamma,unitsx,unitsy
    real, intent(in) :: pmassmin,pmassmax
    real, intent(in), dimension(npart) :: xplot,yplot
    logical, intent(in) :: irescale
    real, dimension(npart) :: residuals,ypart

    real, parameter :: zero = 1.e-10
    integer :: i,ierr,iexactpts,iCurrentColour,iCurrentLineStyle
    real, dimension(:), allocatable :: xexact,yexact,xtemp
    real :: dx,errL1,errL2,errLinf,timei
    character(len=len(filename_exact)) :: filename_tmp

    !
    !--change line style and colour settings, but save old ones
    !
    call plot_qci(iCurrentColour)
    call plot_qls(iCurrentLineStyle)
    call plot_sci(iExactLineColour)
    call plot_sls(iExactLineStyle)
    !
    !--allocate memory
    !
    allocate(xexact(maxexactpts),yexact(maxexactpts),xtemp(maxexactpts),stat=ierr)
    if (ierr /= 0) then
       print "(a)",'*** ERROR allocating memory for exact solution plotting, skipping ***'
       if (allocated(xexact)) deallocate(xexact)
       if (allocated(yexact)) deallocate(yexact)
       if (allocated(xtemp)) deallocate(xtemp)
       return
    endif

    !
    !--set x axis (can be overwritten)
    !  Need to space x in transformed space (e.g. in log space)
    !  but send the values of x in *real* space to the calculation routines
    !  then need to plot x in transformed space
    !
    !  Best solution is to set x grid initially, and inverse transform to get x values.
    !  These values can then be overwritten, if required in the exact subroutines
    !  We then re-transform the x array to plot it, which means that if spacing is
    !  overwritten the resulting array can still be transformed into log space
    !  but spacing will not be even
    !

    !--note that xmin and xmax will already have been transformed prior to input
    !  as these were the limits used for plotting the particles
    !
    dx = (xmax - xmin)/real(maxexactpts)
    do i=1,maxexactpts
       xexact(i) = xmin + (i-1)*dx
    enddo
    xtemp = xexact
    if (itransx.gt.0) call transform_inverse(xexact,itransx)

    iexactpts = maxexactpts
    !
    !--exact solution plots must return a zero or negative value of ierr to be plotted
    !  (-ve ierr indicates a partial solution)
    !
    ierr = 666
    
    !
    !--use time=0 if time has not been read from dump file (indicated by t < 0)
    !
    if (time > 0) then
       timei = time
    else
       timei = 0.
    endif

    select case(iexact)
    case(1) ! arbitrary function parsing
       if ((iplotx.eq.iexactplotx .and. iploty.eq.iexactploty) .or. iexactploty.eq.0) then
          do i=1,nfunc
             call exact_function(funcstring(i),xexact,yexact,timei,ierr)
             if (i.ne.nfunc) then ! plot all except last line here
                if (itransy.gt.0) call transform(yexact,itransy)
                !--use xtemp, which is xexact but already transformed
                call plot_line(iexactpts,xtemp(1:iexactpts),yexact(1:iexactpts))
             endif
          enddo
       endif
    case(2) ! exact solution read from file
       if (iplotx.eq.iexactplotx .and. iploty.eq.iexactploty) then
          !--substitute %f for filename
          filename_tmp = filename_exact
          call string_replace(filename_tmp,'%f',trim(rootname(ifileopen)))
          !--read exact solution from file
          call exact_fromfile(filename_tmp,xexact,yexact,ixcolfile,iycolfile,iexactpts,ierr)
          !--plot this untransformed (as may already be in log space)
          if (ierr.le.0 .and. .not.iApplyTransExactFile) then
             call plot_line(iexactpts,xexact(1:iexactpts),yexact(1:iexactpts))
             ierr = 1
          endif
          !--change into physical units if appropriate
          if (iRescale .and. iApplyTransExactFile) then
             xexact(1:iexactpts) = xexact(1:iexactpts)*unitsx
             yexact(1:iexactpts) = yexact(1:iexactpts)*unitsy
          endif
       endif
    case(3)! shock tube
       if (iplotx.eq.ix(1) .and. igeom.le.1) then
          if (iploty.eq.irho) then
             call exact_shock(1,timei,gamma,rho_L,rho_R,pr_L,pr_R,v_L,v_R, &
                              rdust_to_gas,xexact,yexact,ierr)
          elseif (iploty.eq.ipr) then
             call exact_shock(2,timei,gamma,rho_L,rho_R,pr_L,pr_R,v_L,v_R, &
                              rdust_to_gas,xexact,yexact,ierr)   
          elseif (iploty.eq.ivx) then
              call exact_shock(3,timei,gamma,rho_L,rho_R,pr_L,pr_R,v_L,v_R, &
                              rdust_to_gas,xexact,yexact,ierr)
          elseif (iploty.eq.iutherm) then
              call exact_shock(4,timei,gamma,rho_L,rho_R,pr_L,pr_R,v_L,v_R, &
                              rdust_to_gas,xexact,yexact,ierr)
          elseif (iploty.eq.ideltav) then
              call exact_shock(5,timei,gamma,rho_L,rho_R,pr_L,pr_R,v_L,v_R, &
                              rdust_to_gas,xexact,yexact,ierr)
          elseif (iploty.eq.idustfrac) then
              call exact_shock(6,timei,gamma,rho_L,rho_R,pr_L,pr_R,v_L,v_R, &
                              rdust_to_gas,xexact,yexact,ierr)
          endif
       endif

    case(4)! sedov blast wave
       ! this subroutine does change xexact
       if (iplotx.eq.irad .or. (igeom.eq.3 .and. iplotx.eq.ix(1))) then
          if (iploty.eq.irho) then
             call exact_sedov(1,timei,gamma,rhosedov,esedov,xmax,xexact,yexact,ierr)
          elseif (iploty.eq.ipr) then
             call exact_sedov(2,timei,gamma,rhosedov,esedov,xmax,xexact,yexact,ierr)
          elseif (iploty.eq.iutherm) then
             call exact_sedov(3,timei,gamma,rhosedov,esedov,xmax,xexact,yexact,ierr)
          elseif (iploty.eq.ike) then
             call exact_sedov(4,timei,gamma,rhosedov,esedov,xmax,xexact,yexact,ierr)
          elseif (iploty.eq.ivx .and. igeom.eq.3) then
             call exact_sedov(5,timei,gamma,rhosedov,esedov,xmax,xexact,yexact,ierr)
          endif
       !elseif (igeom.le.1 .and. is_coord(iplotx,ndim) .and. is_coord(iploty,ndim)) then
       !   call exact_sedov(0,timei,gamma,rhosedov,esedov,xmax,xexact,yexact,ierr)
       endif

    case(5)! polytrope
       if (iploty.eq.irho .and. (iplotx.eq.irad .or.(igeom.eq.3 .and. iplotx.eq.ix(1)))) then
          call exact_polytrope(gamma,polyk,totmass,xexact,yexact,iexactpts,ierr)
       endif

    case(6)! toy star
       if (iBfirst.ne.0) then
          sigma = sigma0
       else
          sigma = 0.
       endif
       if (ndim.eq.1) then
          !
          !--1D toy star solutions
          !
          if (iplotx.eq.ix(1) .or. iplotx.eq.irad) then! if x axis is x or r
             if (iploty.eq.irho) then
                call exact_toystar1D(1,timei,gamma,htstar,atstar,ctstar,sigma,norder, &
                                   xexact,yexact,iexactpts,ierr)
             elseif (iploty.eq.ipr) then
                call exact_toystar1D(2,timei,gamma,htstar,atstar,ctstar,sigma,norder, &
                                   xexact,yexact,iexactpts,ierr)
             elseif (iploty.eq.iutherm) then
                call exact_toystar1D(3,timei,gamma,htstar,atstar,ctstar,sigma,norder, &
                                   xexact,yexact,iexactpts,ierr)
             elseif (iploty.eq.ivx) then
                call exact_toystar1D(4,timei,gamma,htstar,atstar,ctstar,sigma,norder, &
                                   xexact,yexact,iexactpts,ierr)
             elseif (iploty.eq.iBfirst+1) then
                call exact_toystar1D(5,timei,gamma,htstar,atstar,ctstar,sigma,norder, &
                                   xexact,yexact,iexactpts,ierr)
             endif
          elseif (iplotx.eq.irho) then
             if (iploty.eq.iBfirst+1) then
                call exact_toystar1D(6,timei,gamma,htstar,atstar,ctstar,sigma,norder, &
                                   xexact,yexact,iexactpts,ierr)
             endif
          endif

          if (iploty.eq.iacplane) then! plot point on a-c plane
             call exact_toystar1D(7,timei,gamma,htstar,atstar,ctstar,sigma,norder, &
                                xexact,yexact,iexactpts,ierr)
          endif
       else
          !
          !--2D toy star solutions
          !  these routines change xexact
          !
          if (igeom.eq.1 .and.((iplotx.eq.ix(1) .and. iploty.eq.ivx) &
               .or. (iplotx.eq.ix(2) .and. iploty.eq.ivx+1))) then
             call exact_toystar2D(4,timei,gamma,polyk,totmass, &
                  atstar,htstar,ctstar,norder,morder, &
                  alphatstar,betatstar,ctstar1,ctstar2,xexact,yexact,ierr)
          endif
          if (iplotx.eq.irad .or. (igeom.eq.2 .and. iplotx.eq.ix(1))) then
             if (iploty.eq.irho) then
                call exact_toystar2D(1,timei,gamma,polyk,totmass, &
                     atstar,htstar,ctstar,norder,morder, &
                     alphatstar,betatstar,ctstar1,ctstar2,xexact,yexact,ierr)
             elseif (iploty.eq.ipr) then
                call exact_toystar2D(2,timei,gamma,polyk,totmass, &
                     atstar,htstar,ctstar,norder,morder, &
                     alphatstar,betatstar,ctstar1,ctstar2,xexact,yexact,ierr)
             elseif (iploty.eq.iutherm) then
                call exact_toystar2D(3,timei,gamma,polyk,totmass, &
                     atstar,htstar,ctstar,norder,morder, &
                     alphatstar,betatstar,ctstar1,ctstar2,xexact,yexact,ierr)
             elseif (igeom.eq.2 .and. iploty.eq.ivx) then
                call exact_toystar2D(4,timei,gamma,polyk,totmass, &
                     atstar,htstar,ctstar,norder,morder, &
                     alphatstar,betatstar,ctstar1,ctstar2,xexact,yexact,ierr)
             elseif (iploty.eq.ike) then
                call exact_toystar2D(5,timei,gamma,polyk,totmass, &
                     atstar,htstar,ctstar,norder,morder, &
                     alphatstar,betatstar,ctstar1,ctstar2,xexact,yexact,ierr)
             endif
          elseif (is_coord(iplotx,ndim) .and. is_coord(iploty,ndim) .and. igeom.eq.1) then
             call exact_toystar2D(0,timei,gamma,polyk,totmass, &
                  atstar,htstar,ctstar,norder,morder, &
                  alphatstar,betatstar,ctstar1,ctstar2,xexact,yexact,ierr)
          endif
       endif

    case(7)! linear wave
       !if ((iploty.eq.iwaveploty).and.(iplotx.eq.iwaveplotx)) then
       !   ymean = SUM(yplot(1:npart))/REAL(npart)
       !   call exact_wave(timei,ampl,period,lambda,xzero,ymean,xexact,yexact,ierr)
       !endif
       if (igeom.eq.2 .and. ndim.ge.2) then
          if (iploty.eq.ivx+1) then
             call exact_gresho(1,xexact,yexact,ierr)          
          elseif (iploty.eq.ipr) then
             call exact_gresho(2,xexact,yexact,ierr)
          endif
       endif
    case(8) ! mhd shock tubes
       ! this subroutine modifies xexact
       if (iplotx.eq.ix(1) .and. igeom.le.1) then
          if (iploty.eq.irho) then
             call exact_mhdshock(1,ishk,timei,gamma,xmin,xmax,xshock, &
                                 xexact,yexact,iexactpts,ierr)
          elseif (iploty.eq.ipr) then
             call exact_mhdshock(2,ishk,timei,gamma,xmin,xmax,xshock, &
                                 xexact,yexact,iexactpts,ierr)
          elseif (iploty.eq.ivx) then
             call exact_mhdshock(3,ishk,timei,gamma,xmin,xmax,xshock, &
                                 xexact,yexact,iexactpts,ierr)
          elseif (iploty.eq.ivx+1 .and. ndimV.gt.1) then
             call exact_mhdshock(4,ishk,timei,gamma,xmin,xmax,xshock, &
                                 xexact,yexact,iexactpts,ierr)
          elseif (iploty.eq.ivx+ndimV-1 .and. ndimV.gt.2) then
             call exact_mhdshock(5,ishk,timei,gamma,xmin,xmax,xshock, &
                                 xexact,yexact,iexactpts,ierr)
          elseif (iploty.eq.iBfirst+1 .and. ndimV.gt.1) then
             call exact_mhdshock(6,ishk,timei,gamma,xmin,xmax,xshock, &
                                 xexact,yexact,iexactpts,ierr)
          elseif (iploty.eq.iBfirst+ndimV-1 .and. ndimV.gt.2) then
             call exact_mhdshock(7,ishk,timei,gamma,xmin,xmax,xshock, &
                                 xexact,yexact,iexactpts,ierr)
          elseif (iploty.eq.iutherm) then
             call exact_mhdshock(8,ishk,timei,gamma,xmin,xmax,xshock, &
                                 xexact,yexact,iexactpts,ierr)
          elseif (iploty.eq.iBfirst) then
             call exact_mhdshock(9,ishk,timei,gamma,xmin,xmax,xshock, &
                                 xexact,yexact,iexactpts,ierr)
          endif
       endif
    case(9)
       !--h = (1/rho)^(1/ndim)
       if (((iploty.eq.ih).and.(iplotx.eq.irho)) .or. &
           ((iplotx.eq.ih).and.(iploty.eq.irho))) then
          if (iplotx.eq.ih) then
             call exact_rhoh(2,ndim,hfact,pmassmin,xexact,yexact,ierr)
          else
             call exact_rhoh(1,ndim,hfact,pmassmin,xexact,yexact,ierr)
          endif

          !--if variable particle masses, plot one for each pmass value
          if (abs(pmassmin-pmassmax).gt.zero .and. pmassmin.gt.zero) then
             !--plot first line
             if (ierr.le.0) then
                xtemp = xexact ! must not transform xexact as this is done again below
                if (itransx.gt.0) call transform(xtemp,itransx)
                if (itransy.gt.0) call transform(yexact,itransy)
                call plot_line(iexactpts,xtemp(1:iexactpts),yexact(1:iexactpts))
             endif
             !--leave this one to be plotted below
             if (iplotx.eq.ih) then
                call exact_rhoh(2,ndim,hfact,pmassmax,xexact,yexact,ierr)
             else
                call exact_rhoh(1,ndim,hfact,pmassmax,xexact,yexact,ierr)
             endif
          endif
       endif
    case(10) ! density profiles
       if (iplotx.eq.irad .or.(igeom.eq.3 .and. iplotx.eq.ix(1))) then
          if (iploty.eq.irho) then
             call exact_densityprofiles(1,iprofile,Msphere,rsoft,xexact,yexact,ierr)
          elseif (iploty.eq.icolpoten) then
             call exact_densityprofiles(2,iprofile,Msphere,rsoft,xexact,yexact,ierr)
          elseif (iploty.eq.icolfgrav) then
             call exact_densityprofiles(3,iprofile,Msphere,rsoft,xexact,yexact,ierr)
          endif
       endif
    case(11) ! torus
       if (iplotx.eq.irad .or.(igeom.eq.3 .and. iplotx.eq.ix(1))) then
          if (iploty.eq.irho) then
             call exact_torus(1,1,Mstar,Rtorus,polyk,distortion,gamma,xexact,yexact,ierr)
          elseif (iploty.eq.ipr) then
             call exact_torus(2,1,Mstar,Rtorus,polyk,distortion,gamma,xexact,yexact,ierr)
          elseif (iploty.eq.iutherm) then
             call exact_torus(3,1,Mstar,Rtorus,polyk,distortion,gamma,xexact,yexact,ierr)
          endif
       !--pr vs z at r=Rtorus
       elseif (igeom.eq.2 .and. iplotx.eq.ix(3) .and.iploty.eq.ipr) then
          call exact_torus(4,1,Mstar,Rtorus,polyk,distortion,gamma,xexact,yexact,ierr)
       endif
       !--solutions for tokamak torus
       if (igeom.eq.4 .and. iplotx.eq.ix(1)) then
          if (iploty.eq.irho) then
             call exact_torus(1,2,Mstar,Rtorus,polyk,distortion,gamma,xexact,yexact,ierr)
          elseif (iploty.eq.ipr) then
             call exact_torus(2,2,Mstar,Rtorus,polyk,distortion,gamma,xexact,yexact,ierr)
          elseif (iploty.eq.iutherm) then
             call exact_torus(3,2,Mstar,Rtorus,polyk,distortion,gamma,xexact,yexact,ierr)
          elseif (iploty.eq.iBfirst+1 .and. iBfirst.gt.0) then
             call exact_torus(4,2,Mstar,Rtorus,polyk,distortion,gamma,xexact,yexact,ierr)
          elseif (iploty.eq.iJfirst+2 .and. iJfirst.gt.0) then
             call exact_torus(5,2,Mstar,Rtorus,polyk,distortion,gamma,xexact,yexact,ierr)
          endif
       endif
    case(12)
       if (iplotx.eq.irad .or.((igeom.eq.3 .or. igeom.eq.2) .and. iplotx.eq.ix(1))) then
          if (iploty.eq.irho) then
             call exact_ringspread(1,timei,Mring,Rring,viscnu,xexact,yexact,ierr)
          endif
       endif
    case(13) ! special relativistic shock tube
       if (iplotx.eq.ix(1) .and. igeom.le.1) then
          if (iploty.eq.irhorestframe) then
             call exact_shock_sr(1,timei,gamma,rho_L,rho_R,pr_L,pr_R,v_L,v_R,xexact,yexact,ierr)
          elseif (iploty.eq.ipr) then
             call exact_shock_sr(2,timei,gamma,rho_L,rho_R,pr_L,pr_R,v_L,v_R,xexact,yexact,ierr)
          elseif (iploty.eq.ivx) then
             call exact_shock_sr(3,timei,gamma,rho_L,rho_R,pr_L,pr_R,v_L,v_R,xexact,yexact,ierr)
          elseif (iploty.eq.iutherm) then
             call exact_shock_sr(4,timei,gamma,rho_L,rho_R,pr_L,pr_R,v_L,v_R,xexact,yexact,ierr)
          elseif (iploty.eq.irho) then
             call exact_shock_sr(5,timei,gamma,rho_L,rho_R,pr_L,pr_R,v_L,v_R,xexact,yexact,ierr)
          endif
       endif
    case(14) ! dusty wave exact solution
       if (iplotx.eq.ix(1) .and. igeom.le.1) then
          if (iploty.eq.irho) then
             call exact_dustywave(1,timei,ampl,cs,Kdrag,lambda,xzero,rhozero,rhozero*rdust_to_gas,xexact,yexact,ierr)
          elseif (iploty.eq.ivx) then
             call exact_dustywave(2,timei,ampl,cs,Kdrag,lambda,xzero,rhozero,rhozero*rdust_to_gas,xexact,yexact,ierr)
          endif
       endif
    case(15) ! Roche potential
       if (igeom.eq.1 .and. ndim.ge.2 .and. iplotx.eq.ix(1) .and. iploty.eq.ix(2)) then
          call exact_rochelobe(timei,semi,mprim,msec,xexact,yexact,ierr)
       endif
    case(16) ! C-shock
       if (ndim.ge.1 .and. iplotx.eq.ix(1) .and. igeom.le.1) then
          if (iploty.eq.irho) then
             call exact_Cshock(1,timei,gamma,xmin,xmax,xexact,yexact,ierr)
          elseif (iploty.eq.iBfirst+1 .and. iBfirst.gt.0) then
             call exact_Cshock(2,timei,gamma,xmin,xmax,xexact,yexact,ierr)
          endif
       endif
    end select

    !----------------------------------------------------------
    !  plot this as a line on the current graph
    !----------------------------------------------------------
    if (ierr.le.0) then
       if (itransx.gt.0) call transform(xexact(1:iexactpts),itransx)
       if (itransy.gt.0) call transform(yexact(1:iexactpts),itransy)
       call plot_line(iexactpts,xexact(1:iexactpts),yexact(1:iexactpts))
       !
       !--calculate errors
       !
       if (iCalculateExactErrors) then
          !--untransform y axis again for error calculation
          if (itransy.gt.0) call transform_inverse(yexact(1:iexactpts),itransy)
          !--untransform particle y axis also
          ypart(1:npart) = yplot(1:npart)
          if (itransy.gt.0) call transform_inverse(ypart(1:npart),itransy)
          !--calculate errors
          call calculate_errors(xexact(1:iexactpts),yexact(1:iexactpts), &
                                xplot(1:npart),ypart(1:npart),residuals(1:npart), &
                                errL1,errL2,errLinf)
          print "(3(a,1pe10.3,1x))",' L1 error = ',errL1,' L2 error = ',errL2, &
                                   ' L(infinity) error = ',errLinf
          if (iPlotResiduals) call plot_residuals(xplot,residuals,imarker,iaxisy)
       endif
    endif
    !
    !--reset line and colour settings
    !
    call plot_sci(iCurrentColour)
    call plot_sls(iCurrentLineStyle)
    !
    !--deallocate memory
    !
    if (allocated(xexact)) deallocate(xexact)
    if (allocated(yexact)) deallocate(yexact)
    if (allocated(xtemp)) deallocate(xtemp)

    return

  end subroutine exact_solution

  subroutine calculate_errors(xexact,yexact,xpts,ypts,residual,errL1,errL2,errLinf)
   implicit none
   real, dimension(:), intent(in) :: xexact,yexact,xpts,ypts
   real, dimension(size(xpts)), intent(out) :: residual
   real, intent(out) :: errL1,errL2,errLinf
   integer :: i,j,npart,iused,nerr
   real :: xi,dy,dx,yexacti,err1,ymax

   errL1 = 0.
   errL2 = 0.
   errLinf = 0.
   residual = 0.
   npart = size(xpts)
   iused = 0
   ymax = -huge(ymax)
   nerr = 0

   do i=1,npart
      xi = xpts(i)
      yexacti = 0.
      !
      !--find nearest point in exact solution table
      !
      do j=1,size(xexact)-1
         if (xexact(j).lt.xi .and. xexact(j+1).gt.xi) then
            if (abs(residual(i)).gt.tiny(residual)) nerr = nerr + 1
            !--linear interpolation from tabulated exact solution
            dy = yexact(j+1) - yexact(j)
            dx = xexact(j+1) - xexact(j)
            if (dx.gt.0.) then
               yexacti = yexact(j) + dy/dx*(xi - xexact(j))
               residual(i) = ypts(i) - yexacti
            elseif (dy.gt.0.) then
               yexacti = yexact(j)
               residual(i) = ypts(i) - yexacti
            else
               nerr = nerr + 1
               residual(i) = 0.
            endif
            iused = iused + 1
            ymax = max(ymax,abs(yexacti))
         endif
      enddo
      err1 = abs(residual(i))
      errL1 = errL1 + err1
      errL2 = errL2 + err1**2
      errLinf = max(errLinf,err1)
      if (yexacti.gt.tiny(yexacti)) residual(i) = residual(i)/abs(yexacti)
   enddo
   !
   !--normalise errors (use maximum y value)
   !
   if (ymax.gt.tiny(ymax)) then
      errL1 = errL1/(npart*ymax)
      errL2 = sqrt(errL2/(npart*ymax**2))
      errLinf = errLinf/ymax
   else
      print "(a)",' error normalising errors'
      errL1 = 0.
      errL2 = 0.
      errLinf = 0.
   endif
   if (nerr.gt.0) print*,'WARNING: ',nerr,' errors in residual calculation'
   if (iused.ne.npart) print*,'errors calculated using ',iused,' of ',npart, 'particles'

   return
  end subroutine calculate_errors

  subroutine plot_residuals(xpts,residuals,imarker,iaxisy)
   use plotlib, only:plot_qvp,plot_qwin,plot_svp,plot_qci,plot_qfs, &
                     plot_qcs,plot_sci,plot_sfs,plot_svp,plot_box, &
                     plot_pt,plot_swin,plot_rect
   implicit none
   real, dimension(:), intent(in) :: xpts,residuals
   integer, intent(in) :: imarker,iaxisy
   real :: vptxminold,vptxmaxold,vptyminold,vptymaxold
   real :: vptxmin,vptxmax,vptymin,vptymax
   real :: xminold,xmaxold,yminold,ymaxold,ymin,ymax
   real :: xch,ych
   integer :: ioldcolour,ioldfill

   !--query old viewport and window size
   call plot_qvp(0,vptxminold,vptxmaxold,vptyminold,vptymaxold)
   call plot_qwin(xminold,xmaxold,yminold,ymaxold)

   !--use specified bottom % of viewport
   vptxmin = vptxminold
   vptxmax = vptxmaxold
   vptymin = vptyminold
   vptymax = vptyminold + FracinsetResiduals*(vptymaxold - vptyminold)
   call plot_svp(vptxmin,vptxmax,vptymin,vptymax)

   !--set window
   if (residualmax.lt.tiny(residualmax)) then
      ymax = maxval(abs(residuals))
      print*,'max residual = ',ymax
   else
      ymax = residualmax
   endif
   ymin = -ymax

   !--erase space for residual plot
   call plot_qci(ioldcolour)
   call plot_qfs(ioldfill)
   call plot_qcs(0,xch,ych)
   call plot_sci(0)
   call plot_sfs(1)
   if (iaxisy.lt.0) then
      call plot_svp(vptxmin,vptxmax,vptymin,vptymax)
   else
      call plot_svp(vptxmin - 3.*xch,vptxmax,vptymin,vptymax)
   endif
   call plot_swin(xminold,xmaxold,ymin,ymax)
   call plot_rect(xminold,xmaxold,ymin,ymax)
   !--restore fill style
   call plot_sfs(ioldfill)
   call plot_sci(1)

   !--set window and draw axes
   call plot_svp(vptxmin,vptxmax,vptymin,vptymax)
   call plot_swin(xminold,xmaxold,ymin,ymax)
   if (iaxisy.lt.0) then
      call plot_box('ABCST',0.0,0,'BCST',0.0,0)
   else
      call plot_box('ABCST',0.0,0,'BVNCST',0.0,0)
   endif

   !--plot residuals
   call plot_sci(ioldcolour)
   call plot_pt(size(xpts),xpts,residuals,imarker)

   !--restore old viewport, window and colour index
   call plot_svp(vptxminold,vptxmaxold,vptyminold,vptymaxold)
   call plot_swin(xminold,xmaxold,yminold,ymaxold)

  end subroutine plot_residuals

end module exact
