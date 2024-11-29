const readline = require('readline');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// File path for storing the commands
const commandsFilePath = path.join(__dirname, 'commands.json');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Load the saved commands from the file or initialize an empty list
let commands = loadCommands();

// Function to load commands from the file
function loadCommands() {
  if (fs.existsSync(commandsFilePath)) {
    const data = fs.readFileSync(commandsFilePath, 'utf8');
    return JSON.parse(data);
  } else {
    return []; // If no file, return an empty list
  }
}

// Function to save commands to the file
function saveCommands() {
  fs.writeFileSync(commandsFilePath, JSON.stringify(commands, null, 2), 'utf8');
}

// Function to display the menu options
function displayMenu() {
  console.log("\nOptions:");
  console.log("1. Add Command");
  console.log("2. View Commands");
  console.log("3. Exit");
}

// Function to handle user commands
function handleCommand(command) {
  if (command === "1" || command.toLowerCase() === "add command") {
    rl.question("\nEnter the name of the new command: ", (newCommand) => {
      // Add the new command to the list
      commands.push({
        name: newCommand,
        action: () => {
          // Run the command in the same terminal
          runInSameTerminal(newCommand);
        }
      });

      // Save the commands to the file
      saveCommands();
      console.log(`\nCommand '${newCommand}' added successfully!`);
      promptUser(); // Keep asking for input
    });
    return;  // Prevent further code execution until command is added
  } else if (command === "2" || command.toLowerCase() === "view commands") {
    if (commands.length === 0) {
      console.log("\nNo commands added yet.");
      promptUser(); // Show the main menu again
    } else {
      console.log("\nAvailable Commands:");
      commands.forEach((cmd, index) => {
        console.log(`${index + 1}. ${cmd.name}`);
      });

      rl.question("\nChoose a command number to execute: ", (commandNumber) => {
        const index = parseInt(commandNumber) - 1;
        if (index >= 0 && index < commands.length) {
          // Execute the selected command
          const selectedCommand = commands[index];
          runInSameTerminal(selectedCommand.name);
        } else {
          console.log("\nInvalid command number.");
          promptUser(); // Go back to main menu if invalid
        }
      });
    }
    return;
  } else if (command === "3" || command.toLowerCase() === "exit") {
    console.log("Exiting...");
    rl.close();
    return;
  } else {
    console.log("\nInvalid command. Please choose a valid option.");
    promptUser(); // Show the main menu again
  }
}

// Function to run the command in the same terminal
function runInSameTerminal(command) {
  let shellProfile = '~/.bashrc'; // Default shell profile for Bash
  if (process.env.SHELL.includes('zsh')) {
    shellProfile = '~/.zshrc'; // Use zsh profile if using Zsh
  }

  // Construct the command to source the profile and run the user command
  const fullCommand = `. ${shellProfile} && ${command}`;

  console.log(`Running command: ${fullCommand}`);

  // Open a new interactive shell to load the environment and run the command
  let terminalCommand;
  let args = [];
  
  if (process.platform === 'linux') {
    terminalCommand = 'gnome-terminal'; // For GNOME-based systems
    args = ['--', 'bash', '-i', '-c', `${fullCommand}; exec bash`]; // `-i` makes bash interactive, `exec bash` keeps it open
  } else if (process.platform === 'darwin') {
    terminalCommand = 'osascript';
    args = [`-e`, `tell application "Terminal" to do script "source ~/.zshrc; ${command}; exec bash"`]; // For macOS
  } else if (process.platform === 'win32') {
    terminalCommand = 'cmd.exe';
    args = ['/K', command]; // '/K' keeps the CMD window open
  } else {
    console.log("Unsupported platform.");
    return;
  }

  // Spawn a new terminal with the given command (and ensure it remains open)
  const terminal = spawn(terminalCommand, args, { stdio: 'inherit' });

  terminal.on('error', (err) => {
    console.error(`Error: ${err.message}`);
  });

  terminal.on('exit', (code) => {
    console.log(`Terminal process exited with code ${code}. Returning to the main menu.`);
    promptUser(); // Return to main menu once terminal is closed
  });

  console.log(`Running '${command}' in a new terminal...`);
}

// Function to prompt user for input
function promptUser() {
  displayMenu(); // Display options after each action
  rl.question("Choose an option (1/2/3 or 'add command'/'view commands'/'exit'): ", (input) => {
    handleCommand(input);
  });
}

// Start the prompt
promptUser();
