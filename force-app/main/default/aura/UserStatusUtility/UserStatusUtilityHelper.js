({
    // Helper method to add visual indicators using emojis
    getStatusLabelWithEmoji: function(userStatus) {
        let indicator;

        // Determine the indicator based on the status
        switch (userStatus) {
            case 'Online':
                indicator = '🟢'; // Green circle for Online
                break;
            case 'Offline':
                indicator = '🔴'; // Red circle for Offline
                break;
            default:
                indicator = '🟡'; // Yellow circle for Other statuses
                break;
        }

        // Return the label text with the indicator
        return `${indicator} User Status: ${userStatus}`;
    }
})