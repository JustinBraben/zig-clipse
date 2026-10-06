pub const ControlledExit = error{
    Quit,
    Help,
    Timeout,
    UnitTestPassed,
    UnitTestFailed,
};
pub const GameException = error{
    InvalidOpcode,
    UnimplementedOpcode,
    InvalidRamRead,
    InvalidRamWrite,
};
pub const UserException = error{
    RomMissing,
    LogoChecksumFailed,
    HeaderChecksumFailed,
};
