user = db.getUsers().find(function(user) {
  return user["user"] === "braumeister";
});
if (!user) {
  db.createUser({
    user: "braumeister",
    pwd: "braumeister",
    roles: [{
      db: db.getName(),
      role: "readWrite"
    }]
  });
}
