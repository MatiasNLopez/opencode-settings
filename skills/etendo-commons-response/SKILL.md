---
name: etendo-commons-response
description: >
  Build JSON responses, structured logging, and error handling for Etendo ActionHandlers using ResponseUtils, LoggerUtils, ErrorUtils, and SqlErrorUtils.
  Trigger: When building JSON responses for UI processes, using ResponseUtils, LoggerUtils, ErrorUtils,
  SqlErrorUtils, ResponseType, structured logging, or handling SQL exceptions in Etendo Java code.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Building JSON responses for ActionHandler UI processes (success, error, warning)
- Structured logging with severity levels (LoggerUtils)
- Handling exceptions and extracting root cause messages (ErrorUtils)
- Resolving PL/pgSQL SQL errors to module message enums (SqlErrorUtils)

## Module Location

`modules/com.etendoerp.commons.utils/` — Java package: `com.etendoerp.commons.utils`

Key classes:

- `com.etendoerp.commons.utils.utilities.ResponseUtils`
- `com.etendoerp.commons.utils.utilities.LoggerUtils`
- `com.etendoerp.commons.utils.utilities.ErrorUtils`
- `com.etendoerp.commons.utils.utilities.SqlErrorUtils`
- `com.etendoerp.commons.utils.enums.ResponseType`

---

## Critical Pattern 1: JSON Response Building (ResponseUtils)

**Use in ActionHandlers to build standardized UI responses.**

```java
import com.etendoerp.commons.utils.utilities.ResponseUtils;
import com.etendoerp.commons.utils.enums.ResponseType;

// In your ActionHandler execute() method:
JSONObject result = new JSONObject();
JSONArray actions = ResponseUtils.addActionsInResponse(result);

try {
  // ... business logic ...

  // Success message in UI
  ResponseUtils.jsonMessageResult(ResponseType.SUCCESS,
      Messages.MY_ORDER_CREATED.getMessage(docNo), actions);
  ResponseUtils.refreshView(actions);

} catch (Exception e) {
  // Error message in UI
  ResponseUtils.jsonMessageResult(ResponseType.ERROR,
      ErrorUtils.getDeepestErrorMessage(e), actions);
}

// Simple message result (alternative)
ResponseUtils.messageResult(result, ResponseType.SUCCESS, "Success");
```

---

## Critical Pattern 2: Structured Logging (LoggerUtils)

**Use instead of raw `Logger` for consistent severity-based logging.**

```java
import com.etendoerp.commons.utils.utilities.LoggerUtils;
import com.etendoerp.commons.utils.enums.ResponseType;

public class MyProcess {
  private static final LoggerUtils LOG = new LoggerUtils(MyProcess.class);

  public void execute() {
    // Log with string
    LOG.loggerMessage(ResponseType.INFO, "Starting process for order %s", orderId);

    // Log with MessageUtilityInterface enum (preferred — includes message key)
    // Output: [Message: MY_ORDER_CREATED]: Order SO-001 created successfully
    LOG.loggerMessage(ResponseType.SUCCESS, Messages.MY_ORDER_CREATED, order.getDocumentNo());

    // Log with exception
    LOG.loggerMessage(ResponseType.ERROR, Messages.MY_PRODUCT_VALIDATION_ERROR, exception);
  }
}
```

### Severity Routing

| ResponseType    | Log4j method  |
| --------------- | ------------- |
| `INFO`          | `log.info()`  |
| `ERROR`         | `log.error()` |
| `WARNING`       | `log.warn()`  |
| Everything else | `log.debug()` |

---

## Critical Pattern 3: Error Handling (ErrorUtils)

### General exception handling

```java
import com.etendoerp.commons.utils.utilities.ErrorUtils;

try {
  // ... business logic ...
} catch (Exception e) {
  // Get the deepest root cause message
  String msg = ErrorUtils.getDeepestErrorMessage(e);

  // Check if it's a SQL exception
  if (ErrorUtils.isSQLException(e)) {
    String sqlMsg = ErrorUtils.sqlException(e);
  }
}
```

### SMFCU SQL error resolution (for PL/pgSQL triggers/functions)

```java
import com.etendoerp.commons.utils.utilities.SqlErrorUtils;
import com.etendoerp.commons.utils.utilities.MessageUtility;

try {
  // ... DB operation that may trigger PL/pgSQL error ...
} catch (Exception e) {
  if (ErrorUtils.isSQLException(e)) {
    // Resolve SQL error to your module's message enum
    MessageUtilityInterface<?> resolved =
        SqlErrorUtils.getMessageNameSQL(Messages.class, e);

    if (MessageUtility.isInStanceFallbackMessage(resolved)) {
      // Generic error — could not match to module enum
      LOG.loggerMessage(ResponseType.ERROR, resolved.getMessage());
    } else {
      // Specific module error — handle accordingly
      Messages moduleMsg = (Messages) resolved;
      LOG.loggerMessage(ResponseType.ERROR, moduleMsg);
    }
  }
}
```

