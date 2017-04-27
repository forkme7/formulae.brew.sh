user = db.getUsers().find(function(user) {
  return user["user"] === "braumeister";
});
if (!user) {
  db.createUser({
    user: "braumeister",
    pwd: "braumeister",
    roles: [{
      db: "braumeister",
      role: "readWrite"
    }]
  });
}
