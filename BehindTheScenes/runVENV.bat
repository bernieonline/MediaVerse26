echo Activating venv...
cd J:\MediaVerse 1.0\BehindTheScenes
call venv\Scripts\activate
cd J:\MediaVerse 1.0\BehindTheScenes\music-new\Sandbox\MediaPlayerPy
git status
git fetch origin


shows gits on the remote that you dont have locally
git log main..origin/main --oneline

adding a files
(venv) J:\MediaVerse 1.0\BehindTheScenes\music-new\Sandbox\MediaPlayerQML>git add "StyledMenu.qml"


if vs code ever looks scrambled run these three commands from withinn BehindTheScenes
git branch --show-current        # confirms which branch you're on
git status                       # shows if working tree matches HEAD
git ls-tree -r HEAD --name-only  # lists all files tracked in the commit


overwrites all local files
git fetch origin
git reset --hard origin/main
git clean -fd     This removes untracked items


Just pulls updates
git pull origin main


How to tag a fileSet
git status
commit any files that are untracked or waiting final commit
git add .
git commit -m "Final changes before tagging Top Level Menu"

git tag -a "TopLevelMenuImplemented" -m "Fallback: Top Level Menu Implemented"
verify with git tag
see datails with git show TopLevelMenuImplemented       use q to quit
push it git push origin TopLevelMenuImplemented
if something goes badly wrong this is how you go back to it
git checkout TopLevelMenuImplemented


is a file tracked
git ls-files filename         it will return the filename


changes since last committ
git diff filename → changes since last commit?

