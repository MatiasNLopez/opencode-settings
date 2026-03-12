---
name: etendo-commons-messages
description: >
  Create and use type-safe AD_MESSAGE-based messages in Etendo modules via MessageUtilityInterface enum pattern.
  Trigger: When creating error/validation/info messages, AD_MESSAGE XML entries, Messages enum,
  MessageUtilityInterface, MSGTYPE, or when hardcoded strings need to be externalized to database messages.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Creating or throwing AD_MESSAGE-based error/warning/info messages in Java
- Hardcoded error/validation strings that should be externalized
- Creating new processes, handlers, or webhooks that need user-facing messages
- User asks for "mensajes", "AD_MESSAGE", "MessageUtilityInterface", or "Messages enum"

## Module Location

`modules/com.etendoerp.commons.utils/` — Java package: `com.etendoerp.commons.utils`

Interface: `com.etendoerp.commons.utils.interfaces.MessageUtilityInterface<E>`

---

## Process Flow

```
Identify messages → Determine module prefix + UUID → Generate UUIDs → Create AD_MESSAGE.xml → Create Messages enum → Update code
```

### 1. Identify Messages

Find all hardcoded strings that represent user-facing messages. Categorize by MSGTYPE:

| MSGTYPE | Meaning | Use case                                     |
| ------- | ------- | -------------------------------------------- |
| **E**   | Error   | Validation failures, not-found, unauthorized |
| **S**   | Success | Operation completed successfully             |
| **I**   | Info    | Informational messages                       |
| **W**   | Warning | Non-blocking warnings                        |

### 2. Determine Module Context

From the module being worked on, extract:

- **Module prefix**: e.g. `WPSCPHS`, `WPSPC`, `SMFCU` (from `AD_MODULE.AD_MODULE_ID` or existing entries)
- **Module ID**: 32-char hex UUID (from `AD_MODULE.xml` or existing `AD_MESSAGE.xml`)
- **Package**: e.g. `com.wps.pucara.customizationsphs`

### 3. Generate UUIDs

```bash
python3 -c "import uuid; [print(uuid.uuid4().hex.upper()) for _ in range(N)]"
```

---

## Critical Pattern: Messages Enum (MessageUtilityInterface)

**ALWAYS use this pattern instead of raw `OBMessageUtils.messageBD()` calls.**

### Step 1: Create the enum in your module

File: `modules/<module>/src/<package>/enums/Messages.java`

```java
package com.example.mymodule.enums;

import java.util.EnumMap;
import com.etendoerp.commons.utils.interfaces.MessageUtilityInterface;

public enum Messages implements MessageUtilityInterface<Messages> {

  /**
   * Type: E
   * ES: Producto debe tener vida util > 0 cuando el conjunto de atributos tiene fecha de garantia.
   * EN: Product must have shelf life > 0 when attribute set has guarantee date.
   */
  MY_PRODUCT_VALIDATION_ERROR,

  /**
   * Type: S
   * ES: Orden creada exitosamente: %s.
   * EN: Order created successfully: %s.
   */
  MY_ORDER_CREATED;

  private static final EnumMap<Messages, String> MESSAGE_KEYS =
      new EnumMap<>(Messages.class);

  static {
    MESSAGE_KEYS.put(MY_PRODUCT_VALIDATION_ERROR, "MY_ProductValidationError");
    MESSAGE_KEYS.put(MY_ORDER_CREATED, "MY_OrderCreated");
  }

  @Override
  public EnumMap<Messages, String> getKeysMap() {
    return MESSAGE_KEYS;
  }
}
```

### Step 2: Register in AD_MESSAGE.xml

File: `modules/<module>/src-db/database/sourcedata/AD_MESSAGE.xml`

**Entries MUST be ordered alphabetically by AD_MESSAGE_ID within the XML.**

