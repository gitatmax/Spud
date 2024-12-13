import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';

const execPromise = promisify(exec);

const sourcePath = path.normalize('/Volumes/External/Local Projects/Spud');
const destinationPath = path.normalize('/Volumes/External/World of Warcraft/_retail_/Interface/AddOns/Spud');

async function copyAddon() {
  try {
    console.log('Starting copy process...');
    
    // First, ensure the destination directory exists
    await execPromise(`mkdir -p "${destinationPath}"`);
    
    // Copy only spud.lua and spud.toc
    await execPromise(`cp -v "${sourcePath}/spud.lua" "${sourcePath}/spud.toc" "${destinationPath}/"`);
    console.log('Spud addon files have been copied to the specified location.');
  } catch (error) {
    console.error('Error copying addon:', error.message);
  }
}

copyAddon();

// Define a command to run the copy function
export default {
  copy: copyAddon,
};
