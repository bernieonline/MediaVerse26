import QtQuick 2.15

QtObject {
    id: tools

    // Extract full title from filePath (without extension)
    function extractTitle(path) {
        if (!path)
            return "Unknown";

        // Remove file:/// prefix
        let url = path.replace("file:///", "");

        // Split into path segments
        let parts = url.split(/[\\/]/);
        let file = parts[parts.length - 1];

        // Remove extension
        file = file.replace(/\.[^/.]+$/, "");

        // Decode URL encoding (%20 etc.)
        try { file = decodeURIComponent(file); } catch (e) {}

        return file;
    }

    // Extract year from "(YYYY)" pattern in filename
    function extractYear(path) {
        if (!path)
            return 0;

        let url = path.replace("file:///", "");
        let parts = url.split(/[\\/]/);    // ✅ fixed line
        let file = parts[parts.length - 1];

        try { file = decodeURIComponent(file); } catch (e) {}

        let match = file.match(/\((\d{4})\)/);
        return match ? parseInt(match[1]) : 0;
    }

    // Title with trailing "(YYYY)" removed, for UI display
    function extractCleanTitle(path) {
        let title = extractTitle(path);
        return title.replace(/\(\d{4}\)$/, "").trim();
    }

    // Sorting helper: mode = "year" or "title"
    function sortList(list, mode) {
        if (!list)
            return [];

        let arr = list.slice();

        arr.sort(function(a, b) {
            let yearA = extractYear(a.filePath);
            let yearB = extractYear(b.filePath);

            let titleA = extractTitle(a.filePath).toLowerCase();
            let titleB = extractTitle(b.filePath).toLowerCase();

            // ⭐ MODE: oldest first
            if (mode === "oldest") {
                if (yearA !== yearB)
                    return yearA - yearB;   // oldest first
            }

            // ⭐ MODE: recent first
            if (mode === "recent") {
                if (yearA !== yearB)
                    return yearB - yearA;   // newest first
            }

            // ⭐ MODE: recently added (filesystem order)
            if (mode === "added") {
                // a.addedTime is provided by your Python backend
                if (a.addedTime !== b.addedTime)
                    return b.addedTime - a.addedTime;  // newest added first
            }

            // ⭐ MODE: alphabetical
            if (mode === "alpha") {
                return titleA.localeCompare(titleB);
            }

            // fallback: alphabetical
            return titleA.localeCompare(titleB);
        });

        return arr;
    }
}