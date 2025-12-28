# Scratchify Blox 2 [TO BE FIXED]

A Roblox Studio plugin that brings block-based programming to Roblox, inspired by Scratch. This tool allows developers to create scripts visually using drag-and-drop blocks, making programming more accessible and intuitive.

## Features

- **Block-Based Editor**: Create scripts by dragging and connecting blocks instead of writing code.
- **Block Library**: A comprehensive library of blocks covering categories like Motion, Looks, Sound, Events, Controls, Sensing, Operators, and Variables.
- **Variable Management**: Easily create and manage variables within the editor.
- **UI Manager**: Intuitive user interface for editing and organizing blocks.
- **Data Persistence**: Save and load block configurations.
- **Auto-Update**: Built-in update mechanism for the plugin.

## Disclaimer

**Important Notice:** I (@trmz.dev roblox) am currently too busy to actively work on this project. I am aware of many issues and bugs that exist in the codebase. Contributions are welcome, but please be patient with responses and updates.

## Installation

1. Download the plugin from here (i disabled marketplace for now).
2. Open Roblox Studio.
3. Go to the **Plugins** tab and click **Manage Plugins**.
4. Click **Install** and select the downloaded plugin file.
5. The plugin will appear in your toolbar as "Editor".

## Usage

1. Open a Roblox place in Studio.
2. Click the "Editor" button in the toolbar to open the Scratchify Blox 2 interface.
3. Drag blocks from the sidebar into the canvas.
4. Connect blocks to form scripts.
5. Use the variable maker to create custom variables.
6. Export or inject the generated code into your scripts.

## Project Structure

- `main.legacy.luau`: Main plugin entry point.
- `BlocksFactory/`: Handles block creation and management.
- `UIManager/`: Manages the user interface components.
- `DataManager/`: Handles data persistence and loading.
- `VariableManager/`: Manages variables.
- `Utils/`: Utility modules like auto-update and environment management.
- `Constants/`: Project constants.

## Contributing

As the maintainer is currently unavailable, contributions are appreciated. Please fork the repository, make your changes, and submit a pull request. Be aware that review and merging may take time.

## License

This project is licensed under the MIT License.
