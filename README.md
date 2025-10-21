# 🤖 Public_Robot_Framework_Tests

This repository showcases my **Robot Framework automation suites**, designed for **sanity**, **status validation**, and **UI–Database verification** within pre-production environments.  
These tests form part of my ongoing work to ensure that the **Ripple** system’s advanced search and service dashboards remain accurate and stable across all workflow statuses.

---

## 📂 Project Overview

### 🧩 Folder: `Ripple_Sanity_Checks_Automated/`

This suite contains a series of **automated validation tests** that verify service, order, and product statuses across multiple workflow conditions in the **Ripple application**.

Each `.robot` file targets a specific status type and performs:
- **UI validation** (e.g., verifying table results, labels, and bubble counts)  
- **Database cross-checks** (ensuring UI data matches DB query results)  
- **Advanced search consistency checks** across multiple business states  

These tests help identify discrepancies between frontend presentation and backend records before deployment to production.

---

## 🧠 Key Components

- **Status Validation Tests:**  
  Verify all possible lifecycle statuses such as:
  - `Active`, `Cancelled`, `Provisioning`, `Rejected`, `Suspended`, and `Expired`
  - ISP and OSP workflow transitions (`ISP_Changed`, `ISP_Change_Pending`, `OSP_status`)
  - Product change and order tracking statuses

- **Service Dashboard Sanity Test:**  
  The special file  
  `All_Accordions_Service_Status_Bubbles_Dashboard_Bubble_Verifications.robot`  
  consolidates multiple checks to ensure that:
  - Bubble counts match DB record totals  
  - Accordion drill-downs display the correct service and status information  
  - Dashboard-level summaries are accurate across all status categories

- **Snapshots Folder:**  
  Used for capturing **runtime screenshots** or **evidence logs** during test execution, supporting visual verification.

---

## 🧰 Technology Stack

- **Framework:** [Robot Framework](https://robotframework.org/)  
- **Language:** Python  
- **Database:** SQL validation via `DatabaseLibrary`  
- **API Testing:** REST endpoints using `RequestsLibrary` and `JSONLibrary`  
- **Version Control:** GitHub  
- **Execution:** CLI and CI/CD (GitHub Actions / GitLab Pipelines)  

---
