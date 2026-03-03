import crypto from 'crypto'

function generateStrongPassword(options = {}) {
    const {
        length = 18,
        useLowercase = true,
        useUppercase = true,
        useNumbers = true,
        useSymbols = true
    } = options;

    const lowercaseChars = "abcdefghijklmnopqrstuvwxyz";
    const uppercaseChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    const numberChars = "0123456789";
    const symbolChars = "!@#$%^&*()_+~`|}{[]:;?><,./-=";

    let availableChars = "";
    let passwordArray = [];

    if (useLowercase) {
        availableChars += lowercaseChars;
        passwordArray.push(lowercaseChars[crypto.randomInt(0, lowercaseChars.length)]);
    }
    if (useUppercase) {
        availableChars += uppercaseChars;
        passwordArray.push(uppercaseChars[crypto.randomInt(0, uppercaseChars.length)]);
    }
    if (useNumbers) {
        availableChars += numberChars;
        passwordArray.push(numberChars[crypto.randomInt(0, numberChars.length)]);
    }
    if (useSymbols) {
        availableChars += symbolChars;
        passwordArray.push(symbolChars[crypto.randomInt(0, symbolChars.length)]);
    }

    if (availableChars.length === 0) {
        availableChars = lowercaseChars + numberChars;
        passwordArray.push(lowercaseChars[crypto.randomInt(0, lowercaseChars.length)]);
        passwordArray.push(numberChars[crypto.randomInt(0, numberChars.length)]);
    }

    if (length < passwordArray.length) {
        throw new Error("Password length is too short for the required character types.");
    }

    const remainingLength = length - passwordArray.length;
    for (let i = 0; i < remainingLength; i++) {
        const randomIndex = crypto.randomInt(0, availableChars.length);
        passwordArray.push(availableChars[randomIndex]);
    }

    for (let i = passwordArray.length - 1; i > 0; i--) {
        const j = crypto.randomInt(0, i + 1);
        [passwordArray[i], passwordArray[j]] = [passwordArray[j], passwordArray[i]];
    }

    return passwordArray.join('');
}

// Test it out
console.log("Guaranteed Mix:", generateStrongPassword());
console.log("Strict Length (8), No Symbols:", generateStrongPassword({ length: 8, useSymbols: false }));