# Push CleanSlate to GitHub

## Option 1: Using GitHub Website (Easiest)

1. Go to https://github.com/new
2. Create a new repository with these settings:
   - Repository name: `cleanslate` or `secure-data-wiper`
   - Description: "CleanSlate v1.01 - Professional Data Sanitization Tool (NIST SP 800-88 Compliant)"
   - Public or Private (your choice)
   - DO NOT initialize with README (we already have one)
   - DO NOT add .gitignore (we already have one)

3. After creating, copy the repository URL (e.g., https://github.com/YOUR_USERNAME/cleanslate.git)

4. Run these commands in PowerShell from this directory:
```powershell
# Add your GitHub repository as remote
git remote add origin https://github.com/YOUR_USERNAME/cleanslate.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Option 2: Using GitHub CLI

1. Install GitHub CLI:
```powershell
winget install --id GitHub.cli
```

2. Login to GitHub:
```powershell
gh auth login
```

3. Create and push repository:
```powershell
gh repo create cleanslate --public --source=. --remote=origin --push
```

## Option 3: Using Git with Personal Access Token

1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Generate new token with 'repo' scope
3. Use the token as password when pushing:
```powershell
git remote add origin https://github.com/YOUR_USERNAME/cleanslate.git
git branch -M main
git push -u origin main
# Enter your GitHub username and token as password
```

## Repository Details to Add on GitHub

### About Section
- Description: Professional Data Sanitization Tool - NIST SP 800-88 Compliant
- Website: (optional)
- Topics: `data-sanitization`, `data-wiper`, `security`, `privacy`, `nist-compliant`, `dod-5220`, `python`, `tkinter`

### README Badge
Add this to your README if you want:
```markdown
![Version](https://img.shields.io/badge/version-1.01-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Python](https://img.shields.io/badge/python-3.8%2B-blue)
```

## Files Already Prepared
✅ .gitignore - Excludes unnecessary files
✅ README.md - Complete documentation
✅ CHANGELOG.md - Version history
✅ requirements.txt - Dependencies
✅ All source code - Ready to push

## After Pushing

1. Go to Settings > Pages to enable GitHub Pages (optional)
2. Add a LICENSE file (recommended - MIT or Apache 2.0)
3. Enable Issues for bug tracking
4. Consider adding GitHub Actions for automated testing

Your repository is ready to push!
