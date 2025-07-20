// Basic structure to describe a Firestore attendance doc (used by service)
class Attendance {
  constructor(doc) {
    this.id = doc.id;
    const data = doc.data();
    this.date = data.date || "";
    this.startTime = data.startTime || "";
    this.endTime = data.endTime || "";
    this.updatedAt = data.updatedAt || "";
    this.startLocation = data.startLocation || {};
    this.endLocation = data.endLocation || {};
    this.userId = data.userId || "";
  }
}

module.exports = Attendance;
