{lib}:
with lib; let
  mkDwmConfig = {
    # Appearance
    borderpx ? 1,
    snap ? 32,
    showbar ? true,
    topbar ? true,
    fonts ? ["monospace:size=10"],
    dmenufont ? "monospace:size=10",
    # Colors
    colors ? {
      norm = {
        fg = "#bbbbbb";
        bg = "#222222";
        border = "#444444";
      };
      sel = {
        fg = "#eeeeee";
        bg = "#005577";
        border = "#005577";
      };
    },
    # Tags
    tags ? ["1" "2" "3" "4" "5" "6" "7" "8" "9"],
    # Rules
    rules ? [
      {
        class = "Gimp";
        instance = null;
        title = null;
        tags = 0;
        floating = true;
        monitor = -1;
      }
      {
        class = "Firefox";
        instance = null;
        title = null;
        tags = 256;
        floating = false;
        monitor = -1;
      }
    ],
    # Layout
    mfact ? 0.55,
    nmaster ? 1,
    resizehints ? true,
    lockfullscreen ? true,
    refreshrate ? 120,
    layouts ? [
      {
        symbol = "[]=";
        arrange = "tile";
      }
      {
        symbol = "><>";
        arrange = null;
      }
      {
        symbol = "[M]";
        arrange = "monocle";
      }
    ],
    # Keys
    modkey ? "Mod1Mask",
    termcmd ? ["st"],
    extraCommands ? "",
    keys ? [],
    extraKeys ? "",
    # Buttons
    buttons ? [],
    extraButtons ? "",
  }: let
    boolToInt = b:
      if b
      then "1"
      else "0";

    nullOrStr = v:
      if v == null
      then "NULL"
      else ''"${v}"'';

    mkColorArray = colors: ''
      static const char *colors[][3]      = {
      	/*               fg         bg         border   */
      	[SchemeNorm] = { "${colors.norm.fg}", "${colors.norm.bg}", "${colors.norm.border}" },
      	[SchemeSel]  = { "${colors.sel.fg}", "${colors.sel.bg}", "${colors.sel.border}" },
      };
    '';

    mkFontsArray = fonts: "static const char *fonts[]          = { ${concatMapStringsSep ", " (f: ''"${f}"'') fonts} };";

    mkTagsArray = tags: "static const char *tags[] = { ${concatMapStringsSep ", " (t: ''"${t}"'') tags} };";
    mkRule = rule: "\t{ ${nullOrStr (rule.class or null)}, ${nullOrStr (rule.instance or null)}, ${nullOrStr (rule.title or null)}, ${toString (rule.tags or 0)}, ${boolToInt (rule.floating or false)}, ${toString (rule.monitor or "-1")} },";

    mkRulesArray = rules: ''
      static const Rule rules[] = {
      	/* class      instance    title       tags mask     isfloating   monitor */
      ${concatMapStringsSep "\n" mkRule rules}
      };
    '';

    mkLayout = layout: "\t{ \"${layout.symbol}\", ${
      if layout.arrange == null
      then "NULL"
      else layout.arrange
    } },";

    mkLayoutsArray = layouts: ''
      static const Layout layouts[] = {
      	/* symbol     arrange function */
      ${concatMapStringsSep "\n" mkLayout layouts}
      };
    '';

    defaultKeys = ''
      /* modifier                     key        function        argument */
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
      { MODKEY|ShiftMask,             XK_q,      quit,           {0} },
    '';

    defaultButtons = ''
      /* click                event mask      button          function        argument */
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
    '';
  in ''
    /* See LICENSE file for copyright and license details. */
    #include <X11/XF86keysym.h>

    /* appearance */
    static const unsigned int borderpx  = ${toString borderpx};        /* border pixel of windows */
    static const unsigned int snap      = ${toString snap};       /* snap pixel */
    static const int showbar            = ${boolToInt showbar};        /* 0 means no bar */
    static const int topbar             = ${boolToInt topbar};        /* 0 means bottom bar */
    ${mkFontsArray fonts}
    static const char dmenufont[]       = "${dmenufont}";
    ${mkColorArray colors}

    /* tagging */
    ${mkTagsArray tags}

    ${mkRulesArray rules}

    /* layout(s) */
    static const float mfact     = ${toString mfact}; /* factor of master area size [0.05..0.95] */
    static const int nmaster     = ${toString nmaster};    /* number of clients in master area */
    static const int resizehints = ${boolToInt resizehints};    /* 1 means respect size hints in tiled resizals */
    static const int lockfullscreen = ${boolToInt lockfullscreen}; /* 1 will force focus on the fullscreen window */
    static const int refreshrate = ${toString refreshrate};  /* refresh rate (per second) for client move/resize */

    ${mkLayoutsArray layouts}

    /* key definitions */
    #define MODKEY ${modkey}
    #define TAGKEYS(KEY,TAG) \
    	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
    	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
    	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
    	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

    /* helper for spawning shell commands in the pre dwm-5.0 fashion */
    #define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

    /* commands */
    static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
    static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", "${colors.norm.bg}", "-nf", "${colors.norm.fg}", "-sb", "${colors.norm.border}", "-sf", "${colors.sel.fg}", NULL };
    static const char *termcmd[]  = { ${concatMapStringsSep ", " (c: ''"${c}"'') termcmd}, NULL };
    ${extraCommands}

    static const Key keys[] = {
    ${defaultKeys}${optionalString (extraKeys != "") "\n${extraKeys}"}
    };

    /* button definitions */
    /* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
    static const Button buttons[] = {
    ${defaultButtons}${optionalString (extraButtons != "") "\n${extraButtons}"}
    };
  '';
in {inherit mkDwmConfig;}
