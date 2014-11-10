// Da Chrome's Turbo Safety RLV Implementation
// A Lightweight Multi-Relay Built for Speed
// This Relay Uses Auto and Ask Modes via a Queuing Script as well as Blacklisting and Safewords
// Restrictions are applied in the order they are taken
// Turbo RLV Relay by Da Chrome and Toy Wylie is licensed under a Creative Commons Attribution 3.0 Unported License. http://creativecommons.org/licenses/by/3.0/ Keep This Line Intact.
// You do NOT have to make derivative works open source.
// Experimental ORG code commented out in this version

//Constants

string VERSION_IMPL="Turbo Safety 1.312"; // for !implversion
string ORG_VERSION="!x-orgversions,ORG=0003/who=0002/mode=0000";
integer VERSION_API=1100; // Version of RLV API
integer MEMORY_LIMIT=61439; //Fine-tune to prevent Stackheap
integer PIN=-5875279; // Auto updater PIN (WIP)
integer RLV_CHANNEL=-1812221819;
key WILDCARD="ffffffff-ffff-ffff-ffff-ffffffffffff";
key NULL=NULL_KEY;
key MESSAGE="Message";
list NULL_LIST=[]; // Fastest way to check / set empty list
list RLV_PARSE=["|"]; // Speeds up Parsing a little
list OBJECT_DETAILS=[OBJECT_POS];
string POWER_OFF="PowerOff";
string POWER_ON="PowerOn";
string NORMAL="Normal";
string WARNING="Warning";
string CAPABILITIES="Capabilities";
string SYNC=", sync, ";
string CONTROLLERS="Controllers, ";
string RELEASE_HEADER="release";
string RELEASE_FOOTER=",!release,ok";
string CLEAR="@clear";
string CLEAR_ALL="@clear,detach=n,setdebug_renderresolutiondivisor:1=force";
string CLEAR_DEBUG_RENDER="@setdebug_renderresolutiondivisor:1=force";
string CLEAR_ENV="@setenv_daytime:-1=force";
string FORCE_UNSIT="@unsit=force";
vector RED=<1.0,0.0,0.0>;
vector DARK_RED=<0.3,0.0,0.0>;

// Variables

