<div align="center">
<p align="center">
  <img src="https://capsule-render.vercel.app/api?text=MODERN-LABWC&type=waving&color=gradient&height=150&section=header&fontSize=50&fontColor=ffffff"/>
</p>
  
A ready to use configuration for **Labwc** wayland compositor with 19 preconfigured color schemes + dynamic wallpaper-based color generation using matuge AND my cool scripts....

</div>

<div align="center">
<h5>
If you enjoy this project, consider giving it a star!
<picture>
  <source srcset="https://fonts.gstatic.com/s/e/notoemoji/latest/1f31f/512.webp" type="image/webp">
  <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f31f/512.gif" alt="🌟" width="32" height="32">
</picture>
</h5>
</div>

---

- **[Installation](#installation)**
- **[Dependencies](#dependencies)**
- **[Keybindings](#keybindings)**
- **[Configuring shell to use Alarm and Timer script from terminal](#configuration)**
- **[Configuring](#configuration)**
  - [1. Keybindings](#1-keybindings)
  - [2. Mouse & Touchpad Acceleration](#2-mouse--touchpad-acceleration)
  - [3. Workspaces](#3-workspaces)
  - [4. Waybar Customization](#4-waybar-customization)
  - [5. Changing Wallpaper Path](#5-changing-wallpaper-path)
  - [6. Adding context menu in thunar to easily set wallpaper](#6-adding-context-menu-in-thunar-to-easily-set-wallpaer-by-right-clicking-on-images-or-gifs)
  - [7. Changing Lockscreen Profile Photo](#7-changing-lockscreen-profile-photo)
  - [8. Use TUI Version of todo countdown and clock-calendar](#8-use-tui-version-of-todo-countdown-and-clock-calendar)
  - [9. Locale & Input](#9-locale--input)
  - [10. Rofi Tube](#10-rofi-tube)
  - [11. Changing Notification Daemon](#11-changing-notification-daemon)
- **[Update](#update-and-fixes)**

---

<h2>
<picture>
  <source srcset="https://fonts.gstatic.com/s/e/notoemoji/latest/2728/512.webp" type="image/webp">
  <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2728/512.gif" alt="✨" width="32" height="32">
</picture>
  Features
</h2>

- **Preconfigured Themes** - Preconfigured color schemes for labwc, GTK3, GTK4, Rofi, and waybar.
- **Wallpaper-Based Color Generation** - Generate themes from wallpapers using Matugen.
- **Rofi Applets** - Useful Rofi Applets
- **Audio Feedback** - Plays audio on system login and hardware changes.
- **Dynamic Desktop Menu** - A Python-based menu generator that builds beautiful, icon-rich `labwc` root menus with optional custom headers.
- **Idle Management** - Manage screen dimming, locking and device suspension.
- **Immersive Hyprlock** - Matugen-themed lockscreen with 'Now Playing' album art and direct wallpaper background rendering (not simple screenshot).
- **Wallpaper Picker On Steroids** - Handles both images and GIFs. It toggles system theme (dark/light) based on generated color scheme, extracts GIF frame for lockscreen consistency, and analyzes wallpaper brightness to generate readable text colors for Hyprlock.

   And many more.....

<details>
<summary>
<strong>
<picture>
  <source srcset="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4f8/512.webp" type="image/webp">
  <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4f8/512.gif" alt="📸" width="32" height="32">
</picture>
  Click Here to View Screenshots, Videos
</strong><br></br>
  NOTE! Screenshots are old and not updated the UI is same but there are some improvements like no thick borders, better colors, improved scripts etc...
</summary>

---

## 🎨 Preconfigured Themes (20 Total)

<table>
  <tr>
    <td align="center">
      <h5>Tokyo Night, Onedark, Dracula, Catppuccin, Gruvbox, Nord, Everforest, Everforest Light, Solarized Dark, Solarized, Lavender Pastel, Arc, Adapta, Black, Navy, Lovelace, Paper, Cyberpunk, Yousai, and Wallpaper-based.</h5>
    </td>
  </tr>
<tr>
 <td><img src="https://github.com/user-attachments/assets/a090d01a-e89e-41d9-8d57-ef9db4a2b344" width="100%" alt="launcher10"></td>
</tr>
</table>

<table>
  <tr>
    <td colspan="2" align="center">
      <h5>Beautiful Labwc Root Menu</h5>
    </td>
  </tr>  
  <tr>
    <td><h6>Without Header</h6><img src="https://github.com/user-attachments/assets/9fe692af-6d6e-41d6-9a1f-a671377cd811" width="100%" alt="launcher10"></td>
    <td><h6>With Header</h6><img src="https://github.com/user-attachments/assets/e0e9d20a-c171-4701-b7f6-268b733ec2ab" width="100%" alt="launcher9"></td>
  </tr>
</table>

### Rofi Launchers

<table>
  <tr>
    <td colspan="2" align="center">
      <h5>Rofi Launchers</h5>
    </td>
  </tr>  
  <tr>
    <td><img src="https://github.com/user-attachments/assets/2bf01b16-5133-41f9-b02c-1898ad59fef3" width="100%" alt="launcher10"></td>
    <td><img src="https://github.com/user-attachments/assets/6a4b8384-5bb5-4a31-aeb0-497a372ff6d1" width="100%" alt="launcher9"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/12dd4fa5-3081-4d50-a526-153c2445c998" width="100%" alt="launcher8"></td>
    <td><img src="https://github.com/user-attachments/assets/bb6053bc-64d6-446b-a812-119b60d70809" width="100%" alt="launcher7"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/10a1db31-4672-4125-969d-e2a8e9611c11" width="100%" alt="launcher6"></td>
    <td><img src="https://github.com/user-attachments/assets/6e4bafe4-b262-490b-92e2-9578899a41bc" width="100%" alt="launcher5"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/356e4410-9c0c-4e9b-b215-2cc399b9ab80" width="100%" alt="launcher4"></td>
    <td><img src="https://github.com/user-attachments/assets/e6aa844e-d9ad-48cd-8abe-add5221bd291" width="100%" alt="launcher3"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/dae41bc2-db4e-42cf-834e-7c901230dc2f" width="100%" alt="launcher2"></td>
    <td><img src="https://github.com/user-attachments/assets/813b093f-0638-40ca-883b-bfd615dbc815" width="100%" alt="launcher1"></td>
  </tr>
</table>

<table>
  <tr>
    <td colspan="2" align="center">
      <h5>Rofi Powermenus</h5>
    </td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/63ef714b-339a-4f24-910f-39063ca9901d" width="100%" alt="pm1"></td>
    <td><img src="https://github.com/user-attachments/assets/34ac5343-d1e8-4dda-bdde-02d18860ed31" width="100%" alt="pm2"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/8d234137-a551-4b79-af26-25aa4ab5994f" width="100%" alt="pm3"></td>
    <td><img src="https://github.com/user-attachments/assets/e208c391-66ae-493b-a4b4-00c7b833b0ab" width="100%" alt="pm4"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/6fa0ef70-9857-47ef-adc7-459a801e5bfb" width="100%" alt="pm5"></td>
    <td><img src="https://github.com/user-attachments/assets/81155fec-a7a5-4e71-b697-39b0a3f4df45" width="100%" alt="pm6"></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/e47197f3-04be-43bd-afeb-6eeba9570435" width="100%" alt="pm7"></td>
    <td><img src="https://github.com/user-attachments/assets/36122913-484f-4e04-bad0-1a1a7c7dd98a" width="100%" alt="pm8"></td>
  </tr>
</table>

## Waybar

<table> 
  <tr>
    <td colspan="2" align="center">
      <h5>Caps Lock ON</h5>
      <img src="https://github.com/user-attachments/assets/e6bc5bef-359c-4715-9b87-25700bf36e1b" width="100%" alt="Caps Lock ON">
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <h5>Compact Pill</h5>
      <img src="https://github.com/user-attachments/assets/08f4fb75-5470-4e34-bec7-500449e2a385" width="100%" alt="Compact Pill">
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <h5>Pill</h5>
      <img src="https://github.com/user-attachments/assets/dde66362-c0cd-439f-b22d-8cd5c82e9a1a" width="100%" alt="Pill">
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <h5>Square</h5>
      <img src="https://github.com/user-attachments/assets/1609929a-9d09-4e9b-a393-710ffda6c7d1" width="100%" alt="Square">
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <h5>Outline</h5>
      <img src="https://github.com/user-attachments/assets/54131236-9d1f-403c-8219-0d684e591809" width="100%" alt="Outline">
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center">
      <h5>Standard</h5>
      <img src="https://github.com/user-attachments/assets/46bb7698-7cdb-4043-982b-e20f61240b6a" width="100%" alt="Standard">
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <h5>Waybar Customization</h5>      
      <video src="https://github.com/user-attachments/assets/e5012ace-2f97-4851-abf2-6c24fcae5005" controls="controls" style="max-width: 100%;"></video>
    </td>    
    <td width="50%" align="center">
      <h5>Change System Theme From Waybar</h5>
      <img src="https://github.com/user-attachments/assets/f5dc93d5-157f-4104-95fb-100fd733ca00" width="100%" alt="image" />
    </td>
  </tr>
</table>

### Rofi Applets

<table>
 <tr>
    <td colspan="2" align="center">
      <h5>Wallpaper Picker</h5>
    </td>
  </tr>    
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/16c61848-88e1-49f6-bad9-cf69a048f0bc" width="100%" alt="wallselect"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/99052231-6865-4e05-b5cd-bc62d01ef06a" width="100%" alt="wallselect"></td>
  </tr>
</table>

<table>
  <tr>
    <td width="50%" align="center">
      <h5>Rofi WIFI Manager</h5>
      <video src="https://github.com/user-attachments/assets/779cb6fa-7909-4df0-9d58-5d9d525d3b18" controls="controls" style="max-width: 100%;"></video>
    </td>
    <td width="50%" align="center">
      <h5>Rofi Nowplaying</h5>
      <video src="https://github.com/user-attachments/assets/9426fdae-8a95-4335-972e-11dd9aaa1762" controls="controls" style="max-width: 100%;"></video>
    </td>
  </tr>
</table>

<table>
  <tr>
    <td width="50%" align="center">
      <h5>Rofi Clipboard Manager</h5>
      <video src="https://github.com/user-attachments/assets/bc4f54b8-6bb6-4a74-96db-2ca61d81e915" controls="controls" style="max-width: 100%;"></video>
    </td>
    <td width="50%" align="center">
      <h5>Rofi Nightlight</h5>
      <video src="https://github.com/user-attachments/assets/11784326-a632-456d-a01c-0ad04f59d83b" controls="controls" style="max-width: 100%;"></video>
    </td>
  </tr>
</table>

<table>
  <tr>
    <td colspan="3" align="center">
      <h5>Rofi Screen Tool</h5>
    </td>
  </tr>  
  <tr>
    <td align="center">
      <h5>Recording Thumbnail</h5>
      <img src="https://github.com/user-attachments/assets/66757cca-3feb-4080-b832-9972bc87d675" width="100%">
    </td>
    <td align="center">
      <h5>Screenshot Save</h5>
      <img src="https://github.com/user-attachments/assets/b55b5e35-360d-4c1f-aab0-13e88de17074" width="100%">
    </td>
    <td align="center">
      <h5>Screenshot Copied</h5>
      <img src="https://github.com/user-attachments/assets/cb97e7fd-4218-48ef-897f-bad77e97939a" width="100%">
    </td>
  </tr>
  <tr>
    <td colspan="3" align="center">
      <video src="https://github.com/user-attachments/assets/3ea9bfa6-5348-4d1e-a7a1-1ed885b7a2c6" controls="controls" style="max-width: 100%;"></video>
    </td>
  </tr>
</table>

### Hyprlock

<table>
  <tr>
    <td colspan="3" align="center">
      <h5>Hyprlock With Matugen and Dynamic Nowplaying With albumart</h5>
    </td>
  </tr>
  <tr>
    <td align="center">
      <h5>Nothing Playing Clean Look</h5>
      <img src="https://github.com/user-attachments/assets/67d58c10-5324-4365-922c-0da4bb15f6e0" width="100%">
    </td>    
    <td align="center">
      <h5>Lock Screen With Albumart</h5>
      <img src="https://github.com/user-attachments/assets/e6592c97-4b73-4ba6-b290-90bb89f1ea1a" width="100%">
    </td>
    <td align="center">
      <h5>Fallback Albumart</h5>
      <img src="https://github.com/user-attachments/assets/c2702797-a553-47f3-924f-ed50e172f966" width="100%">
    </td>
  </tr>
  <tr>
    <td colspan="3" align="center">
      <video src="https://github.com/user-attachments/assets/e68fd9ec-675a-49fa-8df6-c1aab044256a" controls="controls" style="max-width: 100%;"></video>
    </td>
  </tr>
</table>

### Mpv

<table>
  <tr>
    <td colspan="2" align="center">
      <h5>Mpv With Matugen And Modern Look</h5>
    </td>
  </tr>  
  <tr>
    <td><img src="https://github.com/user-attachments/assets/9c7bc7a5-6ce6-4128-b1b8-5a46e94de633" width="100%" alt="mpv2"></td>
    <td><img src="https://github.com/user-attachments/assets/eef3d42f-9b0f-47c1-aced-c4af8e262c44" width="100%" alt="mpv1"></td>
  </tr>
</table>


</details>

---
  
## Update and Fixes

*First of all, scripts are efficent and light they literally use < 0% cpu and With all the daemons and script running at once the ram usage should be under 50-60mb.*

### New Scripts

- `alarm:` A full function alarm with snoozing feature. you can set alarm once, specific day of week or daily with alarm title.
- `waybar timer:` A waybar timere with `stopwatch`, `countdown` and `pomodoro` mode with sound ofcourse.
- `data monitor:` A script to monitor internet traffic. It shows internet speed, control data usage (you set data limit for day and month and it will notify when usage reaches 90%. **(It will not disconnect internet connection)**
- `pin notes:` A script that shows notes as waybar tooltip. It reads the files in `pins` folder in your home directory finds `.txt` file which are your notes and show them as tooltip. You can scroll to switch the notes and also use some basic markup.
  ```
     H3 (###) -> Medium Bold
     H2 (##)  -> Large Bold
     H1 (#)   -> Extra Large Bold Underline
     Bold (**text**) 
     Italic (*text*) 
     Bullets (- ) -> • 
  ```
- `dns changer:` A script to apply encrypted (DoT) dns to you system (requires systemd.resolved to work). It works!!!
- `clock-calendar` script for waybar. This script shows calendar tooltip with events.
- `rofi tube:` A Python script to play youtube videos in mpv or vlc. You can use `Youtube` or `Youtube-music`. It's good if you use it for listening to music. It stores the search history and also has cache function so it's not slow.
  
    **Some clarification about this script**
   - I know that yt-dlp is integrated in mpv by default
   - I know you can fetch youtube search from yt-dlp and don't need a youtube scrapper
   - I used these complex function as Youtube scrapper is super fast it takes few seconds maybe 2-3 (depending on internet speed) whereas yt-dlp can take more than 30sec maybe even more than a minute
   - Providing a direct link to mpv will generate a very long playlist which is time taking and also useless in my point of view i wanted few items only.
   - One downside of this script is that you can't have an actual playlist in the player and to skip an item you just end the video and it will play next (no previous)
- `Swaync:` You can use swaync as notification daemon. It will give you buttons in notification and animation.
  
and few more small scripts...

### Improvements

- Hover selection and single mouse click input for all rofi window.
- Fixes notification flooding by using notification id's
- Improved `wallselect` script, you can now use script as `wallselect.sh /path/to/img` and it will use that image. You can set context menu in thunar and now just right click the image and set it as wallpaer and everything will update colors, theme etc.
- Improved `rofi-nowplaying` script (more fast, improved notifications, player cache and more themes) It's great....
- Improved `screen-tool` script, Now you can record system audio too and also screen freez while taking screenshot so that you can take screenshot of tooltips, popups etc..
- Dynamic colors for `fallback_album_arts` for both hyprlock and rofi
- Added keybindings for volume and brightness buttons `XF86`buttons to `bash script` that shows real beautiful notification
- Added copied image as icon for notification when copying from history in `clipboard.sh`.
- New transparency(alpha) control app for waybar to customize.
  
and many more small changes...

<details>
<summary>
<strong>
<picture>
  <source srcset="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4f8/512.webp" type="image/webp">
  <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4f8/512.gif" alt="📸" width="32" height="32">
</picture>
 Click Here to View Updates and Changes
</strong>
</summary>

<table>
  <tr>
    <td colspan="4" align="center">
      <h4>Alarm</h4>
    </td>
  </tr>
  <tr>
    <td colspan="2" align="center"><h6>Dunst</h6></td>
    <td colspan="2" align="center"><h6>Swaync</h6></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/d1712a91-0eb4-4abd-b506-f3c058818d53" width="100%" alt="launcher8"></td>
    <td><img src="https://github.com/user-attachments/assets/1a6384ce-1168-4f2f-9a8a-82da60ec5098" width="100%" alt="launcher7"></td>
    <td><img src="https://github.com/user-attachments/assets/344e63d1-30d4-4dcf-9cb5-2fadafc1b024" width="100%" alt="launcher10"></td>
    <td><img src="https://github.com/user-attachments/assets/8eb60868-b5ad-4345-928c-0aa5ee6339af" width="100%" alt="launcher9"></td>
  </tr>
</table>

<table width="100%">
  <tr>
    <td colspan="2" align="center">
      <h4>Clock-Calendar Script</h4>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="https://github.com/user-attachments/assets/97c55f0f-1898-42b1-bd16-6b7db50a883f" 
           width="40%"">
    </td>
    <td width="50%">
      <img src="https://github.com/user-attachments/assets/506e33f9-3a94-49e7-b3c9-d4e1b949b3ee" 
           width="100%">
    </td>
  </tr>
  <tr>
    <td>
      <img src="https://github.com/user-attachments/assets/0a554df6-a796-4da1-9131-be0f7cd0de28" 
           width="100%">
    </td>
    <td>
      <img src="https://github.com/user-attachments/assets/4b59d788-b613-43df-92ee-ea3b70ce127d" 
           width="100%">
    </td>
  </tr>
</table>

<table>
  <tr>
    <td colspan="5" align="center">
      <h4>New Styles of Rofi nowplaying</h4>
    </td>
  </tr>
  <tr>
    <td align="center"><h6>Style 1</h6></td>
    <td align="center"><h6>Style 2</h6></td>
    <td align="center"><h6>Style 3</h6></td>
    <td align="center"><h6>Style 4</h6></td>
    <td align="center"><h6>Style 5</h6></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/318e0673-141c-4c71-b216-88a786e8407e" alt="style-1" width="100%"></td>
    <td><img src="https://github.com/user-attachments/assets/f30fbfd5-0250-4c45-8f9d-6d09cbe34901" alt="style-2" width="100%"></td>
    <td><img src="https://github.com/user-attachments/assets/dbea83a3-4795-423b-9ddc-d77d5dde1286" alt="style-3" width="100%"></td>
    <td><img src="https://github.com/user-attachments/assets/bee7b565-3b1b-4b1e-bb26-4d020ab1a02c" alt="style-4" width="100%"></td>
    <td><img src="https://github.com/user-attachments/assets/d32f8b0c-cc11-4e2b-bd47-6af8844b626a" alt="style-5" width="100%"></td>
  </tr>
</table>

<table>
  <tr>
    <td colspan="4" align="center">
      <h4>Dns (Dot) and Data Monitor Script</h4>
    </td>
  </tr>
    <tr>
    <td align="center"><h6>Waybar Tooltip</h6></td>
    <td align="center"><h6>DNS Changer</h6></td>
    <td align="center"><h6>Alert Notification</h6></td>      
    <td align="center"><h6> </h6></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/5850b50a-b340-4ac9-8ba8-9c2bfcd5d0c9" alt="img2" width="100%"></td>    
    <td><img src="https://github.com/user-attachments/assets/5f025653-866f-4f90-93c3-59771bb10403" alt="img4" width="100%"></td>        
    <td><img src="https://github.com/user-attachments/assets/4cf8f577-629c-46a0-bb0d-f8bc9d3407be" alt="img4" width="100%"></td>    
    <td><img src="https://github.com/user-attachments/assets/87134b5c-428f-4ada-a7de-c371851ee851" alt="img3" width="100%"></td>
  </tr>
</table>

<table>
  <tr>
    <td colspan="4" align="center">
      <h4>New Todo and Countdown Scripts</h4>
    </td>
  </tr>
    <tr>
    <td align="center"><h6>Todo</h6></td>
    <td align="center"><h6>Countdown</h6></td>      
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/b73e56a2-2692-4e7e-aeb9-c6439ca5c41d" alt="img2" width="100%"></td>        
    <td><img src="https://github.com/user-attachments/assets/ec819501-dd9e-40d4-9dca-62372846126e" alt="img4" width="100%"></td>     
  </tr>
</table>

<table>
  <tr>
    <td colspan="3" align="center">
      <h4>Rofi Tube</h4>
    </td>
  </tr>
    <tr>
    <td align="center"><h6>Mode Selection</h6></td>
    <td align="center"><h6>Search window with history</h6></td>
    <td align="center"><h6>Search result window</h6></td>   
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/614440ed-e098-4818-ae6d-a2055e677578" alt="img2" width="100%"></td>    
    <td><img src="https://github.com/user-attachments/assets/6e4df99d-3b2f-4eda-865b-0749d36272c9" alt="img4" width="100%"></td>        
    <td><img src="https://github.com/user-attachments/assets/878f78ac-5504-416d-9c63-d21bb2e21edf" alt="img4" width="100%"></td> 
  </tr>
</table>

### Videos (unmute video to listen to sound)

https://github.com/user-attachments/assets/a293e78c-6146-41db-a1be-18af4ed766de

https://github.com/user-attachments/assets/1c202ae5-f2ef-4c59-8a94-aa8c9203e549

https://github.com/user-attachments/assets/cdbfb685-a99e-4d71-ad53-4ff991510009

https://github.com/user-attachments/assets/fdc9f80e-db2b-4c67-81eb-9e24b13d2762

https://github.com/user-attachments/assets/ade195c9-219c-4e0d-bea4-b20a41ce1714

https://github.com/user-attachments/assets/c450293f-6e24-42b9-bff6-51a4a6371388

</details>

---

## Installation

**Arch Linux Users:**
```bash
git clone https://github.com/Harsh-bin/modern-labwc/
cd modern-labwc
chmod +x setup.sh
./setup.sh
```

**Other Distributions:**
1. Install dependencies manually.
2. Copy config files to `~/.config/` matching the directory structure.
3. Copy fonts to `~/.local/share/`.
4. Copy Curso theme to `~/.local/share/icons`.
5. Copy `matugen-labwc` theme folder to `~/.themes`.

## Dependencies

**For Arch Linux**: Run `setup.sh` to automatically install all dependencies.

**For Other Distributions**: Install these packages manually:

`imagemagick`, `labwc`, `wl-clipboard`, `cliphist`, `wl-clip-persist`, `waybar`, `rofi`, `ffmpegthumbnailer`, `ffmpeg`, `dunst`, `matugen`, `foot`, `swww`, `swayidle`,
`hyprlock`, `qt5-wayland`, `qt5ct`, `qt6ct`, `qt6-wayland`, `nm-connection-editor`, `lxqt-policykit`, `gnome-keyring`, `wf-recorder`, `grim`, `gammastep`, `mpv-mpris`, 
`slurp`, `playerctl`, `pavucontrol`, `pamixer`, `brightnessctl`, `xdg-desktop-portal`, `xdg-desktop-portal-wlr`, `thunar`, `xfce4-taskmanager`, `jq`, `netcat`, 
`python-watchdog`, `alsa-utils`, `swayimg`, `otf-font-awesome`, `inter-font`, `ttf-roboto`, `papirus-icon-theme`, `adw-gtk-theme`.

---

## Keybindings

Keybindings are configured in `~/.config/labwc/rc.xml`.

**Keys Naming:**
--**Return**: Enter key
- **W**: Super / Windows key
- **A**: Alt key
- **S**: Shift key  (Note: lowercase `s` is just alphabate, uppercase `S` is shift)
- **C**: Ctrl key

**Example of how to edit:**
To change the terminal (Return key) shortcut:
```xml
<keybind key="W-Return">
    <action name="Execute" command="foot" />
</keybind>
```

### Main Shortcuts (used in this confi)

| Key Combination | Action | Description |
| :--- | :--- | :--- |
| `W-Return` | Execute | Open Terminal (foot) |
| `F11` | ToggleFullscreen | Toggle fullscreen mode |
| `W-d` | Execute | Open Rofi Dmenu (Apps Launcher) |
| `W-c` | Execute | Customization Panel |
| `W-b` | Execute | Wallpaper selector |
| `W-Delete` | Execute | Power Menu |
| `W-g` | Execute | Generate desktop root menu (Apps Menu) |
| `W-s` | Execute | Open Screen Tool (Screenshot/Record) |
| `W-y` | Execute | Open Rofi Tube (YouTube) |
| `W-l` | Execute | Lock Session |
| `W-r` | Reconfigure | Reload Labwc Config |
| `A-Tab` | NextWindow | Switch to next window |
| `A-S-Tab` | PreviousWindow | Switch to previous window |

### Workspaces & Windows

| Key Combination | Description |
| :--- | :--- |
| `W-1` to `W-4` | Switch to Workspace 1-4 |
| `W-S-1` to `W-S-4` | Move window to Workspace 1-4 |
| `W-Arrow Keys` | Snap window to Top/Bottom/Left/Right |

---

## Configuration

> [!CAUTION]
> Important Configuration to control `Alarm` and `Timer` script from terminal <br></br>

<details>
<summary>
<strong>
 Click here to see instruction 
</strong>
</summary>

<br>

> [!WARNING]
> This script uses syntax compatible with **Bash** and **Zsh**.  
> It **will not work** on **Fish** or **NuShell** without modification.

Add the following lines to your `~/.bashrc` or `~/.zshrc` just copy paste it:

```bash
######################################
#### To Control Waybar Timer #########
######################################

timer() {
    local script_path="$HOME/.config/waybar/scripts/timer/waybar_timer.py"

    if [[ ! -f "$script_path" ]]; then
        echo "Error: Script not found at $script_path"
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        python3 "$script_path" --help
        return
    fi

    case "$1" in
        # Shortcuts for specific modes
        sw|stopwatch)
            python3 "$script_path" stopwatch "${@:2}"
            ;;
        cd|countdown)
            python3 "$script_path" countdown "${@:2}"
            ;;
        add)
            python3 "$script_path" countdown add "${@:2}"
            ;;
        pomo|pomodoro)
            python3 "$script_path" pomodoro "${@:2}"
            ;;
        pause|resume|start|reset|toggle|toggle-pause)
            python3 "$script_path" --current "$1"
            ;;            
        # View toggling
        view|toggle-view)
            python3 "$script_path" --toggle-view
            ;;            
        [0-9]*)
            python3 "$script_path" countdown "$@"
            ;;            
        # Pass anything else directly to the script
        *)
            python3 "$script_path" "$@"
            ;;
    esac
}

###################################
#### To Manage Alarms #############
###################################

alias alarm='~/.config/waybar/scripts/clock_calendar/alarm/alarm.sh'
```
</details>  

### 1. Keybindings
As mentioned above, all keybindings are handled in `~/.config/labwc/rc.xml` inside the `<keyboard>` section.

### 2. Mouse & Touchpad Acceleration
To change mouse/touchpad speed and acceleration, edit the `<libinput>` section in `~/.config/labwc/rc.xml`.

**Example:**
```xml
<libinput>
    <device category="touchpad">
        <pointerSpeed>0.3</pointerSpeed> <!-- -1.0 (slowest) to 1.0 (fastest) -->
        <accelProfile>adaptive</accelProfile> <!-- adaptive or flat -->
        <tap>yes</tap>
    </device>
</libinput>
```

### 3. Workspaces
To change the number of workspaces or their names, edit the `<desktops>` section in `~/.config/labwc/rc.xml`:

```xml
<desktops number="4" />
<desktops>
    <names>
        <name>WS 1</name>
        <name>WS 2</name>
    </names>
</desktops>
```

### 4. Waybar Customization
You can tweak `config.jsonc` to your needs.

*IMPORTANT!!! Don't change the module name like if you planed to modify the config to use `firefox` insted of chrome then you shouldn't change the module name form `custom/chrome` to `custom/firefox` as if you do then you have to edit the waybar css to apply the changes so it's best to just edit the command.*


**Example: Change the browser used by the `custom/chrome` module**

- **Open** the file `~/.config/waybar/config.jsonc` and edit `custom/chrome`:

```json
"custom/chrome":
{
	"format": "",
	"tooltip": true,
	"tooltip-format": "Browser",
	"on-click": "google-chrome-stable",
	"on-click-right": "chromium",
	"on-click-middle": "brave"
}
```

- **Edit** the `on-click`, `on-click-right`, or `on-click-middle` commands to your preferred browsers. For example:

```json
"custom/chrome":
{
	"format": "",
	"tooltip": true,
	"tooltip-format": "Browser",
	"on-click": "firefox",
	"on-click-right": "brave",
	"on-click-middle": "google-chrome-stable"
}
```
Apply the same edit pattern to other `custom/*` modules.

To know more follow [waybar wiki](https://github.com/Alexays/Waybar/wiki/Module:-Custom)

### 5. Changing Wallpaper Path
To change the directory: Edit `~/.config/rofi/wallselect/wallselect.sh` and change the `wall_dir` path to your liking.

You can also change the wallpaper picker theme to `style-2`

```
# Change path to wallpaper
wall_dir="/usr/share/backgrounds/images/"

# Wallselect theme file
wallselect_theme="$HOME/.config/rofi/wallselect/style-1.rasi"
```

### 6. Adding context menu in thunar to easily set wallpaer by right clicking on Images or Gif's

- Open thunar go to Edit -> Configure custom actions
- Click `+` icon to add new
- In `command` field write this `$HOME/.config/rofi/wallselect/wallselect.sh %f`
- The go to `Appearance Conditions` and tick  `imgage files`

**Tip** If you don't use xfce4 and don't use the default `Set as wallpaper` option that is used to set background  in xfce4 then you can disable it by 
`sudo mv thunar-wallpaper-plugin.so thunar-wallpaper-plugin.so.old` and to re-enable it `sudo mv thunar-wallpaper-plugin.so.old thunar-wallpaper-plugin.so`

<table>
<tr>
<td><img src="https://github.com/user-attachments/assets/f10b3be8-fc95-41b2-9f19-751ffccbf39d" width="90%"></td>  
<td><img src="https://github.com/user-attachments/assets/08f95c53-a098-435b-95bd-513f2abf9502" width="90%"></td>
</tr>
</table>

### 7. Changing Lockscreen Profile Photo
To change the profile picture (pfp), you must replace the `~/.config/hypr/hyprlock/user.jpg` image.
1. Rename your desired photo to `user.jpg`.
2. Move it to `~/.config/hypr/hyprlock/`.

**Troubleshooting:**
*   **Extension Mismatch:** If you rename a `.png` file to `.jpg` manually, it may not load. The file extension must match the format.
*   **Convert Image:** Run `magick your_image.png output.jpg` to convert it properly.
*   **Use PNG:** If you prefer using a PNG, edit `~/.config/hypr/hyprlock.conf`. Look for line 34:
    `path = ~/.config/hypr/hyprlock/user.jpg`
    Change it to: `path = ~/.config/hypr/hyprlock/user.png`.

### 8. Use TUI Version of `todo` `countdown` and `clock-calendar`
Tui version of these scripts exist to use them you have to modify the waybar `config.jsonc` file 

**Example**
```
{
      "custom/todo":
      {
          "format": "\u00a0{}",
          "exec": "~/.config/waybar/scripts/todo/todo.sh",
          "on-double-click": "~/.config/waybar/scripts/todo/todo.sh --mark-done",

          /// To use tui on right click use something like this
         ///  "on-click-right": "foot ~/.config/waybar/scripts/todo/todo.sh --show-tui",

          "on-click-right": "killall rofi || bash ~/.config/waybar/scripts/todo/todo.sh --show-rofi",
          "on-click-middle": "~/.config/waybar/scripts/todo/todo.sh --middle-click",
          "return-type": "json",
          "interval": 5,
          "tooltip": true
      },
}
```

Note: For `clock-calendar script you have to edit this

```
      "custom/clock":
      {
          "exec": "~/.config/waybar/scripts/clock_calendar/clock_calendar.sh",
          "return-type": "json",
          "format": "  {}",
          "format-alt": "  {alt}",
          "interval": 10,
          "tooltip": true,

          /// To use tui on right click use something like this
         ///  "on-click-right": "foot ~/.config/waybar/scripts/clock_calendar/clock_calendar.sh --show-tui",

          "on-click-right": "killall rofi || bash ~/.config/waybar/scripts/clock_calendar/choose.sh",
          "on-scroll-up": "$HOME/.config/waybar/scripts/clock_calendar/clock_calendar.sh --scroll-up",
          "on-scroll-down": "$HOME/.config/waybar/scripts/clock_calendar/clock_calendar.sh --scroll-down"
      },
  ```

### 9. Locale & Input
To change your keyboard layout or region, edit `~/.config/labwc/environment`:

```bash
# --- Input & Region ---
XKB_DEFAULT_LAYOUT=us
LANG=en.US.UTF-8
```

### 10. Rofi Tube
You can set the video Quality, Coded and video player by editing `~.config/rofi/rofi-tube/rofi-tube.conf` 

Important Rofi tube will stop working if you use it regularly without using a browser cookie
To fix this:
- you have to Download this extension [Get cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)
- Open `Incognito Window` and open youtube and then click this extension and click `Export All Cookies` this will download a `.txt` file
- Rename that `.txt` file to `youtube-cookies.txt` and move it to `~.config/rofi/rofi-tube/`

***TIP** You can watch youtube in browser for a while to build your feed, then export cookies. so that rofi tube can use that cookie and recommend the videos and music which you like*

*IMPORTANT!!! Don't use your google account cookies as it may block your youtube account*

### 11. Changing Notification Daemon
To Change the notification daemon you have to edit the `~/.config/labwc/autostart` file.
Search the `dunst >/dev/null 2>&1 &` and replace it with `swaync >/dev/null 2>&1 &`
 
<h2>
<picture>
  <source srcset="https://fonts.gstatic.com/s/e/notoemoji/latest/1f91d_1f3fb/512.webp" type="image/webp">
  <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f91d_1f3fb/512.gif" alt="🤝" width="32" height="32">
</picture>
  Contributing
</h2>
I am happy to collaborate! Feel free to contribute to this project in any way you can.
Whether it's fixing a bug, adding a new feature, or even a small change like enhancing README, every contribution matters and is highly appreciated.

### Credits
Rofi launcher and powermenu [adi1090x](https://github.com/adi1090x) Matugen [InioX](https://github.com/InioX)

<h4>
Enjoy your beautifully themed Labwc desktop!
<picture>
  <source srcset="https://fonts.gstatic.com/s/e/notoemoji/latest/1f389/512.webp" type="image/webp">
  <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f389/512.gif" alt="🎉" width="32" height="32">
</picture>
</h4>

[![Star History Chart](https://api.star-history.com/svg?repos=Harsh-bin/modern-labwc&type=Timeline)](https://star-history.com/#Harsh-bin/modern-labw&Timeline)
