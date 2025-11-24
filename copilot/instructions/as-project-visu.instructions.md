---
description: 'Guidelines for B&R MappView HMI development following BRDK standards'
applyTo: '**/*.{content,page,widget,binding,eventbinding,eventscript,theme,dialog,tmx}'
---

# B&R MappView Development Guidelines

You are an expert in B&R MappView development (Automation Studio 6.0+).
Follow these guidelines when generating code, bindings, and structures for MappView projects within the BRDK framework.

## General Instructions

- **Tool Version:** Use Automation Studio 6.0 or newer.
- **Goal:** Create maintainable, high-standard HMI projects with consistent structure and naming.
- **Theme:** Use the BRDK standard theme unless otherwise specified. Ensure all widgets use the default theme with additional styles defined in the theme file.

## Architecture & File Structure

### Package File Management (`Package.pkg`)
The `Package.pkg` file is the backbone of the Automation Studio project structure. It lists all files and sub-packages contained within a directory.
**CRITICAL:** Whenever you create, rename, or delete a file or folder, you **MUST** update the corresponding `Package.pkg` file.

**Example `Package.pkg`:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<?AutomationStudio FileVersion="4.9"?>
<Package xmlns="http://br-automation.co.at/AS/Package">
  <Objects>
    <Object Type="File">PageName.page</Object>
    <Object Type="File">PageName.content</Object>
    <Object Type="File">PageName.tmx</Object>
  </Objects>
</Package>
```

### Logical View
Organize the `Logical View` to separate common resources from specific page content, respecting the resolution folder structure.

```text
Logical View
└── mappView
    ├── Resources
    │   ├── Snippets
    │   └── Texts
    └── 16by9                   # Resolution Folder (e.g., 16by9, 16by10)
        ├── Dialogs             # Dedicated folder for Dialogs
        │   └── DialogName
        │       ├── DialogName.dialog
        │       ├── DialogName.content
        │       └── DialogName.tmx
        ├── Pages               # Dedicated folder for Pages
        │   └── PageName
        │       ├── PageName.page
        │       ├── PageName.content
        │       └── PageName.tmx
        ├── Resources
        └── Variables
```

### Configuration View (Physical View)
Mirror the Logical View structure in the `Physical View` under the active configuration.

```text
Physical View
└── <Config>
    └── <Hardware>
        └── mappView
            └── MainVisu        # Visualization Folder
                ├── PageName    # All bindings for the page go here
                │   ├── PageName.binding
                │   ├── PageName.eventbinding
                │   └── PageName.eventscript
                └── DialogName
                    ├── DialogName.binding
                    └── DialogName.eventbinding
```

## File Relationships & XML Structure

### Visualization Hierarchy
The MappView project is structured hierarchically. The `Resolution Folder` (e.g., `16by9`) represents a specific visualization scope (e.g., "MainVisu", "ServiceVisu").

1.  **Visualization (`.vis`)**: The root file. Defines the start page, themes, and lists all pages, contents, and binding sets used.
2.  **Layout (`.layout`)**: Defines the geometric areas (`Area`) where contents can be placed.
3.  **Page (`.page`)**: Assigns `Content` files to `Layout Areas`.
4.  **Content (`.content`)**: Contains the actual UI elements (`Widgets`).
5.  **Bindings (`.binding`, `.eventbinding`)**: Connect widgets to variables (data) or actions (events).

### XML Structure Examples

#### 1. Visualization (`.vis`)
Registers all resources.
```xml
<vdef:Visualization id="vis_1" ...>
  <StartPage pageRefId="Main" />
  <Pages>
    <Page refId="Main" />
  </Pages>
  <Contents>
    <Content refId="commonHeader" />
    <Content refId="Main" />
  </Contents>
  <BindingsSets>
    <BindingsSet refId="Main_binding" />
  </BindingsSets>
  <EventBindingsSets>
    <EventBindingsSet refId="Main_eventbinding" />
  </EventBindingsSets>
</vdef:Visualization>
```

#### 2. Layout (`.layout`)
Defines areas.
```xml
<ldef:Layout id="pageLayout" height="1080" width="1920" ...>
  <Areas>
    <Area id="AreaHeader" height="90" width="1920" left="0" top="0" />
    <Area id="AreaContent" height="990" width="1920" left="0" top="90" />
  </Areas>
</ldef:Layout>
```

#### 3. Page (`.page`)
Maps contents to layout areas.
```xml
<pdef:Page id="Main" layoutRefId="pageLayout" ...>
  <Assignments>
    <Assignment type="Content" baseContentRefId="commonHeader" areaRefId="AreaHeader" />
    <Assignment type="Content" baseContentRefId="Main" areaRefId="AreaContent" />
  </Assignments>
</pdef:Page>
```

#### 4. Content (`.content`)
Defines widgets.
```xml
<Content id="Main" ...>
  <Widgets>
    <Widget xsi:type="widgets.brease.Button" id="startBt" ... />
    <Widget xsi:type="widgets.brease.NumericOutput" id="speedNumOut" ... />
  </Widgets>
