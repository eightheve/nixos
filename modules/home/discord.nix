{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.homeModules.discord;
in {
  options.homeModules.discord = {
    enable = lib.mkEnableOption "discord (managed by nixcord)";
  };

  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  config = lib.mkIf cfg.enable {
    programs.nixcord = {
      enable = true;
      discord.enable = false;
      discord.equicord.enable = false;
      discord.vencord.enable = false;
      equibop.enable = true;
      config = {
        frameless = true;
        disableMinSize = true;
        plugins = {
          BlurNSFW.enable = true;
          ClearURLs.enable = true;
          LastFMRichPresence = {
            enable = true;
            useListeningStatus = true;
            username = "LiquidC2H2";
          };
          USRBG.enable = true;
          anonymiseFileNames.enable = true;
          clientTheme = lib.mkIf config.colorScheme.enable {
            enable = true;
            color = config.colorScheme.colors.shade1;
          };
          ctrlEnterSend = {
            enable = true;
            sendMessageInTheMiddleOfACodeBlock = false;
            submitRule = "enter";
          };
          dearrow.enable = true;
          decor.enable = true;
          fakeNitro.enable = true;
          followVoiceUser.enable = true;
          forceOwnerCrown.enable = true;
          homeTyping.enable = true;
          messageLogger = {
            enable = true;
            collapseDeleted = true;
            ignoreSelf = true;
            showEditDiffs = true;
            separatedDiffs = true;
          };
          moreKaomoji.enable = true;
          moreCommands.enable = true;
          noNitroUpsell.enable = true;
          noTypingAnimation.enable = true;
        };
      };
    };
  };
}
