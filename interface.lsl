//Interface Script by Da Chrome and Toy Wylie is licensed under a Creative Commons Attribution 3.0 Unported License. http://creativecommons.org/licenses/by/3.0/ Keep This Line Intact.
// You do NOT have to make derivative works open source.
// Supports 3 objects max

// Constants

key WILDCARD="ffffffff-ffff-ffff-ffff-ffffffffffff";
string NULL=NULL_KEY;
list NULL_LIST=[];
vector RED=<1.0,0.0,0.0>;
vector DARK_RED=<0.3,0.0,0.0>;
vector GREEN=<0.0,1.0,0.0>;
vector YELLOW=<1.000, 1.000, 0.000>;
vector ORANGE=<0.071, 0.071, 0.000>;
vector VIOLET=<1.0,0.0,1.0>;
vector DARK_VIOLET=<0.3,0.0,0.3>;
vector BLANK=<1.0,1.0,1.0>;
vector GREY=<0.910, 0.910, 0.910>;
vector BLUE=<0.000, 0.502, 1.000>;
string LED_ON="db551eeb-a066-f3bc-1a99-5ac772625970";
string LED_OFF=TEXTURE_TRANSPARENT;
//integer DEBUG=1; //Uncomment this and all //if(DEBUG) lines to debug

// Variables

