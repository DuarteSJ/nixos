{config, ...}: let
  colors = config.colorScheme.palette;
in {
  programs.vesktop = {
    enable = true;

    settings = {
      disableMinSize = true;
      minimizeToTray = false;
      splashTheming = true;
      transparencyOption = "mica";
    };

    vencord.settings = {
      plugins = {
        ChatInputButtonAPI.enabled = true;
        CommandsAPI.enabled = true;
        DynamicImageModalAPI.enabled = true;
        MemberListDecoratorsAPI.enabled = true;
        MessageAccessoriesAPI.enabled = true;
        MessageDecorationsAPI.enabled = true;
        MessageEventsAPI.enabled = true;
        MessagePopoverAPI.enabled = true;
        ServerListAPI.enabled = true;
        UserSettingsAPI.enabled = true;
        CrashHandler.enabled = true;
        DisableCallIdle.enabled = true;
        ExpressionCloner.enabled = true;
        FakeNitro = {
          enabled = true;
          enableStickerBypass = true;
          enableStreamQualityBypass = true;
          enableEmojiBypass = true;
          transformEmojis = true;
          transformStickers = true;
          transformCompoundSentence = false;
        };
        FakeProfileThemes.enabled = true;
        FixCodeblockGap.enabled = true;
        FixImagesQuality.enabled = true;
        FixSpotifyEmbeds.enabled = true;
        ForceOwnerCrown.enabled = true;
        GameActivityToggle = {
          enabled = true;
          oldIcon = false;
        };
        GifPaste.enabled = true;
        GreetStickerPicker.enabled = true;
        iLoveSpam.enabled = true;
        ImageFilename = {
          enabled = true;
          showFullUrl = false;
        };
        ImageLink.enabled = true;
        ImageZoom = {
          enabled = true;
          size = 100;
          zoom = 2;
          saveZoomValues = true;
          nearestNeighbour = false;
          square = false;
        };
        ImplicitRelationships = {
          enabled = true;
          sortByAffinity = true;
        };
        IrcColors = {
          enabled = true;
          lightness = 70;
          memberListColors = true;
          applyColorOnlyToUsersWithoutColor = false;
          applyColorOnlyInDms = false;
        };
        MemberCount = {
          enabled = true;
          memberList = true;
          toolTip = true;
          voiceActivity = true;
        };
        MessageClickActions = {
          enabled = true;
          enableDeleteOnClick = true;
          enableDoubleClickToEdit = true;
          enableDoubleClickToReply = true;
          requireModifier = false;
        };
        PermissionFreeWill = {
          enabled = true;
          lockout = true;
          onboarding = true;
        };
        PermissionsViewer.enabled = true;
        petpet.enabled = true;
        PictureInPicture.enabled = true;
        PinDMs = {
          enabled = true;
          canCollapseDmSection = false;
          pinOrder = 0;
        };
        PlatformIndicators = {
          enabled = true;
          colorMobileIndicator = true;
          list = true;
          badges = true;
          messages = true;
        };
        PreviewMessage.enabled = true;
        QuickMention.enabled = true;
        ReadAllNotificationsButton.enabled = true;
        RelationshipNotifier = {
          enabled = true;
          offlineRemovals = true;
          groups = true;
          servers = true;
          friends = true;
          friendRequestCancels = true;
        };
        ReplyTimestamp.enabled = true;
        ReverseImageSearch.enabled = true;
        SecretRingToneEnabler = {
          enabled = true;
          onlySnow = false;
        };
        ServerInfo.enabled = true;
        ShowHiddenChannels = {
          enabled = true;
          showMode = 0;
          hideUnreads = true;
          defaultAllowedUsersAndRolesDropdownState = true;
        };
        ShowHiddenThings = {
          enabled = true;
          showTimeouts = true;
          showInvitesPaused = true;
          showModView = true;
        };
        SilentTyping = {
          enabled = true;
          isEnabled = true;
          showIcon = false;
        };
        SpotifyShareCommands.enabled = true;
        StickerPaste.enabled = true;
        TypingIndicator = {
          enabled = true;
          includeMutedChannels = false;
          includeCurrentChannel = true;
          indicatorMode = 3;
        };
        UnlockedAvatarZoom.enabled = true;
        UserVoiceShow = {
          enabled = true;
          showInUserProfileModal = true;
          showInMemberList = true;
          showInMessages = true;
        };
        ValidReply.enabled = true;
        ValidUser.enabled = true;
        VoiceChatDoubleClick.enabled = true;
        ViewIcons = {
          enabled = true;
          format = "webp";
          imgSize = "1024";
        };
        ViewRaw = {
          enabled = true;
          clickMethod = "Left";
        };
        VoiceDownload.enabled = true;
        VoiceMessages = {
          enabled = true;
          noiseSuppression = true;
          echoCancellation = true;
        };
        WebKeybinds.enabled = true;
        WebScreenShareFixes.enabled = true;
        YoutubeAdblock.enabled = true;
        BadgeAPI.enabled = true;
        NoTrack = {
          enabled = true;
          disableAnalytics = true;
        };
        Settings = {
          enabled = true;
          settingsLocation = "aboveNitro";
        };
        DisableDeepLinks.enabled = true;
        SupportHelper.enabled = true;
        WebContextMenus.enabled = true;
      };
    };
  };

  xdg.configFile."vesktop/settings/quickCss.css".text = ''
    @import url('https://refact0r.github.io/midnight-discord/build/midnight.css');

    body {
        --font: "figtree";
        --code-font: "";
        font-weight: 400;

        --gap: 10px;
        --divider-thickness: 4px;
        --border-thickness: 1px;

        --animations: on;
        --list-item-transition: 0.2s ease;
        --dms-icon-svg-transition: 0.4s ease;
        --border-hover-transition: 0.2s ease;

        --top-bar-height: var(--gap);
        --top-bar-button-position: titlebar;
        --top-bar-title-position: off;
        --subtle-top-bar-title: off;

        --custom-window-controls: on;
        --window-control-size: 14px;

        --custom-dms-icon: off;
        --dms-icon-svg-size: 90%;
        --dms-icon-color-before: var(--icon-secondary);
        --dms-icon-color-after: var(--white);

        --transparency-tweaks: on;
        --remove-bg-layer: on;
        --panel-blur: off;
        --blur-amount: 0px;
        --app-opacity: 1;

        --custom-chatbar: aligned;
        --chatbar-height: 47px;
        --chatbar-padding: 8px;

        --small-user-panel: on;
    }

    :root {
        --colors: on;

        --text-0: #${colors.base01};
        --text-1: #${colors.base07};
        --text-2: #${colors.base06};
        --text-3: #${colors.base05};
        --text-4: #${colors.base04};
        --text-5: #${colors.base03};

        --bg-1: #${colors.base03};
        --bg-2: #${colors.base02};
        --bg-3: #${colors.base01};
        --bg-4: #${colors.base00};
        --hover: hsla(220, 20%, 50%, 0.1);
        --active: hsla(220, 20%, 50%, 0.2);
        --active-2: hsla(220, 20%, 50%, 0.3);
        --message-hover: hsla(0, 0%, 0%, 0.1);

        --accent-1: #${colors.base0D};
        --accent-2: #${colors.base0D};
        --accent-3: #${colors.base0D};
        --accent-4: #${colors.base0C};
        --accent-5: #${colors.base0C};
        --accent-new: #${colors.base0D};
        --mention: linear-gradient(to right, color-mix(in hsl, #${colors.base0D}, transparent 90%) 40%, transparent);
        --mention-hover: linear-gradient(to right, color-mix(in hsl, #${colors.base0D}, transparent 95%) 40%, transparent);
        --reply: linear-gradient(to right, color-mix(in hsl, #${colors.base05}, transparent 90%) 40%, transparent);
        --reply-hover: linear-gradient(to right, color-mix(in hsl, #${colors.base05}, transparent 95%) 40%, transparent);

        --online: #${colors.base0B};
        --dnd: #${colors.base08};
        --idle: #${colors.base0A};
        --streaming: #${colors.base0E};
        --offline: #${colors.base03};

        --border-light: hsla(220, 20%, 50%, 0.05);
        --border: hsla(220, 20%, 50%, 0.1);
        --border-hover: hsla(220, 20%, 50%, 0.1);
        --button-border: hsl(0, 0%, 100%, 0.1);

        --red-1: #${colors.base08};
        --red-2: #${colors.base08};
        --red-3: #${colors.base08};
        --red-4: #${colors.base08};
        --red-5: #${colors.base08};

        --green-1: #${colors.base0B};
        --green-2: #${colors.base0B};
        --green-3: #${colors.base0B};
        --green-4: #${colors.base0B};
        --green-5: #${colors.base0B};

        --blue-1: #${colors.base0D};
        --blue-2: #${colors.base0D};
        --blue-3: #${colors.base0D};
        --blue-4: #${colors.base0C};
        --blue-5: #${colors.base0C};

        --yellow-1: #${colors.base0A};
        --yellow-2: #${colors.base0A};
        --yellow-3: #${colors.base0A};
        --yellow-4: #${colors.base0A};
        --yellow-5: #${colors.base0A};

        --purple-1: #${colors.base0E};
        --purple-2: #${colors.base0E};
        --purple-3: #${colors.base0E};
        --purple-4: #${colors.base0E};
        --purple-5: #${colors.base0E};
    }
  '';
}
