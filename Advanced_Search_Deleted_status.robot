*** Settings ***
Documentation     Advanced Search Functionality - Robust UI and DB Validation
Suite Setup       Connect To Database Using Custom Params
Library           DatabaseLibrary
Library           SeleniumLibrary
Library           DateTime
Library           ScreenCapLibrary    monitor=2 embed=True
Library           String
Library           Collections
Suite Teardown    Cleanup Suite
Test Teardown     Run Keyword If Test Failed    Capture Page Screenshot

*** Variables ***
${BROWSER}        chrome
${URL}            https://preprod.ripplefiber.dev.aex.systems/
${EMAIL}
${PASSWORD}
${TIMESTAMP}      ${EMPTY}
${DB_DRIVER}      pymssql
${DB_USER}
${DB_PASSWORD}
${DB_SERVER}      sql.dev.aex.rocks
${DB_PORT}        1433
${DB_NAME}        OpenFiberUSAPortalPreProd

# ========== MAIN CONFIGURATION - UPDATE THESE FOR DIFFERENT TEST CASES ==========
# This is the status you want to search for and validate
${EXPECTED_STATUS}    Deleted
# This is the dropdown option number (1=Active, 2=Expression of Interest, 6=Expiring, 8=Expired, etc.)
${DROPDOWN_OPTION_NUMBER}    4
# This is the status_id in the database (must match your DB schema)
${DB_STATUS_ID}    17
# =================================================================================

${STATUS_COLUMN_XPATH}    xpath://*[@id="pr_id_1-table"]/tbody/tr/td[3]/div/div
${NEXT_PAGE_BUTTON}    xpath://button[contains(@class, 'p-paginator-next') and not(contains(@class, 'p-disabled'))]

*** Test Cases ***
Verify Advance Search Functionality
    [Documentation]    Testing Advanced Search with complete UI count vs DB validation
    ...    This test:
    ...    1. Counts all entries with the expected status across all pages
    ...    2. Validates each page only contains the expected status (fails if mismatch found)
    ...    3. Compares total UI count with database count
    ...
    ...    TO REUSE THIS TEST FOR DIFFERENT STATUSES:
    ...    Simply update the three variables at the top of the file:
    ...    - ${EXPECTED_STATUS}
    ...    - ${DROPDOWN_OPTION_NUMBER}
    ...    - ${DB_STATUS_ID}
    [Tags]    Sanity Tests Ripple

    Step 1 : Log into Portal
    Step 2 : Navigate to Advanced Search And Apply Filter    ${EXPECTED_STATUS}    ${DROPDOWN_OPTION_NUMBER}
    Step 3 : Count And Validate All Pages    ${EXPECTED_STATUS}    ${DB_STATUS_ID}

*** Keywords ***
Connect To Database Using Custom Params
    [Documentation]    Establishes connection to the database
    ${connection}=    Connect To Database    pymssql    ${DB_NAME}    ${DB_USER}    ${DB_PASSWORD}    ${DB_SERVER}    ${DB_PORT}
    Log    Successfully connected to the database

Cleanup Suite
    [Documentation]    Closes all connections and browsers
    Run Keyword And Ignore Error    Disconnect From Database
    Close All Browsers

Step 1 : Log into Portal
    [Documentation]    Opens browser and logs into the portal
    Open Browser    ${URL}    ${BROWSER}
    Maximize Browser Window
    ${timestamp}=    Get Current Date    result_format=%Y-%m-%d_%H-%M-%S
    Set Suite Variable    ${TIMESTAMP}    ${timestamp}

    # Login flow
    Select Frame    id=embbeded-iframe
    Wait Until Element Is Visible    //button[contains(., 'Log In')]    timeout=10s
    Sleep    2s
    Click Element    //button[contains(., 'Log In')]
    Unselect Frame

    # Enter credentials
    Select Frame    id=embbeded-iframe
    Wait Until Element Is Visible    //input[@type='email']    timeout=10s
    Input Text    //input[@type='email']    ${EMAIL}
    Input Password    //input[@type='password']    ${PASSWORD}
    Click Element    //button[contains(., 'Login')]
    Unselect Frame
    Sleep    3s