</Content>
```

#### 5. Binding (`.binding`)
Links widget properties to OPC UA variables or MpLinks.
```xml
<BindingsSet id="Alarm" ...>
  <Bindings>
    <Binding mode="oneWay">
      <Source xsi:type="mapp" refId="gAlarmXCore" attribute="link" />
      <Target xsi:type="brease" contentRefId="Alarm" widgetRefId="AlarmList1" attribute="mpLink" />
    </Binding>
  </Bindings>
</BindingsSet>
```

#### 6. Event Binding (`.eventbinding`)
Links widget events to actions.
```xml
<EventBindingSet id="commonHeader" ...>
  <Bindings>
    <EventBinding id="commonHeader.LoginInfo1.Click">
      <Source xsi:type="widgets.brease.LoginInfo.Event" contentRefId="commonHeader" widgetRefId="LoginInfo1" event="Click" />
      <EventHandler>
        <Action>
          <Target xsi:type="clientSystem.Action">
            <Method xsi:type="clientSystem.Action.OpenDialog" dialogId="login" autoClose="true" />
          </Target>
        </Action>
      </EventHandler>
    </EventBinding>
  </Bindings>
</EventBindingSet>
```

## Workflow: Adding UI Elements

### Adding a Widget (e.g., Button)
1.  **Edit `.content`**: Add the `<Widget>` element with a unique ID (suffix rule).
2.  **Edit `.binding`**: If the widget displays data, add a `<Binding>` entry.
3.  **Edit `.eventbinding`**: If the widget triggers an action, add an `<EventBinding>` entry.

### Adding a New Content
1.  **Create `.content`**: Define the new content file and add widgets.
2.  **Update `.page`**: Add an `<Assignment>` to place the content in a specific Layout Area.
3.  **Update `.vis`**: Add the `<Content refId="..." />` to the `<Contents>` list.

### Adding a New Page
1.  **Create `.page`**: Define the page and assign a Layout.
2.  **Create `.content`s**: Create the necessary content files.
3.  **Update `.page`**: Assign the contents to the layout areas.
4.  **Update `.vis`**:
    - Add `<Page refId="..." />` to `<Pages>`.
    - Add all new `<Content refId="..." />` entries to `<Contents>`.
    - Add `<BindingsSet refId="..." />` and `<EventBindingsSet refId="..." />` if created.

## Naming Conventions

### Pages & Contents
- **Pages:** Use descriptive names (e.g., `MainOverview`, `Settings`).
- **Contents:** Must use the page name as a prefix if the page has multiple contents.
- **Folders:** Match the page/dialog name.

### Widgets
- **Suffix Rule:** Always append a suffix describing the widget type to facilitate debugging in binding files.
  - `startBt` (Button)
  - `speedNumOut` (NumericOutput)
  - `tempNumIn` (NumericInput)
  - `statusTxt` (TextOutput)

### Bindings
- **Naming:** Bindings should automatically match the name of the content they are bound to.

## Best Practices & Features

### Event Scripts (Preferred)
- **Usage:** Use Event Scripts (`.eventscript`) instead of Event Bindings, Snippets, or Expressions whenever possible.
- **Reasoning:** They run on target (JavaScript), are easier to debug, and streamline the code.
- **Note:** Requires an extra license.

### Snippets & Expressions (Avoid)
- **Snippets:** Keep to a minimum. Use only for dynamic text updates or embedding OPC-UA variables in text if Event Scripts cannot be used.
- **Expressions:** Avoid. They run client-side and are difficult to debug. Logic should be handled in the PLC or Event Scripts.

### Session Variables
- **Usage:** Use only for small, internal HMI state (e.g., tab selection).
- **Warning:** Remember they are unique per client session. Shared state must be handled in the PLC.

### Dialogs & Messages
- **Dialogs:** Use for wizards, configurations, or non-critical information. Avoid distracting pop-ups.
- **Messages:** Avoid general use. Only use for critical confirmations (e.g., Safety Acknowledge, Critical Alarms).

## Widget Selection

### Preferred Widgets
- All [Base Widgets](https://help.br-automation.com/#/en/6/visualization/mappview/widgets/widgets.html)
- `Paper`
- `ProgressBar`
- `TabControl`
- `Table`
- `ToggleSwitch`

### Not Recommended
- `ContentCarousel`
- `FlyOut`

### Widget Classes (Performance)
- Be mindful of Widget Classes (A, B, C) relative to the target hardware (e.g., avoid Class C on T50 panels).

## Security & Configuration

### `config.mappview` Settings
- **Protocol:** `HTTP`
- **Max Clients:** At least `2` (1 local + 1 remote).
- **Startup User:** `Anonymous` token.
- **Diagnostics:** Enable the diagnostic page for debugging (set appropriate role).
- **Default Visualization:** Must be set (Default ID: `Visu`).

## Examples

### Widget Naming Example
```xml
<!-- Good: Suffix indicates type -->
<Widget xsi:type="widgets.brease.Button" id="startBt" ... />
<Widget xsi:type="widgets.brease.NumericOutput" id="currentSpeedNumOut" ... />

<!-- Bad: Ambiguous names -->
<Widget xsi:type="widgets.brease.Button" id="Button1" ... />
<Widget xsi:type="widgets.brease.NumericOutput" id="Value" ... />
```

### Event Script Example
```javascript
// Recommended: Handle logic in Event Script
function btnClickHandler(event) {
    var value = event.value;
    // Complex logic here
    return value * 2;
}
```
