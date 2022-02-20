*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    Telnet
Library    Collections
Library    RPA.Robocorp.Process
Library    RPA.Archive
Library    RPA.PDF
Library    RPA.Robocloud.Secrets
Library    RPA.Dialogs


*** Variables ***
${retry}=    10x
${retry_interval}=    5s

*** Keywords ***
Open the robot order website
    Open Available Browser     https://robotsparebinindustries.com/#/robot-order
    Maximize Browser Window
Click on tab Order your BOT
    Click Element If Visible    xpath://a[contains(text(),'Order your robot!')]

Validate pop-up and close
    Click Element If Visible    xpath://button[contains(.,'OK')]

Download csv file

    Add heading    Please enter the order csv file path
    Add text input    url    label= CSV file Path 
    ${result}=    Run dialog
    [Return]    ${result["url"]}
    
Get orders
    ${order_tbl}=    Read table from CSV    orders.csv    header=True
    [Return]    ${order_tbl}
Fill Order form
    [Arguments]    ${element}
    Select From List By Value    css:#head    ${element}[Head]
    Click Element If Visible    id:id-body-${element}[Body]
    Input Text    xpath://label[contains(.,'3. Legs:')]/../input    ${element}[Legs]
    Input Text    xpath://input[@id='address']    ${element}[Address]
Preview order
    Click Element If Visible    xpath://button[@id='preview']
Submit order
    Click Button    id:order
    Page Should Contain Element    id:receipt
Order another robot
    Wait And Click Button    id:order-another
Log Out And Close The Browser
    Close Browser
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:order-completion
    ${order_number}=    Get Text    xpath://div[@id="receipt"]/p[1]
    ${receipt_html}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
    [Return]    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot     id:robot-preview    ${CURDIR}${/}output${/}${order_number}.png
    [Return]       ${CURDIR}${/}output${/}${order_number}.png
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}   ${pdf}
    Open Pdf       ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf      ${pdf}
Create a ZIP file of the receipts
    Archive Folder With Zip  ${CURDIR}${/}output${/}receipts   ${CURDIR}${/}output${/}receipt.zip



*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Click on tab Order your BOT         
    Validate pop-up and close           
    ${csv_url}=    Download csv file                   
    Download        ${csv_url}                overwrite=True


     ${orders}=   Get orders
        FOR    ${ord_detail}    IN    @{orders}
            Validate pop-up and close
            Fill Order form    ${ord_detail}                                                  
            Wait Until Keyword Succeeds    ${retry}    ${retry_interval}    Preview order                    
            Wait Until Keyword Succeeds    10x    5s    Submit order                          
            ${pdf}=    Store the receipt as a PDF file    ${ord_detail}[Order number]                           
            ${screenshot}=    Take a screenshot of the robot    ${ord_detail}[Order number]                    
            Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}                      
            Order another robot                                                               
        END
        Create a ZIP file of the receipts                                    
        [Teardown]    Close Browser