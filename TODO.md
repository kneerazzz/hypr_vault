# QML Rewrite TODO

## Plan: Rewrite all QML files with improved architecture

### Issues to Fix:
1. masterPassword not passed to child views (CredentialDetailView, AddCredentialView)
2. CredentialDetailView decrypt function using empty masterPassword
3. AddCredentialView genModeMarker access issues
4. VaultListView filter functionality broken
5. Overall state management improvements

### Files to Rewrite:
- [ ] 1. scripts/shell.qml - Entry point (keep minimal)
- [ ] 2. scripts/VaultWidget.qml - Main state, pass masterPassword to children
- [ ] 3. scripts/LoginView.qml - Clean login UI Fix The Repeating logic of LoginView
- [ ] 4. scripts/VaultListView.qml - Fix filter, improve list
- [ ] 5. scripts/CredentialDetailView.qml - Fix masterPassword, decryption
- [ ] 6. scripts/AddCredentialView.qml - Fix genModeMarker, add functionality
- [ ] 7. scripts/DetailField.qml - Simple field display with copy
- [ ] 8. scripts/EditField.qml - Proper value binding

### Key Architecture Changes:
- Pass masterPassword explicitly to all child views that need it
- Use proper property bindings instead of trying to access QML objects
- Fix filter type selection to use proper QML patterns
- Improve Process handling with better stdin/stdout management
- Add proper error handling and status messages

