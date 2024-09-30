# Vizbee Roku Demo App
Vizbee Roku Demo App demonstrates how to integrate Vizbee casting functionality into the Roku app.

## Prerequisites

This repository contains a Roku BrightScript project set up for development using Visual Studio Code (VSCode) and the vscode-brightscript-language extension.

Before you begin, ensure you have the following installed:

- [Visual Studio Code](https://code.visualstudio.com/)
- [vscode-brightscript-language](https://marketplace.visualstudio.com/items?itemName=RokuCommunity.brightscript) extension for VSCode
- [Roku Device](https://www.roku.com/products/players) for testing

## Setup

1. Clone this repository:
   ```
   git clone git@github.com:ClaspTV/vizbee-roku-demo-app.git -b homesso-integration
   cd vizbee-roku-demo-app
   ```

2. Open the project in VSCode:
   ```
   code .
   ```

3. Install the vscode-brightscript-language extension if you haven't already:
   - Open the Extensions view in VSCode (Ctrl+Shift+X)
   - Search for "brightscript"
   - Install the "BrightScript Language" extension by Roku Community

4. Configure your Roku device:
   - Create a `.env` file in your project root
   - Add the following configuration, replacing `YOUR_ROKU_IP` with your Roku device's IP address and `YOUR_ROKU_PASSWORD` with your Roku device's dev password:

     ```text
     # .env

     #the IP address of the roku device
     ROKU_IP=YOUR_ROKU_IP
     #the password for the roku
     ROKU_PASSWORD=YOUR_ROKU_PASSWORD
     ```

## Project Structure

```
vizbee-roku-demo-app/
├── source/
│   ├── main.brs
│── components/
│   └── SomeComponent.brs
├── images/
├── fonts/
├── manifest
├── .env
└── .vscode/
    └── launch.json
```

- `source/`: Contains the BrightScript source files
- `components/`: Contains the scene graph components files
- `images/`: Contains the image assets
- `fonts/`: Contains the font files
- `manifest`: The channel manifest file
- `.env`: Contains Roku device info i.e. Roku IP and Roku dev password
- `.vscode/`: VSCode-specific settings and launch configurations

## Integration Steps for your Roku app

Refer to the [code snippets](https://console.vizbee.tv/app/vzb2000001/develop/guides/roku-sg-snippets) and [developer guide](https://console.vizbee.tv/app/vzb2000001/develop/guides/roku-sg-sdk) for detailed steps regarding integration.

Also, look for the block comments with text "[BEGIN] Vizbee Integration" and "[END] Vizbee Integration" in the code for an easy understanding of the integration with respect to this demo app.

### Manifest Setup
1. Update the `dial_title` in the manifest file with the DIAL name for your Roku app. This should be the same DIAL name configured in Vizbee Continuity configuration in the Vizbee console.
2. Update the `vizbee_app_id` with the Vizbee provided appId for your Roku app.

## Launch and Run

1. Use the VSCode debugger to launch the app on the Roku device:
   - Press F5 or select "Run and Debug" from the sidebar
   - Choose "BrightScript Debug: Launch" from the dropdown menu

2. The extension will package your app, deploy it to your Roku device, and attach the debugger.

## Troubleshooting

If you encounter any issues, refer to the [troubleshooting guide](https://console.vizbee.tv/app/vzb2000001/develop/guides/roku-troubleshooting-snippets).

## Support

For any questions or support, please contact support@vizbee.tv or visit our [documentation](https://console.vizbee.tv/app/vzb2000001/develop/guides/roku-sg-sdk)