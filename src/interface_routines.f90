!> \file
!> $Id: interface_routines.f90 690 2009-09-30 23:27:16Z chrispbradley $
!> \author David Nordsletten
!> \brief This module contains all interface routines.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is OpenCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s):
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delte
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!> This module contains all interface routines.
MODULE INTERFACE_ROUTINES

  USE BASE_ROUTINES
  USE FIELD_ROUTINES
  USE GENERATED_MESH_ROUTINES
  USE INPUT_OUTPUT
  USE INTERFACE_CONDITIONS_ROUTINES
  USE ISO_VARYING_STRING
  USE KINDS
  USE MESH_ROUTINES
  USE NODE_ROUTINES
  USE STRINGS
  USE TYPES

  IMPLICIT NONE

  PRIVATE

  !Module parameters

  !Module types

  !Module variables

  PUBLIC INTERFACE_MESH_ADD

  PUBLIC INTERFACE_CREATE_START, INTERFACE_CREATE_FINISH

  PUBLIC INTERFACE_DESTROY, INTERFACE_MESH_CONNECTIVITY_DESTROY

  PUBLIC INTERFACE_MESH_CONNECTIVITY_CREATE_START, INTERFACE_MESH_CONNECTIVITY_CREATE_FINISH

  PUBLIC INTERFACE_USER_NUMBER_FIND

  PUBLIC INTERFACES_FINALISE,INTERFACES_INITIALISE

  PUBLIC INTERFACE_MESH_CONNECTIVITY_ELEMENT_XI_SET, INTERFACE_MESH_CONNECTIVITY_ELEMENT_NUMBER_ELEMENTS_SET
  