integer primRoot=1; //Link Vars
integer primL1;
integer primL2;
integer primL3;
integer primSafety;
integer primMode;
integer primYes;
integer primNo;
integer primLockout;
integer primAAL;
integer primQueue;
integer primRelay=-2; // Defaults to LINK_ALL_OTHERS if you don't set the relay prim's name to "Relay"
integer buttonHeld; // Operation Vars
integer superSafety;
integer timeout;
integer holdTimeout;
integer srsTimeout;
integer flashTimeout;
integer attachSafetyTimeout=15;
integer lockoutTimeout;
integer controllerCount;
integer relayMode;
integer warningMode;
integer asking;
integer power;
integer listener;
integer attachmentListener;
integer attachmentsLocked;
integer attachmentTimeout;
integer attachmentStage;
list attachmentLockList;
list clothingLockList;
list avatarBlacklist;
list ATTACHMENTS=["none","chest","skull","left shoulder","right shoulder","left hand","right hand","left foot","right foot","spine",
"pelvis","mouth","chin","left ear","right ear","left eyeball","right eyeball","nose","r upper arm","r forearm",
"l upper arm","l forearm","right hip","r upper leg","r lower leg","left hip","l upper leg","l lower leg","stomach","left pec",
"right pec","center 2","top right","top","top left","center","bottom left","bottom","bottom right","neck","root"];
list CLOTHING=["gloves","jacket","pants","shirt","shoes","skirt","socks","underpants","undershirt","skin","eyes","hair","shape","alpha","tattoo"];
key ownerKey=NULL_KEY;
key avatarKey=NULL_KEY;
key safeKey=NULL_KEY;
key askingKey=NULL_KEY;
key object1Key=NULL_KEY;
key object2Key=NULL_KEY;
key object3Key=NULL_KEY;
integer lockoutGlobal;
list lockoutObjects; // To check for locked out objects
integer lockoutTimer;
integer detachMe;
integer permissionGranted;
integer lastSlot;
//integer SAFETY_DELAY_TIME=120; // Hardcoded ## Da
integer lockoutSafetyDelay=0;    // ## Toy
init()
{
    ownerKey=llGetOwner();
    permissionGranted=0;
    llSetTimerEvent(1.0);
    if(llGetAttached())
    {
        integer slot=llGetAttached();
        if(lastSlot!=slot)
        {
            lastSlot=slot;
            //llSetRot(llEuler2Rot(<0.0,270.0,260.0>*DEG_TO_RAD));
            if(slot==ATTACH_HUD_CENTER_2) llSetPos(<0.0,0.0,0.0>);
            else if(slot==ATTACH_HUD_TOP_RIGHT) llSetPos(<0.0,0.15,-0.15>);
            else if(slot==ATTACH_HUD_TOP_CENTER) llSetPos(<0.0,0.0,-0.15>);
            else if(slot==ATTACH_HUD_TOP_LEFT) llSetPos(<0.0,-0.15,-0.15>);
            else if(slot==ATTACH_HUD_CENTER_1) llSetPos(<0.0,0.0,0.0>);
            else if(slot==ATTACH_HUD_BOTTOM_RIGHT) llSetPos(<0.0,0.15,0.15>);
            else if(slot==ATTACH_HUD_BOTTOM) llSetPos(<0.0,0.0,0.15>);
            else if(slot==ATTACH_HUD_BOTTOM_LEFT) llSetPos(<0.0,-0.15,0.15>);
        }
        llRequestPermissions(ownerKey,PERMISSION_ATTACH | PERMISSION_TAKE_CONTROLS);
        if(slot<39 && slot>30)
        {
            if(attachmentsLocked)
            {
                lockAttachments();
            }
            llListen(-201818,"","","");
            llRegionSayTo(ownerKey,-201818,"Safety!");
            attachSafetyTimeout=15;
            if(lockoutSafetyDelay) lockoutSafetyDelay=120;
        }
        else
        {
            llOwnerSay("Please Attach to HUD only!");
            detachMe=1;
        }
    }
}
post()
{
    primL1=0;
    primL2=0;
    primL3=0;
    primSafety=0;
    primMode=0;
    primYes=0;
    primNo=0;
    primLockout=0;
    primQueue=0;
    integer y=llGetNumberOfPrims();
    if(y==1) primRoot=0;
    integer x;
    while(++x<=y)
    {
        if(llGetLinkName(x)=="1") primL1=x;
        else if(llGetLinkName(x)=="2") primL2=x;
        else if(llGetLinkName(x)=="3") primL3=x;
        else if(llGetLinkName(x)=="Safety") primSafety=x;
        else if(llGetLinkName(x)=="Mode") primMode=x;
        else if(llGetLinkName(x)=="Yes") primYes=x;
        else if(llGetLinkName(x)=="No") primNo=x;
        else if(llGetLinkName(x)=="Lockout") primLockout=x;
        else if(llGetLinkName(x)=="AAL") primAAL=x;
        else if(llGetLinkName(x)=="Relay Menu") primQueue=x;
        else if(llGetLinkName(x)=="Relay") primRelay=x;
    }
    if(primLockout) llSetLinkColor(primLockout,RED,ALL_SIDES);
    if(primSafety) llSetLinkColor(primSafety,YELLOW,ALL_SIDES);
    if(primMode) setMode(relayMode);
    else setMode(3);
    if(primL1) llSetLinkTexture(primL1,LED_ON,ALL_SIDES);
    if(primYes) llSetLinkColor(primYes,GREEN,ALL_SIDES);
    llSetLinkColor(primRoot,BLUE,ALL_SIDES);
    if(primAAL) llSetLinkTexture(primAAL,"dbde5431-812b-5fbc-bb6c-e97bf804bf69",ALL_SIDES);
    llSleep(0.1);
    if(primL2) llSetLinkTexture(primL2,LED_ON,ALL_SIDES);
    if(primNo) llSetLinkColor(primNo,RED,ALL_SIDES);
    llSleep(0.1);
    if(primL3) llSetLinkTexture(primL3,LED_ON,ALL_SIDES);
    if(primQueue) llSetLinkColor(primQueue,VIOLET,ALL_SIDES);
    llSleep(0.8);
    if(primL3) llSetLinkTexture(primL3,LED_OFF,ALL_SIDES);
    if(primQueue) llSetLinkColor(primQueue,DARK_VIOLET,ALL_SIDES);
    llSleep(0.1);
    if(primL2) llSetLinkTexture(primL2,LED_OFF,ALL_SIDES);
    if(primNo) llSetLinkColor(primNo,BLANK,ALL_SIDES);
    llSleep(0.1);
    if(primL1) llSetLinkTexture(primL1,LED_OFF,ALL_SIDES);
    if(primYes) llSetLinkColor(primYes,BLANK,ALL_SIDES);
    if(primLockout)
    {
        if(!lockoutTimer || !power) llSetLinkColor(primLockout,DARK_RED,ALL_SIDES);
        else llSetLinkColor(primLockout,ORANGE,ALL_SIDES);
    }
    if(primSafety)
    {
        if(!lockoutGlobal) setSafetyColor();
    }
    if(!power)
    {
        if(primMode) llSetLinkTexture(primMode,"269545d5-5691-b916-18ff-b0248d2ae39f",ALL_SIDES);
        llSetLinkColor(primRoot,BLANK,ALL_SIDES);
        if(primSafety) llSetLinkColor(primSafety,BLANK,ALL_SIDES);
    }
    else if(warningMode==1) llSetLinkColor(primRoot,GREY,ALL_SIDES);
    else llSetLinkColor(primRoot,BLANK,ALL_SIDES);
    if(attachmentsLocked)
    {
        if(primAAL) llSetLinkTexture(primAAL,"dbde5431-812b-5fbc-bb6c-e97bf804bf69",ALL_SIDES);
    }
    else
    {
        if(primAAL) llSetLinkTexture(primAAL,"382ae69b-1ee2-3073-e54e-00354d71fe05",ALL_SIDES);
    }
    lockoutObjects=NULL_LIST;
}
askSafety(key ids)
{
    avatarKey=ids;
    listener=llListen(181917,"",avatarKey,"");
    string message;
    if(safeKey==WILDCARD) message+=llGetUsername(ownerKey)+" is pleading for your help.\n\nWill you let them go?\nIgnoring this dialog will allow "+llGetUsername(ownerKey)+" to immediately ask someone else!";
    else message+=llGetUsername(ownerKey)+" is pleading for your help to be free of "+llKey2Name(safeKey)+".\n\nWill you let them go?\nIgnoring this dialog will allow "+llGetUsername(ownerKey)+" to immediately ask someone else!";
    llDialog(avatarKey,message,["Yes","No"],181917); //Give them a Yes/No menu
    if(llGetUsername(avatarKey)!="") llOwnerSay("Asking "+llGetUsername(avatarKey)+" for help");
    else llOwnerSay("Asking "+(string)avatarKey+" for help");
    //if(DEBUG) llOwnerSay((string)avatarKey);
}
closeAsking()
{
    llSetLinkColor(primYes,BLANK,ALL_SIDES);
    llSetLinkColor(primNo,BLANK,ALL_SIDES);
    llSetLinkColor(primQueue,DARK_VIOLET,ALL_SIDES);
    llSetLinkColor(primRoot,BLANK,ALL_SIDES);
    asking=0;
    askingKey=NULL;
}
setMode(integer newMode)
{
    if(newMode>3) newMode=0;
    if(!newMode)
    {
        llSetLinkTexture(primMode,"80741de3-c2a8-03ac-40a8-0801f92ca251",ALL_SIDES);
        llOwnerSay("Ask Mode");
    }
    else if(newMode==1)
    {
        llSetLinkTexture(primMode,"6046abf0-9460-ad32-64ae-69f852680924",ALL_SIDES);
        llOwnerSay("Lite Mode\n\n(Auto Force, Ask Restrictions)\n");
    }
    else if(newMode==2)
    {
        llSetLinkTexture(primMode,"adc2cd56-d422-47c9-7d11-3bb601f9dfcf",ALL_SIDES);
        llOwnerSay("Auto Mode\n\n(With Blacklist)\n");
    }
    else if(newMode==3)
    {
        llSetLinkTexture(primMode,"f32086f6-8c84-55db-dbe2-0fb782b6cad7",ALL_SIDES);
        llOwnerSay("⚠ Risky Mode ⚠\n\n(NO Blacklist)\n");
    }
    relayMode=newMode;
    llMessageLinked(LINK_ALL_OTHERS,relayMode,"SetMode",NULL);
    if(relayMode>1)
    {
        if(asking) closeAsking();
    }
}
setSafetyColor()
{
    if(primSafety)
    {
        if(superSafety) llSetLinkColor(primSafety,GREEN,ALL_SIDES);
        else llSetLinkColor(primSafety,BLANK,ALL_SIDES);
    }
}
lockAttachments()
{
    integer x=~llGetListLength(attachmentLockList);
    while(++x)
    {
        llOwnerSay(llList2String(attachmentLockList,x));
    }
    x=~llGetListLength(clothingLockList);
    while(++x)
    {
        llOwnerSay(llList2String(clothingLockList,x));
    }
    if(primAAL) llSetLinkTexture(primAAL,"dbde5431-812b-5fbc-bb6c-e97bf804bf69",ALL_SIDES);
    attachmentsLocked=1;
}
unlockAttachments()
{
    llOwnerSay("@clear=remattach");
    llOwnerSay("@clear=remoutfit");
    llMessageLinked(LINK_ALL_OTHERS,0,"Refresh",WILDCARD);
    if(primAAL) llSetLinkTexture(primAAL,"382ae69b-1ee2-3073-e54e-00354d71fe05",ALL_SIDES);
    attachmentsLocked=0;
    attachmentLockList=NULL_LIST;
    clothingLockList=NULL_LIST;
    attachmentStage=0;
    attachmentTimeout=0;
    llOwnerSay("Attachments Unlocked");
}
forceDetach()
{
    detachMe=0;
    llMessageLinked(LINK_ALL_OTHERS,0,"ForceDetach",ownerKey);
    llOwnerSay("@clear");
    llSleep(2.0);
    llDetachFromAvatar();
}
activateSafety() //Activates the Safety System
{
    if(controllerCount)
    {
        if(superSafety)
        {
            llMessageLinked(LINK_ALL_OTHERS,0,"Safety!",safeKey);
            llOwnerSay("You are free to go");
            closeSafety();
        }
        else
        {
            timeout=30;
            if(primSafety) llSetLinkColor(primSafety,YELLOW,ALL_SIDES);
            llSensor("","",AGENT,20.0,PI);
        }
    }
    else
    {
        if(superSafety!=1)
        {
            superSafety=1;
            llOwnerSay("Immediate Safeword Mode");
        }
        else
        {
            superSafety=0;
            llOwnerSay("Evil Safeword Mode");
        }
        setSafetyColor();
    }
}
closeSafety() //Closes the Safeword System
{
    llListenRemove(listener);
    if(avatarKey) avatarBlacklist+=avatarKey;
    setSafetyColor();
    safeKey=NULL;
    timeout=0;
    srsTimeout=0;
    avatarKey=NULL;
}
syncLockouts()
{
    if(primLockout)
    {
        integer x=~llGetListLength(lockoutObjects);
        key test;
        while(++x)
        {
            test=llList2Key(lockoutObjects,x);
            if(test!=object1Key)
            {
                if(test!=object2Key)
                {
                    if(test!=object3Key) lockoutObjects=llDeleteSubList(lockoutObjects,x,x);
                }
            }
        }
        if(lockoutGlobal+llGetListLength(lockoutObjects)+lockoutTimer==0)
        {
            if(primLockout) llSetLinkColor(primLockout,DARK_RED,ALL_SIDES);
        }
    }
}
default
{
    link_message(integer linkNumber, integer number, string message, key id)
    {
        if(message=="PowerOff")
        {
            lockoutSafetyDelay=0;    // ## Toy
            llOwnerSay("Relay Offline");
            power=0;
            if(primL1) llSetLinkTexture(primL1,LED_OFF,ALL_SIDES);
            if(primL2) llSetLinkTexture(primL2,LED_OFF,ALL_SIDES);
            if(primL3) llSetLinkTexture(primL3,LED_OFF,ALL_SIDES);
            if(primSafety) llSetLinkColor(primSafety,BLANK,ALL_SIDES);
            if(primMode) llSetLinkTexture(primMode,"269545d5-5691-b916-18ff-b0248d2ae39f",ALL_SIDES);
            if(primYes) llSetLinkColor(primYes,BLANK,ALL_SIDES);
            if(primNo) llSetLinkColor(primNo,BLANK,ALL_SIDES);
            if(primLockout) llSetLinkColor(primLockout,DARK_RED,ALL_SIDES);
            buttonHeld=0;
            holdTimeout=0;
            if(attachmentsLocked) unlockAttachments();
            llSetLinkColor(primRoot,BLANK,ALL_SIDES);
        }
        else if(message=="POST")
        {
            power=1;
            post();
        }
        else if(message=="PowerOn")
        {
            if(!power)
            {
                power=1;
                post();
            }
        }
        else if(message=="Flash")
        {
            if(power) llSetLinkColor(primRoot,BLANK,ALL_SIDES);
            flashTimeout=2;
            if(controllerCount>0 && primL1) llSetLinkTexture(primL1,LED_ON,ALL_SIDES);
            if(controllerCount>1 && primL2) llSetLinkTexture(primL2,LED_ON,ALL_SIDES);
            if(controllerCount>2 && primL3) llSetLinkTexture(primL1,LED_ON,ALL_SIDES);
        }
        else if(message=="Asking")
        {
            asking=0;
            if(primMode)
            {
                if(primYes)
                {
                    if(primNo)
                    {
                        askingKey=id;
                        llSetLinkColor(primYes,GREEN,ALL_SIDES);
                        llSetLinkColor(primNo,RED,ALL_SIDES);
                        if(primQueue) llSetLinkColor(primQueue,VIOLET,ALL_SIDES);
                        llSetLinkColor(primRoot,BLANK,ALL_SIDES);
                        asking=1;
                    }
                }
            }
            if(!asking)
            {
                setMode(3);
            }
        }
        else if(message=="Timeout") closeAsking();
        else if(message=="GetMode")
        {
            if(primMode==-1) setMode(3);
            else llMessageLinked(LINK_ALL_OTHERS,relayMode,"SetMode",NULL);
        }
        else if(message=="SetMode")
        {
            setMode(number);
        }
        else if(message=="Normal")
        {
            warningMode=0;
            llSetLinkColor(primRoot,BLANK,ALL_SIDES);
        }
        else if(message=="Warning")
        {
            warningMode=1;
            llSetLinkColor(primRoot,GREY,ALL_SIDES);
        }
        else if(message=="Detach")
        {
            string response="settings, "+(string)superSafety+", "+(string)relayMode+", "+(string)lockoutGlobal+", ";
            if(~llListFindList(lockoutObjects,[object1Key])) response+="1, ";
            else response+="0, ";
            if(~llListFindList(lockoutObjects,[object2Key])) response+="1, ";
            else response+="0, ";
            if(~llListFindList(lockoutObjects,[object3Key])) response+="1, ";
            else response+="0, ";
            response+=(string)lockoutTimer+", "+(string)lockoutSafetyDelay;
            llRegionSayTo(ownerKey,-201818,response);
            integer x=~llGetListLength(avatarBlacklist);
            while(++x)
            {
                llRegionSayTo(ownerKey,-201818,"blacklist, "+llList2String(avatarBlacklist,x));
            }
            detachMe=1;
        }
        else if(message=="BlackLight")
        {
            if(number) llSetLinkColor(primQueue,VIOLET,ALL_SIDES);
            else llSetLinkColor(primQueue,DARK_VIOLET,ALL_SIDES);
        }
        else if(message=="Blacklisted")
        {
            //if(DEBUG) llOwnerSay("Skipping blacklisted user "+llGetUsername(id));
            avatarBlacklist+=id;
            llSensor("","",AGENT,20.0,PI);
        }
        else if(message=="NotBlacklisted") askSafety(id);
        else if(id=="Message") llOwnerSay(message);
        else
        {
            list temp=llCSV2List(message);
            if(llList2String(temp,0)=="Controllers")
            {
                if(lockoutTimer==1)
                {
                    if(number>controllerCount)    // ## Toy
                    {    // ## Toy
                        if(primLockout) llSetLinkColor(primLockout,ORANGE,ALL_SIDES);    // ## Toy
                        // llOwnerSay("Safeword delayed");    // ## Toy
                        lockoutSafetyDelay=120;    // ## Toy
                    }    // ## Toy
                    else if(!number)    // ## Toy
                    {    // ## Toy
                        lockoutSafetyDelay=0;    // ## Toy
                        if(primLockout) llSetLinkColor(primLockout,ORANGE,ALL_SIDES);    // ## Toy
                    }    // ## Toy
                }
                controllerCount=number;
                if(!controllerCount)
                {
                    if(primL1) llSetLinkTexture(primL1,LED_OFF,ALL_SIDES);
                    if(primL2) llSetLinkTexture(primL2,LED_OFF,ALL_SIDES);
                    if(primL3) llSetLinkTexture(primL3,LED_OFF,ALL_SIDES);
                    if(srsTimeout+timeout) closeSafety();
                }
                else if(controllerCount==1)
                {
                    if(primL1) llSetLinkTexture(primL1,LED_ON,ALL_SIDES);
                    if(primL2) llSetLinkTexture(primL2,LED_OFF,ALL_SIDES);
                    if(primL3) llSetLinkTexture(primL3,LED_OFF,ALL_SIDES);
                }
                else if(controllerCount==2)
                {
                    if(primL1) llSetLinkTexture(primL1,LED_ON,ALL_SIDES);
                    if(primL2) llSetLinkTexture(primL2,LED_ON,ALL_SIDES);
                    if(primL3) llSetLinkTexture(primL3,LED_OFF,ALL_SIDES);
                }
                else if(controllerCount==3)
                {
                    if(primL1) llSetLinkTexture(primL1,LED_ON,ALL_SIDES);
                    if(primL2) llSetLinkTexture(primL2,LED_ON,ALL_SIDES);
                    if(primL3) llSetLinkTexture(primL3,LED_ON,ALL_SIDES);
                }
                object1Key=llList2Key(temp,1);
                object2Key=llList2Key(temp,2);
                object3Key=llList2Key(temp,3);
                syncLockouts();
            }
        }
    }
    touch_start(integer total)
    {
        if(power)
        {
            integer linkDetected=llDetectedLinkNumber(0);
            if(linkDetected==primSafety)
            {
                if(timeout<=0 && !lockoutSafetyDelay)    // ## Toy
                {
                    if(srsTimeout)
                    {
                        srsTimeout=0;
                        activateSafety();
                    }
                    else if(lockoutGlobal+llGetListLength(lockoutObjects)==0)
                    {
                        if(controllerCount)
                        {
                            llSetLinkColor(primSafety,YELLOW,ALL_SIDES);
                            safeKey=WILDCARD;
                            buttonHeld=primSafety;
                            holdTimeout=1;
                        }
                        else
                        {
                            safeKey=WILDCARD;
                            buttonHeld=primSafety;
                            holdTimeout=2;
                        }
                    }
                }
            }
            else if(linkDetected==primL1)
            {
                if(object1Key)
                {
                    if(lockoutTimeout)
                    {
                        lockoutObjects+=object1Key;
                        lockoutTimeout=0;
                        llSetLinkColor(primLockout,RED,ALL_SIDES);
                        llOwnerSay(llKey2Name(object1Key)+" is now locked out from safeword.");
                    }
                    else
                    {
                        buttonHeld=primL1;
                        holdTimeout=4;
                    }
                }
            }
            else if(linkDetected==primL2)
            {
                if(object2Key)
                {
                    if(lockoutTimeout)
                    {
                        lockoutObjects+=object2Key;
                        lockoutTimeout=0;
                        llSetLinkColor(primLockout,RED,ALL_SIDES);
                        llOwnerSay(llKey2Name(object2Key)+" is now locked out from safeword.");
                    }
                    else
                    {
                        buttonHeld=primL2;
                        holdTimeout=4;
                    }
                }
            }
            else if(linkDetected==primL3)
            {
                if(object3Key)
                {
                    if(lockoutTimeout)
                    {
                        lockoutObjects+=object3Key;
                        lockoutTimeout=0;
                        llSetLinkColor(primLockout,RED,ALL_SIDES);
                        llOwnerSay(llKey2Name(object3Key)+" is now locked out from safeword.");
                    }
                    else
                    {
                        buttonHeld=primL3;
                        holdTimeout=4;
                    }
                }
            }
            else if(linkDetected==primMode)
            {
                setMode(relayMode+1);
            }
            else if(linkDetected==primLockout)
            {
                if(lockoutTimeout<=0)
                {
                    if(!lockoutGlobal)
                    {
                        holdTimeout=4;
                        buttonHeld=primLockout;
                        llSetLinkColor(primLockout,BLUE,ALL_SIDES);
                    }
                    else if(!controllerCount)
                    {
                        lockoutGlobal=0;
                        lockoutObjects=NULL_LIST;
                        llSetLinkColor(primLockout,DARK_RED,ALL_SIDES);
                        llOwnerSay("Safeword Enabled");
                    }
                }
                else lockoutTimeout=1;
            }
            else if(linkDetected==primAAL)
            {
                if(!attachmentStage)
                {
                    if(attachmentsLocked) unlockAttachments();
                    else
                    {
                        attachmentStage=1;
                        //llSetLinkColor(primAAL,YELLOW,ALL_SIDES);
                        attachmentListener=llListen(11215311,"",ownerKey,"");
                        llOwnerSay("@getattach=11215311");
                        attachmentTimeout=10;
                    }
                }
            }
            else if(linkDetected==primQueue)
            {
                if(asking)
                {
                    llMessageLinked(primQueue,0,"Blacklist",askingKey);
                    closeAsking();
                }
                else llMessageLinked(primQueue,0,"Blacklist",WILDCARD);
            }
            else if(linkDetected==primYes && asking)
            {
                llMessageLinked(primQueue,0,"Yes",askingKey);
                closeAsking();
            }
            else if(linkDetected==primNo && asking)
            {
                llMessageLinked(primQueue,0,"No",askingKey);
                closeAsking();
            }
            else
            {
                holdTimeout=1;
                buttonHeld=primRoot;
                llSetLinkColor(primRoot,GREY,ALL_SIDES);
            }
        }
        else if(llDetectedLinkNumber(0)==primRoot)
        {
            llMessageLinked(LINK_ALL_OTHERS,1,"PowerOn",NULL);
            llOwnerSay("Starting Relay");
        }
    }
    touch_end(integer total)
    {
        if(buttonHeld==primSafety)
        {
            holdTimeout=0;
            if(timeout+srsTimeout==0) setSafetyColor();
        }
        else if(holdTimeout>0)
        {
            if(buttonHeld==primL1)
            {
                llOwnerSay(llKey2Name(object1Key));
                holdTimeout=0;
            }
            else if(buttonHeld==primL2)
            {
                llOwnerSay(llKey2Name(object2Key));
                holdTimeout=0;
            }
            else if(buttonHeld==primL3)
            {
                llOwnerSay(llKey2Name(object3Key));
                holdTimeout=0;
            }
            else if(buttonHeld==primLockout)
            {
                holdTimeout=0;
                if(controllerCount>0)
                {
                    lockoutTimeout=11;
                    llOwnerSay("Tap the Active Controller you want to Lockout Safeword on");
                }
                else
                {
                    if(!lockoutTimer) llSetLinkColor(primLockout,DARK_RED,ALL_SIDES);
                    else llSetLinkColor(primLockout,ORANGE,ALL_SIDES);
                }
            }
            else if(buttonHeld==primRoot)
            {
                if(power) llSetLinkColor(primRoot,BLANK,ALL_SIDES);
                if(controllerCount)
                {
                    llOwnerSay("Interface Memory Usage: "+(string)(llGetUsedMemory()/1024)+"kb");
                    llMessageLinked(LINK_ALL_OTHERS,0,"Status",NULL);
                }
                holdTimeout=0;
            }
        }
    }
    listen(integer chatChannel, string objectName, key objectKey, string chatMessage)
    {
        if(chatChannel==181917)
        {
            if(objectKey==llGetOwner()) return;
            if(chatMessage=="Yes") //If the user said Yes
            {
                llMessageLinked(LINK_ALL_OTHERS,0,"Safety!",safeKey);
                llSleep(0.5);
                llOwnerSay(llGetUsername(avatarKey)+" has released you");
                avatarKey=NULL;
                closeSafety();
            }
            else //If they said No
            {
                llOwnerSay(llGetUsername(avatarKey)+" has denied your request to escape");
                llListenRemove(listener);
                timeout=120; //You have to wait 2 minutes
                lockoutSafetyDelay=120;
                if(primLockout) llSetLinkColor(primLockout,ORANGE,ALL_SIDES);
                avatarKey=NULL;
            }
        }
        else if(chatChannel==11215311)
        {
            if(attachmentStage==2)
            {
                attachmentTimeout=0;
                llListenRemove(attachmentListener);
                integer x=-1;
                string y="0";
                integer z=llStringLength(chatMessage);
                clothingLockList=NULL_LIST;
                while(++x<z)
                {
                    y=llGetSubString(chatMessage,x,x);
                    if(y!="0") clothingLockList+="@remoutfit:"+llList2String(CLOTHING,x)+"=n";
                }
                x=0;
                lockAttachments();
                llOwnerSay("Attachments Locked On");
                //llOwnerSay("memory Used: "+(string)(llGetUsedMemory()/1024)+"kb");
                attachmentStage=0;
                if(primAAL) llSetLinkTexture(primAAL,"dbde5431-812b-5fbc-bb6c-e97bf804bf69",ALL_SIDES);
            }
            else if(attachmentStage==1)
            {
                attachmentTimeout=0;
                llListenRemove(attachmentListener);
                integer x=-1;
                string y="0";
                integer z=llStringLength(chatMessage);
                attachmentLockList=NULL_LIST;
                while(++x<z)
                {
                    y=llGetSubString(chatMessage,x,x);
                    if(y!="0") attachmentLockList+="@remattach:"+llList2String(ATTACHMENTS,x)+"=n";
                }
                x=0;
                attachmentStage=2;
                attachmentListener=llListen(11215311,"",llGetOwner(),"");
                llOwnerSay("@getoutfit=11215311");
                attachmentTimeout=10;
            }
        }
        else if(chatChannel==-201818 && llGetOwnerKey(objectKey)==ownerKey)
        {
            if(objectKey==llGetOwner()) return;
            if(chatMessage=="Safety!")
            {
                if(attachmentsLocked) llOwnerSay("@remattach:"+llList2String(ATTACHMENTS,llGetAttached())+"=rem");
                if(attachSafetyTimeout<=0) llMessageLinked(LINK_ALL_OTHERS,0,"Sync",NULL);
                else llRegionSayTo(ownerKey,-201818,"SafetyDenied!");
            }
            else if(chatMessage=="SafetyDenied!") detachMe=1;
            else if(chatMessage=="Done") llMessageLinked(LINK_ALL_OTHERS,0,"FinishedSync",NULL);
            else
            {
                list restriction=llCSV2List(chatMessage);
                if(!power) power=1;
                if(llList2String(restriction,0)=="blacklist")
                avatarBlacklist+=llList2Key(restriction,1);
                else if(llList2String(restriction,0)=="settings")
                {
                    superSafety=llList2Integer(restriction,1);
                    relayMode=llList2Integer(restriction,2);
                    lockoutGlobal=llList2Integer(restriction,3);
                    if(llList2Integer(restriction,4)) lockoutObjects+=object1Key;
                    if(llList2Integer(restriction,5)) lockoutObjects+=object2Key;
                    if(llList2Integer(restriction,6)) lockoutObjects+=object3Key;
                    lockoutTimer=llList2Integer(restriction,7);
                    lockoutSafetyDelay=llList2Integer(restriction,8);
                    setSafetyColor();
                    post();
                }
                else if(llList2String(restriction,1)=="sync") llMessageLinked(LINK_ALL_OTHERS,-201818,llList2CSV(llDeleteSubList(restriction,0,0)),llList2Key(restriction,0));
            }
        }
    }
    sensor(integer total) //If Avatars Are Detected...
    {
        integer x=-1;
        list avatarKeys=NULL_LIST;
        while(++x<total)
        {
            if(llListFindList(avatarBlacklist,[llDetectedKey(x)])==-1)
            {
                 if(llGetAgentInfo(llDetectedKey(x)) & ~AGENT_BUSY & ~AGENT_AWAY)
                 avatarKeys+=llDetectedKey(x); //Filter out Busy and Away avatars
            }
        }
        if(avatarKeys!=NULL_LIST) //If there's at least one paying attention
        {
            if(primQueue) llMessageLinked(primQueue,0,"CheckBlacklist",llList2Key(avatarKeys,(integer)llFrand((float)llGetListLength(avatarKeys))));
            else askSafety(llList2Key(avatarKeys,(integer)llFrand((float)llGetListLength(avatarKeys))));
        }
        else //If everyone nearby is Busy or Away
        { //Lets the user go via Safeword
            llMessageLinked(LINK_ALL_OTHERS,0,"Safety!",safeKey);
            llOwnerSay("You are free to go since no one is paying attention");
            closeSafety();
        }
    }
    no_sensor() //If no one is nearby...
    {
        llMessageLinked(LINK_ALL_OTHERS,0,"Safety!",safeKey);
        llOwnerSay("You are free to go since no one is here");
        closeSafety();
    }
    timer()
    {
        if(lockoutSafetyDelay==1)    // ## Toy
        {    // ## Toy
            if(primLockout) llSetLinkColor(primLockout,DARK_RED,ALL_SIDES);    // ## Toy
        }    // ## Toy
        if(holdTimeout==1)
        {
            if(power && buttonHeld==primRoot) llMessageLinked(LINK_ALL_OTHERS,0,"PowerOff",NULL);
            else if(!lockoutSafetyDelay)
            {
                if(buttonHeld==primSafety) activateSafety();    // ## Toy
                else if(buttonHeld==primLockout)
                {
                    if(lockoutTimer==1)
                    {
                        lockoutTimer=0;
                        lockoutGlobal=1;
                        llSetLinkColor(primLockout,RED,ALL_SIDES);
                        llOwnerSay(" /!\\ Safeword Disabled /!\\ ");
                    }
                    else if(lockoutTimer+lockoutGlobal==0)
                    {
                        lockoutTimer=1;
                        llSetLinkColor(primLockout,ORANGE,ALL_SIDES);
                        llOwnerSay("2 Minute Safeword Lockout Enabled");
                    }
                }
                else
                {
                    if(!lockoutGlobal)
                    {
                        if(buttonHeld==primL1 && llListFindList(lockoutObjects,[object1Key])==-1)
                        {
                            llOwnerSay("Ready to activate SRS on "+llKey2Name(object1Key));
                            safeKey=object1Key;
                            srsTimeout=11;
                            llSetLinkColor(primSafety,RED,ALL_SIDES);
                        }
                        else if(buttonHeld==primL2 && llListFindList(lockoutObjects,[object2Key])==-1)
                        {
                            llOwnerSay("Ready to activate SRS on "+llKey2Name(object2Key));
                            safeKey=object2Key;
                            srsTimeout=11;
                            llSetLinkColor(primSafety,RED,ALL_SIDES);
                        }
                        else if(buttonHeld==primL3 && llListFindList(lockoutObjects,[object3Key])==-1)
                        {
                            llOwnerSay("Ready to activate SRS on "+llKey2Name(object3Key));
                            safeKey=object3Key;
                            srsTimeout=11;
                            llSetLinkColor(primSafety,RED,ALL_SIDES);
                        }
                    }
                }
            }
        }
        if(lockoutTimeout==1)
        {
            if(!lockoutTimer) llSetLinkColor(primLockout,DARK_RED,ALL_SIDES);
            else llSetLinkColor(primLockout,ORANGE,ALL_SIDES);
            lockoutTimeout=0;
        }
        if(attachmentTimeout==1)
        {
            llListenRemove(attachmentListener);
            unlockAttachments();
        }
        if(detachMe)
        {
            if(permissionGranted)
            {
                forceDetach();
            }
        }
        if(flashTimeout==1)
        {
            if(controllerCount>0 && primL1) llSetLinkTexture(primL1,LED_ON,ALL_SIDES);
            if(controllerCount>1 && primL2) llSetLinkTexture(primL2,LED_ON,ALL_SIDES);
            if(controllerCount>2 && primL3) llSetLinkTexture(primL3,LED_ON,ALL_SIDES);
        }
        if(flashTimeout) flashTimeout--;
        if(srsTimeout==1) closeSafety();
        if(timeout==1) closeSafety();
        if(timeout) timeout--;
        if(holdTimeout) holdTimeout--;
        if(srsTimeout) srsTimeout--;
        if(lockoutTimeout) lockoutTimeout--;
        if(lockoutSafetyDelay) lockoutSafetyDelay--;
        if(attachmentTimeout) attachmentTimeout--;
        if(attachSafetyTimeout) attachSafetyTimeout--;
    }
    state_entry()
    {
        init();
        post();
        //llOwnerSay("Memory Usage: "+(string)(llGetUsedMemory()/1024)+"kb");
    }
    on_rez(integer total)
    {
        init();
    }
    run_time_permissions(integer permissions)
    {
        if(PERMISSION_ATTACH & permissions)
        {
            permissionGranted=1;
            if(detachMe) forceDetach();
        }
        if(PERMISSION_TAKE_CONTROLS & permissions) 
        {
            if(!(llGetAgentInfo(ownerKey) & AGENT_ON_OBJECT)) llTakeControls(CONTROL_ML_LBUTTON | 0,FALSE,TRUE);
        }
    }
    changed(integer change)
    {
        if(change & CHANGED_LINK) post();
        if(change & CHANGED_OWNER) ownerKey=llGetOwner();
    }
}