---

## ResponseType — Response Severities

`SUCCESS`, `ERROR`, `WARNING`, `INFO`, `RUNNING`, `PENDING`, `DEBUG`

## MovementType — Inventory Movement Codes

```java
MovementType.CUSTOMER_SHIPMENT.getCode()  // "C-"
MovementType.VENDOR_RECEIPTS.getCode()    // "V+"
MovementType.fromCode("M+")              // MovementType.MOVEMENT_TO
```

---

## Complete ActionHandler Example

```java
package com.example.mymodule.actionHandler;

import java.util.Map;
import org.codehaus.jettison.json.JSONArray;
import org.codehaus.jettison.json.JSONObject;
import org.openbravo.client.kernel.BaseActionHandler;

import com.etendoerp.commons.utils.enums.CoreParamsKey;
import com.etendoerp.commons.utils.enums.FallbackMessage;
import com.etendoerp.commons.utils.enums.ResponseType;
import com.etendoerp.commons.utils.utilities.ErrorUtils;
import com.etendoerp.commons.utils.utilities.LoggerUtils;
import com.etendoerp.commons.utils.utilities.ResponseUtils;
import com.example.mymodule.enums.Messages;
import com.example.mymodule.enums.ParamsCustom;

public class MyActionHandler extends BaseActionHandler {
  private static final LoggerUtils LOG = new LoggerUtils(MyActionHandler.class);

  @Override
  protected JSONObject execute(Map<String, Object> parameters, String content) {
    JSONObject result = new JSONObject();
    JSONArray actions = ResponseUtils.addActionsInResponse(result);

    try {
      JSONObject request = new JSONObject(content);
      JSONObject params = CoreParamsKey.PARAMS_KEY.getJsonObject(request, true);
      String orderId = CoreParamsKey.C_ORDER_ID.getStringInJson(request, true);
      String locatorId = ParamsCustom.LOCATOR_ID.getStringInJson(params, true);

      LOG.loggerMessage(ResponseType.INFO, "Processing order %s", orderId);

      // ... business logic ...

      ResponseUtils.jsonMessageResult(ResponseType.SUCCESS,
          Messages.MY_ORDER_CREATED.getMessage(docNo), actions);
      ResponseUtils.refreshView(actions);

    } catch (Exception e) {
      LOG.loggerMessage(ResponseType.ERROR, FallbackMessage.SMFCU_ERROR, e);
      ResponseUtils.jsonMessageResult(ResponseType.ERROR,
          ErrorUtils.getDeepestErrorMessage(e), actions);
    }

    return result;
  }
}
```

**Note**: This example also uses `Messages` (from `etendo-commons-messages`) and `ParamsCustom`/`CoreParamsKey` (from `etendo-commons-params`). Load those skills if you need their full patterns.

---

## Anti-Patterns

| Bad                                           | Good                                                  |
| --------------------------------------------- | ----------------------------------------------------- |
| `Logger.getLogger(MyClass.class)`             | `new LoggerUtils(MyClass.class)`                      |
| `new JSONObject(); result.put("msgType",...)` | `ResponseUtils.jsonMessageResult(type, msg, actions)` |
| `e.getMessage()` for root cause               | `ErrorUtils.getDeepestErrorMessage(e)`                |
| Manual SQL exception string parsing           | `SqlErrorUtils.getMessageNameSQL(Messages.class, e)`  |

## Dependency

Module UUID: `8886CBAB63DB43A0BD7B927C8299D738`

```xml
<AD_MODULE_DEPENDENCY>
  <AD_DEPENDENT_MODULE_ID><![CDATA[8886CBAB63DB43A0BD7B927C8299D738]]></AD_DEPENDENT_MODULE_ID>
  <STARTVERSION><![CDATA[1.0.0]]></STARTVERSION>
  <ISINCLUDED><![CDATA[N]]></ISINCLUDED>
  <DEPENDANT_MODULE_NAME><![CDATA[Etendo Common Utilities]]></DEPENDANT_MODULE_NAME>
  <DEPENDENCY_ENFORCEMENT><![CDATA[MAJOR]]></DEPENDENCY_ENFORCEMENT>
</AD_MODULE_DEPENDENCY>
```
