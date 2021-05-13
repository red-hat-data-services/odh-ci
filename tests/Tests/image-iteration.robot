*** Settings ***
Resource         ../Resources/ODS.robot
Resource         ../Resources/Common.robot
Library          DebugLibrary
Library          JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Variables ***
@{IMAGES}  s2i-generic-data-science-notebook  s2i-minimal-notebook


*** Test Cases ***
Open ODH Dashboard
  [Tags]  Sanity
  Login To ODH Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for ODH Dashboard to Load

Iterative Testing
  [Template]  Iterative Image Test
  [Tags]  Sanity
  FOR  ${image}  IN  @{IMAGES}
    ${image}  https://github.com/lugi0/minimal-nb-image-test  minimal-nb-image-test/minimal-nb.ipynb
  END

*** Keywords ***
Iterative Image Test
    [Arguments]  ${image}  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
    Launch JupyterHub From ODH Dashboard Dropdown
    Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Select Notebook Image  ${image}
    Spawn Notebook
    Wait for JupyterLab Splash Screen  timeout=30
    Maybe Select Kernel
    ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
    Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
    Launch a new JupyterLab Document
    Close Other JupyterLab Tabs
    Sleep  5
    Run Cell And Check Output  print("Hello World!")  Hello World!
    #Needs to change for RHODS release
    Run Cell And Check Output  !python --version  Python 3.8.3
    #Run Cell And Check Output  !python --version  Python 3.8.7
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible
    Clone Git Repository And Run  ${REPO_URL}  ${NOTEBOOK_TO_RUN}
    Clean Up Server
    Click JupyterLab Menu  File
    Capture Page Screenshot
    Click JupyterLab Menu Item  Hub Control Panel
    Switch Window  JupyterHub
    Sleep  5
    Click Element  //*[@id="stop"]
    Wait Until Page Contains  Start My Server  timeout=15
    Capture Page Screenshot
    Go To  ${ODH_DASHBOARD_URL}
    Sleep  10