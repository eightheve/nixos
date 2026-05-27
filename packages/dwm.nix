{
  pkgs,
  lib,
  colorscheme ? null,
  isLaptop ? false,
  refreshRate ? 120,
}:
# Derive DWM colors from colorscheme
let
  colors =
    if colorscheme != null
    then {
      gray1 = "#${colorscheme.shade0}";
      gray2 = "#${colorscheme.shade2}";
      gray3 = "#${colorscheme.shade3}";
      gray4 = "#${colorscheme.shade5}";
      accent1 = "#${colorscheme.accent4."0"}";
      accent2 = "#${colorscheme.accent4."1"}";
    }
    else {
      gray1 = "#000000";
      gray2 = "#181818";
      gray3 = "#e1e1e1";
      gray4 = "#ffffff";
      accent1 = "#222244";
      accent2 = "#444477";
    };

  # Keybind scripts
  screenshotAll = pkgs.writeShellScript "screenshot-all" ''
    mkdir -p "$HOME/Resources/.screenshots"
    ${pkgs.scrot}/bin/scrot "$HOME/Resources/.screenshots/%m-%d-%Y-%H%M%S.png" -e '${pkgs.xclip}/bin/xclip -selection clipboard -t image/png -i $f'
  '';

  screenshotSelection = pkgs.writeShellScript "screenshot-selection" ''
    mkdir -p "$HOME/Resources/.screenshots"
    ${pkgs.scrot}/bin/scrot "$HOME/Resources/.screenshots/%m-%d-%Y-%H%M%S.png" --select --line mode=edge -e '${pkgs.xclip}/bin/xclip -selection clipboard -t image/png -i $f'
  '';

  volumeCtrl = pkgs.writeShellScript "volume-control" ''
    case "$1" in
      1)  ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +10%; ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ 0;;
      -1) ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -10%;;
      *)  ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle;;
    esac
  '';

  brightnessCtrl = if isLaptop then pkgs.writeShellScript "brightness-control" ''
    case "$1" in
      1) ${pkgs.brightnessctl}/bin/brightnessctl set 10%+ -e -n 10%;;
      -1) ${pkgs.brightnessctl}/bin/brightnessctl set 10%- -e -n 10%;;
    esac
  '' else "";

  terminal = ["${pkgs.kitty}/bin/kitty"];

  configH = ''
    #include <X11/XF86keysym.h>

    static const unsigned int borderpx  = 1;
    static const unsigned int snap      = 32;
    static const int showbar            = 1;
    static const int topbar             = 1;
    static const char *fonts[]          = { "monospace:size=10" };
    static const char dmenufont[]       = "monospace:size=10";
    static const char *colors[][3]      = {
    	/*               fg         bg         border   */
    	[SchemeNorm] = { "${colors.gray3}", "${colors.gray1}", "${colors.gray2}" },
    	[SchemeSel]  = { "${colors.gray4}", "${colors.accent1}", "${colors.accent2}" },
    };

    static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

    static const Rule rules[] = {
    	{ "Gimp",     NULL,       NULL, 0,    True,    -1 },
    	{ "Firefox",  NULL,       NULL, 1 << 8, False,  -1 },
    };

    static const float mfact     = 0.55;
    static const int nmaster     = 1;
    static const int resizehints = 1;
    static const int lockfullscreen = 1;
    static const int refreshrate = ${toString refreshRate};

    static const Layout layouts[] = {
    	{ "[]=",      tile },
    	{ "><>",      NULL },
    	{ "[M]",      monocle },
    	{ "TTT",      bstack },
    	{ "===",      bstackhoriz },
    };
    ${lib.optionalString (!isLaptop) ''
    /* per-monitor default layout (NULL = use layouts[0]). index = monitor number */
    static const Layout *monlayouts[] = { &layouts[0], &layouts[3] };
    ''}

    #define MODKEY Mod4Mask
    #define TAGKEYS(KEY,TAG) \
    	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
    	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
    	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
    	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

    #define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

    static char dmenumon[2] = "0";
    static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", "${colors.gray1}", "-nf", "${colors.gray3}", "-sb", "${colors.gray2}", "-sf", "${colors.gray4}", NULL };
    static const char *termcmd[]  = { ${lib.concatMapStringsSep ", " (c: ''"${c}"'') terminal}, NULL };
    static const char *up_vol[]   = { "${volumeCtrl}", "1", NULL};
    static const char *down_vol[] = { "${volumeCtrl}", "-1", NULL};
    static const char *mute_vol[] = { "${volumeCtrl}", "0", NULL};
    ${lib.optionalString isLaptop ''
    static const char *brighter[] = { "${brightnessCtrl}", "1", NULL};
    static const char *dimmer[]   = { "${brightnessCtrl}", "-1", NULL};
    ''}
    static const char *ss_all[]   = { "${screenshotAll}", NULL };
    static const char *ss_sel[]   = { "${screenshotSelection}", NULL };

    static const Key keys[] = {
    	{ MODKEY,                       XK_p,      spawn,          {.v = dmenucmd } },
    	{ MODKEY|ShiftMask,             XK_Return, spawn,          {.v = termcmd } },
    	{ MODKEY,                       XK_b,      togglebar,      {0} },
    	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
    	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
    	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
    	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
    	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
    	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
    	{ MODKEY,                       XK_Return, zoom,           {0} },
    	{ MODKEY,                       XK_Tab,    view,           {0} },
    	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },
    	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
    	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },
    	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
    	{ MODKEY,                       XK_u,      setlayout,      {.v = &layouts[3]} },
    	{ MODKEY,                       XK_o,      setlayout,      {.v = &layouts[4]} },
    	{ MODKEY,                       XK_space,  setlayout,      {0} },
    	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
    	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
    	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
    	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
    	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
    	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
    	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
    	TAGKEYS(                        XK_1,                      0)
    	TAGKEYS(                        XK_2,                      1)
    	TAGKEYS(                        XK_3,                      2)
    	TAGKEYS(                        XK_4,                      3)
    	TAGKEYS(                        XK_5,                      4)
    	TAGKEYS(                        XK_6,                      5)
    	TAGKEYS(                        XK_7,                      6)
    	TAGKEYS(                        XK_8,                      7)
    	TAGKEYS(                        XK_9,                      8)
    	{ 0, XF86XK_AudioMute,         spawn, {.v = mute_vol } },
    	{ 0, XF86XK_AudioLowerVolume,  spawn, {.v = down_vol } },
    	{ 0, XF86XK_AudioRaiseVolume,  spawn, {.v = up_vol } },
    	${lib.optionalString isLaptop ''
    	{ 0, XF86XK_MonBrightnessDown, spawn, {.v = dimmer } },
    	{ 0, XF86XK_MonBrightnessUp,   spawn, {.v = brighter } },
    	''}
    	{ 0,           XK_Print,       spawn, {.v = ss_all } },
    	{ ShiftMask,   XK_Print,       spawn, {.v = ss_sel } },
    	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },
    };

    static const Button buttons[] = {
    	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
    	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
    	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
    	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
    	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
    	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
    	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
    	{ ClkTagBar,            0,              Button1,        view,           {0} },
    	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
    	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
    	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
    };
  '';

  # Patch dwm.c: after assigning m->num in updategeom(), apply per-monitor
  # default layout from the monlayouts[] config array (NULL = use default tile)
  monlayoutPatch = pkgs.writeText "dwm-monlayouts.patch" ''
    diff --git a/dwm.c b/dwm.c
    --- a/dwm.c
    +++ b/dwm.c
    @@ -1907,6 +1907,11 @@
     			{
     				dirty = 1;
     				m->num = i;
    +				if (i < LENGTH(monlayouts) && monlayouts[i]) {
    +					m->lt[0] = monlayouts[i];
    +					m->lt[1] = &layouts[0];
    +					strncpy(m->ltsymbol, monlayouts[i]->symbol, sizeof m->ltsymbol);
    +				}
     				m->mx = m->wx = unique[i].x_org;
     				m->my = m->wy = unique[i].y_org;
     				m->mw = m->ww = unique[i].width;
  '';
in
  pkgs.dwm.overrideAttrs (oldAttrs: {
    patches = [
      (pkgs.fetchpatch {
        url = "https://dwm.suckless.org/patches/bottomstack/dwm-bottomstack-6.1.diff";
        hash = "sha256-B38SP1NGBhve8gG1Ci2hjahZqePKdHOuXGGL+n450Jk=";
      })
      monlayoutPatch
    ];
    postPatch = ''
      cp ${pkgs.writeText "config.h" configH} config.h
    '';
  })
