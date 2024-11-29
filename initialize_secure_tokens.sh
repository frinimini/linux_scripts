#!/bin/bash

# Set up variables
BASE_DIR="secure_tokens_project"
SCRIPT_FILE="$BASE_DIR/secureTokens.js"
TOKENS_FILE="$BASE_DIR/tokens.json"

# Create the directory
mkdir -p "$BASE_DIR"
echo "Created directory: $BASE_DIR"

# Create secureTokens.js script
cat <<EOL > "$SCRIPT_FILE"
// secureTokens.js
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const readline = require('readline');

// Path to store the encrypted tokens
const tokensFilePath = path.join(__dirname, 'tokens.json');

// Encryption/Decryption key and algorithm (This should be securely stored and not hardcoded in production)
const SECRET_KEY = 'your_secret_key';  // Make sure it's 32 bytes for aes-256-ctr
const ALGORITHM = 'aes-256-ctr';  // The algorithm used for encryption

// Ensure the SECRET_KEY is 32 bytes by hashing it
const keyBuffer = crypto.createHash('sha256').update(SECRET_KEY).digest(); // SHA-256 hashes it to 32 bytes

// Initialize readline interface for user input
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

// Function to encrypt a token using createCipheriv
function encryptToken(token) {
    const iv = crypto.randomBytes(16);  // Generate a random initialization vector (IV)
    const cipher = crypto.createCipheriv(ALGORITHM, keyBuffer, iv);
    let encrypted = cipher.update(token, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return { encryptedToken: encrypted, iv: iv.toString('hex') }; // Return both encrypted token and IV
}

// Function to decrypt a token using createDecipheriv
function decryptToken(encryptedToken, iv) {
    console.log('Decrypting with IV:', iv);  // Log the IV being used
    if (!iv) {
        throw new Error('Invalid IV');
    }

    const ivBuffer = Buffer.from(iv, 'hex');  // Convert IV from hex back to buffer
    const decipher = crypto.createDecipheriv(ALGORITHM, keyBuffer, ivBuffer);
    let decrypted = decipher.update(encryptedToken, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
}

// Function to read tokens from file (or initialize if not present)
function loadTokens() {
    if (!fs.existsSync(tokensFilePath)) {
        fs.writeFileSync(tokensFilePath, JSON.stringify({}));
    }
    return JSON.parse(fs.readFileSync(tokensFilePath, 'utf8'));
}

// Function to save tokens to file
function saveTokens(tokens) {
    fs.writeFileSync(tokensFilePath, JSON.stringify(tokens, null, 2));
}

// Function to ask a question and get user input
function askQuestion(query) {
    return new Promise(resolve => rl.question(query, resolve));
}

// Function to store a new token (encrypted)
async function storeToken() {
    const tokens = loadTokens();

    const name = await askQuestion('Enter token name: ');
    const token = await askQuestion('Enter token: ');

    // Encrypt the token before storing
    const { encryptedToken, iv } = encryptToken(token);

    // Store both the encrypted token and IV
    tokens[name] = { encryptedToken, iv };  
    saveTokens(tokens);

    console.log('Token stored securely.');
    rl.close();
}

// Function to view stored tokens (decrypted)
async function viewTokens() {
    const tokens = loadTokens();

    if (Object.keys(tokens).length === 0) {
        console.log('No tokens stored.');
        rl.close();
        return;
    }

    console.log('Available tokens:');
    const tokenNames = Object.keys(tokens);

    tokenNames.forEach((name, index) => {
        console.log(`${index + 1}. ${name}`);
    });

    const choice = await askQuestion('Select a token by number: ');
    const selectedName = tokenNames[parseInt(choice) - 1];

    if (selectedName) {
        const { encryptedToken, iv } = tokens[selectedName];
        console.log('Retrieved IV:', iv);  // Log the IV being retrieved

        try {
            const decryptedToken = decryptToken(encryptedToken, iv);
            console.log(`Token for ${selectedName}: ${decryptedToken}`);
        } catch (error) {
            console.log('Error decrypting token:', error);
        }
    } else {
        console.log('Invalid choice.');
    }

    rl.close();
}

// Function to delete a stored token
async function deleteToken() {
    const tokens = loadTokens();

    if (Object.keys(tokens).length === 0) {
        console.log('No tokens to delete.');
        rl.close();
        return;
    }

    console.log('Available tokens to delete:');
    const tokenNames = Object.keys(tokens);

    tokenNames.forEach((name, index) => {
        console.log(`${index + 1}. ${name}`);
    });

    const choice = await askQuestion('Select a token to delete by number: ');
    const selectedName = tokenNames[parseInt(choice) - 1];

    if (selectedName) {
        delete tokens[selectedName];  // Remove the selected token from the object
        saveTokens(tokens);  // Save the updated tokens to the file
        console.log(`${selectedName} has been deleted.`);
    } else {
        console.log('Invalid choice.');
    }

    rl.close();
}

// Main function to display options
async function main() {
    console.log('Options:');
    console.log('1. Store a new token');
    console.log('2. View stored tokens');
    console.log('3. Delete stored token');

    const choice = await askQuestion('Enter your choice (1, 2, or 3): ');

    if (choice === '1') {
        await storeToken();
    } else if (choice === '2') {
        await viewTokens();
    } else if (choice === '3') {
        await deleteToken();
    } else {
        console.log('Invalid choice.');
        rl.close();
    }
}

main();
EOL
echo "Created secureTokens.js at: $SCRIPT_FILE"

# Navigate to the project directory
cd "$BASE_DIR"
echo "Navigated to $BASE_DIR"

# Install dotenv
npm init -y  # Initialize npm package if not already done
npm install dotenv
echo "Installed dotenv package"

# Run the script
echo "Running secureTokens.js..."
node secureTokens.js

# Add alias to the shell config file
SHELL_CONFIG_FILE="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
fi

# Add the alias to the shell config file
echo "Adding alias to shell configuration file: $SHELL_CONFIG_FILE"
echo "alias mytokens='node $BASE_DIR/secureTokens.js'" >> "$SHELL_CONFIG_FILE"

# Refresh the shell configuration
echo "Source the shell config to update the alias."
source "$SHELL_CONFIG_FILE"

echo "Alias 'mytokens' added. You can now run the script with the command: mytokens"
