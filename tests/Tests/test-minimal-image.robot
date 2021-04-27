*** Settings ***
Resource        ../Resources/ODS.robot
Resource        ../Resources/Common.robot
Library         DebugLibrary
Library         JupyterLibrary
Suite Setup      Begin Web Test
Suite Teardown   End Web Test

*** Variables ***


*** Test Cases ***
Open ODH Dashboard
  [Tags]  Sanity
  Login To ODH Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait For Condition  return document.title == "Red Hat OpenShift Data Science Dashboard"

Can Launch Jupyterhub
  [Tags]  Sanity
  Launch JupyterHub From ODH Dashboard Dropdown

Can Login to Jupyterhub
  [Tags]  Sanity
  Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  ${authorization_required} =  Is Service Account Authorization Required
  Run Keyword If  ${authorization_required}  Authorize jupyterhub service account

Can Spawn Notebook
  [Tags]  Sanity
  # We need to skip this testcase if the user has an existing pod
  ${spawner_visible} =  JupyterHub Spawner Is Visible
  Skip If  ${spawner_visible}!=True  The user has an existing notebook pod running
  Select Notebook Image  s2i-minimal-notebook
  Spawn Notebook

Can Launch Python3 Smoke Test Notebook
  [Tags]  Sanity

  # We need to send a PR to https://github.com/robots-from-jupyter/robotframework-jupyterlibrary/blob/master/src/JupyterLibrary/clients/jupyterlab/Shell.robot
  # To increase the timeout here.
  Wait for JupyterLab Splash Screen


  # Sometimes we get a modal pop-up upon server spawn asking to select a kernel for the notebooks
  ${is_kernel_selected} =  Run Keyword And Return Status  Page Should Not Contain Element  xpath=//div[@class="jp-Dialog-buttonLabel"][.="Select"]
  Run Keyword If  not ${is_kernel_selected}  Click Element  xpath=//div[@class="jp-Dialog-buttonLabel"][.="Select"]

  ${is_launcher_selected} =  Run Keyword And Return Status  JupyterLab Launcher Tab Is Selected
  Run Keyword If  not ${is_launcher_selected}  Open JupyterLab Launcher
  Launch a new JupyterLab Document

  Close Other JupyterLab Tabs

  ##################################################
  # Manual Notebook Input
  ##################################################
  # Sometimes the kernel is not ready if we run the cell too fast
  Sleep  5
  Run Cell And Check For Errors  !pip install boto3

  Add and Run JupyterLab Code Cell  import os
  Run Cell And Check Output  print("Hello World!")  Hello World!

  #Needs to change for RHODS release
  Run Cell And Check Output  !python --version  Python 3.8.3
  #Run Cell And Check Output  !python --version  Python 3.8.7

  Capture Page Screenshot
  JupyterLab Code Cell Error Output Should Not Be Visible

  ##################################################
  # Git clone repo and run existing notebook
  ##################################################
  Maybe Open JupyterLab Sidebar  File Browser
  Navigate Home In JupyterLab Sidebar
  Open With JupyterLab Menu  Git  Clone a Repository
  Input Text  //div[.="Clone a repo"]/../div[contains(@class, "jp-Dialog-body")]//input  https://github.com/lugi0/minimal-nb-image-test
  Click Element  xpath://div[.="CLONE"]

  Open With JupyterLab Menu  File  Open from Path…
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  minimal-nb-image-test/minimal-nb.ipynb
  Click Element  xpath://div[.="Open"]

  Wait Until minimal-nb.ipynb JupyterLab Tab Is Selected
  Close Other JupyterLab Tabs

  Open With JupyterLab Menu  Run  Run All Cells
  Wait Until JupyterLab Code Cell Is Not Active  timeout=300
  JupyterLab Code Cell Error Output Should Not Be Visible

  #Get the text of the last output cell
  ${output} =  Get Text  (//div[contains(@class,"jp-OutputArea-output")])[last()]
  Should Not Match  ${output}  ERROR*
  Should Be Equal As Strings  ${output}  [0.40201256371442895, 0.8875, 0.846875, 0.875, 0.896875, 0.9116818405511811]

  # Clean up workspace for next run
  # Might make sense to abstract it into a single Keyword
  Open With JupyterLab Menu  File  Open from Path…
  Sleep  1
  Input Text  xpath=//input[@placeholder="/path/relative/to/jlab/root"]  Untitled.ipynb
  Click Element  xpath://div[.="Open"]
  Wait Until Untitled.ipynb JupyterLab Tab Is Selected
  Close Other JupyterLab Tabs
  Add and Run JupyterLab Code Cell  !rm -rf *
