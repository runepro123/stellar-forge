
const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs');
const { autoUpdater } = require('electron-updater');

autoUpdater.autoDownload = true;
autoUpdater.autoInstallOnAppQuit = true;

let mainWindow;

// Define custom save path: Documents/devcitystudio/Stellar Forge/save.json
// This ensures the specific directory structure requested by the user.
const saveDir = path.join(app.getPath('documents'), 'devcitystudio', 'Stellar Forge');
const savePath = path.join(saveDir, 'save.json');

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 720,
    minWidth: 800,
    minHeight: 600,
    title: "Stellar Forge Demo",
    backgroundColor: '#0f172a',
    autoHideMenuBar: true,
    show: false,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
      webSecurity: false 
    }
  });

  const indexPath = path.join(__dirname, 'index.html');
  mainWindow.loadFile(indexPath).catch(err => {
    console.error("Failed to load index.html:", err);
  });

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
    if (app.isPackaged) {
      autoUpdater.checkForUpdatesAndNotify();
    }
  });

  mainWindow.on('closed', function () {
    mainWindow = null;
  });
}

app.on('ready', createWindow);

app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') app.quit();
});

app.on('activate', function () {
  if (mainWindow === null) createWindow();
});

// Save/Load IPC Handlers
ipcMain.handle('save-game', async (event, data) => {
  try {
    if (!fs.existsSync(saveDir)) {
      fs.mkdirSync(saveDir, { recursive: true });
    }
    fs.writeFileSync(savePath, JSON.stringify(data, null, 2));
    return { success: true, path: savePath };
  } catch (error) {
    console.error('Failed to save game:', error);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('load-game', async () => {
  try {
    if (fs.existsSync(savePath)) {
      const data = fs.readFileSync(savePath, 'utf8');
      return JSON.parse(data);
    }
    return null;
  } catch (error) {
    console.error('Failed to load game:', error);
    return null;
  }
});

// Auto Updater Events
autoUpdater.on('update-available', (info) => {
  if (mainWindow) mainWindow.webContents.send('update_status', { status: 'available', info });
});
autoUpdater.on('update-not-available', (info) => {
  if (mainWindow) mainWindow.webContents.send('update_status', { status: 'none', info });
});
autoUpdater.on('error', (err) => {
  if (mainWindow) mainWindow.webContents.send('update_status', { status: 'error', error: err.message });
});
autoUpdater.on('download-progress', (progressObj) => {
  if (mainWindow) mainWindow.webContents.send('update_progress', progressObj.percent);
});
autoUpdater.on('update-downloaded', (info) => {
  if (mainWindow) mainWindow.webContents.send('update_status', { status: 'downloaded', info });
});

ipcMain.on('restart_app', () => {
  autoUpdater.quitAndInstall();
});
ipcMain.on('check_for_updates', () => {
  autoUpdater.checkForUpdatesAndNotify();
});
