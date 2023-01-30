*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.Tables
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Robocorp.Vault
Library    RPA.Dialogs

*** Variables ***
${order_page1}=    https://robotsparebinindustries.com/#/robot-order 
${CSV_URL1}=     https://robotsparebinindustries.com/orders.csv

*** Tasks ***
Order robots from RobotSpareBin Industries Inc    
   ${CSV_URL}=    Get orders url from user
   Open the robot order website
    ${orders}=     Get orders    ${CSV_URL}
    FOR    ${row}    IN    @{orders}
         Close the annoying modal
         Fill the form    ${row}
         Preview the robot
         Submit the order
        ${x}=    Set Variable    ${0}
        WHILE    ${x} < 3
            ${x}=    Evaluate    ${x} + 1
             ${isVisible}=    Is Element Visible    id:receipt
            IF   ${isVisible}    BREAK    # Break out of loop.
            Submit the order    
        END
         ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
         ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
         Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
         Go to order another robot
    END
    Create a ZIP file of the receipts



*** Keywords ***
Open the robot order website
    ${secret} =    Get Secret    urls
    Open Available Browser    ${secret}[order_page_url]

Get orders url from user
    Add heading    Add file path to orders csv
    Add text input    url    csv file path    Enter url
    ${response}=    Run dialog
    RETURN    ${response.url}
Log in
    Input Text    username    maria
    Input Password    password    thoushallnotpass
    Submit Form

Close the annoying modal
    Wait Until Element Contains    class:btn-dark    OK
    Click Element   class:btn-dark

Get orders
    [Arguments]    ${CSV_URL}
    Download    ${CSV_URL}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    RETURN    ${orders}
Fill the form
    [Arguments]    ${row}
    Select From List By Value    name:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text     //input[@placeholder='Enter the part number for the legs']   ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    Click Button    id:order
Store the receipt as a PDF file
    [Arguments]    ${Order number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipt${/}${Order number}.pdf
    RETURN    ${OUTPUT_DIR}${/}receipt${/}${Order number}.pdf

Take a screenshot of the robot
    [Arguments]    ${Order number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}receipt${/}${Order number}.png
    RETURN    ${OUTPUT_DIR}${/}receipt${/}${Order number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${pngList}=    Create List    ${screenshot}:align=center
    Open Pdf    ${pdf}
    Add Files To Pdf  ${pngList}    ${pdf}    append=True
    Close Pdf

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    ${zip_file_name} =    Set Variable    ${OUTPUT_DIR}${/}all_receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipt${/}    ${zip_file_name}