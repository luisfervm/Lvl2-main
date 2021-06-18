*** Settings ***
Documentation   Template robot main suite.
Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.Archive
Library         Dialogs
Library         RPA.Robocloud.Secrets


*** Keywords ***
BrowserActions
    [Arguments]    ${Link}
    Open Chrome Browser    ${Link}
    Wait Until Element Is Visible    //button[normalize-space()='I guess so...']
    Click Button    //button[normalize-space()='I guess so...']

*** Keywords ***
DownloadExcelFile
    [Arguments]    ${Link}
    Download    ${Link}    overwrite=True

*** Keywords ***
GetDataFromExcelFile
    [Arguments]    ${Filename}  
    ${sales_reps}=    Read Table From Csv    ${Filename}    header=True
    FOR    ${sales_rep}    IN    @{sales_reps}
        FillAndSubmitTheFormWithData    ${sales_rep}
        
    END

*** Keywords ***
FillAndSubmitTheFormWithData
    [Arguments]    ${sales_rep}
    ${stdWait}=   Convert To String    30s
    Wait Until Element Is Visible    //select[@id='head']  ${stdWait}
    Select From List By Value    //select[@id='head']    ${sales_rep}[Head]
    Select Radio Button  body    ${sales_rep}[Body]
    Input Text    //input[@placeholder='Enter the part number for the legs']    ${sales_rep}[Legs]  
    Input Text    //input[@id='address']  ${sales_rep}[Address]
    Wait Until Element Is Visible    //button[normalize-space()='Preview']  ${stdWait}
    Click Button    //button[normalize-space()='Preview']
    Wait Until Element Is Visible    //button[normalize-space()='Order']  ${stdWait}
    Click Button    //button[normalize-space()='Order']
    ${Orderidxpath}=  Convert To String    //div[@id='order-completion']
    ${Alert}=  Is Element Visible    //div[@id='receipt']
    IF   ${Alert}==False
        FOR    ${i}    IN RANGE    20
            Click Button    //button[normalize-space()='Preview']
            Click Button    //button[normalize-space()='Order']
            ${Alert}=  Is Element Visible    //div[@id='receipt']
            Exit For Loop If  ${Alert}==True
        END
    END
    Wait Until Element Is Visible  ${Orderidxpath}  ${stdWait}
    CreatePDF  ${sales_rep}[Order number]

*** Keywords ***
CreatePDF
    [Arguments]     ${OrderNumber}
    ${stdWait}=   Convert To String    30s
    Wait Until Element Is Visible  //div[@id='robot-preview-image']  ${stdWait}
    Screenshot   //div[@id='robot-preview']     ${CURDIR}${/}output${/}${OrderNumber}${/}OrderPreview${OrderNumber}.png
    ${Orderidxpath}=  Convert To String    //div[@id='receipt']
    Wait Until Element Is Visible  ${Orderidxpath}
    Screenshot    ${Orderidxpath}    ${CURDIR}${/}output${/}${OrderNumber}${/}OrderNum${OrderNumber}.png
    ${ListImages}=  Create List  ${CURDIR}${/}output${/}${OrderNumber}${/}OrderPreview${OrderNumber}.png  ${CURDIR}${/}output${/}${OrderNumber}${/}OrderNum${OrderNumber}.png
    Add Files To Pdf  ${ListImages}  ${CURDIR}${/}output${/}${OrderNumber}${/}Order${OrderNumber}.pdf
    Wait Until Element Is Visible  //button[normalize-space()='Order another robot']
    Click Button    //button[normalize-space()='Order another robot']
    Wait Until Element Is Visible    //button[normalize-space()='I guess so...']
    Click Button    //button[normalize-space()='I guess so...']


*** Keywords ***
CreateZipFile
    Archive Folder With Zip    ${CURDIR}${/}output    ${CURDIR}${/}output${/}FinalOutput.zip   recursive=True

*** Keywords ***
GetSecretValue
    ${secret}=    Get Secret    URLLVL2
    Log    ${secret}[URL]
    [Return]   ${secret}[URL]

*** Tasks ***
MainTaskLvl2
    ${urlvalue}=   GetSecretValue
    ${CSVlink} =	Get Value From User  CSV Link   default
    #https://robotsparebinindustries.com/orders.csv 
    DownloadExcelFile  ${CSVlink}
    #https://robotsparebinindustries.com/#/robot-order
    BrowserActions  ${urlvalue}
    GetDataFromExcelFile  orders.csv
    CreateZipFile
    [Teardown]  Close Browser
