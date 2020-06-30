#!/bin/bash

# This script allows will allow the user to name or rename the MacBook, bind it to a domain, and create a Mobile Account.
# If the account added is a valid Mobile Account, the option to make it an Administrator is also presented.  
# If the computer is already on a Domain, script can also be run to remove the device from Domain as well.  

# Author: John Hawkins | johnhawkins3d@gmail.com )

### Variables ###
OU0="replacewithyourOU0" # OU Group 1
OU1="replacewithyourOU1" # OU Group 2
DC0="replacewithyourDC0" # DC Group 1
DC1="replacewithyourDC1" # DC Group 2
domain="yourcompany.local" # Server for Domain Controller 

maxNum="********" # char length var used to determine username length

computerName=$(scutil --get ComputerName) # query the computer name
getModel=$(sysctl hw.model) # Gets the model name, either Air, Pro, or Mac
assetTag=$(ioreg -l | grep IOPlatformSerialNumber | cut -c 41-44) # Gets the serial number. 

# function to name or rename the MacBook
fNameOrRename()   {

    if echo "$getModel" =~ 'Pro'; then # if statement when query returns a 'pro'

        macModel='MBP'

    elif echo "$getModel" =~ 'Air'; then # if statement when query returns a 'air'

        macModel='MBA'

    elif echo "$getModel" =~ 'Mac'; then # if statement when query returns a 'imac or other'

        macModel='MAC'
    
    fi

    echo "Enter the User Name associated with this MacBook: "

    read -r userName

    if [ "$userName" \> "$maxNum" ]; then # determine if username entered is longer than char length allowed

        echo "User Name entered is longer than maximum allowed characters." 

        userName=$(echo "$userName" | cut -c 1-7)

    fi

    scutil --set ComputerName "$userName-$assetTag$macModel"

    echo "This MacBook has been named to: $computerName"

    fMainMenu

}

# function to enroll the MacBook to a domain
fEnrollToDomain()   {

    if curl --head dc1 | grep "OK" &>/dev/null; then # check if Mac can communicate with AD server

        echo "Established communication with Domain Controller..."

        if dsconfigad -show | grep "$domain"; then

            echo
            echo "This MacBooks is currently bound to a Domain."
            echo "Continue and Unbind it from Domain?"
            echo "    1  Yes : Confirm, confirm this request."
            echo "    2  No  : Cancel this request."
            read -r -p "Pick an action # (1-2): " CONFIRMUNBIND

            case $CONFIRMUNBIND in
                1 ) fUnbindFromDomain ;;
                2 ) fMainMenu ;;
            esac

        fi

        echo "We need a valid Domain Administrator that can bind the MacBook to the company Domain."
        echo "Please enter a valid Domain Administrator's User ID:"

        read -r domainAdmin

        echo "Attempting to bind this MacBook to $domain..."

        sudo dsconfigad -a "$computerName" -u "$domainAdmin" -ou "OU=$OU0,OU=$OU1,DC=$DC0,DC=$DC1" -domain "$domain"

        if dsconfigad -show | grep "$domain" &>/dev/null; then

            echo "The MacBook has been successfully enrolled to $domain."

        else

            echo "The MacBook has not been successfully enrolled to $domain."

        fi

    else 

        echo "There was no response from the Domain Server.  Are you connected to VPN?"

    fi

    fMainMenu

}

# function to create the mobile accout, and bind it to the Macbook, and ask if mobile account should be made admin
fCreateMobileAccount()  {

    if dsconfigad -show | grep "$domain" &>/dev/null; then # check if Mac can communicate with Domain Controller (if bound to Domain)

        echo "Please enter the User ID for the Mobile Account: "

        read -r mobileAccount

        echo "Attempting to add the Mobile Account as user on this MacBook..."

        sudo /System/Library/CoreServices/ManagedClient.app/Contents/Resources/createmobileaccount -n "$mobileAccount"

        echo
        echo "Make $mobileAccount an Administrator?"
        echo "    1  Yes : Confirm, confirm this request."
        echo "    2  No  : Cancel this request."
        read -r -p "Pick an action # (1-2): " CONFIRMADMIN

        case $CONFIRMADMIN in
            1 ) fMakeMobileAccountAdmin ;;
            2 ) fMainMenu ;;
        esac

    else 

        echo "There was no response from the Domain Server, or this MacBook is not bound to the Domain."

        fMainMenu

    fi

}

