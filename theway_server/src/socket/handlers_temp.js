// Temporary mock socket handlers to bypass the sqlite3 issue
module.exports = (io) => {
    console.log('Socket.IO handlers loaded with temporary mock');
    return io;
};