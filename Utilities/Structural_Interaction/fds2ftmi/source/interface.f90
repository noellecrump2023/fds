PROGRAM interface

! Program to convert exposed surface elementos into ANSYS SURF152

IMPLICIT NONE

CHARACTER(256) NODES,ELMS,INTFILE
INTEGER NUMEL,NNODE,I,J,NO1,NO2,NO3,NO4,LINHAS,VARIABLE,CURVEID
INTEGER SHELL,EL,LAYER,HIGHNODE,N_OR,ROUND,CODE,N_AVERAGE,T_AVERAGE
REAL SOMAX,SOMAY,SOMAZ,A(3),B(3),C(3)
REAL, ALLOCATABLE, DIMENSION(:,:) :: NOS,NOMASTER,N,BOUNDARY
INTEGER, ALLOCATABLE, DIMENSION(:,:) :: ELEMENTOS
REAL C_SIZE,TINT,TBEG,TEND,VEC_MULT,HC,EM
CHARACTER(256) CHID,INPUT
CHARACTER(8) INTFILE2,INTFILE3,FILE_END,ARG

C_SIZE=0.0
TINT=0.0
TBEG=0.0
TEND=0.0
SHELL=0
ROUND=1

! Open node file        
NODES='nodes'
OPEN(1,FILE=TRIM(NODES)//'.dat',STATUS='OLD',FORM='FORMATTED')
READ(1,*) NNODE,HIGHNODE
ALLOCATE (NOS(NNODE,4))

! Open element file
ELMS='elements'
OPEN(2,FILE=TRIM(ELMS)//'.dat',STATUS='OLD',FORM='FORMATTED')
!READ(2,'(I8)',ADVANCE='NO') NUMEL
READ(2,*) NUMEL,SHELL,LAYER,EL

! Allocate the pointers
ALLOCATE (NOMASTER(NUMEL,4))
NOMASTER=0.D0
ALLOCATE (ELEMENTOS(NUMEL,9))
ELEMENTOS=0.D0
ALLOCATE (N(NUMEL,4))
N=0.D0

!Normal Orientation (1) for outside the solid and (-1) for inside the solid
N_OR=1
!

!********TRY TO GET INFORMATION THROUGH ARGUMENTS*********
CALL GET_COMMAND_ARGUMENT(1,INPUT)
CALL GET_COMMAND_ARGUMENT(2,ARG)
IF (LEN_TRIM(ARG)/=0) THEN
CHID=INPUT
READ(ARG,*) C_SIZE
CALL GET_COMMAND_ARGUMENT(3,ARG)
READ(ARG,*) VARIABLE
IF (VARIABLE == 1) THEN
    CALL GET_COMMAND_ARGUMENT(4,ARG)
    READ(ARG,*) HC
    CALL GET_COMMAND_ARGUMENT(5,ARG)
    READ(ARG,*) TBEG
    CALL GET_COMMAND_ARGUMENT(6,ARG)
    READ(ARG,*) TEND
    CALL GET_COMMAND_ARGUMENT(7,ARG)
    READ(ARG,*) TINT
    CALL GET_COMMAND_ARGUMENT(8,ARG)
    READ(ARG,*) N_AVERAGE
    CALL GET_COMMAND_ARGUMENT(9,ARG)
    READ(ARG,*) T_AVERAGE
    CALL GET_COMMAND_ARGUMENT(10,ARG)    
    READ(ARG,*) CODE
    CALL GET_COMMAND_ARGUMENT(11,INTFILE)
    IF (CODE == 2) THEN
        CALL GET_COMMAND_ARGUMENT(11,ARG)
        READ(ARG,*) CURVEID
        CALL GET_COMMAND_ARGUMENT(12,ARG)
        READ(ARG,*) EM
        WRITE(6,*) 'Support for export just one variable to LS-Dyna is under development...'
        STOP
    ENDIF
ELSE
    CALL GET_COMMAND_ARGUMENT(4,ARG)
    READ(ARG,*) TBEG
    CALL GET_COMMAND_ARGUMENT(5,ARG)
    READ(ARG,*) TEND
    CALL GET_COMMAND_ARGUMENT(6,ARG)
    READ(ARG,*) TINT
    CALL GET_COMMAND_ARGUMENT(7,ARG)
    READ(ARG,*) N_AVERAGE
    CALL GET_COMMAND_ARGUMENT(8,ARG)
    READ(ARG,*) T_AVERAGE
    CALL GET_COMMAND_ARGUMENT(9,ARG)
    READ(ARG,*) CODE
    CALL GET_COMMAND_ARGUMENT(10,INTFILE)
    IF (CODE == 2) THEN
        CALL GET_COMMAND_ARGUMENT(11,ARG)
        READ(ARG,*) CURVEID
        CALL GET_COMMAND_ARGUMENT(12,ARG)
        READ(ARG,*) EM
    ENDIF
ENDIF
!********TRY TO GET INFORMATION THROUGH INPUTFILE*********
ELSEIF (LEN_TRIM(INPUT)/=0) THEN
OPEN(3,FILE=TRIM(INPUT),STATUS='OLD',FORM='FORMATTED')
READ(3,'(a)') CHID
READ(3,*) C_SIZE
READ(3,*) VARIABLE,HC
READ(3,*) TBEG,TEND,TINT
READ(3,*) N_AVERAGE,T_AVERAGE
READ(3,*) CODE
READ(3,'(a)') INTFILE
IF (CODE == 2) THEN
    READ(3,*) CURVEID,EM
ENDIF
CLOSE(3)
ENDIF
!***********GET INFORMATION THROUGH USER INPUT************
IF (LEN_TRIM(CHID) == 0) THEN
   WRITE(6,*) ' Enter Job ID string (CHID):'
   READ(*,'(a)') CHID
! Beggining of the inputs for the new code 
   WRITE(6,*) ' Enter Cell Size (m)'
   READ(*,*) C_SIZE
   WRITE(6,*) ' Enter number of variables '
   READ(*,*) VARIABLE
   IF (VARIABLE == 1) THEN
        WRITE(6,*) ' Specify the convective heat transfer coefficient (W/(m².K))'
        READ(*,*) HC
   ENDIF       
   WRITE(6,*) ' Enter starting and ending time (s)'
   READ(*,*) TBEG,TEND
   WRITE(6,*) ' Enter time interval (s)'
   READ(*,*) TINT
   WRITE(6,*) ' Enter number of average points to consider constant steady-state exposure conditions (0 if NO average)'
   READ(*,*) N_AVERAGE
   WRITE(6,*) ' Enter time interval to average the exposure conditions (0 if NO average)'
   READ(*,*) T_AVERAGE
   WRITE(6,*) ' Enter FEM code to use: (1) Ansys, (2) LS-Dyna'
   READ(*,*) CODE
   IF (CODE == 2) THEN
      WRITE(6,*) ' Enter starting number to LS-Dyna CurveID'
      READ(3,*) CURVEID
      WRITE(6,*) ' Enter emissivity for exposed surfaces'
      READ(3,*) EM
   ENDIF
ENDIF         
!*********************************************************
! Read nodes and elements
READ_NODES: DO I=1,NNODE
   READ (1,*) NOS(I,1),NOS(I,2),NOS(I,3),NOS(I,4)
ENDDO READ_NODES
10  CONTINUE

READ_ELMS: DO I=1,NUMEL
   READ (2,*) ELEMENTOS(I,1),ELEMENTOS(I,2),ELEMENTOS(I,3),ELEMENTOS(I,4), ELEMENTOS(I,5), &
ELEMENTOS(I,6),ELEMENTOS(I,7),ELEMENTOS(I,8),ELEMENTOS(I,9)
ENDDO READ_ELMS
CREATE_NOMASTER: DO I=1,NUMEL
   HIGHNODE=HIGHNODE+1
   NO1=ELEMENTOS(I,2)
   NO2=ELEMENTOS(I,3)
   NO3=ELEMENTOS(I,4)
   NO4=ELEMENTOS(I,5)
   SOMAX=0.D0
   SOMAY=0.D0
   SOMAZ=0.D0
   DO J=1,NNODE
      IF (NO1==NOS(J,1)) THEN
         SOMAX=SOMAX+NOS(J,2)
         SOMAY=SOMAY+NOS(J,3)
         SOMAZ=SOMAZ+NOS(J,4)
         A(1)=NOS(J,2)
         A(2)=NOS(J,3)
         A(3)=NOS(J,4)
      ELSE IF (NO2==NOS(J,1)) THEN
         SOMAX=SOMAX+NOS(J,2)
         SOMAY=SOMAY+NOS(J,3)
         SOMAZ=SOMAZ+NOS(J,4)
         B(1)=NOS(J,2)
         B(2)=NOS(J,3)
         B(3)=NOS(J,4)
      ELSE IF (NO3==NOS(J,1)) THEN
         SOMAX=SOMAX+NOS(J,2)
         SOMAY=SOMAY+NOS(J,3)
         SOMAZ=SOMAZ+NOS(J,4)
         C(1)=NOS(J,2)
         C(2)=NOS(J,3)
         C(3)=NOS(J,4)
      ELSE IF (NO4/=NO3 .AND. NO4==NOS(J,1)) THEN
         SOMAX=SOMAX+NOS(J,2)
         SOMAY=SOMAY+NOS(J,3)
         SOMAZ=SOMAZ+NOS(J,4)
      ENDIF
   ENDDO
   IF (NO4==NO3) THEN
      NOMASTER(I,1)=HIGHNODE
      NOMASTER(I,2)=SOMAX/3
      NOMASTER(I,3)=SOMAY/3
      NOMASTER(I,4)=SOMAZ/3
   ELSE 
      NOMASTER(I,1)=HIGHNODE
      NOMASTER(I,2)=SOMAX/4
      NOMASTER(I,3)=SOMAY/4
      NOMASTER(I,4)=SOMAZ/4
   ENDIF

   N(I,1)=NOMASTER(I,1)
   N(I,2)=N_OR*((B(2)-A(2))*(C(3)-A(3))-(B(3)-A(3))*(C(2)-A(2)))
   N(I,3)=N_OR*((B(3)-A(3))*(C(1)-A(1))-(B(1)-A(1))*(C(3)-A(3)))
   N(I,4)=N_OR*((B(1)-A(1))*(C(2)-A(2))-(B(2)-A(2))*(C(1)-A(1)))

ENDDO CREATE_NOMASTER
!***** SELECT CASE - WHICH FEM CODE ARE YOU USING! *****
!CODE =1
! 1- ANSYS, 2- LS-Dyna, 3- ..
SELECT CASE (CODE)
CASE (1) ! ANSYS
IF (SHELL==1) THEN
   DO I=1,NUMEL
      VEC_MULT=(C_SIZE/2)/(SQRT((N(I,2)**2)+(N(I,3)**2)+(N(I,4)**2)))
      NOMASTER(I,2)=NOMASTER(I,2)+(N_OR*(N(I,2)*VEC_MULT))
      NOMASTER(I,3)=NOMASTER(I,3)+(N_OR*(N(I,3)*VEC_MULT))
      NOMASTER(I,4)=NOMASTER(I,4)+(N_OR*(N(I,4)*VEC_MULT))
   ENDDO
ENDIF
!
IF (ROUND==1) THEN
   IF (LEN_TRIM(INTFILE)==0) THEN
      WRITE(6,*) ' Enter output file name :'
      READ(*,'(a)') INTFILE
   ENDIF
   OPEN(70,FILE=TRIM(INTFILE)//'.dat',FORM='FORMATTED',STATUS='UNKNOWN')
   OPEN(71,FILE=TRIM(INTFILE)//'_loads.dat',FORM='FORMATTED',STATUS='UNKNOWN')
ENDIF
!************** CREATE EXTRA NODES *********************
WRITE(70,'(A)') '/PREP7' 
IF (VARIABLE==1 .OR. VARIABLE==2) THEN
   DO I=1,NUMEL
      WRITE(70,'(A, I8, A, F7.3, A, F7.3, A, F7.3, A)') "N,", INT(NOMASTER(I,1)), ",", NOMASTER(I,2), ",", &
      NOMASTER(I,3), ",", NOMASTER(I,4), ",,,,"
! Zhi Transformations      
!      WRITE(70,'(A, I8, A, F10.3, A, F10.3, A, F10.3, A)') "N,", INT(NOMASTER(I,1)), ",", NOMASTER(I,3), ",", &
!      NOMASTER(I,4), ",", NOMASTER(I,2), ",,,,"      
!     N,"NODE NUMBER","COORD X","COORD Y","COORD Z",,,,
   ENDDO
ENDIF
!***********************************
!!WORKING!!
!**************** CREATE ELEMENT TYPE SURF152 ********************
WRITE(70,'(A)') "!*"
WRITE(70,'(A, I8, A)') "ET,", EL, ",SURF152"
WRITE(70,'(A)') "!*"
WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",1,0"
WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",2,0"
WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",3,0"
WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",4,0"
IF (VARIABLE==3) THEN
   WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",5,0"
   WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",6,0"
   WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",7,0"
   WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",8,1"
   WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",9,0"
   IF (SHELL==0) THEN
      WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",11,0"
   ENDIF
    WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",13,0"
ELSE
    WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",5,1"
    WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",6,0"
    WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",7,0"
    WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",8,4"
    WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",9,1"
ENDIF
! IF IT IS SHELL ELEMENTS,
! 1 FOR TOP LAYER AND 2 FOR BOTTOM LAYER !
IF (SHELL==1) THEN
   IF (LAYER==1) WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",11,1"
   IF (LAYER==2)  WRITE(70,'(A, I8, A)') "KEYOPT,", EL, ",11,2"
ENDIF
!
WRITE(70,'(A)') "!*"
WRITE(70,'(A)') "!*"
WRITE(70,'(A, I8, A)') "R,", EL, ",1,5.67E-08, , , ,"
WRITE(70,'(A)') "RMORE, , , ,"
WRITE(70,'(A)') "RMORE, , ,"
WRITE(70,'(A)') "!*"
!****************************
!!WORKING!!
!************* CREATE SURF152 ELEMENTS ********
PRINT *, 'LOOP_SURF152'
WRITE(70,'(A)') "!*"
WRITE(70,'(A, I8)') "TYPE,", EL
WRITE(70,'(A, I8)') "MAT,", 1
WRITE(70,'(A, I8)') "REAL,", EL
WRITE(70,'(A, I8)') "ESYS,", 0
WRITE(70,'(A)') "SECNUM,"
WRITE(70,'(A)') "TSHAP,LINE"
WRITE(70,'(A)') "!*"
LOOP_SURF152:DO I=1,NUMEL
   IF (ELEMENTOS(I,6)==0) THEN
      WRITE(70,'(A, I8)') "nsel,S,node,,", ELEMENTOS(I,2)
      WRITE(70,'(A, I8)') "nsel,A,node,,", ELEMENTOS(I,3)
      WRITE(70,'(A, I8)') "nsel,A,node,,", ELEMENTOS(I,4)
      WRITE(70,'(A, I8)') "nsel,A,node,,", ELEMENTOS(I,5)
      IF (VARIABLE==3) THEN
         WRITE(70,'(A)') "ESURF,0"
         ELSE
         WRITE(70,'(A, I8)') "ESURF,", INT(NOMASTER(I,1))
      ENDIF
      WRITE(70,'(A)') "!*"
   ELSE
       WRITE(70,'(A, I8)') "nsel,S,node,,", ELEMENTOS(I,2)
       WRITE(70,'(A, I8)') "nsel,A,node,,", ELEMENTOS(I,3)
       WRITE(70,'(A, I8)') "nsel,A,node,,", ELEMENTOS(I,4)
       WRITE(70,'(A, I8)') "nsel,A,node,,", ELEMENTOS(I,5)
       WRITE(70,'(A, I8)') "nsel,A,node,,", ELEMENTOS(I,6)
       WRITE(70,'(A, I8)') "nsel,A,node,,", ELEMENTOS(I,7)
       WRITE(70,'(A, I8)') "nsel,A,node,,", ELEMENTOS(I,8)
       WRITE(70,'(A, I8)') "nsel,A,node,,", ELEMENTOS(I,9)
       IF (VARIABLE==3) THEN
          WRITE(70,'(A)') "ESURF,0"
       ELSE
          WRITE(70,'(A, I8)') "ESURF,", INT(NOMASTER(I,1))
       ENDIF
       WRITE(70,'(A)') "!*"
   ENDIF
ENDDO LOOP_SURF152
WRITE(70,'(A)') "ALLSEL,ALL"
WRITE(70,'(A)') "!*"
!*******************************
!!WORKING!!
!*********** CREATING TABLES (.DAT) **********
PRINT *, 'LOOP_TABELAS'
LOOP_TABELAS:DO I=1,NUMEL
   WRITE (INTFILE2,'(g8.0)') INT(NOMASTER(I,1))
   PRINT *, INTFILE2
   IF (T_AVERAGE==0) THEN
      IF (N_AVERAGE==0) THEN
         LINHAS=INT((TEND-TBEG)/TINT)+1
      ELSE
         LINHAS=INT((TEND-TBEG)/TINT)+2
      ENDIF
   ELSE
      IF (N_AVERAGE==0) THEN
         LINHAS=INT((TEND-TBEG)/T_AVERAGE)+1
      ELSE
         LINHAS=INT((TEND-TBEG)/T_AVERAGE)+2
      ENDIF
   ENDIF
   IF (VARIABLE==1 .OR. VARIABLE==2) THEN
      WRITE(70,'(A, A, A, I8, A)') "*DIM,A", INTFILE2, ",TABLE,", LINHAS, ",1,1,TIME,TEMP," 
      WRITE(70,'(A)') "!*"
      IF (VARIABLE==2) WRITE(70,'(A, A, A, I8, A)') "*DIM,H", INTFILE2, ",TABLE,", LINHAS, ",1,1,TIME,," 
      IF (VARIABLE==2) WRITE(70,'(A)') "!*"
   ENDIF
   IF (VARIABLE==3) THEN
      WRITE(70,'(A, A, A, I8, A)') "*DIM,A", INTFILE2, ",TABLE,", LINHAS, ",1,1,TIME, ," 
      WRITE(70,'(A)') "!*"
   ENDIF
ENDDO LOOP_TABELAS    
!****************************
!!WORKING!!
!****** LOOP AT FDS2AST TO EXTRACT RESULTS FROM BNDF FILES *****
PRINT *, 'LOOP_FDS2AST'
CALL FDS2AST (CHID,NOMASTER,C_SIZE,TBEG,TEND,TINT,NUMEL,VARIABLE,N,N_AVERAGE,T_AVERAGE)
!*******************
!!WORKING!!
!*********** APPLYING TABLES AS NODAL LOADS **********
IF (VARIABLE==1 .OR. VARIABLE==2) THEN
   WRITE(71,'(A)') "/PREP7"
   PRINT *, 'LOOP_CARGAS'
   LOOP_CARGAS:DO I=1,NUMEL
      WRITE (INTFILE2,'(g8.0)') INT(NOMASTER(I,1))
      PRINT *, INTFILE2
      WRITE(71,'(A)') "!*"
      WRITE(71,'(A, A, A, A, A)') "D,",INTFILE2,", , %A", INTFILE2, "% , , , ,TEMP, , , , ,"
   ENDDO LOOP_CARGAS
ENDIF
!*******************************
!!WORKING!!
!*********** APPLYING TABLES AS CONVECTIVE HEAT TRANSFER COEFFICIENT **********
IF (VARIABLE==2) THEN
   WRITE(71,'(A)') "/PREP7"
   PRINT *, 'LOOP_HEAT_TRANSFER'
   LOOP_HEAT2:DO I=1,NUMEL
      WRITE (INTFILE2,'(g8.0)') INT(NOMASTER(I,1))
      PRINT *, INTFILE2
      WRITE (INTFILE3,'(g8.0)') INT(ELEMENTOS(I,1))
      PRINT *, INTFILE3
      WRITE(71,'(A,A,A,A,A)') "SFE,",INTFILE3,",1,CONV,0,%H",INTFILE2,"%"
   ENDDO LOOP_HEAT2
ENDIF
IF (VARIABLE==1) THEN
   WRITE(71,'(A)') "/PREP7"
   PRINT *, 'LOOP_HEAT_TRANSFER'
   LOOP_HEAT1:DO I=1,NUMEL
      WRITE (INTFILE2,'(g8.0)') INT(NOMASTER(I,1))
      PRINT *, INTFILE2
      WRITE (INTFILE3,'(g8.0)') INT(ELEMENTOS(I,1))
      PRINT *, INTFILE3
      WRITE(71,'(A,A,A,F7.3)') "SFE,",INTFILE3,",1,CONV,0,",HC
   ENDDO LOOP_HEAT1
ENDIF
!*******************************
!*********** APPLYING TABLES AS CONVECTIVE HEAT TRANSFER COEFFICIENT **********
IF (VARIABLE==3) THEN
   WRITE(71,'(A)') "/PREP7"
   PRINT *, 'LOOP_HEAT_FLUX'
   LOOP_HEAT3:DO I=1,NUMEL
      WRITE (INTFILE2,'(g8.0)') INT(NOMASTER(I,1))
      PRINT *, INTFILE2
      WRITE (INTFILE3,'(g8.0)') INT(ELEMENTOS(I,1))
      PRINT *, INTFILE3
      WRITE(71,'(A,A,A,A,A)') "SFE,",INTFILE3,",1,HFLUX,0,%A",INTFILE2,"%"
   ENDDO LOOP_HEAT3
ENDIF
!*******************************
READ(2,'(a)') FILE_END
IF (FILE_END=='END') THEN
   WRITE(6,*) FILE_END
   !******* INPUT OF THE LOADS FILE
   WRITE(70,'(A,A,A)') "/input,",TRIM(INTFILE),"_loads,dat"
   !*******************************
ELSE
   DEALLOCATE (NOMASTER)
   DEALLOCATE (N)
   DEALLOCATE (ELEMENTOS)
   BACKSPACE 2
   READ(2,*) NUMEL,SHELL,LAYER,EL
   ALLOCATE (NOMASTER(NUMEL,4))
   NOMASTER=0.D0
   ALLOCATE (ELEMENTOS(NUMEL,9))
   ELEMENTOS=0.D0
   ALLOCATE (N(NUMEL,4))
   N=0.D0
   ROUND=2
   GO TO 10 
ENDIF
!*******************************
CASE (2) ! LS-Dyna
ALLOCATE (BOUNDARY(2*NUMEL,4))
BOUNDARY=0.D0
IF (LEN_TRIM(INTFILE)==0) THEN
   WRITE(6,*) ' Enter output file name :'
   READ(*,'(a)') INTFILE
ENDIF
OPEN(70,FILE=TRIM(INTFILE)//'.dat',FORM='FORMATTED',STATUS='UNKNOWN')
!************** CREATE SEGMENTS *********************
PRINT *, 'LOOP_SEGMENTS'
DO I=1,NUMEL
   WRITE(70,'(A)') "*SET_SEGMENT"
   WRITE(70,'(I8, A)') I, ", , , , ,"
   WRITE(70,'(I8, A, I8, A, I8, A, I8, A)') INT(ELEMENTOS(I,2)), ",", INT(ELEMENTOS(I,3)), ",", &
   INT(ELEMENTOS(I,4)), ",", INT(ELEMENTOS(I,5)), ", , , ,"
!  SEGMENT NUMBER, , , , , 
!  N1, N2, N3, N4, , , , 
ENDDO
!***********************************
!!WORKING!!
!****** LOOP AT FDS2LS_DYNA TO EXTRACT RESULTS FROM BNDF FILES *****
PRINT *, 'LOOP_FDS2LS_DYNA'
CALL FDS2LS_DYNA (CHID,NOMASTER,C_SIZE,TBEG,TEND,TINT,NUMEL,VARIABLE,N,N_AVERAGE,BOUNDARY,CURVEID)
!*******************
!!WORKING!!
!*********** APPLYING TABLES AS NODAL LOADS **********
PRINT *, 'LOOP_CONV_BOUNDARY'
LOOP_CONV:DO I=1,NUMEL*2
   WRITE(70,'(A)') "*BOUNDARY_CONVECTION_SET"
   WRITE(70,'(I8)') INT(BOUNDARY(I,1))
   WRITE(70,'(I8, A, I8, A, I2)') INT(BOUNDARY(I,3)), ",1.0,", INT(BOUNDARY(I,2)), ",1.0,", INT(BOUNDARY(I,4))
ENDDO LOOP_CONV
!*******************************
!!WORKING!!
PRINT *, 'LOOP_RAD_BOUNDARY'
LOOP_RAD:DO I=1,NUMEL*2
   WRITE(70,'(A)') "*BOUNDARY_RADIATION_SET"
   WRITE(70,'(I8, A)') INT(BOUNDARY(I,1)), ",1"
   WRITE(70,'(A, ES10.3, A, I8, A, I2)') "0,", EM*5.67E-8, ",", INT(BOUNDARY(I,2)), ",1.0,", INT(BOUNDARY(I,4))
ENDDO LOOP_RAD
!*******************************
!!WORKING!!
!*******************************
READ(2,'(a)') FILE_END
IF (FILE_END=='END') THEN
   WRITE(6,*) FILE_END
ELSE
   DEALLOCATE (NOMASTER)
   DEALLOCATE (N)
   DEALLOCATE (ELEMENTOS)
   BACKSPACE 2
   READ(2,*) NUMEL,SHELL,LAYER,EL
   ALLOCATE (NOMASTER(NUMEL,4))
   NOMASTER=0.D0
   ALLOCATE (ELEMENTOS(NUMEL,9))
   ELEMENTOS=0.D0
   ALLOCATE (N(NUMEL,4))
   N=0.D0
   ROUND=2
   GO TO 10 
ENDIF
!*******************************
! SPACE LEFT TO OTHER CODES IMPLEMENTATION
! JUST CHANGE THE OUPUT FORMAT AND KEEP THE 
! CODE STRUCTURE
!*******************************
END SELECT
END PROGRAM interface 