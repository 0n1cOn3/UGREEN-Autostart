# Autostart for external storage media for UGREEN UGOS PRO

**Autostart** allows you to **execute any shell script statements** that are automatically executed **after** connecting an **external USB storage media** to your **UGREEN NAS**.

> [!NOTE]
> If you looking for the german version, click on [this]( https://github.com/toafez/UGREEN_autostart) Link.

## How does autostart work

If an external USB storage media is connected to the **UGREEN-NAS**, it is first recognized by **UGOS Pro** and integrated into the system (mounted). Then **autostart** checks whether there is a shell script file with the name **autostart.sh** in the root directory of the external USB storage media or on the mounted partitions. If this is the case, the content of the shell script file is executed, otherwise the monitoring for this storage media is terminated. After the execution of the shell script file, a log file with the name **autostart.log** is stored in the root directory of the external USB storage media.

> [!IMPORTANT]
> ## Safety instructions
> After setting up **autostart**, the contents of the **autostart.sh** file are executed with **root rights** each time an external USB storage media is plugged in. This gives the user a great deal of freedom, but also a
> **high degree of responsibility**. In addition to unintentional or unforeseeable errors in the script itself, some of which can cause considerable damage, there may also be deliberate attempts by third parties to
> compromise the script if they are aware of the existence of autostart on your UGREEN NAS.
> Since **autostart** cannot yet be integrated as an app in **UGOS Pro**, there are also no advanced configuration options, such as a switch to temporarily deactivate the autostart function or to swap the shell script
> file to an internal volume of the UGREEN NAS and link it to the UUID of the external USB storage media, as the app [AutoPilot](https://github.com/toafez/AutoPilot) from toafez written for Synology allows.
> Due to the existing security deficiencies, toafez added instructions at the end on how to uninstall **autostart** via the command line if necessary.

## Installation instructions

For the initial setup of autostart, it is necessary to connect to the command line of your UGREEN NAS via SSH. This requires a terminal program such as PuTTy, Windows PowerShell, MAC Terminal or one of the numerous terminal programs under Linux. However, the command line will no longer be required later, as the autostart.sh shell script file can be edited using the **TextEdit** app provided by UGREEN.

### Activate SSH service

To establish an SSH connection to your UGREEN NAS, you must first activate the SSH service in UGOS Pro. To do this, log in to the UGOS Pro of your UGREEN NAS with an administrator account. Then navigate to My Apps > Control Panel > Terminal and activate the Enable SSH checkbox. If required, you can adjust the port that the SSH service should use directly below. Click on the Apply button to save your settings.

### Establish connection

1) Start your preferred terminal program.
2) In the following example, the name of the UGOS Pro administrator account is MyAdmin. In this example, the UGREEN NAS itself can be reached via the IPv4 address 172.16.1.12 and has the name UGREEN NAS. Therefore, replace the placeholders for [PORT], [USERNAME] and [IP ADDRESS] in the following command with your own data. Then execute the following command.

> [!NOTE]
> Text in capital letters within square brackets serves as a placeholder and must be replaced by your own information, including the square brackets.

  **Syntax:**

```bash
ssh -p [PORT] [USERNAME]@[IP ADDRESS]
```

  **Example:** Command input in the Windows PowerShell

```Powershell
PS C:\Users\MyUser> ssh -p 22 MyAdmin@172.16.1.12
```

After executing the connection command by pressing Enter, you will be prompted to enter the password of the administrator account with which you want to log in to the console of your UGREEN NAS.

```bash
MyAdmin@172.16.1.12's password:
```

After successfully entering the password and then pressing Enter, the prompt should appear after a short greeting and, if necessary, further information.

```bash
MyAdmin@UGREEN-NAS:~$
```

### Download script files and set permissions

Now you need to download a UDEV rules file and another shell script file from this GitHub repository to your UGREEN NAS. Starting with the UDEV rules file **99-usb-device-detection.rules**, copy the following command line into your open terminal window and execute the command.

```bash
sudo curl -L https://raw.githubusercontent.com/toafez/UGREEN_autostart/refs/heads/main/scripts/99-usb-device-detection.rules -o /usr/lib/udev/rules.d/99-usb-device-detection.rules
```

As the command must be executed as the system user root (recognizable by the preceding sudo command), you will be asked for a password once again. Here you enter the same password that you have already used to log in as administrator.

Now continue with the shell script file **usb-autostart-script-detection.sh**, copy the following command line into your open terminal window and execute the command as well.

```bash
sudo curl -L https://raw.githubusercontent.com/toafez/UGREEN_autostart/refs/heads/main/scripts/usb-autostart-script-detection.sh -o /usr/local/bin/usb-autostart-script-detection.sh
```

As you have already logged in as root, you do not need to enter the password again.

Certain access rights must still be assigned for this shell script file. Therefore, please also enter the following command

```bash
sudo chmod +x /usr/local/bin/usb-autostart-script-detection.sh
```

The installation is now completed. The monitoring of the external USB storage media is now active and the terminal connection can be terminated by entering the command exit.
 
### Create autostart.sh and fill it with content

As already mentioned at the beginning, autostart now monitors whether an external USB drive has been connected to the UGREEN NAS and checks whether there is a shell script file with the name autostart.sh in the root directory of this external drive or on the mounted partitions.If this is the case, the content of the shell script file is executed, otherwise monitoring is terminated. At this point, it is up to you to decide which shell scripts you want to execute and which tasks should be associated with them. There are also no major requirements such as the assignment of access rights to this file, the only important thing is that the name of the file is autostart.sh.

## Example: synchronous rsync data backup to an external storage media

To illustrate this, an rsync script for synchronous data backup of internal data to an external storage media is executed below.

- Connect an external USB storage media to your UGREEN NAS.
- Using the TextEdit app, which can be installed via the UGOS Pro App Center, create a new empty file with the name autostart.sh and save it in the root directory of the external drive or on a partition mounted there.
- Open this GitHub repository in a browser of your choice and change to the /scripts directory

    ![10_UGREEN_autostart_raw](/images/10_UGREEN_autostart_raw.png)

- Click on the shell script file autostart.sh to display the contents of the file.

    ![11_UGREEN_autostart_raw](/images/11_UGREEN_autostart_raw.png)

- Then click on the Raw button in the menu bar at the top right.

    ![12_UGREEN_autostart_raw](/images/12_UGREEN_autostart_raw.png)

- Right-click in the window and select “Select all” or “Select all” from the context menu that opens. Right-click in the window again and select “Copy” from the context menu that opens and paste the copied content into the opened autostart.sh file of the TextEdit app.

    ![13_UGREEN_autostart_raw](/images/13_UGREEN_autostart_raw.png)

- Look at the contents of the autostart.sh file, note the help texts in the User input section and adapt the variables for the target directory, the backup source(s) etc. to your needs.

    ![14_UGREEN_autostart_raw](/images/14_UGREEN_autostart_raw.png)

- Save the file again and close it.
- Then remove the external storage media and insert it again. The data backup script should now be executed.

## Uninstallation instructions

Due to the security deficiencies mentioned above, autostart can be uninstalled relatively easily via the command line if required. First and foremost, it is sufficient to delete the UDEV rule file, as this terminates the monitoring. Alternatively, the shell script file that executes autostart.sh on the external storage media can also be deleted.

**Deleting the UDEV rule file**

```bash
sudo rm /usr/lib/udev/rules.d/99-usb-device-detection.rules
```

**Delete the shell script file**

```bash 
sudo rm /usr/local/bin/usb-autostart-script-detection.sh
```
