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
!  Copyright (C) 2005-2015 Daniel Price. All rights reserved.
!  Contact: daniel.price@monash.edu
!
!-----------------------------------------------------------------

!-------------------------------------------------------------------------
! this subroutine reads from the data file(s)
! change this to change the format of data input
!
! THIS VERSION IS FOR READING TIPSY FILES
!
! => HANDLES BOTH BINARY AND ASCII TIPSY FORMATS
!    (DETECTS WHICH ONE AUTOMATICALLY)
!
!  BINARY FORMAT READING REQUIRES F2003 STREAM I/O
!  WHICH MAY NOT BE IMPLEMENTED ON OLDER COMPILERS
!
! the data is stored in the global array dat
!
! >> this subroutine must return values for the following: <<
!
! ncolumns    : number of data columns
! ndim, ndimV : number of spatial, velocity dimensions
! nstepsread  : number of steps read from this file
!
! maxplot,maxpart,maxstep      : dimensions of main data array
! dat(maxplot,maxpart,maxstep) : main data array
!
! npartoftype(1:6,maxstep) : number of particles of each type in each timestep
!
! time(maxstep)       : time at each step
! gamma(maxstep)      : gamma at each step
!
! most of these values are stored in global arrays
! in the module 'particle_data'
!-------------------------------------------------------------------------


