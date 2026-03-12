---
name: etendo-commons-utils
description: >
  Router for Etendo Common Utilities sub-skills. Routes to the correct sub-skill based on context:
  etendo-commons-messages (AD_MESSAGE), etendo-commons-params (JSON params),
  etendo-commons-state (EventHandler state), etendo-commons-response (responses, logging, errors).
  Trigger: When writing Java code in Etendo that needs AD_MESSAGE messages, ActionHandler/Process
  JSON params, EventHandler state management, structured logging, or SQL error parsing.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "2.0"
---

## Router — Load the Right Sub-Skill

This skill is a **router**. Do NOT implement patterns from here — load the specific sub-skill instead.

| You are doing...                                                                                    | Load this skill           |
| --------------------------------------------------------------------------------------------------- | ------------------------- |
| Creating/using AD_MESSAGE messages, Messages enum, MessageUtilityInterface                          | `etendo-commons-messages` |
| Reading JSON params in ActionHandler/Process, CoreParamsKey, ProcessParamAccessor                   | `etendo-commons-params`   |
| Reading/comparing/mutating entity state in EventHandler, EntityStateUtils                           | `etendo-commons-state`    |
| Building JSON responses, structured logging, error handling, ResponseUtils, LoggerUtils, ErrorUtils | `etendo-commons-response` |

### Multiple Patterns Needed?

Load each sub-skill that applies. Common combinations:

| Scenario                    | Load these skills                                                               |
| --------------------------- | ------------------------------------------------------------------------------- |
| **ActionHandler** (typical) | `etendo-commons-messages` + `etendo-commons-params` + `etendo-commons-response` |
| **EventHandler** (typical)  | `etendo-commons-messages` + `etendo-commons-state` + `etendo-commons-response`  |
| **Background Process**      | `etendo-commons-messages` + `etendo-commons-response`                           |
| **Just adding messages**    | `etendo-commons-messages`                                                       |

---

## Module Overview

`modules/com.etendoerp.commons.utils/` — Java package: `com.etendoerp.commons.utils`

DB prefix: `SMFCU`

```
com.etendoerp.commons.utils/
├── interfaces/
│   ├── MessageUtilityInterface<E>    # → etendo-commons-messages
│   ├── ProcessParamAccessor          # → etendo-commons-params
│   └── OrderUtilityInterface         # Order retrieval helpers
├── enums/
│   ├── FallbackMessage               # → etendo-commons-messages
│   ├── EntityStateMessages           # → etendo-commons-state
│   ├── ResponseType                  # → etendo-commons-response
│   ├── CoreParamsKey                 # → etendo-commons-params
│   ├── ConstantKey                   # → etendo-commons-params
│   ├── MovementType                  # → etendo-commons-response
│   └── SqlMessageCode               # → etendo-commons-response
└── utilities/
    ├── EntityStateUtils              # → etendo-commons-state
    ├── LoggerUtils                   # → etendo-commons-response
    ├── ResponseUtils                 # → etendo-commons-response
    ├── ErrorUtils                    # → etendo-commons-response
    ├── SqlErrorUtils                 # → etendo-commons-response
    ├── FormatUtils                   # → etendo-commons-messages
    ├── MessageUtility                # → etendo-commons-messages
    └── SessionSQLUtils               # Hibernate session cleanup
```

## Dependency (applies to ALL sub-skills)

Module UUID: `8886CBAB63DB43A0BD7B927C8299D738`

Ensure your module declares `Etendo Common Utilities` in `AD_MODULE_DEPENDENCY.xml`:

```xml
<AD_MODULE_DEPENDENCY>
  <AD_DEPENDENT_MODULE_ID><![CDATA[8886CBAB63DB43A0BD7B927C8299D738]]></AD_DEPENDENT_MODULE_ID>
  <STARTVERSION><![CDATA[1.0.0]]></STARTVERSION>
  <ISINCLUDED><![CDATA[N]]></ISINCLUDED>
  <DEPENDANT_MODULE_NAME><![CDATA[Etendo Common Utilities]]></DEPENDANT_MODULE_NAME>
  <DEPENDENCY_ENFORCEMENT><![CDATA[MAJOR]]></DEPENDENCY_ENFORCEMENT>
</AD_MODULE_DEPENDENCY>
```
