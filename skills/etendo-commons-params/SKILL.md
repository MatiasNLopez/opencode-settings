---
name: etendo-commons-params
description: >
  Type-safe JSON parameter extraction for Etendo ActionHandlers and Processes using ProcessParamAccessor enum pattern.
  Trigger: When writing ActionHandlers or Processes that read JSON parameters, extract _params,
  use CoreParamsKey, ProcessParamAccessor, or need type-safe JSON access in Etendo Java code.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Writing ActionHandlers or Processes that read JSON parameters
- Extracting `_params` object from request JSON
- Need type-safe access to standard Etendo entity IDs (C_Order_ID, M_Product_ID, etc.)
- Replacing raw `json.getString("key")` calls with typed accessors

## Module Location

`modules/com.etendoerp.commons.utils/` — Java package: `com.etendoerp.commons.utils`

Interface: `com.etendoerp.commons.utils.interfaces.ProcessParamAccessor`

---

## Critical Pattern: Params Enum (ProcessParamAccessor)

**ALWAYS use this instead of raw `json.getString("key")` calls.**

### Create a params enum in your module

```java
package com.example.mymodule.enums;

import com.etendoerp.commons.utils.interfaces.ProcessParamAccessor;

public enum ParamsCustom implements ProcessParamAccessor {

  LOCATOR_ID("locatorID"),
  MOVEMENT_DATE("MovementDate"),
  CHK_VINCULATE("chkVinculate");

  private final String paramKey;

  ParamsCustom(String paramKey) {
    this.paramKey = paramKey;
  }

  @Override
  public String getParamKey() {
    return this.paramKey;
  }
}
```

### Use in ActionHandlers

```java
// Extract _params object from request
JSONObject params = CoreParamsKey.PARAMS_KEY.getJsonObject(request, true);

// Extract typed values (required = true throws if missing)
String locatorId = ParamsCustom.LOCATOR_ID.getStringInJson(params, true);
Boolean vinculate = ParamsCustom.CHK_VINCULATE.getBooleanInJson(params);
String orderId = CoreParamsKey.C_ORDER_ID.getStringInJson(request, true);

// Check existence before access
if (ParamsCustom.MOVEMENT_DATE.hasKeyInJson(params)) {
  String date = ParamsCustom.MOVEMENT_DATE.getStringInJson(params);
}

// Write values to response
ParamsCustom.LOCATOR_ID.insertValue(response, newLocatorId);
ParamsCustom.LOCATOR_ID.updateValueIfExists(response, newLocatorId);
```

---

## Available Extraction Methods

| Method                               | Returns      | Null-safe            |
| ------------------------------------ | ------------ | -------------------- |
| `getStringInJson(json, required)`    | `String`     | Yes                  |
| `getBooleanInJson(json, required)`   | `Boolean`    | Yes (defaults false) |
| `getJsonObject(json, required)`      | `JSONObject` | Yes                  |
| `getJsonArrayInJson(json, required)` | `JSONArray`  | Yes                  |
| `hasKeyInJson(json)`                 | `boolean`    | Yes                  |

All methods have `*WithKeyCase(json, required, KeyCase)` variants for case-insensitive access.

### Write Methods

| Method                             | Description                        |
| ---------------------------------- | ---------------------------------- |
| `insertValue(json, value)`         | Adds key-value to JSON object      |
| `updateValueIfExists(json, value)` | Updates only if key already exists |

---

## CoreParamsKey — Standard Etendo Parameter Keys

Built-in enum that implements `ProcessParamAccessor` for standard Etendo entity parameters:

```java
CoreParamsKey.PARAMS_KEY       // "_params"
CoreParamsKey.C_ORDER_ID       // "C_Order_ID"
CoreParamsKey.C_INVOICE_ID     // "C_Invoice_ID"
CoreParamsKey.C_INVOICE_LINE_ID // "C_InvoiceLine_ID"
CoreParamsKey.M_PRODUCT_ID     // "M_Product_ID"
CoreParamsKey.M_IN_OUT_ID      // "M_InOut_ID"
CoreParamsKey.M_IN_OUT_LINE_ID // "M_InOutLine_ID"
CoreParamsKey.C_ORDER_LINE_ID  // "C_Orderline_ID"
CoreParamsKey.C_DOC_TYPE_ID    // "C_DocType_ID"
```

Use `CoreParamsKey` for standard entity IDs. Create your own `ParamsCustom` enum for module-specific parameters.

---

## ConstantKey — Boolean String Flags

```java
ConstantKey.TRUE_STRING.getConstantKey()   // "Y"
ConstantKey.FALSE_STRING.getConstantKey()  // "N"
```

Use instead of hardcoded `"Y"` / `"N"` strings.

---

## Anti-Patterns

| Bad                                              | Good                                                    |
| ------------------------------------------------ | ------------------------------------------------------- |
| `json.getString("C_Order_ID")`                   | `CoreParamsKey.C_ORDER_ID.getStringInJson(json, true)`  |
| `json.has("key") ? json.getString("key") : null` | `ParamsCustom.MY_KEY.getStringInJson(json, false)`      |
| Hardcoded `"Y"` / `"N"`                          | `ConstantKey.TRUE_STRING.getConstantKey()`              |
| `json.getJSONObject("_params")`                  | `CoreParamsKey.PARAMS_KEY.getJsonObject(request, true)` |

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