subroutine read_data(rootname,indexstart,ipos,nstepsread)
  use particle_data, only:dat,time,npartoftype,gamma,maxpart
  use params
  use settings_data, only:ndim,ndimV,ncolumns
  use mem_allocation, only:alloc
  use labels, only:label,ih,ipmass,irho,imetals,itform,ipot,tipsylabel,ncolextra
  use exact, only:hfact
  implicit none
  integer, intent(in) :: indexstart,ipos
  integer, intent(out) :: nstepsread
  character(len=*), intent(in) :: rootname
  !character(len=10), dimension(maxplot) :: tipsylabel
  integer, parameter :: iunit = 16
  integer :: k,j,ierr
  integer :: nprint,ngas,ndark,nptmass,npart_max,nstep_max
  integer :: ncol,nread,iambinaryfile
  logical :: iexist
  character(len=len(rootname)) :: dumpfile
  character(len=11) :: fmt
  real :: timei

  nstepsread = 0
  nstep_max = 0
  npart_max = maxpart
  ncolextra=0
  dumpfile = trim(rootname)
  !
  !--check if first data file exists
  !
  inquire(file=dumpfile,exist=iexist)
  if (.not.iexist) then
     print "(a)",' *** error: '//trim(dumpfile)//': file not found ***'
     return
  endif

  nstep_max = max(nstep_max,indexstart,1)
  j = indexstart
  nstepsread = 0

  write(*,"(26('>'),1x,a,1x,26('<'))") trim(dumpfile)

  !
  !--Check if .label exist (if extra column files exist)
  !
  inquire(file=''//trim(dumpfile)//'.label',exist=iexist)
  if (iexist) then
     open(unit=iunit,file=''//trim(dumpfile)//".label",status='old',form='formatted',iostat=ierr)
     call read_labelfile(iunit,ierr,1)
  endif
  if (.not.iexist) then
     print "(a)",' No label file included or no extra data columns'
  endif

  !
  !--determine whether file is binary or ascii and open it
  !
  inquire(file=dumpfile,form=fmt)
  !print*,'fmt = ',fmt

  select case(trim(adjustl(fmt)))
  case('UNFORMATTED')
     iambinaryfile = 1
!#ifdef __INTEL_COMPILER
!#if __INTEL_COMPILER<1010
     !--this is how stream access is implemented for ifort 9 and lower
!     open(unit=iunit,file=dumpfile,status='old',form='unformatted',recordtype='stream',iostat=ierr)
!#else
!     open(unit=iunit,file=dumpfile,status='old',form='unformatted',access='stream',iostat=ierr)
!#endif
!#else
     open(unit=iunit,file=dumpfile,status='old',form='unformatted',access='stream',iostat=ierr)
!#endif
  case('FORMATTED')
     iambinaryfile = 0
     open(unit=iunit,file=dumpfile,status='old',form='formatted',iostat=ierr)
  case default
     !--if compiler cannot distinguish the two, try ascii first, then binary
     iambinaryfile = 1
     open(unit=iunit,file=dumpfile,status='old',form='unformatted',access='stream',iostat=ierr)
  end select

  if (ierr /= 0) then
     print "(a)",'*** ERROR OPENING '//trim(dumpfile)//' ***'
     return
  endif
  !
  !--read the file header
  !  try ascii format first, and if unsuccessful try binary
  !
  if (iambinaryfile.eq.1) then
     print "(a)",' reading binary tipsy format '
     call read_tipsyheader_binary(iunit,ierr)
  else
     if (iambinaryfile.eq.0) print "(a)",' reading ascii tipsy format '
     call read_tipsyheader_ascii(iunit,ierr,iambinaryfile)
     if (iambinaryfile.lt.0) then
        if (ierr.eq.0) then
           !--if successful ascii header read, file is ascii
           iambinaryfile = 0
           print "(a)",' reading ascii tipsy format '
        else
           !--otherwise, close ascii file, and assume file is binary
           close(unit=iunit)
           iambinaryfile = 1
!#ifdef __INTEL_COMPILER
!#if __INTEL_COMPILER<1010
     !--this is how stream access is implemented for ifort 9 and lower
!          open(unit=iunit,file=dumpfile,status='old',form='unformatted',recordtype='stream',iostat=ierr)
!#else
!          open(unit=iunit,file=dumpfile,status='old',form='unformatted',access='stream',iostat=ierr)
!#endif
!#else
           open(unit=iunit,file=dumpfile,status='old',form='unformatted',access='stream',iostat=ierr)
!#endif
           print "(a)",' reading binary tipsy format '
           call read_tipsyheader_binary(iunit,ierr)
        endif
     endif
  endif
  if (ierr /= 0) then
     print*
     ndim = 0
     ncolumns = 0
     close(unit=iunit)
     return
  endif

  print "(a,f10.2,1(a,i1))",' time: ',timei,' ndim: ',ndim
  print "(4(a,i10))",' ntot: ',nprint,' ngas: ',ngas,' ndark: ',ndark,' nstar: ',nptmass

  ndimV = ndim
  ncol = 2*ndim + 7+ncolextra
  ncolumns = ncol
  !
  !--allocate memory
  !
  if (.not.allocated(dat) .or. nprint.gt.npart_max) then
     npart_max = max(npart_max,nprint)
     call alloc(npart_max,nstep_max,ncolumns)
  endif
  !
  !--now read the timestep data in the dumpfile
  !
  dat(:,:,j) = 0.
  time(j) = timei

  nread = 0
  call set_labels

  if (iambinaryfile.eq.1) then
     call read_tipsybody_binary(iunit,ierr,nread)
  else
     call read_tipsybody_ascii(iunit,ierr,nread)
  endif
  close(unit=iunit)

  if (nread.lt.ncol) then
     print "(a,i2)",' WARNING: END OF FILE: READ TO COLUMN ',nread
     ncolumns = nread
  endif
  !
  !--often tipsy dumps contain only a (fixed) gravitational softening length
  ! for sph particles. In this case we need to create a sensible smoothing length
  ! (and warn people about the evils of using fixed softening lengths for sph particles)
  !
  do k=1,ncolextra
     if (tipsylabel(k)=='smoothleng') then
        dat(1:ngas,ih,j)=dat(1:ngas,ipot+k,j)
     endif
  enddo
  if (ngas.ge.0 .and. nread.ge.irho .and. all(abs(dat(1:ngas,ih,j)-dat(1,ih,j)).le.tiny(dat))) then
     print "(a)",'WARNING: fixed softening lengths detected: simulation may contain artificial fragmentation!'
     print "(a,f5.2,a,i1,a)",'       : creating SPH smoothing lengths using h = ',hfact,'*(m/rho)**(1/',ndim,')'
     dat(1:ngas,ih,j) = hfact*(dat(1:ngas,ipmass,j)/(dat(1:ngas,irho,j) + tiny(dat)))**(1./ndim)
  endif

  nstepsread = nstepsread + 1
  npartoftype(1,j) = ngas
  npartoftype(2,j) = ndark
  npartoftype(3,j) = nptmass
  gamma(j) = 1.666666666667
  j = j + 1

  if (allocated(npartoftype)) then
     print*,'>> end of dump file: nsteps =',j-1,'ntot = ',sum(npartoftype(:,j-1))
  endif

return

contains

!----------------------------------------------------
! ascii header read
!----------------------------------------------------
subroutine read_tipsyheader_ascii(iunit,ierr,iwarn)
 implicit none
 integer, intent(in) :: iunit,iwarn
 integer, intent(out) :: ierr

 read(iunit,*,end=55,iostat=ierr) nprint,ngas,nptmass
 read(iunit,*,end=55,iostat=ierr) ndim
 read(iunit,*,end=55,iostat=ierr) timei
 ndark = nprint - ngas - nptmass
 !--errors in header read
 if (nprint.le.0 .or. nprint.gt.1e10 .or. ndim.le.0 .or. ndim.gt.3 .or. ndark.lt.0) then
    if (iwarn.ge.0) print "(a)",' ERROR reading ascii file header '
    ierr = 2
    return
 endif

 return

55 continue
 if (iwarn.ge.0) print "(a)",' ERROR: end of file in ascii header read '
 ierr = -1
 return

end subroutine read_tipsyheader_ascii

!----------------------------------------------------
! binary header read
!----------------------------------------------------
subroutine read_tipsyheader_binary(iunitb,ierr)
 implicit none
 integer, intent(in) :: iunitb
 integer, intent(out) :: ierr
 real(doub_prec) :: timedb
 integer :: ipad

 ierr = 0
 read(iunitb,iostat=ierr,end=55) timedb,nprint,ndim,ngas,ndark,nptmass,ipad
 print*,'header = ',timedb,nprint,ndim,ngas,ndark,nptmass
 timei = real(timedb)

 !--check for wrong endianness
 if (ierr /= 0 .or. timedb.lt.0. .or. ndim.lt.0 .or. ndim.gt.3 &
     .or. nprint.le.0 .or. ngas.lt.0 .or. ndark.lt.0 .or. nptmass.lt.0 &
     .or. nprint.gt.1e10 .or. ngas.gt.1.e10 .or. ndark.gt.1.e10 .or. nptmass.gt.1.e8) then
    print "(a)",' ERROR reading binary file header: wrong endian? '
    ierr = 2
 endif
 if (ndim.eq.0) ndim = 3

 return

55 continue
 print "(a)",' ERROR: end of file in binary header read'
 ierr = -1
 return

end subroutine read_tipsyheader_binary

subroutine read_labelfile(iunit,ierr,iwarn)
 implicit none
 integer, intent(in) :: iunit,iwarn
 integer, intent(out) :: ierr
 integer :: i

 read(iunit,*,end=66,iostat=ierr) ncolextra
 print *, ncolextra
 do i=1,ncolextra
   read(iunit,*,end=66,iostat=ierr) tipsylabel(i)
   print *, tipsylabel(i)
 enddo

 return

66 continue
 if (iwarn.ge.0) print "(a)",' ERROR: end of file in ascii label read '
 ierr = -1
 return


end subroutine read_labelfile


!----------------------------------------------------
! ascii body read
!----------------------------------------------------
subroutine read_tipsybody_ascii(iunit,ierr,nread)
 implicit none
 integer, intent(in) :: iunit
 integer, intent(out) :: ierr, nread
 integer :: i,ic,icol,nerr

 !--pmass,x,y,z,vx,vy,vz
 do ic=1,2*ndim+1
    nerr = 0
    nread = nread + 1
    if (ic.eq.1) then ! pmass
       icol = ndim + 1
    elseif (ic.ge.2 .and. ic.le.ndim+1) then ! x, y, z
       icol = ic - 1
    else ! everything after
       icol = ic
    endif
    !print "(1x,a)",trim(label(icol))
    nerr = 0
    do i=1,nprint
       read(iunit,*,end=44,iostat=ierr) dat(i,icol,j)
       if (ierr /= 0) nerr = nerr + 1
    enddo
    if (nerr.gt.0) print *,'*** WARNING: ERRORS READING '//trim(label(icol))//' ON ',nerr,' LINES'
 enddo
 !--h dark matter
 if (ndark.gt.0) then
    nerr = 0
    do i=ngas+1,ngas+ndark
       read(iunit,*,end=44,iostat=ierr) dat(i,ih,j)
       if (ierr /= 0) nerr = nerr + 1
    enddo
    if (nerr.gt.0) print *,'*** WARNING: ERRORS READING DARK MATTER H ON ',nerr,' LINES'
 endif
 !--h star particles
 if (nptmass.gt.0) then
    nerr = 0
    do i=ngas+ndark+1,ngas+ndark+nptmass
       read(iunit,*,end=44,iostat=ierr) dat(i,ih,j)
       if (ierr /= 0) nerr = nerr + 1
    enddo
    if (nerr.gt.0) print *,'*** WARNING: ERRORS READING PTMASS H ON ',nerr,' LINES'
 endif
 !--density, temperature, sph smoothing length, metals gas
 do icol=2*ndim+2,2*ndim+5
    nread = nread + 1
    !print "(1x,a)",trim(label(icol))
    do i=1,ngas
       read(iunit,*,end=44,iostat=ierr) dat(i,icol,j)
       if (ierr /= 0) nerr = nerr + 1
    enddo
    if (nerr.gt.0) print *,'*** WARNING: ERRORS READING '//trim(label(icol))//' ON ',nerr,' LINES'
 enddo
 !--metals and tform starparticles
 if (nptmass.gt.0) then
    nerr = 0
    do i=ngas+ndark+1,ngas+ndark+nptmass
       read(iunit,*,end=44,iostat=ierr) dat(i,imetals,j)
       if (ierr /= 0) nerr = nerr + 1
    enddo
    nread = nread + 1
    do i=ngas+ndark+1,ngas+ndark+nptmass
       read(iunit,*,end=44,iostat=ierr) dat(i,itform,j)
       if (ierr /= 0) nerr = nerr + 1
    enddo
    if (nerr.gt.0) print *,'*** WARNING: ERRORS READING PTMASS H ON ',nerr,' LINES'
 endif
!--potential all particles
   nerr = 0
   nread = nread + 1
    do i=1,nprint
       read(iunit,*,end=44,iostat=ierr) dat(i,ipot,j)
       if (ierr /= 0) nerr = nerr + 1
    enddo

    if (nerr.gt.0) print *,'*** WARNING: ERRORS READING PTMASS H ON ',nerr,' LINES'

 ierr = 0
 return

44 continue
 ierr = -1

end subroutine read_tipsybody_ascii

!----------------------------------------------------
! binary body read
!----------------------------------------------------
subroutine read_tipsybody_binary(iunitb,ierr,nread)
 integer, intent(in) :: iunitb
 integer, intent(out) :: ierr,nread
 integer :: i,nerr
 real :: dummy
 !--gas particles
 nerr = 0
 do i=1,ngas
    !--pmass,x,y,z,vx,vy,vz,rho,temp,h
    read(iunitb,end=44,iostat=ierr) dat(i,ipmass,j),dat(i,1:ndim,j),dat(i,ndim+2:ncolumns-1,j)
    !print*, ' xyz = ',dat(i,1:ncolumns-1,j)
    if (ierr /= 0) nerr = nerr + 1
 enddo
 nread = ncolumns
 print*, ' nred: ',nread
 if (nerr.gt.0) print *,'*** WARNING: ERRORS READING GAS PARTICLES ON ',nerr,' LINES'

 !--dark matter
 if (ndark.gt.0) then
    nerr = 0
    do i=ngas+1,ngas+ndark
       !--only read as far as velocities, then eps as smoothing length
       read(iunitb,end=44,iostat=ierr) dat(i,ipmass,j),dat(i,1:ndim,j),dat(i,ndim+2:2*ndim+1,j),dat(i,ih,j), &
dat(i,ipot,j),dat(i,ipot+1:ncolumns-1,j)
       !print*,' DM mass = ',i,dat(i,ipmass,j)
       if (ierr /= 0) nerr = nerr + 1
    enddo
    if (nerr.gt.0) print *,'*** WARNING: ERRORS READING DARK MATTER PARTICLES ON ',nerr,' LINES'
 endif

 !--star particles
 if (nptmass.gt.0) then
    nerr = 0
    do i=ngas+ndark+1,ngas+ndark+nptmass
       !--only read as far as velocities, then eps as smoothing length
       read(iunitb,end=44,iostat=ierr) dat(i,ipmass,j),dat(i,1:ndim,j),dat(i,ndim+2:2*ndim+1,j),dat(i,imetals,j), &
dat(i,itform,j),dat(i,ih,j),dat(i,ipot,j),dat(i,ipot+1:ncolumns-1,j)
       !print*,' star mass = ',i,dat(i,ipmass,j)
       if (ierr /= 0) nerr = nerr + 1
    enddo
    if (nerr.gt.0) print *,'*** WARNING: ERRORS READING STAR PARTICLES ON ',nerr,' LINES'
 endif

 ierr = 0
 return

44 continue
 ierr = -1

end subroutine read_tipsybody_binary

end subroutine read_data

!!------------------------------------------------------------
!! set labels for each column of data
!!------------------------------------------------------------

subroutine set_labels
  use labels, only:label,labelvec,labeltype,iamvec,&
              ix,ivx,ih,irho,ipmass,imetals,idivb,iBfirst,iJfirst,itform,ipot,tipsylabel,ncolextra !,iutherm
  use settings_data, only:ndim,ndimV,ntypes,UseTypeInRenderings
  use geometry, only:labelcoord
  !use settings_units, only:units,unitslabel
  implicit none
  integer :: i
  !iBfirst=0
  !iJfirst=0
  if (ndim.le.0 .or. ndim.gt.3) then
     print*,'*** ERROR: ndim = ',ndim,' in set_labels ***'
     return
  endif
  if (ndimV.le.0 .or. ndimV.gt.3) then
     print*,'*** ERROR: ndimV = ',ndimV,' in set_labels ***'
     return
  endif
  do i=1,ndim
     ix(i) = i
  enddo
  print *, ncolextra
  ipmass = ndim + 1
  ivx = ndim + 2
  irho = ivx + ndim
  !iutherm = irho + 1
  label(irho+1) = 'temperature'
  ih = irho + 2
  imetals = irho+3
  ipot = irho+4

  label(ix(1:ndim)) = labelcoord(1:ndim,1)
  label(ih) = 'h'
  !if (iutherm.gt.0) label(iutherm) = 'temperature'
  label(ipmass) = 'particle mass'
  label(irho) = 'density'
  label(imetals) = 'metals'
  label(ipot) = 'potential'
  do i=1,ncolextra
     if (tipsylabel(i)=='smoothleng') then
        label(ipot+i) = 'h'
        label(ih) = 'eps'
     else
     label(ipot+i) = tipsylabel(i)
endif
     if (tipsylabel(i)=='BFieldx') then
        iBfirst=ipot+i
endif
     if (tipsylabel(i)=='CurlBx') then
        iJfirst=ipot+i
endif
 if (tipsylabel(i)=='DivB') then
        idivb=ipot+i
endif
  enddo
  itform = ipot+ncolextra+1
  label(itform) = 'tform'
  if (ivx.ne.0) then
     iamvec(ivx:ivx+ndimV-1) = ivx
     labelvec(ivx:ivx+ndimV-1) = 'v'
     do i=1,ndimV
        label(ivx+i-1) = trim(labelvec(ivx))//'\d'//trim(labelcoord(i,1))
     enddo
  endif
  if (iBfirst.ne.0) then
     iamvec(iBfirst:iBfirst+ndimV-1) = iBfirst
     labelvec(iBfirst:iBfirst+ndimV-1) = 'B'
     do i=1,ndimV
        label(iBfirst+i-1) = trim(labelvec(iBfirst))//'\d'//trim(labelcoord(i,1))
     enddo
  endif
  if (iJfirst.ne.0) then
     iamvec(iJfirst:iJfirst+ndimV-1) = iJfirst
     labelvec(iJfirst:iJfirst+ndimV-1) = 'CurlB'
     do i=1,ndimV
        label(iJfirst+i-1) = trim(labelvec(iJfirst))//'\d'//trim(labelcoord(i,1))
     enddo
  endif
  !
  !--set labels for each particle type
  !
  ntypes = 3
  labeltype(1) = 'gas'
  labeltype(2) = 'dark matter'
  labeltype(3) = 'star'
  UseTypeInRenderings(1) = .true.
  UseTypeInRenderings(2) = .false.
  UseTypeInRenderings(3) = .false.

!-----------------------------------------------------------

  return
end subroutine set_labels