```xml
<!--<UUID>--><AD_MESSAGE>
<!--<UUID>-->  <AD_MESSAGE_ID><![CDATA[<UUID>]]></AD_MESSAGE_ID>
<!--<UUID>-->  <AD_CLIENT_ID><![CDATA[0]]></AD_CLIENT_ID>
<!--<UUID>-->  <AD_ORG_ID><![CDATA[0]]></AD_ORG_ID>
<!--<UUID>-->  <ISACTIVE><![CDATA[Y]]></ISACTIVE>
<!--<UUID>-->  <VALUE><![CDATA[MY_ProductValidationError]]></VALUE>
<!--<UUID>-->  <MSGTEXT><![CDATA[Producto debe tener vida util mayor a cero.]]></MSGTEXT>
<!--<UUID>-->  <MSGTYPE><![CDATA[E]]></MSGTYPE>
<!--<UUID>-->  <AD_MODULE_ID><![CDATA[{YOUR_MODULE_UUID}]]></AD_MODULE_ID>
<!--<UUID>-->  <ISINCLUDEINI18N><![CDATA[N]]></ISINCLUDEINI18N>
<!--<UUID>--></AD_MESSAGE>
```

### Step 3: Use in Java code

```java
// Simple message (no params)
throw new OBException(Messages.MY_PRODUCT_VALIDATION_ERROR.getMessage());

// With parameters (%s placeholders in MSGTEXT)
throw new OBException(Messages.MY_ORDER_CREATED.getMessage(order.getDocumentNo()));

// Reverse lookup by AD_MESSAGE key
Messages msg = MessageUtilityInterface.fromName(Messages.class, "MY_ProductValidationError");

// Get the AD_MESSAGE key string
String key = Messages.MY_ORDER_CREATED.getName(); // "MY_OrderCreated"
```

---

## Naming Conventions

| Element       | Convention                    | Example                      |
| ------------- | ----------------------------- | ---------------------------- |
| VALUE (XML)   | `PREFIX_PascalCase`           | `WPSCPHS_ProductNotFound`    |
| Enum constant | `PREFIX_UPPER_SNAKE`          | `WPSCPHS_PRODUCT_NOT_FOUND`  |
| MSGTEXT       | Spanish text with `%s` params | `Producto no encontrado: %s` |
| Javadoc EN    | English translation           | `Product not found: %s`      |
| Parameters    | Use `%s` (not `%s1`)          | `Almacen no encontrado: %s`  |

## Key Rules

- Each enum constant Javadoc MUST include Type (E/W/S/I), ES text, and EN text
- The `static {}` block maps enum constants -> AD_MESSAGE VALUE keys
- `getMessage(Object... args)` resolves from DB, applies safe formatting, cleans leftover placeholders
- `getName()` returns the AD_MESSAGE key string
- Never catch exceptions from `getMessage()` — it uses `safeMessageBD()` internally
- Every enum constant MUST have a `MESSAGE_KEYS.put()` entry in the static block
- Use `%s` for parameters, NOT `%s1` (old Etendo style)

## FallbackMessage — Built-in Generic Messages

```java
FallbackMessage.SUCCESS_DEFAULT_MESSAGE.getMessage()  // "Success" from AD_Message
FallbackMessage.ERROR_DEFAULT_MESSAGE.getMessage()    // "Error" from AD_Message
FallbackMessage.SMFCU_ERROR.getMessage(detail)        // "ERROR: {detail}."
FallbackMessage.INVALID_ARGUMENTS.getMessage()        // "InvalidArguments" from AD_Message
```

Use `MessageUtility.isInStanceFallbackMessage(msg)` to check if a resolved message is a fallback.

## Quick Reference

| Field           | Value                                                                  |
| --------------- | ---------------------------------------------------------------------- |
| AD_CLIENT_ID    | Always `0`                                                             |
| AD_ORG_ID       | Always `0`                                                             |
| ISACTIVE        | Always `Y`                                                             |
| ISINCLUDEINI18N | Always `N`                                                             |
| XML ordering    | Alphabetical by AD_MESSAGE_ID                                          |
| getMessage()    | Resolves via `OBMessageUtils.messageBD()` + `FormatUtils.safeFormat()` |

## Anti-Patterns

| Bad                               | Good                                |
| --------------------------------- | ----------------------------------- |
| `OBMessageUtils.messageBD("key")` | `Messages.MY_CONSTANT.getMessage()` |
| `String.format(msg, args)`        | `FormatUtils.safeFormat(msg, args)` |
| Missing Javadoc on enum constants | Always include Type + ES + EN       |
| Using `%s1` placeholders          | Use `%s` only                       |

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
