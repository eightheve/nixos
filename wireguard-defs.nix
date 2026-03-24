{
  network = "10.100.0.0/24";

  hosts = {
    sys = {
      ip = "10.100.0.1";
      publicKey = "1I3PO1MgFdqffo816H34YalYgnCrwPo3ssBbsLTxzBg=";
      isServer = true;
      listenPort = 51820;
    };

    SAOTOME = {
      ip = "10.100.0.2";
      publicKey = "0hrwVOfaPGTs2bfHoGrHroHGqG2aJiiu8JO9o5/K0xg=";
      isServer = false;
    };

    # Non-nix
    FORTRESS = {
      ip = "10.100.0.3";
      publicKey = "62AFcf79kP5HyAoj1IRaj4fwnJTYvfK0hhTYjSMQg0w=";
      isServer = false;
    };
  };
}
