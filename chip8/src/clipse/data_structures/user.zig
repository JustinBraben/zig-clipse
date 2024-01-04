pub const User = struct {
    id: u64,
    power: i32,

    pub fn init(id: u64, power: i32) *User {
        var user = User{
            .id = id,
            .power = power,
        };
        // this is a dangling pointer
        return &user;
    }

    pub fn levelUp(user: *User) void {
        user.power += 1;
    }
};
