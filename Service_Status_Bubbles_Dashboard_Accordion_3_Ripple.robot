*** Settings ***
Documentation     Dashboard Bubble Count Verification - RIPPLE ACCORDION
...               This test validates that bubble counts on the Ripple accordion
...               match the actual number of entries shown in their drilldown tables.
Library           SeleniumLibrary
Library           DateTime
Library           ScreenCapLibrary    monitor=2 embed=True
Library           String
Library           Collections
Test Teardown     Run Keyword If Test Failed    Capture Page Screenshot

*** Variables ***
${BROWSER}        chrome
${URL}            https://preprod.ripplefiber.dev.aex.systems/
${EMAIL}          
${PASSWORD}
${TIMESTAMP}      ${EMPTY}

# Ripple Accordion (Accordion 3)
${ACCORDION_3}    //*[@id="ui-id-5"]

# List to track mismatches
@{MISMATCHES}

*** Test Cases ***
Verify Ripple Accordion Bubble Counts
    [Documentation]    Validates all bubble counts in the Ripple accordion
    Log into Portal
    Navigate to Service Dashboard
    Validate Ripple Accordion Bubbles
    Report Final Results
    [Teardown]    Close Browser

*** Keywords ***
Log into Portal
    [Documentation]    Opens browser and logs into the Ripple Fiber portal
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window

    ${timestamp}=    Get Current Date    result_format=%Y-%m-%d_%H-%M-%S
    Set Suite Variable    ${TIMESTAMP}    ${timestamp}

    # Step 1: Click initial Login button in iframe
    Select Frame    id=embbeded-iframe
    Wait Until Element Is Visible    //button[contains(., 'Log In')]    timeout=10s
    Sleep    2s
    Click Element    //button[contains(., 'Log In')]
    Unselect Frame

    # Step 2: Enter credentials in iframe
    Select Frame    id=embbeded-iframe
    Wait Until Element Is Visible    //input[@type='email']    timeout=10s
    Input Text    //input[@type='email']    ${EMAIL}
    Input Password    //input[@type='password']    ${PASSWORD}
    Click Element    //button[contains(., 'Login')]
    Unselect Frame

    Sleep    3s
    Log To Console    ✅ Successfully logged into portal