CONTAINS

  !
  !================================================================================================================================
  !

  SUBROUTINE INTERFACE_MESH_ADD(INTERFACE,MESH,MESH_INDEX,ERR,ERROR,*)   

    !Argument variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<A pointer to the interface to add a mesh to
    TYPE(MESH_TYPE), POINTER :: MESH !<A pointer to the mesh to add to the interface
    INTEGER(INTG), INTENT(OUT) :: MESH_INDEX !<On return, the index of the added mesh in the list of meshes in the interface
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: mesh_idx
    LOGICAL :: MESH_ALREADY_COUPLED
    TYPE(MESH_TYPE), POINTER :: COUPLED_MESH
    TYPE(MESH_PTR_TYPE), POINTER :: NEW_COUPLED_MESHES(:)
    TYPE(REGION_TYPE), POINTER :: COUPLED_MESH_REGION,MESH_REGION
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    NULLIFY(NEW_COUPLED_MESHES)
    
    CALL ENTERS("INTERFACE_MESH_ADD",ERR,ERROR,*999)

    IF(ASSOCIATED(INTERFACE)) THEN
      IF(INTERFACE%INTERFACE_FINISHED) THEN
        CALL FLAG_ERROR("Interface has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(ASSOCIATED(MESH)) THEN
          IF(MESH%MESH_FINISHED) THEN
            MESH_REGION=>MESH%REGION
            IF(ASSOCIATED(MESH_REGION)) THEN
              ALLOCATE(NEW_COUPLED_MESHES(INTERFACE%NUMBER_OF_COUPLED_MESHES+1),STAT=ERR)
              IF(ERR/=0) CALL FLAG_ERROR("Could not allocate new coupled meshes.",ERR,ERROR,*999)
              !Check that the mesh is not already in the list of meshes for the interface.
              IF(INTERFACE%NUMBER_OF_COUPLED_MESHES>0) THEN
                IF(ASSOCIATED(INTERFACE%COUPLED_MESHES)) THEN
                  MESH_ALREADY_COUPLED=.FALSE.
                  DO mesh_idx=1,INTERFACE%NUMBER_OF_COUPLED_MESHES
                    COUPLED_MESH=>INTERFACE%COUPLED_MESHES(mesh_idx)%PTR
                    IF(ASSOCIATED(COUPLED_MESH)) THEN
                      COUPLED_MESH_REGION=>COUPLED_MESH%REGION
                      IF(ASSOCIATED(COUPLED_MESH_REGION)) THEN
                        IF(MESH_REGION%USER_NUMBER==COUPLED_MESH_REGION%USER_NUMBER) THEN
                          IF(MESH%USER_NUMBER==COUPLED_MESH%USER_NUMBER) THEN
                            MESH_ALREADY_COUPLED=.TRUE.
                            EXIT
                          ENDIF
                        ENDIF
                      ELSE
                        LOCAL_ERROR="Coupled interface mesh region for mesh index "// &
                          & TRIM(NUMBER_TO_VSTRING(mesh_idx,"*",ERR,ERROR))//" is not associated."
                        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      LOCAL_ERROR="Coupled interface mesh for mesh index "//TRIM(NUMBER_TO_VSTRING(mesh_idx,"*",ERR,ERROR))// &
                        & " is not associated."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                    NEW_COUPLED_MESHES(mesh_idx)%PTR=>INTERFACE%COUPLED_MESHES(mesh_idx)%PTR
                  ENDDO !mesh_idx
                  IF(MESH_ALREADY_COUPLED) THEN
                    LOCAL_ERROR="The supplied mesh has already been added to the list of coupled meshes at mesh index "// &
                      & TRIM(NUMBER_TO_VSTRING(mesh_idx,"*",ERR,ERROR))//"."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  ENDIF
                  DEALLOCATE(INTERFACE%COUPLED_MESHES)
                ELSE
                  CALL FLAG_ERROR("Interface coupled meshes is not associated.",ERR,ERROR,*999)
                ENDIF
              ENDIF
              !Add the mesh to the list of coupled meshes
              NEW_COUPLED_MESHES(INTERFACE%NUMBER_OF_COUPLED_MESHES+1)%PTR=>MESH
              INTERFACE%COUPLED_MESHES=>NEW_COUPLED_MESHES
              !Increment the number of coupled meshes and return the index
              INTERFACE%NUMBER_OF_COUPLED_MESHES=INTERFACE%NUMBER_OF_COUPLED_MESHES+1
              MESH_INDEX=INTERFACE%NUMBER_OF_COUPLED_MESHES
            ELSE
              CALL FLAG_ERROR("Mesh region is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Mesh has not been finished.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Mesh is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Interface is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("INTERFACE_MESH_ADD")
    RETURN
999 IF(ASSOCIATED(NEW_COUPLED_MESHES)) DEALLOCATE(NEW_COUPLED_MESHES)
    CALL ERRORS("INTERFACE_MESH_ADD",ERR,ERROR)
    CALL EXITS("INTERFACE_MESH_ADD")
    RETURN 1
    
  END SUBROUTINE INTERFACE_MESH_ADD

  !
  !================================================================================================================================
  !

  !>Finishes the creation of an interface. \see OPENCMISS::CMISSInterfaceCreateFinish
  SUBROUTINE INTERFACE_CREATE_FINISH(INTERFACE,ERR,ERROR,*) 

    !Argument variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<A pointer to the interface to finish the creation of
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
     
    CALL ENTERS("INTERFACE_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(INTERFACE)) THEN
      IF(INTERFACE%INTERFACE_FINISHED) THEN
        CALL FLAG_ERROR("Interface has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(INTERFACE%NUMBER_OF_COUPLED_MESHES<2) THEN
          LOCAL_ERROR="Invalid mesh coupling. Only "//TRIM(NUMBER_TO_VSTRING(INTERFACE%NUMBER_OF_COUPLED_MESHES,"*",ERR,ERROR))// &
            & " have been coupled. The number of coupled meshes must be >= 2."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
        INTERFACE%INTERFACE_FINISHED=.TRUE.
      ENDIF
    ELSE
      CALL FLAG_ERROR("Interface is not associated.",ERR,ERROR,*999)
    ENDIF
    
    IF(DIAGNOSTICS1) THEN
      CALL WRITE_STRING(DIAGNOSTIC_OUTPUT_TYPE,"Interface :",ERR,ERROR,*999)      
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  User number = ",INTERFACE%USER_NUMBER,ERR,ERROR,*999)      
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Global number = ",INTERFACE%GLOBAL_NUMBER,ERR,ERROR,*999)      
      CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Label = ",INTERFACE%LABEL,ERR,ERROR,*999)
      IF(ASSOCIATED(INTERFACE%INTERFACES)) THEN
        IF(ASSOCIATED(INTERFACE%INTERFACES%PARENT_REGION)) THEN
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Parent region user number = ",INTERFACE%INTERFACES% &
            & PARENT_REGION%USER_NUMBER,ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(DIAGNOSTIC_OUTPUT_TYPE,"  Parent region label = ",INTERFACE%INTERFACES% &
            & PARENT_REGION%LABEL,ERR,ERROR,*999)        
        ELSE
          CALL FLAG_ERROR("Interfaces parent region is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Interface interfaces is not associated.",ERR,ERROR,*999)
      ENDIF
    ENDIF
    
    CALL EXITS("INTERFACE_CREATE_FINISH")
    RETURN
999 CALL ERRORS("INTERFACE_CREATE_FINISH",ERR,ERROR)
    CALL EXITS("INTERFACE_CREATE_FINISH")
    RETURN 1
  END SUBROUTINE INTERFACE_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Starts the creation of an interface on a parent region. \see OPENCMISS::CMISSInterfaceCreateStart
  SUBROUTINE INTERFACE_CREATE_START(USER_NUMBER,PARENT_REGION,INTERFACE,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: USER_NUMBER !<The user number of the interface to create
    TYPE(REGION_TYPE), POINTER :: PARENT_REGION !<A pointer to the parent region to create the interface on.
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<On exit, a pointer to the created interface. Must not be associated on entry.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR,interface_idx
    TYPE(INTERFACE_TYPE), POINTER :: NEW_INTERFACE
    TYPE(INTERFACE_PTR_TYPE), POINTER :: NEW_INTERFACES(:)
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR,LOCAL_STRING

    NULLIFY(NEW_INTERFACE)
    NULLIFY(NEW_INTERFACES)
    
    CALL ENTERS("INTERFACE_CREATE_START",ERR,ERROR,*998)

    IF(ASSOCIATED(PARENT_REGION)) THEN
      IF(ASSOCIATED(INTERFACE)) THEN
        CALL FLAG_ERROR("Interface is already associated.",ERR,ERROR,*998)
      ELSE
        NULLIFY(INTERFACE)
        CALL INTERFACE_USER_NUMBER_FIND(USER_NUMBER,PARENT_REGION,INTERFACE,ERR,ERROR,*998)
        IF(ASSOCIATED(INTERFACE)) THEN
          LOCAL_ERROR="Interface number "//TRIM(NUMBER_TO_VSTRING(USER_NUMBER,"*",ERR,ERROR))// &
            & " has already been created on region number "//TRIM(NUMBER_TO_VSTRING(PARENT_REGION%USER_NUMBER,"*",ERR,ERROR))//"."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*998)
        ELSE        
          NULLIFY(INTERFACE)
          !Allocate and set default interface properties.
          CALL INTERFACE_INITIALISE(NEW_INTERFACE,ERR,ERROR,*999)
          NEW_INTERFACE%USER_NUMBER=USER_NUMBER
          NEW_INTERFACE%GLOBAL_NUMBER=PARENT_REGION%INTERFACES%NUMBER_OF_INTERFACES+1
          LOCAL_STRING="Interface "//NUMBER_TO_VSTRING(USER_NUMBER,"*",ERR,ERROR)
          NEW_INTERFACE%LABEL=CHAR(LOCAL_STRING)
          IF(ERR/=0) GOTO 999
          NEW_INTERFACE%INTERFACES=>PARENT_REGION%INTERFACES
          NEW_INTERFACE%PARENT_REGION=>PARENT_REGION
          !Add new initerface into list of interfaces in the parent region
          ALLOCATE(NEW_INTERFACES(PARENT_REGION%INTERFACES%NUMBER_OF_INTERFACES+1),STAT=ERR)
          IF(ERR/=0) CALL FLAG_ERROR("Could not allocate new interfaces.",ERR,ERROR,*999)
          DO interface_idx=1,PARENT_REGION%INTERFACES%NUMBER_OF_INTERFACES
            NEW_INTERFACES(interface_idx)%PTR=>PARENT_REGION%INTERFACES%INTERFACES(interface_idx)%PTR
          ENDDO !interface_idx
          NEW_INTERFACES(PARENT_REGION%INTERFACES%NUMBER_OF_INTERFACES+1)%PTR=>NEW_INTERFACE
          IF(ASSOCIATED(PARENT_REGION%INTERFACES%INTERFACES)) DEALLOCATE(PARENT_REGION%INTERFACES%INTERFACES)
          PARENT_REGION%INTERFACES%INTERFACES=>NEW_INTERFACES
          PARENT_REGION%INTERFACES%NUMBER_OF_INTERFACES=PARENT_REGION%INTERFACES%NUMBER_OF_INTERFACES+1
          INTERFACE=>NEW_INTERFACE
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Parent region is not associated.",ERR,ERROR,*998)
    ENDIF
    
    CALL EXITS("INTERFACE_CREATE_START")
    RETURN
999 IF(ASSOCIATED(NEW_INTERFACES)) DEALLOCATE(NEW_INTERFACES)
    CALL INTERFACE_FINALISE(INTERFACE,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("INTERFACE_CREATE_START",ERR,ERROR)
    CALL EXITS("INTERFACE_CREATE_START")
    RETURN 1
  END SUBROUTINE INTERFACE_CREATE_START

  !
  !================================================================================================================================
  !

  !>Destroys an interface. \see OPENCMISS::CMISSInterfaceDestroy
  SUBROUTINE INTERFACE_DESTROY(INTERFACE,ERR,ERROR,*) 

    !Argument variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<A pointer to the interface to destroy
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: interface_idx,interface_position
    TYPE(INTERFACE_PTR_TYPE), POINTER :: NEW_INTERFACES(:)
    TYPE(INTERFACES_TYPE), POINTER :: INTERFACES
     
    NULLIFY(NEW_INTERFACES)

    CALL ENTERS("INTERFACE_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(INTERFACE)) THEN
      INTERFACES=>INTERFACE%INTERFACES
      IF(ASSOCIATED(INTERFACES)) THEN
        interface_position=INTERFACE%GLOBAL_NUMBER

        !Destroy all the interface condition components
        CALL INTERFACE_FINALISE(INTERFACE,ERR,ERROR,*999)
        
        !Remove the interface condition from the list of interface conditions
        IF(INTERFACES%NUMBER_OF_INTERFACES>1) THEN
          ALLOCATE(NEW_INTERFACES(INTERFACES%NUMBER_OF_INTERFACES-1),STAT=ERR)
          IF(ERR/=0) CALL FLAG_ERROR("Could not allocate new interface conditions.",ERR,ERROR,*999)
          DO interface_idx=1,INTERFACES%NUMBER_OF_INTERFACES
            IF(interface_idx<interface_position) THEN
              NEW_INTERFACES(interface_idx)%PTR=>INTERFACES%INTERFACES(interface_idx)%PTR
            ELSE IF(interface_idx>interface_position) THEN
              INTERFACES%INTERFACES(interface_idx)%PTR%GLOBAL_NUMBER=INTERFACES%INTERFACES(interface_idx)%PTR%GLOBAL_NUMBER-1
              NEW_INTERFACES(interface_idx-1)%PTR=>INTERFACES%INTERFACES(interface_idx)%PTR
            ENDIF
          ENDDO !interface_idx
          IF(ASSOCIATED(INTERFACES%INTERFACES)) DEALLOCATE(INTERFACES%INTERFACES)
          INTERFACES%INTERFACES=>NEW_INTERFACES
          INTERFACES%NUMBER_OF_INTERFACES=INTERFACES%NUMBER_OF_INTERFACES-1
        ELSE
          DEALLOCATE(INTERFACES%INTERFACES)
          INTERFACES%NUMBER_OF_INTERFACES=0
        ENDIF
        
      ELSE
        CALL FLAG_ERROR("Interface interfaces is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Interface is not associated.",ERR,ERROR,*999)
    ENDIF    
    
    CALL EXITS("INTERFACE_DESTROY")
    RETURN
999 CALL ERRORS("INTERFACE_DESTROY",ERR,ERROR)
    CALL EXITS("INTERFACE_DESTROY")
    RETURN 1
  END SUBROUTINE INTERFACE_DESTROY

  !
  !================================================================================================================================
  !

  !>Finalises an interface and deallocates all memory.
  SUBROUTINE INTERFACE_FINALISE(INTERFACE,ERR,ERROR,*) 

    !Argument variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<A pointer to the interface to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("INTERFACE_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(INTERFACE)) THEN
      IF(ASSOCIATED(INTERFACE%COUPLED_MESHES)) DEALLOCATE(INTERFACE%COUPLED_MESHES)
      CALL INTERFACE_MESH_CONNECTIVITY_FINALISE(INTERFACE%MESH_CONNECTIVITY,ERR,ERROR,*999)
      IF(ASSOCIATED(INTERFACE%NODES)) CALL NODES_DESTROY(INTERFACE%NODES,ERR,ERROR,*999)
      CALL MESHES_FINALISE(INTERFACE%MESHES,ERR,ERROR,*999)
      CALL FIELDS_FINALISE(INTERFACE%FIELDS,ERR,ERROR,*999)
      CALL INTERFACE_CONDITIONS_FINALISE(INTERFACE%INTERFACE_CONDITIONS,ERR,ERROR,*999)
      DEALLOCATE(INTERFACE)
    ENDIF
    
    CALL EXITS("INTERFACE_FINALISE")
    RETURN
999 CALL ERRORS("INTERFACE_FINALISE",ERR,ERROR)
    CALL EXITS("INTERFACE_FINALISE")
    RETURN 1
  END SUBROUTINE INTERFACE_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises an interface.
  SUBROUTINE INTERFACE_INITIALISE(INTERFACE,ERR,ERROR,*) 

    !Argument variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<A pointer to the interface to initialise.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("INTERFACE_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(INTERFACE)) THEN
      CALL FLAG_ERROR("Interface is already associated.",ERR,ERROR,*999)
    ELSE
      ALLOCATE(INTERFACE,STAT=ERR)
      IF(ERR/=0) CALL FLAG_ERROR("Could not allocate interface.",ERR,ERROR,*999)
      INTERFACE%USER_NUMBER=0
      INTERFACE%GLOBAL_NUMBER=0
      INTERFACE%INTERFACE_FINISHED=.FALSE.
      INTERFACE%LABEL=""
      NULLIFY(INTERFACE%INTERFACES)
      NULLIFY(INTERFACE%PARENT_REGION)
      INTERFACE%NUMBER_OF_COUPLED_MESHES=0
      NULLIFY(INTERFACE%COUPLED_MESHES)
      NULLIFY(INTERFACE%MESH_CONNECTIVITY)
      NULLIFY(INTERFACE%NODES)
      NULLIFY(INTERFACE%MESHES)
      NULLIFY(INTERFACE%GENERATED_MESHES)
      NULLIFY(INTERFACE%FIELDS)
      NULLIFY(INTERFACE%INTERFACE_CONDITIONS)
      CALL MESHES_INITIALISE(INTERFACE,ERR,ERROR,*999)
      CALL GENERATED_MESHES_INITIALISE(INTERFACE,ERR,ERROR,*999)
      CALL FIELDS_INITIALISE(INTERFACE,ERR,ERROR,*999)
      CALL INTERFACE_CONDITIONS_INITIALISE(INTERFACE,ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("INTERFACE_INITIALISE")
    RETURN
999 CALL ERRORS("INTERFACE_INITIALISE",ERR,ERROR)
    CALL EXITS("INTERFACE_INITIALISE")
    RETURN 1
  END SUBROUTINE INTERFACE_INITIALISE

  !
  !================================================================================================================================
  !

  !>Initialises a meshes connectivity for an interface.
  SUBROUTINE INTERFACE_MESH_CONNECTIVITY_CREATE_FINISH(INTERFACE_MESH_CONNECTIVITY,ERR,ERROR,*) 

    !Argument variables
    TYPE(INTERFACE_MESH_CONNECTIVITY_TYPE), POINTER :: INTERFACE_MESH_CONNECTIVITY !<A pointer to the interface meshes connectivity to finish creating
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("INTERFACE_MESH_CONNECTIVITY_CREATE_FINISH",ERR,ERROR,*999)

     IF(ASSOCIATED(INTERFACE_MESH_CONNECTIVITY)) THEN
       IF(INTERFACE_MESH_CONNECTIVITY%MESH_CONNECTIVITY_FINISHED) THEN
         CALL FLAG_ERROR("Interface meshes connectivity has already been finished.",ERR,ERROR,*999)
       ELSE
         INTERFACE_MESH_CONNECTIVITY%MESH_CONNECTIVITY_FINISHED=.TRUE.
       ENDIF
     ELSE
       CALL FLAG_ERROR("Interface meshes connectivity is not associated.",ERR,ERROR,*999)
     ENDIF
    
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_CREATE_FINISH")
    RETURN
999 CALL ERRORS("INTERFACE_MESH_CONNECTIVITY_CREATE_FINISH",ERR,ERROR)
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_CREATE_FINISH")
    RETURN 1
  END SUBROUTINE INTERFACE_MESH_CONNECTIVITY_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Initialises a meshes connectivity for an interface.
  SUBROUTINE INTERFACE_MESH_CONNECTIVITY_CREATE_START(INTERFACE,MESH,INTERFACE_MESH_CONNECTIVITY,ERR,ERROR,*) 

    !Argument variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<A pointer to the interface to create the meshes connectivity for
    TYPE(MESH_TYPE), POINTER :: MESH
    TYPE(INTERFACE_MESH_CONNECTIVITY_TYPE), POINTER :: INTERFACE_MESH_CONNECTIVITY !<On return, a pointer to the created meshes connectivity
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR

    CALL ENTERS("INTERFACE_MESH_CONNECTIVITY_CREATE_START",ERR,ERROR,*999)

    IF(ASSOCIATED(INTERFACE)) THEN
      IF(INTERFACE%INTERFACE_FINISHED) THEN
        IF(ASSOCIATED(INTERFACE%MESH_CONNECTIVITY)) THEN
          CALL FLAG_ERROR("The interface already has a meshes connectivity associated.",ERR,ERROR,*999)
        ELSE
          !Initialise the meshes connectivity
          CALL INTERFACE_MESH_CONNECTIVITY_INITIALISE(INTERFACE,MESH,ERR,ERROR,*999)
          !Return the pointer
          INTERFACE_MESH_CONNECTIVITY=>INTERFACE%MESH_CONNECTIVITY
        ENDIF
      ELSE
        CALL FLAG_ERROR("Interface has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Interface is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_CREATE_START")
    RETURN
999 CALL ERRORS("INTERFACE_MESH_CONNECTIVITY_CREATE_START",ERR,ERROR)
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_CREATE_START")
    RETURN 1
    
  END SUBROUTINE INTERFACE_MESH_CONNECTIVITY_CREATE_START

  !
  !================================================================================================================================
  !

  !>Finalises a meshes connectivity and deallocates all memory
  SUBROUTINE INTERFACE_MESH_CONNECTIVITY_DESTROY(INTERFACE_MESH_CONNECTIVITY,ERR,ERROR,*) 

    !Argument variables
    TYPE(INTERFACE_MESH_CONNECTIVITY_TYPE), POINTER :: INTERFACE_MESH_CONNECTIVITY !<A pointer to the interface meshes connectivity to destroy
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    
    CALL ENTERS("INTERFACE_MESH_CONNECTIVITY_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(INTERFACE_MESH_CONNECTIVITY)) THEN
      CALL INTERFACE_MESH_CONNECTIVITY_FINALISE(INTERFACE_MESH_CONNECTIVITY,ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Interface meshes connectivity is not associated.",ERR,ERROR,*999)
    ENDIF
       
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_DESTROY")
    RETURN
999 CALL ERRORS("INTERFACE_MESH_CONNECTIVITY_DESTROY",ERR,ERROR)
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_DESTROY")
    RETURN 1
  END SUBROUTINE INTERFACE_MESH_CONNECTIVITY_DESTROY

  !
  !================================================================================================================================
  !
  
  !>Finalises the meshes connectivity and deallocates all memory
  SUBROUTINE INTERFACE_MESH_CONNECTIVITY_ELEMENT_XI_SET(MESH_CON,INT_ELEM,COUPLED_MESHID,COUPLED_ELEM,LOCAL_NODE, &
    & COMP_NO,XI,ERR,ERROR,*)

    !Argument variables
    TYPE(INTERFACE_MESH_CONNECTIVITY_TYPE), POINTER :: MESH_CON !<A pointer to interface mesh connectivity to set the element number of elements for.
    INTEGER(INTG), INTENT(IN) :: INT_ELEM !<
    INTEGER(INTG), INTENT(IN) :: COUPLED_MESHID !<The index of the coupled mesh in the interface to set the number of elements for.
    INTEGER(INTG), INTENT(IN) :: COUPLED_ELEM !<
    INTEGER(INTG), INTENT(IN) :: LOCAL_NODE !<
    INTEGER(INTG), INTENT(IN) :: COMP_NO !<
    REAL(DP), INTENT(IN) :: XI(:) !<XI(xi_idx). The xi value for the xi_idx'th xi direction in the coupled mesh element.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: I, K !< Dummy index
    INTEGER(INTG) :: XI_DIR !<Number of XI directions of the coupled mesh
    
    CALL ENTERS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_XI_SET",ERR,ERROR,*999)

    ! Preliminary error checks to verify user input information
    IF(.NOT.ASSOCIATED(MESH_CON)) CALL FLAG_ERROR("Interface mesh connectivity is not associated.",ERR,ERROR,*999)
    IF(MESH_CON%MESH_CONNECTIVITY_FINISHED) CALL FLAG_ERROR("Interface mesh connectivity already been finished.",ERR,ERROR,*999)
    IF (.NOT.ALLOCATED(MESH_CON%ELEMENTS_CONNECTIVITY)) CALL FLAG_ERROR("Interface elements connectivity array not allocated.", &
      & ERR,ERROR,*999)
    IF((INT_ELEM > MESH_CON%NUMBER_INT_ELEM).OR.(INT_ELEM < 0)) CALL FLAG_ERROR("Interface mesh element number out of range.", &
      & ERR,ERROR,*999)
    IF((COUPLED_MESHID > MESH_CON%NUMBER_INT_DOM).OR.(COUPLED_MESHID < 0)) CALL FLAG_ERROR("Interface coupled mesh index number &
      & out of range.",ERR,ERROR,*999)
    IF((COUPLED_ELEM>MESH_CON%INTERFACE%COUPLED_MESHES(COUPLED_MESHID)%PTR%NUMBER_OF_ELEMENTS).OR.(COUPLED_ELEM<0))THEN
      CALL FLAG_ERROR("Coupled mesh element number out of range.",ERR,ERROR,*999)
    END IF
    IF((COMP_NO<0).OR.(COMP_NO>MESH_CON%INTERFACE_MESH%NUMBER_OF_COMPONENTS+1)) CALL FLAG_ERROR("Interface component number is &
      & out of range.",ERR,ERROR,*999)
    IF((LOCAL_NODE<0).OR.(LOCAL_NODE>SIZE(MESH_CON%ELEMENTS_CONNECTIVITY(INT_ELEM,COUPLED_MESHID)%XI,3)))THEN
      CALL FLAG_ERROR("Interface local node number is out of range.",ERR,ERROR,*999)   
    END IF

    ! Core routine 
    K=0
    DO I=1,MESH_CON%ELEMENTS_CONNECTIVITY(INT_ELEM,COUPLED_MESHID)%NUMBER_OF_COUPLED_MESH_ELEMENTS
      IF(MESH_CON%ELEMENTS_CONNECTIVITY(INT_ELEM,COUPLED_MESHID)%COUPLED_MESH_ELEMENT_NUMBERS(I)==COUPLED_ELEM)THEN
        K = I; EXIT
      ELSEIF(MESH_CON%ELEMENTS_CONNECTIVITY(INT_ELEM,COUPLED_MESHID)%COUPLED_MESH_ELEMENT_NUMBERS(I)==0)THEN
        MESH_CON%ELEMENTS_CONNECTIVITY(INT_ELEM,COUPLED_MESHID)%COUPLED_MESH_ELEMENT_NUMBERS(I)=COUPLED_ELEM
        K=I; EXIT
      ENDIF
    ENDDO
    IF (K==0) THEN
      CALL FLAG_ERROR("Coupled mesh element exceeds number of elements coupled to the interface.",ERR,ERROR,*999)
    ELSE
      MESH_CON%ELEMENTS_CONNECTIVITY(INT_ELEM,COUPLED_MESHID)%XI(:,COMP_NO,LOCAL_NODE,K)=XI(:)
    END IF
    
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_XI_SET")
    RETURN
999 CALL ERRORS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_XI_SET",ERR,ERROR)
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_XI_SET")
    RETURN 1
    
  END SUBROUTINE INTERFACE_MESH_CONNECTIVITY_ELEMENT_XI_SET

  !
  !================================================================================================================================
  !
  
  !>Finalises the meshes connectivity and deallocates all memory
  SUBROUTINE INTERFACE_MESH_CONNECTIVITY_ELEMENT_NUMBER_ELEMENTS_SET(MESH_CON,INT_MESH_ELEM, &
    & COUPLED_MESHID,NO_ELEM,ERR,ERROR,*)

    !Argument variables
    TYPE(INTERFACE_MESH_CONNECTIVITY_TYPE), POINTER :: MESH_CON !<A pointer to interface mesh connectivity to set the element number of elements for.
    TYPE(MESH_TYPE), POINTER :: INTERFACE_MESH !<A pointer to the interface mesh to set the number of elements for
    INTEGER(INTG), INTENT(IN) :: INT_MESH_ELEM !<Interface mesh element number
    INTEGER(INTG), INTENT(IN) :: COUPLED_MESHID !<The index of the coupled mesh in the interface to set the number of elements for.
    INTEGER(INTG), INTENT(IN) :: NO_ELEM !<The number of elements to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: I !< Dummy index
    INTEGER(INTG) :: XI_DIR !<Number of XI directions of the coupled mesh
    INTEGER(INTG) :: LOCAL_NODE !<Number of local nodes in the interface
    
    CALL ENTERS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_NUMBER_ELEMENTS_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(MESH_CON)) THEN
      IF(MESH_CON%MESH_CONNECTIVITY_FINISHED) THEN
        CALL FLAG_ERROR("Interface mesh connectivity has already been finished.",ERR,ERROR,*999)
      ELSE
        IF ((INT_MESH_ELEM > MESH_CON%NUMBER_INT_ELEM).OR.(INT_MESH_ELEM < 0)) THEN
          CALL FLAG_ERROR("Interface mesh element number out of range.",ERR,ERROR,*999)
        ELSE
          IF ((COUPLED_MESHID > MESH_CON%NUMBER_INT_DOM).OR.(COUPLED_MESHID < 0)) THEN
             CALL FLAG_ERROR("Interface coupled mesh index number out of range.",ERR,ERROR,*999)
          ELSE
             IF (ALLOCATED(MESH_CON%ELEMENTS_CONNECTIVITY)) THEN
               IF (MESH_CON%ELEMENTS_CONNECTIVITY(INT_MESH_ELEM,COUPLED_MESHID)%NUMBER_OF_COUPLED_MESH_ELEMENTS==0) THEN
                 MESH_CON%ELEMENTS_CONNECTIVITY(INT_MESH_ELEM,COUPLED_MESHID)%NUMBER_OF_COUPLED_MESH_ELEMENTS=NO_ELEM
                 ALLOCATE(MESH_CON%ELEMENTS_CONNECTIVITY(INT_MESH_ELEM,COUPLED_MESHID)%COUPLED_MESH_ELEMENT_NUMBERS(NO_ELEM))
                 MESH_CON%ELEMENTS_CONNECTIVITY(INT_MESH_ELEM,COUPLED_MESHID)%COUPLED_MESH_ELEMENT_NUMBERS=0
                 XI_DIR=MESH_CON%INTERFACE_MESH%NUMBER_OF_DIMENSIONS+1
                 LOCAL_NODE=0
                 DO I = 1,MESH_CON%INTERFACE_MESH%NUMBER_OF_COMPONENTS
                    LOCAL_NODE=MAX(LOCAL_NODE,MESH_CON%INTERFACE_MESH%TOPOLOGY(I)%PTR%ELEMENTS% &
                      & ELEMENTS(INT_MESH_ELEM)%BASIS%NUMBER_OF_NODES)
                 END DO ! ENDING I -- COUNTER THROUGH THE MESH COMPONENTS
                 ALLOCATE(MESH_CON%ELEMENTS_CONNECTIVITY(INT_MESH_ELEM,COUPLED_MESHID)%XI(XI_DIR,XI_DIR,LOCAL_NODE,NO_ELEM))
                 MESH_CON%ELEMENTS_CONNECTIVITY(INT_MESH_ELEM,COUPLED_MESHID)%XI=0.0_DP
               ELSE
                 CALL FLAG_ERROR("Number of coupled elements already set.",ERR,ERROR,*999)
               END IF
             ELSE
               CALL FLAG_ERROR("Interface elements connectivity array not allocated.",ERR,ERROR,*999)
             END IF
          END IF
        END IF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Interface mesh connectivity is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_NUMBER_ELEMENTS_SET")
    RETURN
999 CALL ERRORS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_NUMBER_ELEMENTS_SET",ERR,ERROR)
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_NUMBER_ELEMENTS_SET")
    RETURN 1
    
  END SUBROUTINE INTERFACE_MESH_CONNECTIVITY_ELEMENT_NUMBER_ELEMENTS_SET

  !
  !================================================================================================================================
  !

  !>Finalises the meshes connectivity and deallocates all memory
  SUBROUTINE INTERFACE_MESH_CONNECTIVITY_FINALISE(INTERFACE_MESH_CONNECTIVITY,ERR,ERROR,*)

    !Argument variables
    TYPE(INTERFACE_MESH_CONNECTIVITY_TYPE) :: INTERFACE_MESH_CONNECTIVITY !<The interface mesh connectivity to finalise.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: coupled_mesh_idx,element_idx
     
    CALL ENTERS("INTERFACE_MESH_CONNECTIVITY_FINALISE",ERR,ERROR,*999)

    CALL INTERFACE_MESH_CONNECTIVITY_ELEMENT_FINALISE(INTERFACE_MESH_CONNECTIVITY,ERR,ERROR,*999)
    NULLIFY(INTERFACE_MESH_CONNECTIVITY%INTERFACE)
    NULLIFY(INTERFACE_MESH_CONNECTIVITY%INTERFACE_MESH)
    INTERFACE_MESH_CONNECTIVITY%NUMBER_INT_ELEM=0
    INTERFACE_MESH_CONNECTIVITY%NUMBER_INT_DOM=0
       
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_FINALISE")
    RETURN
999 CALL ERRORS("INTERFACE_MESH_CONNECTIVITY_FINALISE",ERR,ERROR)
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_FINALISE")
    RETURN 1
    
  END SUBROUTINE INTERFACE_MESH_CONNECTIVITY_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the interface mesh connectivity.
  SUBROUTINE INTERFACE_MESH_CONNECTIVITY_INITIALISE(INTERFACE,MESH,ERR,ERROR,*)

    !Argument variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<A pointer to the interface to initialise the mesh connectivity for
    TYPE(MESH_TYPE), POINTER :: MESH
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: I, K, DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
     
    CALL ENTERS("INTERFACE_MESH_CONNECTIVITY_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(INTERFACE)) THEN
      IF(ASSOCIATED(INTERFACE%MESH_CONNECTIVITY)) THEN
        CALL FLAG_ERROR("Interface mesh connectivity is already associated.",ERR,ERROR,*999)
      ELSE
        ALLOCATE(INTERFACE%MESH_CONNECTIVITY,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate interface mesh connectivity.",ERR,ERROR,*999)
        INTERFACE%MESH_CONNECTIVITY%INTERFACE=>INTERFACE
        INTERFACE%MESH_CONNECTIVITY%MESH_CONNECTIVITY_FINISHED=.FALSE.
        INTERFACE%MESH_CONNECTIVITY%INTERFACE_MESH=>MESH
        CALL INTERFACE_MESH_CONNECTIVITY_ELEMENT_INITIALISE(INTERFACE,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Interface is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_INITIALISE")
    RETURN
999 CALL ERRORS("INTERFACE_MESH_CONNECTIVITY_INITIALISE",ERR,ERROR)
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_INITIALISE")
    RETURN 1
  END SUBROUTINE INTERFACE_MESH_CONNECTIVITY_INITIALISE

  !
  !================================================================================================================================
  !

  !>Adds a mesh connectivity coupling point to the mesh connectivity.
  SUBROUTINE INTERFACE_COUPLED_MESH_CONNECTIVITY_POINT_ADD(INTERFACE_MESH_CONNECTIVITY,MESH1_INDEX,USER_ELEMENT1,XI1, &
    & MESH2_INDEX,USER_ELEMENT2,XI2,ERR,ERROR,*) 

    !Argument variables
    TYPE(INTERFACE_MESH_CONNECTIVITY_TYPE), POINTER :: INTERFACE_MESH_CONNECTIVITY !<A pointer to the coupled meshes connectivity to add the point to
    INTEGER(INTG), INTENT(IN) :: MESH1_INDEX !<The first mesh index of the coupled point
    INTEGER(INTG), INTENT(IN) :: USER_ELEMENT1 !<The first element number of the coupled point
    REAL(DP), INTENT(IN) :: XI1(:) !<Xi(ni). The first xi location of the coupled point
    INTEGER(INTG), INTENT(IN) :: MESH2_INDEX !<The second mesh index of the coupled point
    INTEGER(INTG), INTENT(IN) :: USER_ELEMENT2 !<The second element number of the coupled point
    REAL(DP), INTENT(IN) :: XI2(:) !<Xi(ni). The second xi location of the coupled point
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: GLOBAL_ELEMENT1,GLOBAL_ELEMENT2,point_idx,xi_idx
!     LOGICAL :: ELEMENT_EXISTS
!     TYPE(BASIS_TYPE), POINTER :: BASIS1,BASIS2
!     TYPE(INTERFACE_MESH_CONNECTIVITY_POINT_PTR_TYPE), POINTER :: NEW_CONNECTIVITY_POINTS(:)
!     TYPE(INTERFACE_TYPE), POINTER :: INTERFACE
!     TYPE(MESH_TYPE), POINTER :: MESH1,MESH2
!     TYPE(MESH_ELEMENTS_TYPE), POINTER :: MESH1_ELEMENTS,MESH2_ELEMENTS
!     TYPE(VARYING_STRING) :: LOCAL_ERROR

!    NULLIFY(NEW_CONNECTIVITY_POINTS)
    
    CALL ENTERS("INTERFACE_COUPLED_MESH_CONNECTIVITY_POINT_ADD",ERR,ERROR,*999)

    !IF(ASSOCIATED(COUPLED_MESH_CONNECTIVITY)) THEN
    !  IF(COUPLED_MESH_CONNECTIVITY%MESH_CONNECTIVITY_FINISHED) THEN
    !    CALL FLAG_ERROR("Coupled mesh connectivity has already been finished.",ERR,ERROR,*999)
    !  ELSE
    !    INTERFACE=>COUPLED_MESH_CONNECTIVITY%INTERFACE
    !    IF(ASSOCIATED(INTERFACE)) THEN
    !      !Check the mesh indexes are valid.
    !      IF(MESH1_INDEX>0.AND.MESH1_INDEX<=INTERFACE%NUMBER_OF_COUPLED_MESHES) THEN
    !        MESH1=>INTERFACE%COUPLED_MESHES(MESH1_INDEX)%PTR
    !        IF(ASSOCIATED(MESH1)) THEN
    !          IF(MESH2_INDEX>0.AND.MESH2_INDEX<=INTERFACE%NUMBER_OF_COUPLED_MESHES) THEN
    !            MESH2=>INTERFACE%COUPLED_MESHES(MESH2_INDEX)%PTR
    !            IF(ASSOCIATED(MESH2)) THEN
    !              !Just use the first component until the mesh topology is sorted out.
    !              CALL MESH_TOPOLOGY_ELEMENT_CHECK_EXISTS(MESH1,1,USER_ELEMENT1,ELEMENT_EXISTS,GLOBAL_ELEMENT1,ERR,ERROR,*999)
    !              IF(ELEMENT_EXISTS) THEN
    !                !Just use the first component until the mesh topology is sorted out.
    !                CALL MESH_TOPOLOGY_ELEMENT_CHECK_EXISTS(MESH1,1,USER_ELEMENT2,ELEMENT_EXISTS,GLOBAL_ELEMENT2,ERR,ERROR,*999)
    !                IF(ELEMENT_EXISTS) THEN
    !                  IF(ASSOCIATED(MESH1%TOPOLOGY)) THEN
    !                    !Just use the first component as we are only wanting to find the number of xi directions
    !                    IF(ASSOCIATED(MESH1%TOPOLOGY(1)%PTR)) THEN
    !                      IF(ASSOCIATED(MESH2%TOPOLOGY)) THEN
    !                        !Just use the first component as we are only wanting to find the number of xi directions
    !                        IF(ASSOCIATED(MESH2%TOPOLOGY(1)%PTR)) THEN
    !                          MESH1_ELEMENTS=>MESH1%TOPOLOGY(1)%PTR%ELEMENTS
    !                          IF(ASSOCIATED(MESH1_ELEMENTS)) THEN
    !                            MESH2_ELEMENTS=>MESH2%TOPOLOGY(1)%PTR%ELEMENTS
    !                            IF(ASSOCIATED(MESH2_ELEMENTS)) THEN
    !                              BASIS1=>MESH1_ELEMENTS%ELEMENTS(GLOBAL_ELEMENT1)%BASIS
    !                              IF(ASSOCIATED(BASIS1)) THEN
    !                                BASIS2=>MESH2_ELEMENTS%ELEMENTS(GLOBAL_ELEMENT2)%BASIS
    !                                IF(ASSOCIATED(BASIS2)) THEN
    !                                  IF(SIZE(XI1,1)>=BASIS1%NUMBER_OF_XI) THEN
    !                                    IF(SIZE(XI2,1)>=BASIS2%NUMBER_OF_XI) THEN
    !                                      DO xi_idx=1,BASIS1%NUMBER_OF_XI
    !                                        IF(XI1(xi_idx)<0.0_DP.OR.XI1(xi_idx)>1.0_DP) THEN
    !                                          LOCAL_ERROR="The Xi coordinate of "// &
    !                                            & TRIM(NUMBER_TO_VSTRING(XI1(xi_idx),"*",ERR,ERROR))//" for xi direction "// &
    !                                            & TRIM(NUMBER_TO_VSTRING(xi_idx,"*",ERR,ERROR))// &
    !                                            & " of Xi1 is invalid. The coordinate must be >= 0.0 and <= 1.0."
    !                                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
    !                                        ENDIF
    !                                      ENDDO !xi_idx
    !                                      DO xi_idx=1,BASIS2%NUMBER_OF_XI
    !                                        IF(XI2(xi_idx)<0.0_DP.OR.XI2(xi_idx)>1.0_DP) THEN
    !                                          LOCAL_ERROR="The Xi coordinate of "// &
    !                                            & TRIM(NUMBER_TO_VSTRING(XI2(xi_idx),"*",ERR,ERROR))//" for xi direction "// &
    !                                            & TRIM(NUMBER_TO_VSTRING(xi_idx,"*",ERR,ERROR))// &
    !                                            & " of Xi2 is invalid. The coordinate must be >= 0.0 and <= 1.0."
    !                                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
    !                                        ENDIF
    !                                      ENDDO !xi_idx
    !                                      !Inputs all valid. Now create the point.
    !                                      ALLOCATE(NEW_CONNECTIVITY_POINTS(COUPLED_MESH_CONNECTIVITY% &
    !                                        & NUMBER_OF_CONNECTIVITY_POINTS+1),STAT=ERR)
    !                                      IF(ERR/=0) CALL FLAG_ERROR("Could not allocate new connectivity points.",ERR,ERROR,*999)
    !                                      IF(COUPLED_MESH_CONNECTIVITY%NUMBER_OF_CONNECTIVITY_POINTS>0) THEN
    !                                        DO point_idx=1,COUPLED_MESH_CONNECTIVITY%NUMBER_OF_CONNECTIVITY_POINTS
    !                                          NEW_CONNECTIVITY_POINTS(point_idx)%PTR=>COUPLED_MESH_CONNECTIVITY% &
    !                                            & CONNECTIVITY_POINTS(point_idx)%PTR
    !                                        ENDDO !point_idx
    !                                        DEALLOCATE(COUPLED_MESH_CONNECTIVITY%CONNECTIVITY_POINTS)
    !                                      ENDIF
    !                                      COUPLED_MESH_CONNECTIVITY%CONNECTIVITY_POINTS=>NEW_CONNECTIVITY_POINTS
    !                                      CALL INTERFACE_CONNECTIVITY_COUPLED_POINT_INITIALISE( &
    !                                        & COUPLED_MESH_CONNECTIVITY%CONNECTIVITY_POINTS(COUPLED_MESH_CONNECTIVITY% &
    !                                        & NUMBER_OF_CONNECTIVITY_POINTS+1)%PTR,ERR,ERROR,*999)
    !                                      COUPLED_MESH_CONNECTIVITY%CONNECTIVITY_POINTS(COUPLED_MESH_CONNECTIVITY% &
    !                                        & NUMBER_OF_CONNECTIVITY_POINTS+1)%PTR%MESH1_INDEX=MESH1_INDEX
    !                                    ELSE
    !                                      LOCAL_ERROR="The supplied size of xi 2 of "// &
    !                                        & TRIM(NUMBER_TO_VSTRING(SIZE(XI2,1),"*",ERR,ERROR))// &
    !                                        & " is invalid. The size of xi 2 must be >= "// &
    !                                        & TRIM(NUMBER_TO_VSTRING(BASIS2%NUMBER_OF_XI,"*",ERR,ERROR))//"."
    !                                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
    !                                    ENDIF
    !                                  ELSE
    !                                    LOCAL_ERROR="The supplied size of xi 1 of "// &
    !                                      & TRIM(NUMBER_TO_VSTRING(SIZE(XI1,1),"*",ERR,ERROR))// &
    !                                      & " is invalid. The size of xi 1 must be >= "// &
    !                                      & TRIM(NUMBER_TO_VSTRING(BASIS1%NUMBER_OF_XI,"*",ERR,ERROR))//"."
    !                                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
    !                                  ENDIF
    !                                ELSE
    !                                  CALL FLAG_ERROR("Basis is not associated for element 2.",ERR,ERROR,*999)
    !                                ENDIF
    !                              ELSE
    !                                CALL FLAG_ERROR("Basis is not associated for element 1.",ERR,ERROR,*999)
    !                              ENDIF
    !                            ELSE
    !                              CALL FLAG_ERROR("Mesh 1 elements topology is not associated.",ERR,ERROR,*999)
    !                            ENDIF
    !                          ELSE
    !                            CALL FLAG_ERROR("Mesh 1 elements topology is not associated.",ERR,ERROR,*999)
    !                          ENDIF
    !                        ELSE
    !                          CALL FLAG_ERROR("Mesh 2 topology is not associated for component 1.",ERR,ERROR,*999)
    !                        ENDIF
    !                      ELSE
    !                        CALL FLAG_ERROR("Mesh 2 topology is not associated.",ERR,ERROR,*999)
    !                      ENDIF
    !                    ELSE
    !                      CALL FLAG_ERROR("Mesh 1 topology is not associated for component 1.",ERR,ERROR,*999)
    !                    ENDIF
    !                  ELSE
    !                    CALL FLAG_ERROR("Mesh 1 topology is not associated.",ERR,ERROR,*999)
    !                  ENDIF
    !                ELSE
    !                  LOCAL_ERROR="The user element number of "//TRIM(NUMBER_TO_VSTRING(USER_ELEMENT2,"*",ERR,ERROR))// &
    !                    & " does not exist on mesh index 2."
    !                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
    !                ENDIF
    !              ELSE
    !                LOCAL_ERROR="The user element number of "//TRIM(NUMBER_TO_VSTRING(USER_ELEMENT1,"*",ERR,ERROR))// &
    !                  & " does not exist on mesh index 1."
    !                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
    !              ENDIF                  
    !            ELSE
    !              LOCAL_ERROR="The mesh associated with mesh index "//TRIM(NUMBER_TO_VSTRING(MESH2_INDEX,"*",ERR,ERROR))// &
    !                & " is invalid."
    !              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
    !            ENDIF
    !          ELSE
    !            LOCAL_ERROR="The specified value for mesh index 2 of "//TRIM(NUMBER_TO_VSTRING(MESH2_INDEX,"*",ERR,ERROR))// &
    !              & " is invalid. The index must be between 1 and "// &
    !              & TRIM(NUMBER_TO_VSTRING(INTERFACE%NUMBER_OF_COUPLED_MESHES,"*",ERR,ERROR))//"."
    !            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
    !          ENDIF
    !        ELSE
    !          LOCAL_ERROR="The mesh associated with mesh index "//TRIM(NUMBER_TO_VSTRING(MESH1_INDEX,"*",ERR,ERROR))// &
    !            & " is invalid."
    !          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
    !        ENDIF
    !      ELSE
    !        LOCAL_ERROR="The specified value for mesh index 1 of "//TRIM(NUMBER_TO_VSTRING(MESH1_INDEX,"*",ERR,ERROR))// &
    !          & " is invalid. The index must be between 1 and "// &
    !          & TRIM(NUMBER_TO_VSTRING(INTERFACE%NUMBER_OF_COUPLED_MESHES,"*",ERR,ERROR))//"."
    !        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
    !      ENDIF
    !    ELSE
    !      CALL FLAG_ERROR("Coupled meshes connectivity interface is not associated.",ERR,ERROR,*999)
    !    ENDIF
    !  ENDIF
    !ELSE
    !  CALL FLAG_ERROR("Coupled meshes connectivity is not associated.",ERR,ERROR,*999)
    !ENDIF
    
    CALL EXITS("INTERFACE_COUPLED_MESH_CONNECTIVITY_POINT_ADD")
    RETURN
999 CALL ERRORS("INTERFACE_COUPLED_MESH_CONNECTIVITY_POINT_ADD",ERR,ERROR)
    CALL EXITS("INTERFACE_COUPLED_MESH_CONNECTIVITY_POINT_ADD")
    RETURN 1
  END SUBROUTINE INTERFACE_COUPLED_MESH_CONNECTIVITY_POINT_ADD

  !
  !================================================================================================================================
  !

!   !>Finalises a mesh connectivity point and deallocates all memory
!   SUBROUTINE INTERFACE_CONNECTIVITY_POINT_FINALISE(CONNECTIVITY_POINT,ERR,ERROR,*) 
! 
!     !Argument variables
! !    TYPE(INTERFACE_MESH_CONNECTIVITY_POINT_TYPE), POINTER :: CONNECTIVITY_POINT !<A pointer to the meshes connectivity point to finalise
!     INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
!     TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
!     !Local Variables
!      
!     CALL ENTERS("INTERFACE_CONNECTIVITY_POINT_FINALISE",ERR,ERROR,*999)
! 
!     IF(ASSOCIATED(CONNECTIVITY_POINT)) THEN
! !       IF(ALLOCATED(CONNECTIVITY_POINT%XI1)) DEALLOCATE(CONNECTIVITY_POINT%XI1)
! !       IF(ALLOCATED(CONNECTIVITY_POINT%XI2)) DEALLOCATE(CONNECTIVITY_POINT%XI2)
! !       DEALLOCATE(CONNECTIVITY_POINT)
!     ENDIF
!     
!     CALL EXITS("INTERFACE_CONNECTIVITY_POINT_FINALISE")
!     RETURN
! 999 CALL ERRORS("INTERFACE_CONNECTIVITY_POINT_FINALISE",ERR,ERROR)
!     CALL EXITS("INTERFACE_CONNECTIVITY_POINT_FINALISE")
!     RETURN 1
!   END SUBROUTINE INTERFACE_CONNECTIVITY_POINT_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises the meshes connectivity point.
!  SUBROUTINE INTERFACE_CONNECTIVITY_POINT_INITIALISE(CONNECTIVITY_POINT,ERR,ERROR,*) 

!     !Argument variables
!     TYPE(INTERFACE_MESH_CONNECTIVITY_POINT_TYPE), POINTER :: CONNECTIVITY_POINT !<A pointer to the meshes connectivity point to initialise
!     INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
!     TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
!     !Local Variables
!     INTEGER(INTG) :: DUMMY_ERR
!     TYPE(VARYING_STRING) :: DUMMY_ERROR
!      
!     CALL ENTERS("INTERFACE_CONNECTIVITY_POINT_INITIALISE",ERR,ERROR,*998)
! 
!     IF(ASSOCIATED(CONNECTIVITY_POINT)) THEN
!       CALL FLAG_ERROR("Connectivity point is already associated.",ERR,ERROR,*998)
!     ELSE
!       ALLOCATE(CONNECTIVITY_POINT,STAT=ERR)
!       IF(ERR/=0) CALL FLAG_ERROR("Could not allocate connectivity point.",ERR,ERROR,*999)
!       CONNECTIVITY_POINT%MESH1_INDEX=0
!       CONNECTIVITY_POINT%MESH1_ELEMENT=0
!       CONNECTIVITY_POINT%MESH2_INDEX=0
!       CONNECTIVITY_POINT%MESH2_ELEMENT=0
!     ENDIF
    
!     CALL EXITS("INTERFACE_CONNECTIVITY_POINT_INITIALISE")
!     RETURN
! 999 CALL INTERFACE_CONNECTIVITY_POINT_FINALISE(CONNECTIVITY_POINT,DUMMY_ERR,DUMMY_ERROR,*998)
! 998 CALL ERRORS("INTERFACE_CONNECTIVITY_POINT_INITIALISE",ERR,ERROR)
!     CALL EXITS("INTERFACE_CONNECTIVITY_POINT_INITIALISE")
!     RETURN 1
!     
!   END SUBROUTINE INTERFACE_CONNECTIVITY_POINT_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finds and returns in INTERFACE a pointer to the interface identified by USER_NUMBER in the given PARENT_REGION. If no interface with that USER_NUMBER exists INTERFACE is left nullified.
  SUBROUTINE INTERFACE_USER_NUMBER_FIND(USER_NUMBER,PARENT_REGION,INTERFACE,ERR,ERROR,*)

    !Argument variables
    INTEGER(INTG), INTENT(IN) :: USER_NUMBER !<The user number to find.
    TYPE(REGION_TYPE), POINTER :: PARENT_REGION !<The parent region to find the interface in    
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<On return a pointer to the interface with the given user number. If no interface with that user number exists then the pointer is returned as NULL. Must not be associated on entry.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: interface_idx
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("INTERFACE_USER_NUMBER_FIND",ERR,ERROR,*999)

    IF(ASSOCIATED(PARENT_REGION)) THEN
      IF(ASSOCIATED(INTERFACE)) THEN
        CALL FLAG_ERROR("Interface is already associated.",ERR,ERROR,*999)
      ELSE
        NULLIFY(INTERFACE)
        IF(ASSOCIATED(PARENT_REGION%INTERFACES)) THEN
          interface_idx=1
          DO WHILE(interface_idx<=PARENT_REGION%INTERFACES%NUMBER_OF_INTERFACES.AND..NOT.ASSOCIATED(INTERFACE))
            IF(PARENT_REGION%INTERFACES%INTERFACES(interface_idx)%PTR%USER_NUMBER==USER_NUMBER) THEN
              INTERFACE=>PARENT_REGION%INTERFACES%INTERFACES(interface_idx)%PTR
            ELSE
              interface_idx=interface_idx+1
            ENDIF
          ENDDO
        ELSE
          LOCAL_ERROR="The interfaces on parent region number "// &
            & TRIM(NUMBER_TO_VSTRING(PARENT_REGION%USER_NUMBER,"*",ERR,ERROR))//" are not associated."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Parent region is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("INTERFACE_USER_NUMBER_FIND")
    RETURN
999 CALL ERRORS("INTERFACE_USER_NUMBER_FIND",ERR,ERROR)
    CALL EXITS("INTERFACE_USER_NUMBER_FIND")
    RETURN 1
  END SUBROUTINE INTERFACE_USER_NUMBER_FIND

  !
  !================================================================================================================================
  !

  !>Finalises interfaces and deallocates all memory.
  SUBROUTINE INTERFACES_FINALISE(INTERFACES,ERR,ERROR,*) 

    !Argument variables
    TYPE(INTERFACES_TYPE), POINTER :: INTERFACES !<A pointer to the interfaces to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE
     
    CALL ENTERS("INTERFACES_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(INTERFACES)) THEN
      DO WHILE(INTERFACES%NUMBER_OF_INTERFACES>0)
        INTERFACE=>INTERFACES%INTERFACES(1)%PTR
        CALL INTERFACE_DESTROY(INTERFACE,ERR,ERROR,*999)
      ENDDO
      IF(ASSOCIATED(INTERFACES%INTERFACES)) DEALLOCATE(INTERFACES%INTERFACES)
      DEALLOCATE(INTERFACES)
    ENDIF
    
    CALL EXITS("INTERFACES_FINALISE")
    RETURN
999 CALL ERRORS("INTERFACES_FINALISE",ERR,ERROR)
    CALL EXITS("INTERFACES_FINALISE")
    RETURN 1
  END SUBROUTINE INTERFACES_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialises interfaces for a region.
  SUBROUTINE INTERFACES_INITIALISE(REGION,ERR,ERROR,*) 

    !Argument variables
    TYPE(REGION_TYPE), POINTER :: REGION !<A pointer to the region to initialise the interfaces for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR
     
    CALL ENTERS("INTERFACES_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(REGION)) THEN
      IF(ASSOCIATED(REGION%INTERFACES)) THEN
        LOCAL_ERROR="Region number "//TRIM(NUMBER_TO_VSTRING(REGION%USER_NUMBER,"*",ERR,ERROR))// &
          & " already has interfaces associated."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      ELSE
        ALLOCATE(REGION%INTERFACES,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate region interfaces.",ERR,ERROR,*999)
        REGION%INTERFACES%PARENT_REGION=>REGION
        REGION%INTERFACES%NUMBER_OF_INTERFACES=0
      ENDIF
    ELSE
      CALL FLAG_ERROR("Region is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("INTERFACES_INITIALISE")
    RETURN
999 CALL INTERFACES_FINALISE(REGION%INTERFACES,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("INTERFACES_INITIALISE",ERR,ERROR)
    CALL EXITS("INTERFACES_INITIALISE")
    RETURN 1
  END SUBROUTINE INTERFACES_INITIALISE

  !
  !================================================================================================================================
  !

  SUBROUTINE INTERFACE_REGION_LMHOST_SET(INTERFACE,REGION_ID,ERR,ERROR,*)   

    !Argument variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<A pointer to the region to finish the creation of
    INTEGER(INTG), INTENT(IN) :: REGION_ID !<The integer user code for the host region
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("INTERFACE_REGION_LMHOST_SET",ERR,ERROR,*999)

    CALL EXITS("INTERFACE_REGION_LMHOST_SET")
    RETURN
999 CALL ERRORS("INTERFACE_REGION_LMHOST_SET",ERR,ERROR)
    CALL EXITS("INTERFACE_REGION_LMHOST_SET")
    RETURN 1
  END SUBROUTINE INTERFACE_REGION_LMHOST_SET

  !
  !================================================================================================================================
  !


  SUBROUTINE INTERFACE_TYPE_SET(INTERFACE,INTERFACETYPE,COUPLING_TYPE,ERR,ERROR,*) 

    !Argument variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE  !<A pointer to the interface to set the type for
    INTEGER(INTG), INTENT(IN) :: INTERFACETYPE  
    INTEGER(INTG), INTENT(IN) :: COUPLING_TYPE 
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("INTERFACE_TYPE_SET",ERR,ERROR,*999)
    
    CALL EXITS("INTERFACE_TYPE_SET")
    RETURN
999 CALL ERRORS("INTERFACE_TYPE_SET",ERR,ERROR)
    CALL EXITS("INTERFACE_TYPE_SET")
    RETURN 1
  END SUBROUTINE INTERFACE_TYPE_SET  

  !
  !================================================================================================================================
  !

  !>Initialises the interface mesh connectivity.
  SUBROUTINE INTERFACE_MESH_CONNECTIVITY_ELEMENT_INITIALISE(INTERFACE,ERR,ERROR,*)

    !Argument variables
    TYPE(INTERFACE_TYPE), POINTER :: INTERFACE !<A pointer to the interface to initialise the mesh connectivity for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: I, J, K, DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
     
    CALL ENTERS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(INTERFACE)) THEN
      IF(ASSOCIATED(INTERFACE%MESH_CONNECTIVITY)) THEN
        IF(ALLOCATED(INTERFACE%MESH_CONNECTIVITY%ELEMENTS_CONNECTIVITY)) THEN
          CALL FLAG_ERROR("Interface mesh element connectivity is already allocated.",ERR,ERROR,*999)
        ELSE
          IF(INTERFACE%NUMBER_OF_COUPLED_MESHES<=0) CALL FLAG_ERROR("Interface coupled meshes are not associated.",ERR,ERROR,*999)
          IF(INTERFACE%MESH_CONNECTIVITY%INTERFACE_MESH%NUMBER_OF_ELEMENTS<=0) CALL FLAG_ERROR("Interface coupled meshes are not & 
            & associated.",ERR,ERROR,*999)
          INTERFACE%MESH_CONNECTIVITY%NUMBER_INT_ELEM=INTERFACE%MESHES%MESHES(1)%PTR%NUMBER_OF_ELEMENTS
          INTERFACE%MESH_CONNECTIVITY%NUMBER_INT_DOM=INTERFACE%NUMBER_OF_COUPLED_MESHES
          ALLOCATE(INTERFACE%MESH_CONNECTIVITY%ELEMENTS_CONNECTIVITY(INTERFACE%MESH_CONNECTIVITY%NUMBER_INT_ELEM, &
            & INTERFACE%MESH_CONNECTIVITY%NUMBER_INT_DOM))
          DO I = 1, INTERFACE%MESH_CONNECTIVITY%NUMBER_INT_ELEM
            DO J = 1, INTERFACE%MESH_CONNECTIVITY%NUMBER_INT_DOM
              INTERFACE%MESH_CONNECTIVITY%ELEMENTS_CONNECTIVITY(I,J)%NUMBER_OF_COUPLED_MESH_ELEMENTS=0
            ENDDO! J
          ENDDO! I
        END IF
      ELSE
        CALL FLAG_ERROR("Interface mesh connectivity is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Interface is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_INITIALISE")
    RETURN
999 CALL ERRORS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_INITIALISE",ERR,ERROR)
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_INITIALISE")
    RETURN 1
  END SUBROUTINE INTERFACE_MESH_CONNECTIVITY_ELEMENT_INITIALISE


  !
  !================================================================================================================================
  !

  !>Finalises an interface element connectivity and deallocates all memory.
  SUBROUTINE INTERFACE_MESH_CONNECTIVITY_ELEMENT_FINALISE(INTERFACE_MESH_CONNECTIVITY,ERR,ERROR,*) 

    !Argument variables
    TYPE(INTERFACE_MESH_CONNECTIVITY_TYPE) :: INTERFACE_MESH_CONNECTIVITY !<The interface element connectivity to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: I, J 
     
    CALL ENTERS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_FINALISE",ERR,ERROR,*999)

    DO I = 1,INTERFACE_MESH_CONNECTIVITY%NUMBER_INT_ELEM  !<Loop over all the interface mesh elements
      DO J = 1,INTERFACE_MESH_CONNECTIVITY%NUMBER_INT_DOM  !<Loop over all coupled domains 
        IF (.NOT.ALLOCATED(INTERFACE_MESH_CONNECTIVITY%ELEMENTS_CONNECTIVITY)) CALL FLAG_ERROR("Interface mesh connectivity &
          & element connectivity is being deallocated before allocation.",ERR,ERROR,*999)
        INTERFACE_MESH_CONNECTIVITY%ELEMENTS_CONNECTIVITY(I,J)%NUMBER_OF_COUPLED_MESH_ELEMENTS=0
        IF(ALLOCATED(INTERFACE_MESH_CONNECTIVITY%ELEMENTS_CONNECTIVITY(I,J)%XI)) DEALLOCATE(INTERFACE_MESH_CONNECTIVITY% &
          & ELEMENTS_CONNECTIVITY(I,J)%XI)
        IF(ALLOCATED(INTERFACE_MESH_CONNECTIVITY%ELEMENTS_CONNECTIVITY(I,J)%COUPLED_MESH_ELEMENT_NUMBERS)) &
          & DEALLOCATE(INTERFACE_MESH_CONNECTIVITY%ELEMENTS_CONNECTIVITY(I,J)%COUPLED_MESH_ELEMENT_NUMBERS)
      ENDDO ! END J - Loop over all coupled domains
    ENDDO ! END I - Loop over all interface elements

    DEALLOCATE(INTERFACE_MESH_CONNECTIVITY%ELEMENTS_CONNECTIVITY)
    
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_FINALISE")
    RETURN
999 CALL ERRORS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_FINALISE",ERR,ERROR)
    CALL EXITS("INTERFACE_MESH_CONNECTIVITY_ELEMENT_FINALISE")
    RETURN 1
  END SUBROUTINE INTERFACE_MESH_CONNECTIVITY_ELEMENT_FINALISE

  !
  !================================================================================================================================
  !

END MODULE INTERFACE_ROUTINES