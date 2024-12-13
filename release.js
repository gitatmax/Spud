import { exec } from 'child_process';
import { promisify } from 'util';
import { readFileSync, writeFileSync } from 'fs';

const execAsync = promisify(exec);

async function release(type = 'patch') {
  try {
    // Read current version from package.json
    const pkg = JSON.parse(readFileSync('./package.json', 'utf8'));
    const [major, minor, patch] = pkg.version.split('.').map(Number);
    
    // Calculate new version
    let newVersion;
    switch(type) {
      case 'major':
        newVersion = `${major + 1}.0.0`;
        break;
      case 'minor':
        newVersion = `${major}.${minor + 1}.0`;
        break;
      case 'patch':
      default:
        newVersion = `${major}.${minor}.${patch + 1}`;
    }

    // Update package.json
    pkg.version = newVersion;
    writeFileSync('./package.json', JSON.stringify(pkg, null, 2) + '\n');

    // Update spud.toc
    let tocContent = readFileSync('./spud.toc', 'utf8');
    tocContent = tocContent.replace(/## Version: .*/, `## Version: ${newVersion}`);
    writeFileSync('./spud.toc', tocContent);

    // Git commands
    await execAsync('git add package.json spud.toc');
    await execAsync(`git commit -m "chore: bump version to ${newVersion}"`);
    await execAsync(`git tag -a v${newVersion} -m "Release v${newVersion}"`);
    await execAsync('git push && git push --tags');

    console.log(`Successfully released version ${newVersion}`);
  } catch (error) {
    console.error('Release failed:', error.message);
    process.exit(1);
  }
}

// Allow running from command line
const type = process.argv[2];
if (type) {
  release(type);
}

export default release; 