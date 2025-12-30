# Noodlelet Setup Instructions

## 1. Project Structure
The code has been generated with the following structure:
- **Noodlelet/Models**: Contains `LogEntry.swift` (Data Model).
- **Noodlelet/Store**: Contains `LogStore.swift` (Main App Data Logic).
- **Noodlelet/Views**: Contains SwiftUI Views (`ContentView`, `LiveFeedView`, `SearchView`, `DayView`).
- **Noodlelet/Shared**: Contains `LogWriter.swift` (Helper for Extension).
- **NoodleletBroadcast**: Contains `SampleHandler.swift` and `Info.plist` for the Broadcast Upload Extension.

## 2. Xcode Configuration Steps
Since the project file (`project.pbxproj`) cannot be fully automated for new targets in this environment, please follow these steps to finish setting up the app:

### A. Add Main App Files
1. Open `Noodlelet.xcodeproj` in Xcode.
2. If the files in `Models`, `Store`, `Views`, and `Shared` are not visible in the Project Navigator:
   - Right-click the `Noodlelet` folder in Xcode.
   - Select "Add Files to 'Noodlelet'...".
   - Select the `Models`, `Store`, `Views`, and `Shared` folders.
   - Ensure **"Create groups"** is selected.
   - Ensure the **"Noodlelet"** target is checked.
   - Click **Add**.

### B. Create Broadcast Upload Extension Target
1. In Xcode, go to **File > New > Target...**.
2. Select **Broadcast Upload Extension**.
3. Name it `NoodleletBroadcast`.
4. **Uncheck** "Include UI Extension" (we only need the Upload Extension for background processing).
5. Click **Finish**.
6. If asked to activate the scheme, click **Activate**.

### C. Configure Extension Files
1. Delete the default `SampleHandler.swift` that Xcode created in the `NoodleletBroadcast` group.
2. Add the provided files:
   - Right-click the `NoodleletBroadcast` group.
   - Select "Add Files to 'Noodlelet'...".
   - Navigate to the `NoodleletBroadcast` folder on disk and select `SampleHandler.swift`.
   - Ensure the **"NoodleletBroadcast"** target is checked.
3. **Important: Share Code**
   - We need to share `LogEntry.swift` and `LogWriter.swift` with the extension.
   - Select `Noodlelet/Models/LogEntry.swift` in the Project Navigator.
   - In the **File Inspector** (Right panel), under **Target Membership**, check **NoodleletBroadcast**.
   - Select `Noodlelet/Shared/LogWriter.swift`.
   - In the **File Inspector**, check **NoodleletBroadcast**.

### D. Configure App Groups (Crucial for Data Sharing)
1. Select the project root in the Navigator.
2. Select the **Noodlelet** (Main App) target.
3. Go to **Signing & Capabilities**.
4. Click **+ Capability** and search for **App Groups**.
5. Add a new App Group ID: `group.noodlelet` (or your own unique ID).
6. Select the **NoodleletBroadcast** target.
7. Go to **Signing & Capabilities**.
8. Click **+ Capability** and search for **App Groups**.
9. Select the **same** App Group ID (`group.noodlelet`).
   - *Note: If you change the ID, update `appGroupId` in `LogStore.swift` and `LogWriter.swift`.*

## 3. How to Run
1. Build and Run the **Noodlelet** scheme on a **real iOS device** (ReplayKit Broadcasts often fail on Simulators).
2. The app will launch showing the "Live Feed".
3. To start logging:
   - Go to Control Center on your device.
   - Long-press the **Screen Recording** button.
   - Select **Noodlelet** from the list.
   - Tap **Start Broadcast**.
4. Navigate around your phone. The extension will capture text snippets every ~3 seconds.
5. Return to the Noodlelet app to see your log entries appear in real-time!
