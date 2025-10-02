#!/bin/bash
# Git push script to commit and push changes to the repository
git add . # Stage all changes
git status # Show the status of the repository
git commit -m "Updated code" # Commit changes with a message
git push origin main # Push changes to the main branch
echo "Changes pushed to the repository successfully."