string newCommands="release"; // Command Group, default is release for safeword
string find; // Cross-Function Finder strings
string find2;
string find1;
string find0;
string lastControllers;
key keyObject1; // Object Key
key keyObject2;
key keyObject3;
key newObject;
key safetyObject;
list restrictionsObject1; // Restrictions List
list restrictionsObject2;
list restrictionsObject3;
//integer orgBypassObject1; // To bypass in-sim checking
//integer orgBypassObject2; // For ORG remote control
//integer orgBypassObject3; // And other ORG annoyances
list newRestrictions;
list commandList;
list find3; // Used to speed up list searches a tiny bit
key sitTargetKey; // For Force Resitting after a relog
key ownerKey; // Eliminates excessive llGetOwner() calls
integer relayMode; // Are we Ask Mode or Auto Mode?
integer power; // Are we turned off or turned on?
integer controllerCount; // Number of controlling objects
integer listenRLV; // Listener, to save power this offlines when off
integer listenViewer; // Listener for viewer response
integer listenSitTarget; // Listener for integrated sit detection
integer isListening;
integer timeout=-1; // Timeout for Ask Mode
integer safetyTimeout=-1;
integer valid; // For checking command validity
integer index; // Global temp var for more speed
integer rIndex;
integer isKO;
integer pingTimeout; // Ping Timeout
integer checkRezTimeout; // Counter to check Controller is Rezzed
integer objectIndex; // Tired of passing variables around
list pingedObjects; // Keeps track of pingedObjects controllers that have not yet responded
integer primIndicator; //For finding and using the Busy Indicator light directly instead of spamming link messages to the interface scripts
integer primQueue; //For finding the Queue prim, required for Ask Mode and Blacklist to work and related ORG Extensions
//integer primEmail; //Required for x-pollemail
//integer primORG; //Required to use ORG functions
integer startupMemory; //To calculate how much RAM is left
integer synchronizing; //For synchronizing restrictions
setPrims() //For setting the linked script prims
{
    primIndicator=0;
//    primORG=0;
//    primEmail=0;
    primQueue=0;
    integer v;
    integer w=llGetNumberOfPrims();
    while(++v<=w)
    {
        if(llGetLinkName(v)=="Indicator") primIndicator=v;
//        else if(llGetLinkName(v)=="ORG Extensions") primORG=v;
//        else if(llGetLinkName(v)=="Email Indicator") primEmail=v;
        else if(llGetLinkName(v)=="Turbo Safety Menu") primQueue=v;
    }
    if(!primQueue) relayMode=3;
}
busyOn()
{
    if(primIndicator) llSetLinkColor(primIndicator,RED,ALL_SIDES);
}
busyOff()
{
    if(primIndicator) llSetLinkColor(primIndicator,DARK_RED,ALL_SIDES);
}
initVars() //Should not need this, but for some reason, it
{          //is needed for null checks, so it gets used when
    keyObject1=NULL; //Safewording and as a faster way
    keyObject2=NULL; //To !release with only one object
    keyObject3=NULL; //Active in the system
    safetyObject=NULL;
    restrictionsObject1=NULL_LIST;
    restrictionsObject2=NULL_LIST;
    restrictionsObject3=NULL_LIST;
//    orgBypassObject1=0;
//    orgBypassObject2=0;
//    orgBypassObject3=0;
    controllerCount=0;
}
doPing()
{
    if(controllerCount) // Pings active objects after a Intersim Teleport or relog
    {
        checkRez();
        pingTimeout=31;
        listenViewer=llListen(20181817,"",ownerKey,"");
    }
}
checkRez()
{
    if(keyObject3)
    {
//        if(!orgBypassObject1)
//        {
            if(llGetObjectDetails(keyObject3,OBJECT_DETAILS)==NULL_LIST) removeObject(keyObject3);
//        }
    }
    if(keyObject2)
    {
//        if(!orgBypassObject2)
//        {
            if(llGetObjectDetails(keyObject2,OBJECT_DETAILS)==NULL_LIST) removeObject(keyObject2);
//        }
    }
    if(keyObject1)
    {
//        if(!orgBypassObject3)
//        {
            if(llGetObjectDetails(keyObject1,OBJECT_DETAILS)==NULL_LIST) removeObject(keyObject1);
//        }
    }
    checkRezTimeout=60;
}
rejectObject()
{
    newCommands=llList2String(commandList,0);
    newRestrictions=llParseString2List(llList2String(commandList,2),RLV_PARSE,NULL_LIST);
    integer y=~llGetListLength(newRestrictions);
    while(++y)
    {
        if(llSubStringIndex(llList2String(newRestrictions,y),"!")==0) llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+","+llList2String(newRestrictions,y)+",ko");
        else llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+","+llList2String(newRestrictions,y)+",ko");
    }
}
rejectCommand()
{
    llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+","+find+find1+find2+",ko");
}
//sendAllToORG(integer x)
//{
//    llMessageLinked(primORG,1,newCommands+", "+(string)ownerKey+", "+llDumpList2String(llList2List(newRestrictions,x,-1),"|"),newObject);
//    newRestrictions=llDeleteSubList(newRestrictions,x+1,-1);
//}
handleMetaCommands()
{
    integer working;
    string check=llList2String(newRestrictions,rIndex);
    if(check=="!pong") working=2;
    else if(check=="!version")
    {
        llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+",!version,"+(string)VERSION_API);
        working=2;
    }
    else if(check=="!implversion")
    {
        llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+",!implversion,"+(string)VERSION_IMPL);
        working=2;
    }
    else if(check=="!x-orgversions")
    {
        llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+",!x-orgversions,"+(string)ORG_VERSION);
        working=2;
    }
    else if(check=="!x-mode")
    {
        string mode=",!x-mode,";
        if(relayMode<2) mode+="ask"; else mode+="auto";
        if(relayMode==3) mode+="/none"; else mode+="/black";
        llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+mode);
        working=2;
    }
// We take great care to make sure we don't have to
//String Search if at all possible, this slows it down
    else if(llSubStringIndex(check,"!x-who")==0) working=1;
    else working=-1;
        //{ // ORG Spec Stuff starts here, ORG extensions
          // Greatly increase overhead on the script
            //list listOrgCommand=llParseString2List(check,["/"],NULL_LIST);
            //string orgCommand=llList2String(listOrgCommand,0);
            //if(orgCommand=="!x-who") 