Navigate to Service Dashboard
    [Documentation]    Navigates to the Service Dashboard
    ${services_menu}=    Set Variable    xpath:/html/body/div[3]/header/div/div/div[2]/ul/li[4]/a
    Wait Until Element Is Visible    ${services_menu}    timeout=10s

    Click Element    ${services_menu}
    Sleep    2s

    ${dashboard_link}=    Set Variable    xpath:/html/body/div[3]/header/div/div/div[2]/ul/li[4]/ul/li[2]/a
    Wait Until Element Is Visible    ${dashboard_link}    timeout=15s
    Sleep    1s

    ${dashboard_link_clean}=    Set Variable    /html/body/div[3]/header/div/div/div[2]/ul/li[4]/ul/li[2]/a
    Execute JavaScript    var el=document.evaluate("${dashboard_link_clean}", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue; if(el){el.click();}

    Wait Until Page Contains    Service Dashboard    timeout=30s
    Sleep    3s
    Log To Console    ✅ Successfully navigated to Service Dashboard

Validate Ripple Accordion Bubbles
    [Documentation]    Validates all bubbles in the Ripple accordion (Accordion 3)

    Log To Console    ${\n}========================================
    Log To Console    VALIDATING RIPPLE ACCORDION
    Log To Console    ========================================

    # Initialize mismatches list
    @{MISMATCHES}=    Create List
    Set Suite Variable    @{MISMATCHES}

    ${accordion_xpath}=    Set Variable    ${ACCORDION_3}
    ${accordion_name}=     Set Variable    Ripple
    ${panel_xpath}=        Set Variable    //*[@id="ui-id-6"]

    Log To Console    ${\n}Testing Accordion: "${accordion_name}"
    Log To Console    Expanding accordion...

    # Expand Ripple accordion
    Click Element    ${accordion_xpath}
    Sleep    2s

    # Find all bubbles in Ripple accordion
    ${bubble_containers}=    Get WebElements    ${panel_xpath}//div[contains(@id,'btn-')]
    ${total_bubbles}=    Get Length    ${bubble_containers}
    Log To Console    Found ${total_bubbles} bubble(s) in "${accordion_name}"

    # Loop through each bubble
    FOR    ${bubble_idx}    IN RANGE    1    ${total_bubbles}+1

        Log To Console    ${\n}  ┌─────────────────────────────────────────┐
        Log To Console    │  BUBBLE ${bubble_idx}/${total_bubbles} in ${accordion_name}
        Log To Console    └─────────────────────────────────────────┘

        ${bubble_container_xpath}=    Set Variable    (${panel_xpath}//div[contains(@id,'btn-')])[${bubble_idx}]

        ${count_xpath}=    Set Variable    ${bubble_container_xpath}/p
        ${bubble_text}=    Get Text    ${count_xpath}
        ${bubble_text}=    Strip String    ${bubble_text}
        ${bubble_count}=   Convert To Integer    ${bubble_text}
        ${bubble_label}=    Get Text    xpath=(${panel_xpath}//div[@class='circledescription'])[${bubble_idx}]

        Log To Console    → Status: "${bubble_label}"
        Log To Console    → Bubble Count: ${bubble_count}

        Scroll Element Into View    ${bubble_container_xpath}
        Sleep    0.5s
        Click Element    ${bubble_container_xpath}
        Log To Console    → Clicked bubble, waiting for drilldown table...

        Sleep    3s

        Log To Console    → Checking if content is in iframe...

        ${iframe_exists}=    Run Keyword And Return Status
        ...    Wait Until Element Is Visible    id=embbeded-iframe    timeout=5s

        Run Keyword If    ${iframe_exists}
        ...    Run Keywords
        ...    Log To Console    → Found iframe, switching to it...
        ...    AND    Select Frame    id=embbeded-iframe
        ...    AND    Sleep    1s

        Log To Console    → Scrolling to pagination element...

        Wait Until Page Contains Element    xpath://*[@id="pr_id_1"]    timeout=30s

        Execute JavaScript    var outerWrapper = document.querySelector('.p-datatable-wrapper'); if (outerWrapper) { outerWrapper.scrollTop = outerWrapper.scrollHeight; } var scrollableDiv = document.querySelector('.p-datatable-scrollable-body'); if (scrollableDiv) { scrollableDiv.scrollTop = scrollableDiv.scrollHeight; }

        Sleep    2s

        ${pagination_xpath}=    Set Variable    xpath://*[@id="pr_id_1"]/p-paginator/div/span[1]

        Wait Until Element Is Visible    ${pagination_xpath}    timeout=10s

        Execute JavaScript    var paginationEl = document.querySelector('#pr_id_1 p-paginator span'); if (paginationEl) { paginationEl.scrollIntoView({behavior: 'smooth', block: 'center'}); }

        Sleep    2s

        ${entries_text}=    Get Text    ${pagination_xpath}
        Log To Console    → Entries text: "${entries_text}"

        Run Keyword If    ${iframe_exists}
        ...    Run Keywords
        ...    Log To Console    → Exiting iframe...
        ...    AND    Unselect Frame

        ${after_of}=    Fetch From Right    ${entries_text}    of${SPACE}
        ${before_entries}=    Fetch From Left    ${after_of}    ${SPACE}entries
        ${drilldown_count_text}=    Strip String    ${before_entries}

        ${drilldown_count}=    Convert To Integer    ${drilldown_count_text}
        Log To Console    → Drilldown Count: ${drilldown_count}

        Log To Console    ${\n}  ⚖️  COMPARING COUNTS:
        Log To Console    → Bubble shows: ${bubble_count}
        Log To Console    → Drilldown shows: ${drilldown_count}

        ${validation_passed}    ${error_msg}=    Run Keyword And Ignore Error
        ...    Should Be Equal As Integers    ${bubble_count}    ${drilldown_count}

        Run Keyword If    "${validation_passed}" == "PASS"
        ...    Log To Console    → ✅ PASS: Counts match!
        ...    ELSE
        ...    Run Keywords
        ...    Log To Console    → ❌ FAIL: Count mismatch detected (will be reported at end)
        ...    AND    Record Mismatch    ${accordion_name}    ${bubble_label}    ${bubble_count}    ${drilldown_count}

        Log To Console    ${\n}  ← Returning to dashboard...

        Run Keyword And Ignore Error    Unselect Frame

        Go Back
        Sleep   2s
        Reload page

        Wait Until Page Contains Element    ${ACCORDION_3}   timeout=30s

        Log To Console    → Waiting for page to fully load...
        Wait Until Element Is Not Visible    css:.loading    timeout=50s
        Sleep    5s

        Log To Console    → Re-expanding accordion "${accordion_name}"...
        Click Element    ${accordion_xpath}
        Sleep    2s

    END

    Log To Console    ${\n}✅ Completed all bubbles in: "${accordion_name}"
    Log To Console    ${\n}========================================

Record Mismatch
    [Documentation]    Records a count mismatch for later reporting
    [Arguments]    ${accordion}    ${bubble_label}    ${bubble_count}    ${drilldown_count}

    ${mismatch}=    Create Dictionary
    ...    accordion=${accordion}
    ...    bubble=${bubble_label}
    ...    bubble_count=${bubble_count}
    ...    drilldown_count=${drilldown_count}

    Append To List    ${MISMATCHES}    ${mismatch}
    Log To Console    → Mismatch recorded: [${accordion}] "${bubble_label}" - Bubble: ${bubble_count}, Drilldown: ${drilldown_count}

Report Final Results
    [Documentation]    Reports all mismatches found during validation and fails test if any exist

    ${mismatch_count}=    Get Length    ${MISMATCHES}

    Log To Console    ${\n}${\n}╔════════════════════════════════════════════════════════════╗
    Log To Console    ║           RIPPLE ACCORDION - FINAL REPORT                  ║
    Log To Console    ╚════════════════════════════════════════════════════════════╝

    IF    ${mismatch_count} == 0
        Log To Console    ${\n}✅ SUCCESS: All bubble counts match their drilldown tables!
        Log To Console    ${\n}No mismatches found. Test PASSED.${\n}
    ELSE
        Log To Console    ${\n}❌ FAILURES DETECTED: ${mismatch_count} mismatch(es) found${\n}
        Log To Console    ┌────────────────────────────────────────────────────────────┐
        Log To Console    │                    MISMATCH DETAILS                        │
        Log To Console    └────────────────────────────────────────────────────────────┘

        ${counter}=    Set Variable    ${1}
        FOR    ${mismatch}    IN    @{MISMATCHES}
            ${accordion}=        Get From Dictionary    ${mismatch}    accordion
            ${bubble}=           Get From Dictionary    ${mismatch}    bubble
            ${bubble_count}=     Get From Dictionary    ${mismatch}    bubble_count
            ${drilldown_count}=  Get From Dictionary    ${mismatch}    drilldown_count
            ${difference}=       Evaluate    ${bubble_count} - ${drilldown_count}

            ${bubble_str}=    Convert To String    ${bubble_count}
            ${drill_str}=     Convert To String    ${drilldown_count}
            ${diff_str}=      Convert To String    ${difference}

            Log To Console    ${\n}${counter}. [${accordion}] → "${bubble}"
            Log To Console    \ \ \ ├─ Bubble Count:     ${bubble_str}
            Log To Console    \ \ \ ├─ Drilldown Count:  ${drill_str}
            Log To Console    \ \ \ └─ Difference:       ${diff_str}

            ${counter}=    Evaluate    ${counter} + 1
        END

        Log To Console    ${\n}════════════════════════════════════════════════════════════
        Log To Console    ❌ TEST FAILED: ${mismatch_count} bubble count mismatch(es) detected
        Log To Console    ════════════════════════════════════════════════════════════${\n}

        Fail    ${mismatch_count} bubble count mismatch(es) found. See detailed report above.
    END