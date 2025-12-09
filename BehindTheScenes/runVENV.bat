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


overwrites all local files
git fetch origin
git reset --hard origin/main
git clean -fd     This removes untracked items


Just pulls updates
git pull origin main