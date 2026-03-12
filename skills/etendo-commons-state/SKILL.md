---
name: etendo-commons-state
description: >
  EntityStateUtils for Etendo EventHandler state management — read, compare, and mutate entity properties through the event API.
  Trigger: When writing EventHandlers that need to read/compare/mutate entity property state,
  use EntityStateUtils, getPropertyCurrentState, getPropertyPreviousState, hasPropertyChanged,
  or updatePropState in Etendo Java code.
license: Apache-2.0
metadata:
  author: gentleman-programming
  version: "1.0"
---

## When to Use

- Writing EventHandlers that need to read current/previous entity property state
- Comparing property values to detect changes (hasPropertyChanged)
- Mutating entity state through the event API (updatePropState)
- Checking event type (new vs update)

## Module Location

`modules/com.etendoerp.commons.utils/` — Java package: `com.etendoerp.commons.utils`

Class: `com.etendoerp.commons.utils.utilities.EntityStateUtils`

---

## Critical Pattern: EventHandler State (EntityStateUtils)

**Use in EventHandlers to read/compare/mutate property state through the event API.**

### Basic Usage

```java
import com.etendoerp.commons.utils.utilities.EntityStateUtils;

public class MyEventHandler extends EntityPersistenceEventObserver {

  public void onUpdate(@Observes EntityUpdateEvent event) {
    if (!isValidEvent(event)) return;

    EntityStateUtils state = new EntityStateUtils(event, Product.class);

    // Read current state (works for both new and update events)
    String name = (String) state.getPropertyCurrentState(Product.PROPERTY_NAME);

    // Read previous state (returns null for new events)
    String oldName = (String) state.getPropertyPreviousState(Product.PROPERTY_NAME);

    // Check if a property changed
    if (state.hasPropertyChanged(Product.PROPERTY_PURCHASE)) {
      // React to change
    }

    // Mutate state (only works on save/update events)
    state.updatePropState(Product.PROPERTY_DESCRIPTION, "Updated by handler");

    // Mutate only if changed
    state.updatePropStateForce(Product.PROPERTY_NAME, "Forced value");

    // Check event type
    if (state.isNewEvent()) { /* ... */ }
    if (state.isEventUpdate()) { /* ... */ }
  }
}
```

---

## Key Methods

| Method                                  | Description                        |
| --------------------------------------- | ---------------------------------- |
| `getPropertyCurrentState(propName)`     | Current value from the event       |
| `getPropertyPreviousState(propName)`    | Previous value (null on new)       |
| `hasPropertyChanged(propName)`          | Compares previous vs current       |
| `updatePropState(propName, value)`      | Sets current state                 |
| `updatePropStateForce(propName, value)` | Sets only if changed               |
| `isNewEvent()`                          | Returns true for EntityNewEvent    |
| `isEventUpdate()`                       | Returns true for EntityUpdateEvent |
| `getProperty(propName)`                 | Get the Property object            |

---

## Complete EventHandler Example

```java
package com.example.mymodule.eventHandler;

import javax.enterprise.event.Observes;

import org.openbravo.base.exception.OBException;
import org.openbravo.base.model.Entity;
import org.openbravo.base.model.ModelProvider;
import org.openbravo.client.kernel.event.EntityNewEvent;
import org.openbravo.client.kernel.event.EntityPersistenceEvent;
import org.openbravo.client.kernel.event.EntityPersistenceEventObserver;
import org.openbravo.client.kernel.event.EntityUpdateEvent;
import org.openbravo.model.common.plm.Product;

import com.etendoerp.commons.utils.enums.ResponseType;
import com.etendoerp.commons.utils.utilities.EntityStateUtils;
import com.etendoerp.commons.utils.utilities.LoggerUtils;
import com.example.mymodule.enums.Messages;

/**
 * Validates business rule X on {@link Product} save/update.
 */
public class MyValidationEventHandler extends EntityPersistenceEventObserver {
  private static Entity[] entities = {
      ModelProvider.getInstance().getEntity(Product.ENTITY_NAME) };
  private static final LoggerUtils LOG = new LoggerUtils(MyValidationEventHandler.class);

  @Override
  protected Entity[] getObservedEntities() {
    return entities;
  }

  public void onSave(@Observes EntityNewEvent event) {
    if (!isValidEvent(event)) return;
    validate(event);
  }

  public void onUpdate(@Observes EntityUpdateEvent event) {
    if (!isValidEvent(event)) return;
    validate(event);
  }

  private void validate(EntityPersistenceEvent event) {
    EntityStateUtils state = new EntityStateUtils(event, Product.class);
    Product product = (Product) event.getTargetInstance();

    // Read properties from event state
    Boolean active = (Boolean) state.getPropertyCurrentState(Product.PROPERTY_ACTIVE);
    if (Boolean.FALSE.equals(active)) {
      return;
    }

    // Your validation logic
    if (someConditionFails(product, state)) {
      LOG.loggerMessage(ResponseType.ERROR, Messages.MY_VALIDATION_ERROR,
          product.getSearchKey());
      throw new OBException(Messages.MY_VALIDATION_ERROR.getMessage());
    }
  }
}
```

**Note**: This example also uses `LoggerUtils` (from `etendo-commons-response`) and `Messages` (from `etendo-commons-messages`). Load those skills if you need their full patterns.

---

## Anti-Patterns

| Bad                                          | Good                                                           |
| -------------------------------------------- | -------------------------------------------------------------- |
| `event.getCurrentState(prop)`                | `stateUtils.getPropertyCurrentState(propName)`                 |
| Manual index-based state array access        | Use `EntityStateUtils` property name resolution                |
| Casting without null check on previous state | `getPropertyPreviousState()` safely returns null on new events |

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