# function to make the mobile account an admin
fMakeMobileAccountAdmin()   {

    sudo dscl . -merge /Groups/admin GroupMembership "$mobileAccount"

    if dscl . -read /Groups/admin GroupMembership | grep "$mobileAccount" &>/dev/null; then # verify that mobile account is an admin
        
        echo "$mobileAccount is an admin on this computer."
        echo "...however, it might not hurt to open Users & Goups and verify this."

        killall Finder & sleep 3; # refreshes finder, wait 3 seconds for changes to take effect

        open /System/Library/PreferencePanes/Accounts.prefPane # open users and groups so the technician can verify

    else 

        echo "$mobileAccount is not an admin on this computer."

    fi

    fMainMenu

}

# function to unbind the macbook from domain
fUnbindFromDomain() {

    echo "We need a valid Domain Administrator that can bind the MacBook to the company Domain."
    echo "Please enter a valid Domain Administrator's User ID:"

    read -r domainAdmin

    sudo dsconfigad -remove -u "$domainAdmin"

    echo "MacBook has been successfully Unbinded from Domain."

    fMainMenu

}

### function to show author and credits ###
fCredits()  {

    echo
    echo " ########################################################################################### "
    echo " ################################ About This Script ######################################## "
    echo " ########################################################################################### "
    echo
    echo " Author: John Hawkins | Email: johnhawkins3d@gmail.com "
    echo
    echo " Purpose: Multifunction script that handles the following tasks: name or rename the...       "
    echo " ...MacBook, bind or unbind it to a domain, add a mobile account and choose to make that...  "
    echo " ...account a administrator.  Please note that if you are binding / unbinding the Macbook... "
    echo " ...to a domain, you need to input the proper domain server for your organization and OUs... " 
    echo " ...for the script to work correctly.  Input settings in ### variables ### section of script."
    echo
    echo
    echo " Please be aware that I am not responsible for any malfunctions or lost data.                "
    echo " By choosing to run and use this script, you are assuming all risk and liabilities.          "
    echo " Unfortunately, I cannot account for all possible variables, so take extra precautions.      "
    echo 

    fMainMenu

}

# function to exit if user selects to quit
fExit() {

    echo "Exiting Terminal..."

    killall Terminal

}

# main menu / options function
fMainMenu()	{   

    # text-only options prompt in terminal
    echo
    echo " ########################################################################################### "
    echo " ############################## Name and Domain for macOS ################################## "
    echo " ################# By: John Hawkins | Contact: johnhawkins3d@gmail.com ##################### "
    echo " ########################################################################################### "
    echo
    echo " Please make a selection below:                                                              "
    echo "    1  Name or Rename this MacBook <------------------------ Run in Desktop Mode ########### "
    echo "    2  Enroll or Unbind this MacBook to/from Domain <------- Run in Desktop Mode ########### "
    echo "    3  Create Mobile Account for this MacBook <------------- Run in Desktop Mode ########### "
    echo "    4  About this Script <---------------------------------- Run in Desktop Mode ########### "
    echo "    5  Exit Script <---------------------------------------- Run in Desktop Mode ########### "
    read -r -p "Pick an action # (1-5): " MAKESELECTION

    # actions to be taken by the text only options above
    case $MAKESELECTION in
        1 ) fNameOrRename ;;
        2 ) fEnrollToDomain ;;
        3 ) fCreateMobileAccount ;;
        4 ) fCredits ;;
        5 ) fExit ;;
    esac

}

fMainMenu
