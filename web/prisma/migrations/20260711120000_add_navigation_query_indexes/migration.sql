-- Support the per-user filters and ordering used by the navigation views.
CREATE INDEX "Account_userId_provider_idx" ON "Account"("userId", "provider");
CREATE INDEX "Subject_userId_name_idx" ON "Subject"("userId", "name");
CREATE INDEX "TimetableSlot_userId_weekday_startMinutes_idx" ON "TimetableSlot"("userId", "weekday", "startMinutes");
CREATE INDEX "AttendanceRecord_userId_date_idx" ON "AttendanceRecord"("userId", "date");
CREATE INDEX "ClassroomCourse_userId_name_idx" ON "ClassroomCourse"("userId", "name");
CREATE INDEX "Assignment_userId_dueDate_idx" ON "Assignment"("userId", "dueDate");