Step 2 : Navigate to Advanced Search And Apply Filter
    [Documentation]    Navigates to Advanced Search and applies the specified status filter
    ...
    ...    Parameters:
    ...    - status_name: The name of the status to filter by (e.g., "Expiring", "Active")
    ...    - dropdown_option: The position number in the dropdown (1, 2, 6, 8, etc.)
    [Arguments]    ${status_name}    ${dropdown_option}

    # Navigate to search menu
    Wait Until Element Is Visible    xpath:/html/body/div[3]/header/div/div/div[2]/ul/li[4]    timeout=10s
    Click Element    xpath:/html/body/div[3]/header/div/div/div[2]/ul/li[4]
    Wait Until Element Is Visible    xpath:/html/body/div[3]/header/div/div/div[2]/ul/li[4]/ul/li[1]/a    timeout=10s
    Click Element    xpath:/html/body/div[3]/header/div/div/div[2]/ul/li[4]/ul/li[1]/a
    Sleep    2s

    # Expand search panel
    Select Frame    id:embbeded-iframe
    Wait Until Element Is Visible    xpath://*[@id="p-panel-0-titlebar"]    timeout=10s
    Click Element    xpath://*[@id="p-panel-0-titlebar"]
    Unselect Frame
    Sleep    2s

    # Select status filter - using the dropdown_option parameter
    Select Frame    id:embbeded-iframe
    Wait Until Element Is Visible    xpath://*[@id="p-panel-0-content"]/div/div/div[3]/span/p-dropdown/div    timeout=10s
    Click Element    xpath://*[@id="p-panel-0-content"]/div/div/div[3]/span/p-dropdown/div

    # Build dynamic xpath for the dropdown option
    ${option_xpath}=    Set Variable    xpath://*[@id="pr_id_5_list"]/p-dropdownitem[${dropdown_option}]/li
    Wait Until Element Is Visible    ${option_xpath}    timeout=10s
    Click Element    ${option_xpath}
    Unselect Frame

    # Apply filter
    Select Frame    id:embbeded-iframe
    Click Element    xpath://*[@id="p-panel-0-content"]/div/app-report-filter-buttons/div/button[1]/span
    Unselect Frame
    Sleep    3s

    Log    Applied filter for status: ${status_name}

Step 3 : Count And Validate All Pages
    [Documentation]    Main validation keyword that:
    ...    1. Loops through all pages
    ...    2. Counts total entries with expected status
    ...    3. Validates each entry on every page matches expected status (fails immediately if mismatch)
    ...    4. Compares final UI count with database count
    ...
    ...    Parameters:
    ...    - expected_status: The status we're validating (e.g., "Expiring")
    ...    - db_status_id: The status_id to query in the database
    [Arguments]    ${expected_status}    ${db_status_id}

    Select Frame    id:embbeded-iframe

    # Wait for results table to load
    Wait Until Element Is Visible    xpath://*[@id="pr_id_1-table"]    timeout=30s
    Sleep    2s

    # Initialize the total count variable
    ${total_ui_count}=    Set Variable    ${0}

    # Process first page
    Log To Console    ${\n}========== Starting Page Validation ==========
    ${page_count}=    Validate Page And Count Status    ${expected_status}    page=1
    ${total_ui_count}=    Evaluate    ${total_ui_count} + ${page_count}
    Log To Console    Page 1: Found ${page_count} entries | Running Total: ${total_ui_count}

    # Check if there are no results at all
    IF    ${total_ui_count} == 0
        Log To Console    No entries found in UI. Checking database...
        ${db_count}=    Query Database For Status Count    ${db_status_id}

        IF    ${db_count} == 0
            Log To Console    ✓ PASS: Both UI and Database confirm zero records for status '${expected_status}'
            Unselect Frame
            Pass Execution    No records found in UI and DB confirms zero records with status '${expected_status}'
        ELSE
            Unselect Frame
            Fail    ✗ FAIL: UI shows 0 records but database contains ${db_count} records with status '${expected_status}'
        END
    END

    # Loop through remaining pages if pagination exists
    ${page_number}=    Set Variable    ${2}

    WHILE    True
        ${has_next_page}=    Navigate To Next Page

        IF    not ${has_next_page}
            Log To Console    No more pages to process.
            BREAK
        END

        # Validate current page and add to count
        ${page_count}=    Validate Page And Count Status    ${expected_status}    page=${page_number}
        ${total_ui_count}=    Evaluate    ${total_ui_count} + ${page_count}
        Log To Console    Page ${page_number}: Found ${page_count} entries | Running Total: ${total_ui_count}

        ${page_number}=    Evaluate    ${page_number} + 1
    END

    Log To Console    ==========================================
    Log To Console    Total UI Count: ${total_ui_count}

    # Now compare with database
    ${db_count}=    Query Database For Status Count    ${db_status_id}
    Log To Console    Database Count: ${db_count}
    Log To Console    ==========================================

    Unselect Frame

    # Final validation: UI count must match DB count
    IF    ${total_ui_count} == ${db_count}
        Log To Console    ✓ PASS: UI count (${total_ui_count}) matches Database count (${db_count})
        Log    Test passed: UI and DB counts match for status '${expected_status}'
    ELSE
        Fail    ✗ FAIL: UI count (${total_ui_count}) does NOT match Database count (${db_count}) for status '${expected_status}'
    END