//                else if(orgCommand=="!x-handover")
//                {  //Yes, !x-handover flushes the queue
//                    newRestrictions=NULL_LIST;
//                    rIndex=0;
//                    working=0;
//                    if(llList2Integer(listOrgCommand,2))
//                    {  //This is easy, flip the key over and initiate a !ping if restrictions are kept, and belay object in-sim finding for an extra minute
//                        if(newObject==keyObject1) keyObject1=llList2Key(listOrgCommand,1);
//                        else if(newObject==keyObject2) keyObject2=llList2Key(listOrgCommand,1);
//                        else if(newObject==keyObject3) keyObject3=llList2Key(listOrgCommand,1);
//                        else working=-1;
//                        if(!working)
//                        {
//                            llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+","+check+",ok");
//                            checkRezTimeout=60; // Belayed in case of Intersim TP
//                            listenViewer=llListen(20181817,"",ownerKey,"");
//                            pingTimeout=31;
//                        }
//                    }
//                    else
//                    {  //If not keeping restrictions, we'll just
//                       //Allow for extended period of time the new
//                       //Object to interact using permissions
//                        if(newObject==keyObject1) working=0;
//                        else if(newObject==keyObject2) working=0;
//                        else if(newObject==keyObject3) working=0;
//                        else working=-1;
//                        if(!working)
//                        {
//                            removeObject(newObject);
//                            if(primQueue) llMessageLinked(primQueue,0,"HandoverObject",llList2Key(listOrgCommand,1));
//                        }
//                    }
//                }
//                else if(orgCommand=="!x-takeover" || orgCommand=="!x-key")
//                {
//                    llMessageLinked(primORG,1,newCommands+","+(string)newObject+","+check,newObject);
//                    working=2;
//                }
            //else
            //{
                //working=-1;
            //}
        //}
    if(working==1)  // Confirms and removes metacommands from the list
    {
        newRestrictions=llDeleteSubList(newRestrictions,rIndex,rIndex);
        llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+","+check+",ok");
    }
    else if(working==2)  // Removes metacommands from the list (no confirm)
    {
        newRestrictions=llDeleteSubList(newRestrictions,rIndex,rIndex);
    }
    else if(working==-1)  // Rejects and removes metacommands from the list
    {
        newRestrictions=llDeleteSubList(newRestrictions,rIndex,rIndex);
        llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+","+check+",ko");
    }
}
doRLV() // Directs the operation of the relay
{
    newCommands=llList2String(commandList,0);
    newRestrictions=llParseString2List(llList2String(commandList,2),RLV_PARSE,NULL_LIST);
    if(pingedObjects!=NULL_LIST) //Shortcut to reduce processing time, no need to check ping if no pings
    {
        if(~llListFindList(pingedObjects,[newObject])) // Ping Response Reapply
        {
            index=llListFindList(pingedObjects,[newObject]);
            pingedObjects=llDeleteSubList(pingedObjects,index,index);
            find3=["unsit=n"];
            if(searchCommands())
            {
                if(sitTargetKey!=NULL) llOwnerSay("@sit:"+(string)sitTargetKey+"=force");
            }
            if(pingedObjects==NULL_LIST)
            {
                llMessageLinked(LINK_ROOT,0,NORMAL,NULL);
                pingTimeout=0;
            }
        }
    }
    objectIndex=0;
    if(!controllerCount)
    {
        objectIndex=1;
        setObject(); // Shortcut for the first controller
    }
    else
    {
        if(keyObject1==newObject) objectIndex=1; // Checks for existing controls first
        else if(keyObject2==newObject) objectIndex=2;
        else if(keyObject3==newObject) objectIndex=3;
        if(objectIndex) addToObject();
        else
        {
            if(keyObject2==NULL) objectIndex=2; // Sets up a new controller
            else if(keyObject3==NULL) objectIndex=3;
            if(objectIndex) setObject();
            else
            {
                rejectObject();
                return;
            }
        }  // For now, we ignore commands if objects are full
    }
    defragObjects();
}
removalCheck()
{
    find3=[find+find2];
    if(searchCommands()==1)
    {
        if(find2=="=n") llOwnerSay(find+"=y");
        else if(find2=="=add") llOwnerSay(find+"=rem");
        if(find=="setenv") llOwnerSay(CLEAR_ENV);
        if(find=="setdebug") llOwnerSay(CLEAR_DEBUG_RENDER);
    }
}
executeRLV()
{ // Executes RLV command if it's find partitioned
    llOwnerSay(find+find1+find2);
    llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+","+find+find1+find2+",ok");
}
integer applyRLV() // Parses each command, telling the function caller if they can add to the list or remove from it
{
    integer x=0;
    integer y=0;
    integer z=0;
    index=llSubStringIndex(find,":");
    if(~index)
    {
        find1=llDeleteSubString(find,0,index-1);
        find=llDeleteSubString(find,index,-1);
    }
    else find1="";
    find3=[find+find1+find2];
    find0=llGetSubString(find,0,0);
    if(find0=="@")
    {
        if(find2=="=n" || find2=="=add")
        {   // Add it if its a restriction and it hasn't been added before
            if(llGetUsedMemory()>MEMORY_LIMIT)
            {   //Cancels new commands if we're short on memory
                rejectCommand();
                return 0;
            }
            // block acceptpermission for the time being since
            // temp attachments could be used for griefing
            if(find=="@acceptpermission") return 0;
            isKO=0;
            executeRLV();
            return 1;
        }
        else if(find2=="=rem" || find2=="=y")
        {
            if(find2=="=y") find3=[find+find1+"=n"];
            else if(find2=="=rem") find3=[find+find1+"=add"];
            // Prevents lifting another controller's restrictions
            z=searchCommands();    
            if(z==1) return -1;
            else if(!z) return 0; //If you didn't apply it, silently ignore it
            else llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+","+find+find1+find2+",ok");
        }
        else if(find2=="=force")
        {
            executeRLV();  //Confirm One-Shot commands
        }
        else if(find=="clear")
        {
            if(find2=="") //Same as !release for broken devices
            {
                isKO=1;
                llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+",@clear,ok");
            }
            else return 2; //For @clear=param support
        }
        else if(find2=="=0") rejectCommand(); //Channel 0 is not allowed as a response channel
        else executeRLV();
    }
    else if(find=="!release") isKO=1;
    else if(find0=="!") handleMetaCommands(); // Check for meta commands
    else rejectCommand();
    return 0;
}
integer searchCommands()
{
    integer y=0;
    if(~llListFindList(restrictionsObject1,find3)) y++;
    if(~llListFindList(restrictionsObject2,find3)) y++;
    if(y>1) return y;
    else if(~llListFindList(restrictionsObject3,find3)) y++;
    return y;
}
splitCommand(string tempString)
{
    index=llSubStringIndex(tempString,"=");
    if(~index) //This all cuts down on string and list operations
    {
        find2=llDeleteSubString(tempString,0,index-1);
        find=llDeleteSubString(tempString,index,-1);
    }
    else
    {
        find2=""; 
        find=tempString;
    }
}
clearFind(string search2)
{ //No one should be using @clear=, but in case someone does
    find3=[search2]; //This expensive routine emulates it
    if(searchCommands()==1)
    {
        integer index2=llSubStringIndex(search2,"=");
        string search3=llDeleteSubString(search2,index,-1);
        string search4=llDeleteSubString(search2,0,index-1);
        if(search4=="=n") llOwnerSay(search3+"=y");
        else if(search4=="=add") llOwnerSay(search3+"=rem");
    }
}
defragObjects() // Cleans up command lists so they stay in order
{
    integer x=1;
    while(x) // Each if tree checks if a controller has an empty slot under
    { // it and moves the data down to that slot, as well as ticking a variable
        x=0; // If no moves are performed, it exits the loop
        if(keyObject3)
        {
            if(keyObject2==NULL)
            {
                keyObject2=keyObject3;
                restrictionsObject2=restrictionsObject3;
                keyObject3=NULL;
                restrictionsObject3=NULL_LIST;
                x++;
            }
        }
        if(keyObject2)
        {
            if(keyObject1==NULL)
            {
                keyObject1=keyObject2;
                restrictionsObject1=restrictionsObject2;
                keyObject2=NULL;
                restrictionsObject2=NULL_LIST;
                x++;
            }
        }
    }
    if(controllerCount>1)
    {
        if(keyObject3)
        {
            if(restrictionsObject3==NULL_LIST) removeObject(keyObject3);
        }
        if(keyObject2)
        {
            if(restrictionsObject2==NULL_LIST) removeObject(keyObject2);
        }
        if(keyObject1)
        {
            if(restrictionsObject1==NULL_LIST) removeObject(keyObject1);
        }
    }
    else
    {
        if(keyObject1)
        {
            if(restrictionsObject1==NULL_LIST) removeObject(keyObject1);
        }
    }
    string controllerString=CONTROLLERS+(string)keyObject1+", "+(string)keyObject2+", "+(string)keyObject3;
    if(lastControllers!=controllerString)
    {
        lastControllers=controllerString;
        llMessageLinked(LINK_ALL_OTHERS,controllerCount,controllerString,NULL);
    }
    newCommands=RELEASE_HEADER;
}
removeObject(key which) // !release meta command subroutine
{
    integer x=0;
    if(which==WILDCARD || (controllerCount<=1 && which==keyObject1)) // Used when Clearing the last controller, or clearing all controllers (ping)
    {
        llOwnerSay(CLEAR_ALL);
        if(keyObject1) llRegionSayTo(keyObject1,RLV_CHANNEL,newCommands+","+(string)keyObject1+RELEASE_FOOTER);
        if(keyObject2) llRegionSayTo(keyObject2,RLV_CHANNEL,newCommands+","+(string)keyObject2+RELEASE_FOOTER);
        if(keyObject3) llRegionSayTo(keyObject3,RLV_CHANNEL,newCommands+","+(string)keyObject3+RELEASE_FOOTER);
        initVars();
    }
    else if(which==keyObject1)
    {
         // Checks to make sure this is the only object with that restriction, and lifts it if so.
        while(x<llGetListLength(restrictionsObject1))
        {
            splitCommand(llList2String(restrictionsObject1,x));
            removalCheck();
            x++;
        }
        llRegionSayTo(keyObject1,RLV_CHANNEL,newCommands+","+(string)keyObject1+RELEASE_FOOTER);
        keyObject1=NULL;
//        orgBypassObject1=0;
        restrictionsObject1=NULL_LIST;
        controllerCount--;
    }
    else if(which==keyObject2)
    {
        while(x<llGetListLength(restrictionsObject2))
        {
            splitCommand(llList2String(restrictionsObject2,x));
            removalCheck();
            x++;
        }
        llRegionSayTo(keyObject2,RLV_CHANNEL,newCommands+","+(string)keyObject2+RELEASE_FOOTER);
        keyObject2=NULL;
//        orgBypassObject2=0;
        restrictionsObject2=NULL_LIST;
        controllerCount--;
    }
    else if(which==keyObject3)
    {
        while(x<llGetListLength(restrictionsObject3))
        {
            splitCommand(llList2String(restrictionsObject3,x));
            removalCheck();
            x++;
        }
        llRegionSayTo(keyObject3,RLV_CHANNEL,newCommands+","+(string)keyObject3+RELEASE_FOOTER);
        keyObject3=NULL;
//        orgBypassObject3=0;
        restrictionsObject3=NULL_LIST;
        controllerCount--;
    }
}
addToObject() // Assigns restrictions to a controller
{
    integer addOrRemove;
    rIndex=~llGetListLength(newRestrictions);
    if(objectIndex==1)
    {
        while(++rIndex)
        {
            splitCommand(llList2String(newRestrictions,rIndex));
            addOrRemove=applyRLV();
            if(addOrRemove==1)
            {
                if(llListFindList(restrictionsObject1,find3)==-1) restrictionsObject1+=find3;
            }
            else if(addOrRemove==-1)
            {
                index=llListFindList(restrictionsObject1,find3);
                if(~index)
                {
                    restrictionsObject1=llDeleteSubList(restrictionsObject1,index,index);
                    executeRLV();
                }
                else rejectCommand();
            }
            else if(addOrRemove==2)
            {
                string search=llDeleteSubString(find2,0,0);
                integer y=~llGetListLength(restrictionsObject1);
                string search2;
                while(++y)
                {
                    search2=llList2String(restrictionsObject1,y);
                    if(~llSubStringIndex(search2,search))
                    {
                        clearFind(search2);
                        restrictionsObject1=llDeleteSubList(restrictionsObject1,y,y);
                    }
                }
                llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+","+find+find1+find2+",ok");
            }
        }
    }
    else if(objectIndex==2)
    {
        while(++rIndex)
        {
            splitCommand(llList2String(newRestrictions,rIndex));
            addOrRemove=applyRLV();
            if(addOrRemove==1)
            {
                if(llListFindList(restrictionsObject2,find3)==-1) restrictionsObject2+=find3;
            }
            else if(addOrRemove==-1)
            {
                index=llListFindList(restrictionsObject2,find3);
                if(~index)
                {
                    restrictionsObject2=llDeleteSubList(restrictionsObject2,index,index);
                    executeRLV();
                }
                else rejectCommand();
            }
            else if(addOrRemove==2)
            {
                string search=llDeleteSubString(find2,0,0);
                integer y=~llGetListLength(restrictionsObject2);
                string search2;
                while(++y)
                {
                    search2=llList2String(restrictionsObject2,y);
                    if(~llSubStringIndex(search2,search))
                    {
                        clearFind(search2);
                        restrictionsObject2=llDeleteSubList(restrictionsObject2,y,y);
                    }
                }
                llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+","+find+find1+find2+",ok");
            }
        }
    }
    else if(objectIndex==3) 
    {
        while(++rIndex)
        {
            splitCommand(llList2String(newRestrictions,rIndex));
            addOrRemove=applyRLV();
            if(addOrRemove==1)
            {
                if(llListFindList(restrictionsObject3,find3)==-1) restrictionsObject3+=find3;
            }
            else if(addOrRemove==-1)
            {
                index=llListFindList(restrictionsObject3,find3);
                if(~index)
                {
                    restrictionsObject3=llDeleteSubList(restrictionsObject3,index,index);
                    executeRLV();
                }
                else rejectCommand();
            }
            else if(addOrRemove==2)
            {
                string search=llDeleteSubString(find2,0,0);
                integer y=~llGetListLength(restrictionsObject3);
                string search2;
                while(++y)
                {
                    search2=llList2String(restrictionsObject3,y);
                    if(~llSubStringIndex(search2,search))
                    {
                        clearFind(search2);
                        restrictionsObject3=llDeleteSubList(restrictionsObject3,y,y);
                    }
                }
                llRegionSayTo(newObject,RLV_CHANNEL,newCommands+","+(string)newObject+","+find+find1+find2+",ok");
            }
        }
    }
    if(isKO) removeObject(newObject);
}
setObject() // Setsup a new controller
{
    addToObject();
    if(objectIndex==1)
    {
        if(restrictionsObject1!=NULL_LIST)
        {
            controllerCount++;
            keyObject1=newObject;
        }
    }
    else if(objectIndex==2)
    {
        if(restrictionsObject2!=NULL_LIST)
        {
            controllerCount++;
            keyObject2=newObject;
        }
    }
    else if(objectIndex==3)
    {
        if(restrictionsObject3!=NULL_LIST)
        {
            controllerCount++;
            keyObject3=newObject;
        }
    }
    if(isKO) removeObject(newObject);
    else llMessageLinked(LINK_ROOT,controllerCount,"controllerCount",NULL);
}
reapplyRestrictions(key which) // Refreshes restrictions after relog or fast release
{
    integer x;
    if(which==WILDCARD)
    {
        list listAllRestrictions=NULL_LIST;
        if(controllerCount>1 && llGetUsedMemory()<(startupMemory+(65535-startupMemory)))
        {
            x=~llGetListLength(restrictionsObject2);
            listAllRestrictions=restrictionsObject1;
            while(++x)
            {
                find3=[llList2String(restrictionsObject2,x)];
                if(llListFindList(listAllRestrictions,find3)==-1) listAllRestrictions+=find3;
            }
            x=~llGetListLength(restrictionsObject3);
            while(++x)
            {
                find3=[llList2String(restrictionsObject3,x)];
                if(llListFindList(listAllRestrictions,find3)==-1) listAllRestrictions+=find3;
            }
            x=~llGetListLength(listAllRestrictions);
            while(++x)
            {
                llOwnerSay(llList2String(listAllRestrictions,x));
            }
        }
        else
        {
            if(restrictionsObject1!=NULL_LIST) 
            {
                x=~llGetListLength(restrictionsObject1);
                while(++x)
                {
                    llOwnerSay(llList2String(restrictionsObject1,x));
                }
            }
            if(restrictionsObject2!=NULL_LIST)
            {
                x=~llGetListLength(restrictionsObject2);
                while(++x)
                {
                    llOwnerSay(llList2String(restrictionsObject2,x));
                }
            }
            if(restrictionsObject3!=NULL_LIST)
            {
                x=~llGetListLength(restrictionsObject3);
                while(++x)
                {
                    llOwnerSay(llList2String(restrictionsObject3,x));
                }
            }
        }
    }
    else if(which==keyObject1)
    {
        if(restrictionsObject1!=NULL_LIST)
        {
            x=~llGetListLength(restrictionsObject1);
            while(++x)
            {
                llOwnerSay(llList2String(restrictionsObject1,x));
            }
        }
    }
    else if(which==keyObject2)
    {
        if(restrictionsObject2!=NULL_LIST)
        {
            x=~llGetListLength(restrictionsObject2);
            while(++x)
            {
                llOwnerSay(llList2String(restrictionsObject2,x));
            }
        }
    }
    else if(which==keyObject3)
    {
        if(restrictionsObject3!=NULL_LIST)
        {
            x=~llGetListLength(restrictionsObject3);
            while(++x)
            {
                llOwnerSay(llList2String(restrictionsObject3,x));
            }
        }
    }
}
powerOff()
{
    llSetTimerEvent(0.0);
    llListenRemove(listenRLV);
    llListenRemove(listenViewer);
    llListenRemove(listenSitTarget);
    llOwnerSay(CLEAR);
    llOwnerSay(CLEAR_ENV);
    llMessageLinked(LINK_ALL_OTHERS,0,POWER_OFF,NULL);
    power=0;
}
powerOn()
{
    setPrims();
    busyOn();
    initVars();
    llMessageLinked(LINK_ROOT,0,WARNING,NULL);
    llMessageLinked(LINK_ROOT,0,"POST",NULL);
    llMessageLinked(LINK_ALL_OTHERS,0,CONTROLLERS+(string)NULL+", "+(string)NULL+", "+(string)NULL,NULL);
    ownerKey=llGetOwner();
    if(llGetAttached()) llRequestPermissions(ownerKey,PERMISSION_TAKE_CONTROLS);
    llSleep(5.0);
    listenRLV=llListen(RLV_CHANNEL,"",NULL,"");
    listenSitTarget=llListen(202118215,"",ownerKey,"");
    llListenControl(listenSitTarget,FALSE);
    llSetTimerEvent(1.0);
    llMessageLinked(LINK_ROOT,0,CAPABILITIES,NULL);
    llMessageLinked(LINK_ROOT,0,NORMAL,NULL);
    llOwnerSay("@detach=n");
    power=1;
    //llOwnerSay("Memory Usage: "+(string)(llGetUsedMemory()/1024)+"kb");
    busyOff();
}
sendStatus()
{
    llMessageLinked(LINK_ROOT,0,"Flash",NULL);    
    if(pingedObjects==NULL_LIST)
    {
        if(controllerCount)
        {
            string message=" Restrictions In Effect: ";
            if(keyObject1!=NULL) llMessageLinked(LINK_ROOT,0,(string)llGetListLength(restrictionsObject1)+message+llKey2Name(keyObject1)+": "+llList2CSV(restrictionsObject1),MESSAGE);
            if(keyObject2!=NULL) llMessageLinked(LINK_ROOT,0,(string)llGetListLength(restrictionsObject2)+message+llKey2Name(keyObject2)+": "+llList2CSV(restrictionsObject2),MESSAGE);
            if(keyObject3!=NULL) llMessageLinked(LINK_ROOT,0,(string)llGetListLength(restrictionsObject3)+message+llKey2Name(keyObject3)+": "+llList2CSV(restrictionsObject3),MESSAGE);
        }
    }
    else
    {
        llMessageLinked(LINK_ROOT,0,"Pinging Controllers",MESSAGE);
    }
    llMessageLinked(LINK_ROOT,0,"Relay Memory Usage: "+(string)(llGetUsedMemory()/1024)+"kb",MESSAGE);
}
default
{
    state_entry() // Initial startup, 5 second delay
    {
        llSetRemoteScriptAccessPin(0);
        powerOn();
    }
    link_message(integer linkset, integer number, string message, key id)
    {
        if(message==POWER_OFF)
        {
            if(!controllerCount)
            {
                if(!power) llMessageLinked(LINK_ALL_OTHERS,0,POWER_OFF,NULL);
                else powerOff();
            }
            else sendStatus();
        }
        else if(message=="SetMode") relayMode=number;
        else if(message=="Safety!")
        {
            llMessageLinked(LINK_ROOT,0,WARNING,NULL);
            if(id==WILDCARD) //Full Safeword Release
            {
                llListenControl(listenRLV,FALSE);
                llOwnerSay(CLEAR_ALL);
                llOwnerSay(CLEAR_ENV);
                if(keyObject1!=NULL) llRegionSayTo(keyObject1,RLV_CHANNEL,RELEASE_HEADER+","+(string)keyObject1+RELEASE_FOOTER);
                if(keyObject2!=NULL) llRegionSayTo(keyObject2,RLV_CHANNEL,RELEASE_HEADER+","+(string)keyObject2+RELEASE_FOOTER);
                if(keyObject3!=NULL) llRegionSayTo(keyObject3,RLV_CHANNEL,RELEASE_HEADER+","+(string)keyObject3+RELEASE_FOOTER);
                integer forceUnsit;
                if(sitTargetKey==keyObject1) forceUnsit=1;
                else if(sitTargetKey==keyObject2) forceUnsit=1;
                else if(sitTargetKey==keyObject3) forceUnsit=1;
                if(forceUnsit) llOwnerSay(FORCE_UNSIT);
                llResetScript();
            }
            else
            {
                key unSitKey=sitTargetKey;
                removeObject(id);
                defragObjects();
                if(unSitKey==id) llOwnerSay(FORCE_UNSIT);
                safetyObject=id;
                safetyTimeout=10;
                llMessageLinked(LINK_ROOT,0,NORMAL,NULL);
            }
        }
        else if(message==POWER_ON)
        {
            if(!power) llResetScript();
            else llMessageLinked(LINK_ALL_OTHERS,0,POWER_ON,NULL);
        }
        else if(linkset==primQueue)
        {
            busyOn();
            if(number)
            {
                newObject=id;
                commandList=llCSV2List(message);
                doRLV();
            }
            else
            {
                newObject=id;
                commandList=llCSV2List(message);
                rejectObject();
            }
            busyOff();
        }
        else if(message=="Status") sendStatus();
        else if(message=="Refresh") reapplyRestrictions(WILDCARD);
        else if(message=="Sync")
        {
            busyOn();
            integer x=0;
            if(keyObject1)
            {
                while(x<llGetListLength(restrictionsObject1))
                {
                    llRegionSayTo(ownerKey,-201818,(string)keyObject1+SYNC+(string)ownerKey+", "+llList2String(restrictionsObject1,x));
                    x++;
                }
            }
            x=0;
            if(keyObject2)
            {
                while(x<llGetListLength(restrictionsObject2))
                {
                    llRegionSayTo(ownerKey,-201818,(string)keyObject2+SYNC+(string)ownerKey+", "+llList2String(restrictionsObject2,x));
                    x++;
                }
            }
            x=0;
            if(keyObject3)
            {
                while(x<llGetListLength(restrictionsObject3))
                {
                    llRegionSayTo(ownerKey,-201818,(string)keyObject3+SYNC+(string)ownerKey+", "+llList2String(restrictionsObject3,x));
                    x++;
                }
            }
            llSleep(2.0);
            llRegionSayTo(ownerKey,-201818,"Done");
            powerOff();
            llMessageLinked(LINK_ROOT,0,"Detach",NULL);
        }
        else if(message=="FinishedSync")
        {
            synchronizing=0;
            llMessageLinked(LINK_ROOT,0,CAPABILITIES,NULL);
            llListenControl(listenRLV,TRUE);
            llMessageLinked(LINK_ROOT,0,NORMAL,NULL);
        }
        else if(message=="ForceDetach") powerOff();
        else if(number==-201818)
        {
            if(!synchronizing)
            {
                if(!power) powerOn();
                else initVars();
                synchronizing=1;
                relayMode=0;
                llListenControl(listenRLV,FALSE);
                llMessageLinked(LINK_ROOT,0,WARNING,NULL);
            }
            newObject=id;
            commandList=llCSV2List(message);
            doRLV();
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        if(channel==RLV_CHANNEL)
        {
            if(id!=safetyObject)
            {
                busyOn();
                commandList=llCSV2List(message);
                if(llGetListLength(commandList)==3)
                {
                    if(llList2Key(commandList,1)==WILDCARD) commandList=[llList2String(commandList,0),ownerKey,llList2String(commandList,2)];
                    if(llList2Key(commandList,1)==ownerKey)
                    {
                        newObject=id;
                        if(relayMode==3) doRLV();
                        else llMessageLinked(primQueue,0,llList2CSV(commandList),newObject); //Sends off the commands to the queue system
                    }
                }
                busyOff();
            }
        }
        else if(channel==20181817)
        {
            if(pingTimeout==31)
            {
                pingTimeout=30;
                reapplyRestrictions(ownerKey);
                llListenRemove(listenViewer);
                llMessageLinked(LINK_ROOT,0,WARNING,NULL);
                pingedObjects=NULL_LIST;
                if(keyObject1!=NULL) pingedObjects+=keyObject1;
                if(keyObject2!=NULL) pingedObjects+=keyObject2;
                if(keyObject3!=NULL) pingedObjects+=keyObject3;
                integer x=0;
                while(x<llGetListLength(pingedObjects))
                {
                    llRegionSayTo(llList2Key(pingedObjects,x),RLV_CHANNEL,"ping,"+llList2String(pingedObjects,x)+",ping,ping");
                    x++;
                }
            }
        }
        else if(channel==202118215)
        {
            if(pingTimeout<=0) sitTargetKey=(key)message;
        }
    }
    on_rez(integer total)
    {
        llSetTimerEvent(0.0);
        isListening=0;
        ownerKey=llGetOwner(); // Necessary
        if(llGetAttached()) llRequestPermissions(ownerKey,PERMISSION_TAKE_CONTROLS);
        setPrims();
        if(power)
        {
            busyOn();
            listenRLV=llListen(RLV_CHANNEL,"",NULL,"");
            listenSitTarget=llListen(202118215,"",ownerKey,"");
            isListening=1;
            llOwnerSay("@detach=n");
            doPing();
            busyOff();
        }
        llSetTimerEvent(1.0);
    }
    timer()
    {
        if(pingTimeout==31)
        {
            llOwnerSay("@version=20181817");
        }
        else if(!pingTimeout)
        {
            if(pingedObjects!=NULL_LIST) // Clears out objects that have not responded to ping
            {
                integer z=~llGetListLength(pingedObjects);
                while(++z)
                {
                    removeObject(llList2Key(pingedObjects,z));
                }
                pingedObjects=NULL_LIST;
                defragObjects();
                llMessageLinked(LINK_ROOT,0,NORMAL,NULL);
            }
        }
        if(~pingTimeout)
        {
            if(pingTimeout<31) pingTimeout--;
        }
        else
        {
            if(controllerCount)
            {
                if(llGetAgentInfo(ownerKey) & AGENT_ON_OBJECT)
                {
                    if(!isListening) llListenControl(listenSitTarget,TRUE);
                    llOwnerSay("@getsitid=202118215");
                    isListening=1;
                }
                else if(llGetAgentInfo(ownerKey) & ~AGENT_ON_OBJECT)
                {
                    if(isListening)
                    {
                        llListenControl(listenSitTarget,FALSE);
                        sitTargetKey=NULL;
                    }
                    isListening=0;
                }
            }
            else if(isListening)
            {
                llListenControl(listenSitTarget,FALSE);
                sitTargetKey=NULL;
            }
        }
        if(!checkRezTimeout) checkRez();
        else checkRezTimeout--;
        if(!safetyTimeout) safetyObject=NULL;
        if(~safetyTimeout) safetyTimeout--;
    }
    run_time_permissions(integer permissions)
    {
        if(PERMISSION_TAKE_CONTROLS & permissions) 
        {
            if(!(llGetAgentInfo(ownerKey) & AGENT_ON_OBJECT)) llTakeControls(CONTROL_ML_LBUTTON | 0,FALSE,TRUE);
        }
    }
    changed (integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
        if(change & CHANGED_LINK)
        {
            setPrims();
            llMessageLinked(LINK_ROOT,0,CAPABILITIES,NULL);
        }
        if(change & CHANGED_TELEPORT) doPing();
    }
}