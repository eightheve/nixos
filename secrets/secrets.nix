let
  KAZOOIE = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILng6gKqqUcDnbulG2NQ7YoRGHuS1XX7dY82asUCk7g2";
  systems = [ KAZOOIE ];
in {
  "lastFmApiKey.age".publicKeys = [ KAZOOIE ];
}
