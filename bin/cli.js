#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Colors for terminal formatting
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  red: '\x1b[31m',
};

function log(msg, color = colors.reset) {
  console.log(`${color}${msg}${colors.reset}`);
}

function printUsage() {
  log('\n🚀 Hermes Custom Base Installer CLI', colors.bright + colors.cyan);
  console.log(`
Usage:
  npx base-hermes [command] [options]

Commands:
  install, init     Copies the custom Hermes base installer files to your project folder
  help, -h, --help  Display this help message

Options:
  -f, --force       Force copy files and overwrite if they already exist
  -d, --dir <path>  Specify a custom target directory (defaults to current directory)
  `);
}

// Simple recursive directory copy helper
function copyRecursiveSync(src, dest, force = false) {
  const exists = fs.existsSync(src);
  const stats = exists && fs.statSync(src);
  const isDirectory = exists && stats.isDirectory();

  if (isDirectory) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    fs.readdirSync(src).forEach((childItemName) => {
      // Exclude bin directory, package files, and git repository files
      if (
        childItemName === 'bin' ||
        childItemName === 'package.json' ||
        childItemName === 'package-lock.json' ||
        childItemName === '.git' ||
        childItemName === 'node_modules'
      ) {
        return;
      }
      copyRecursiveSync(path.join(src, childItemName), path.join(dest, childItemName), force);
    });
  } else {
    // If it's a file
    if (fs.existsSync(dest) && !force) {
      log(`⚠️  Skipped existing file: ${path.relative(process.cwd(), dest)} (use --force or -f to overwrite)`, colors.yellow);
      return;
    }
    
    // Copy the file
    fs.copyFileSync(src, dest);
    log(`✅ Copied: ${path.relative(process.cwd(), dest)}`, colors.green);
    
    // If it's a shell script, make sure it has execute permissions
    if (src.endsWith('.sh') || dest.endsWith('.sh')) {
      try {
        fs.chmodSync(dest, 0o755);
        log(`📂 Set executable permissions (chmod +x) on ${path.basename(dest)}`, colors.cyan);
      } catch (err) {
        log(`⚠️  Failed to set executable permissions on ${path.basename(dest)}: ${err.message}`, colors.yellow);
      }
    }
  }
}

function main() {
  const args = process.argv.slice(2);
  
  if (args.includes('--help') || args.includes('-h') || args.includes('help')) {
    printUsage();
    process.exit(0);
  }

  let force = args.includes('--force') || args.includes('-f');
  let targetDirIndex = args.indexOf('--dir');
  if (targetDirIndex === -1) targetDirIndex = args.indexOf('-d');
  
  let targetDir = process.cwd();
  if (targetDirIndex !== -1 && args[targetDirIndex + 1]) {
    targetDir = path.resolve(process.cwd(), args[targetDirIndex + 1]);
  }

  // Parse command (default is install)
  const commands = ['install', 'init', 'help'];
  const command = args.find(arg => commands.includes(arg)) || 'install';

  if (command === 'help') {
    printUsage();
    process.exit(0);
  }

  log(`\n📦 Initializing Hermes Custom Base Installer...`, colors.bright + colors.blue);
  log(`📂 Target directory: ${targetDir}`, colors.cyan);

  // Locate the template files (source root of this npm package)
  const srcDir = path.resolve(__dirname, '..');

  // Verify srcDir has the files
  if (!fs.existsSync(path.join(srcDir, 'Dockerfile'))) {
    log(`❌ Error: Source directory does not contain Dockerfile.`, colors.red);
    process.exit(1);
  }

  // Create target directory if it doesn't exist
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
  }

  try {
    // Copy the installer files to targetDir
    const filesToCopy = [
      'Dockerfile',
      'docker-compose.yml',
      '.env.example',
      'setup-telegram.sh',
      'gateway_run.py',
      'scheduler.py',
      'telegram.py',
      'web_server.py',
      'README.md',
      'docs'
    ];

    filesToCopy.forEach((file) => {
      const srcPath = path.join(srcDir, file);
      const destPath = path.join(targetDir, file);
      if (fs.existsSync(srcPath)) {
        copyRecursiveSync(srcPath, destPath, force);
      }
    });

    log(`\n🎉 Installation completed successfully!`, colors.bright + colors.green);
    
    const relativeTarget = path.relative(process.cwd(), targetDir);
    if (relativeTarget) {
      log(`👉 Next steps:\n   1. cd ${relativeTarget}\n   2. Configure your environment variables (.env)\n   3. Run setup-telegram.sh\n   4. Start services using 'docker compose up -d'`, colors.bright);
    } else {
      log(`👉 Next steps:\n   1. Configure your environment variables (.env)\n   2. Run setup-telegram.sh\n   3. Start services using 'docker compose up -d'`, colors.bright);
    }
  } catch (err) {
    log(`\n❌ Error during installation: ${err.message}`, colors.red);
    process.exit(1);
  }
}

main();
