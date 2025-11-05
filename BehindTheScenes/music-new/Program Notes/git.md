
## Using Markdown text editor for program notes

https://www.markdownguide.org/basic-syntax/
ctrl shift v to preview
can only seem to have 1 preview window open - not sure

#### How to prepare and use Git and Git Hub


 **Version change
#### I have added a new feature to my MediaManager branch. It's currently at version 1.0.0 in Git and GitHub How do I now update Git and GitHub and set the new version to 1.1.0"

1. git add main.py
2. git commit -m "Update version to 1.1.0 and add new feature"
3. git push origin MediaManager
4. git tag -a v1.1.0 -m "Release version 1.1.0 with new feature"
5. git push origin v1.1.0

##### Go to your GitHub repository and verify that (../git.md)the MediaManager branch is updated and the new tag v1.1.0 is present.

### What other Git Commands do I need


### I would like to create a new branch for git and github can you take me through it step by step
1. Step 1: , ensure you're on the branch from which you want to create a new branch. You can check your current branch with:
        - git branch
        - The current branch will be highlighted with an asterisk (*).
2. Step 2: Create a New Branch
        - git branch feature-branch where feature-branch should give the branch a new name
3. Step 3: Switch to the New Branch
        - git checkout feature-branch
4. Step 4: Make Changes and Commit
        - Make any changes you need in your code. Once you're ready to commit, stage your changes:
        - git add .
        - Then commit them with a message:
        - git commit -m "Add changes for new feature"
5. Step 5: Push the New Branch to GitHub
        - git push -u origin feature-branch
6. Step 6: Verify on GitHub



#### To create a separate document for your program notes, you can use a Markdown file. Markdown is a lightweight markup language that is easy to read and write, and it integrates well with VS Code. Here's how you can create a documentation file for your project:




# Program Notes for MediaManager Project

## Version Information
- **Current Version**: 1.1.0

#### Logging Configuration
- **Enable Logging**: Set to `True` to enable logging, `False` to disable.
- **Log File**: `D:\PythonMusic\pythonProject6\music-new\application.log`
- **Logging Level**: 
  - `INFO` when logging is enabled.
  - `CRITICAL` when logging is disabled to suppress lower-severity messages.

## Application Setup
- **High DPI Scaling**: Enabled for better display on high-resolution screens.
- **Font Size**: Default font size set to 12 points.

## Main Function Workflow
1. **Logging Setup**: Configures logging based on the `enable_logging` flag.
2. **Application Initialization**: 
   - Sets application attributes for DPI scaling.
   - Creates the `QApplication` instance.
   - Sets the default font size.
3. **Window Management**: 
   - Creates and shows the main application window.
4. **Event Loop**: Starts the event loop and handles application exit.

## Error Handling
- Logs any exceptions that occur during the application run.
- Exits the application with status code 1 in case of an error.

## Future Improvements
- Consider adding more detailed logging for debugging purposes.
- Explore additional configuration options for the `QApplication` instance.



This document serves as a reference for understanding the current setup and configuration of the MediaManager project. Feel free to update it as the project evolves.


This Markdown document provides a structured overview of your program, including version information, logging configuration, application setup, and workflow. You can keep this file in your project directory and open it in VS Code for easy access and editing. If you have any further questions or need additional assistance, feel free to ask!