Validate Page And Count Status
    [Documentation]    Validates all entries on current page match expected status AND counts them
    ...    This keyword serves two purposes:
    ...    1. Validates each entry has the correct status (fails test immediately if mismatch)
    ...    2. Returns the count of entries on this page
    ...
    ...    Returns: Integer count of entries on the page
    [Arguments]    ${expected_status}    ${page}=1

    # Scroll and capture screenshot
    Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
    Sleep    1s
    Capture Page Screenshot    ${CURDIR}/snapshots/Advanced_Search_Page${page}_${TIMESTAMP}.png

    # Get all status elements on current page
    ${status_elements}=    Get WebElements    ${STATUS_COLUMN_XPATH}
    ${count}=    Get Length    ${status_elements}

    # If no elements found on page 1, return 0 to trigger DB comparison in parent keyword
    IF    ${count} == 0
        Log    No status elements found on page ${page}
        RETURN    ${0}
    END

    # Validate EVERY entry on this page
    FOR    ${index}    ${element}    IN ENUMERATE    @{status_elements}    start=1
        ${status}=    Get Text    ${element}
        ${status}=    Strip String    ${status}

        # CRITICAL: If any entry doesn't match, fail immediately
        Should Be Equal As Strings    ${status}    ${expected_status}
        ...    msg=❌ VALIDATION FAILED on Page ${page}, Row ${index}: Expected '${expected_status}' but found '${status}'. Test terminated.
    END

    Log    ✓ Page ${page}: All ${count} entries validated successfully as '${expected_status}'

    # Return the count for this page
    RETURN    ${count}

Navigate To Next Page
    [Documentation]    Attempts to navigate to next page. Returns True if successful, False otherwise
    ${next_enabled}=    Run Keyword And Return Status
    ...    Element Should Be Enabled    ${NEXT_PAGE_BUTTON}

    IF    ${next_enabled}
        Click Element    ${NEXT_PAGE_BUTTON}
        Sleep    2s
        RETURN    ${True}
    END

    RETURN    ${False}

Query Database For Status Count
    [Documentation]    Queries database to get count of records with specified status_id
    ...
    ...    Parameter:
    ...    - status_id: The status_id to query in the database
    ...
    ...    Returns: Integer count from database
    [Arguments]    ${status_id}

    ${query}=    Set Variable    SELECT COUNT(*) as record_count FROM bm_services WHERE status_id = ${status_id}

    Log    Executing DB query: ${query}
    @{result}=    Query    ${query}
    ${db_count}=    Set Variable    ${result[0][0]}

    Log    Database returned: ${db_count} records for status_id=${status_id}
    RETURN    ${db_count}

# ========== STATUS REFERENCE GUIDE ==========
# Use this guide to set up new test cases
#
# Status Name              | Dropdown Option | DB Status ID
# -------------------------|-----------------|-------------
# Active                   | 1               | 2
# Expression of Interest   | 2               | 1
# Expiring                 | 6               | 7
# Expired                  | 8               | 8
# Deleted                  | ?               | 17
#
# To add a new test:
# 1. Copy an existing test case
# 2. Update the test case name
# 3. Update the three parameters in "Step 3" call:
#    - Status Name (as shown in UI)
#    - Dropdown option number
#    - Database status_id
# ============================================