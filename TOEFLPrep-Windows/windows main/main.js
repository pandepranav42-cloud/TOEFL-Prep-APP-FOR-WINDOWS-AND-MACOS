// main.js — Electron main process
//
// Creates the app window, loads the bundled index.html, and remembers window
// size and position between launches. The renderer (index.html) is your
// existing web app; it already handles its own state via localStorage.

const { app, BrowserWindow, shell, Menu } = require('electron');
const path = require('node:path');
const fs = require('node:fs');

// Where to persist window bounds so the app opens where you last left it.
function boundsFile() {
  return path.join(app.getPath('userData'), 'window-bounds.json');
}
function loadBounds() {
  try {
    return JSON.parse(fs.readFileSync(boundsFile(), 'utf8'));
  } catch { return { width: 1240, height: 820 }; }
}
function saveBounds(win) {
  try {
    fs.writeFileSync(boundsFile(), JSON.stringify(win.getBounds()));
  } catch (e) { console.error('saveBounds:', e); }
}

let mainWindow = null;

function createWindow() {
  const b = loadBounds();
  mainWindow = new BrowserWindow({
    width:  b.width  || 1240,
    height: b.height || 820,
    x: b.x,
    y: b.y,
    minWidth: 900,
    minHeight: 620,
    title: 'TOEFL Prep',
    backgroundColor: '#05070F',        // matches the dark themes' --void
    icon: path.join(__dirname, 'build', process.platform === 'win32' ? 'icon.ico' : 'icon.png'),
    autoHideMenuBar: true,             // hide the classic menu strip on Windows
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      // Renderer doesn't need Node. Everything lives inside index.html.
      preload: undefined
    }
  });

  mainWindow.loadFile(path.join(__dirname, 'index.html'));

  // External links open in the user's default browser, not inside our window.
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  mainWindow.on('close', () => saveBounds(mainWindow));
  mainWindow.on('closed', () => { mainWindow = null; });
}

// A minimal menu — File → Quit, View → Reload/DevTools/Full Screen.
function buildMenu() {
  const template = [
    {
      label: 'File',
      submenu: [{ role: 'quit' }]
    },
    {
      label: 'Edit',
      submenu: [
        { role: 'undo' }, { role: 'redo' }, { type: 'separator' },
        { role: 'cut' }, { role: 'copy' }, { role: 'paste' },
        { role: 'selectAll' }
      ]
    },
    {
      label: 'View',
      submenu: [
        { role: 'reload' },
        { role: 'forceReload' },
        { role: 'toggleDevTools' },
        { type: 'separator' },
        { role: 'resetZoom' },
        { role: 'zoomIn' },
        { role: 'zoomOut' },
        { type: 'separator' },
        { role: 'togglefullscreen' }
      ]
    },
    {
      label: 'Window',
      submenu: [{ role: 'minimize' }, { role: 'close' }]
    }
  ];
  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

app.whenReady().then(() => {
  buildMenu();
  createWindow();

  // On macOS keep the app alive when all windows close (dock behaviour).
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
