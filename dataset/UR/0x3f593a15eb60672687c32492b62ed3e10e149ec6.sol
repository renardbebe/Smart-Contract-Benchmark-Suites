 

contract Etherization {
    
     
    uint public START_PRICE = 1000000000000000000;
     
    uint public CITY_PRICE = 800000000000000000;
     
    uint public BUILDING_PRICE = 500000000000000000;
     
    uint public UNIT_PRICE = 200000000000000000;
     
    uint public MAINT_PRICE = 20000000000000000;
     
    uint public MIN_WTH = 100000000000000000;
    
     
    uint public WAIT_TIME = 14400;
    uint MAP_ROWS = 34;
    uint MAP_COLS = 34;
    
    
    struct City {
        uint owner;
        string name;
         
        bool[5] buildings;
         
        uint[10] units;  
        uint[2] rowcol;
        int previousID;
        int nextID;
    }
    
    struct Player {
         
        address etherAddress;
         
        string name;
         
        uint treasury;
         
        uint capitol;
         
        uint numCities;
        uint numUnits;
         
        uint lastTimestamp;
    }
    
    Player player;
    Player[] public players;
    uint public numPlayers = 0;
    
    mapping(address => uint) playerIDs;
    mapping(uint => uint) public playerMsgs;
    
    City city;
    City[] public cities;
    uint public numCities = 0;
    
    uint[] public quarryCities;
    uint[] public farmCities;
    uint[] public woodworksCities;
    uint[] public metalworksCities;
    uint[] public stablesCities;
    
    uint[34][34] public map;

    address wizardAddress;
    
    address utilsAddress;
    address utilsAddress2;
    
     
    uint public totalBalances = 0;

     
    modifier onlywizard { if (msg.sender == wizardAddress) _ }
    
     
    modifier onlyutils { if (msg.sender == utilsAddress || msg.sender == utilsAddress2) _ }



     
    function Etherization() {
        wizardAddress = msg.sender;
    }

    function start(string playerName, string cityName, uint row, uint col, uint rowref, uint colref) {
        
        
         
        if (msg.value < START_PRICE) {
             
             
            return;
        }
         
        if (playerIDs[msg.sender] > 0) {
             
             
            return;
        }
        
        player.etherAddress = msg.sender;
        player.name = playerName;
        player.treasury = msg.value;
        totalBalances += msg.value;
        player.capitol = numCities;
        player.numCities = 1;
        player.numUnits = 1;

        players.push(player);
        
        city.owner = numPlayers;
        city.name = cityName;
         
        if(numCities <= 0) {
            city.buildings[0] = true;
            quarryCities.push(0);
            city.buildings[1] = true;
            farmCities.push(0);
            city.rowcol[0] = 10;
            city.rowcol[1] = 10;
            map[10][10] = numPlayers+1;
        } else {
            city.buildings[0] = false;
            city.buildings[1] = false;
            if(row>33 || col>33 || rowref>33 || colref>33 || int(row)-int(rowref) > int(1) || int(row)-int(rowref) < int(-1) || int(col)-int(colref) > int(1) || int(col)-int(colref) < int(-1) || map[row][col]>0 || map[rowref][colref]<=0) {
                throw;
            }
            city.rowcol[0] = row;
            city.rowcol[1] = col;
            map[row][col] = numPlayers+1;
            
            players[numPlayers].treasury -= START_PRICE;
             
            uint productionCut;
            uint i;
            productionCut = START_PRICE / quarryCities.length;
            for(i=0; i < quarryCities.length; i++) {
                players[cities[quarryCities[i]].owner].treasury += productionCut;
            }
        }
        city.units[0] = 1;   
        city.previousID = -1;
        city.nextID = -1;
        
        cities.push(city);
        
        playerIDs[msg.sender] = numPlayers+1;  
        numPlayers++;
        numCities++;
        
        playerMsgs[playerIDs[msg.sender]-1] = 1 + row*100 + col*10000;
        players[numPlayers-1].lastTimestamp = now;
    }
    
    function deposit() {
        players[playerIDs[msg.sender]-1].treasury += msg.value;
        totalBalances += msg.value;
    }
    
    function withdraw(uint amount) {
        if(int(playerIDs[msg.sender])-1 < 0) {
            throw;
        }
        uint playerID = playerIDs[msg.sender]-1;
        if(timePassed(playerID) < WAIT_TIME) {
            playerMsgs[playerIDs[msg.sender]-1] = 2;
            return;        
        }
        if(amount < players[playerID].treasury && amount > MIN_WTH) {
            players[playerID].treasury -= amount;
            totalBalances -= amount;
            players[playerID].etherAddress.send((amount*99)/100);  
        }
    }
    
    
    
    function getMyPlayerID() constant returns (int ID) {
        return int(playerIDs[msg.sender])-1;
    }
    
    function getMyMsg() constant returns (uint s) {
        return playerMsgs[playerIDs[msg.sender]-1];
    }
    
    function getCity(uint cityID) constant returns (uint owner, string cityName, bool[5] buildings, uint[10] units, uint[2] rowcol, int previousID, int nextID) {
        return (cities[cityID].owner, cities[cityID].name, cities[cityID].buildings, cities[cityID].units, cities[cityID].rowcol, cities[cityID].previousID, cities[cityID].nextID);
    }
    
    
    function timePassed(uint playerID) constant returns (uint tp) {
        return (now - players[playerID].lastTimestamp);
    }


     
    function getCommission() onlywizard constant returns (uint com) {
        return this.balance-totalBalances;
    }

     
    function sweepCommission(uint amount) onlywizard {
        if(amount < this.balance-totalBalances) {
            wizardAddress.send(amount);
        }
    }
    
    
    
    function setUtils(address a) onlywizard {
        utilsAddress = a;
    }
    
    function setUtils2(address a) onlywizard {
        utilsAddress2 = a;
    }
    
    function getPlayerID(address sender) onlyutils constant returns (uint playerID) {
        if(int(playerIDs[sender])-1 < 0) {
            throw;
        }
        return playerIDs[sender]-1;
    }
    
    function getWwLength() constant returns (uint length) {
        return woodworksCities.length;
    }
    
    function getMwLength() constant returns (uint length) {
        return metalworksCities.length;
    }
    
    function getStLength() constant returns (uint length) {
        return stablesCities.length;
    }
    
    function getFmLength() constant returns (uint length) {
        return farmCities.length;
    }
    
    function getQrLength() constant returns (uint length) {
        return quarryCities.length;
    }
    
    
    function setMsg(address sender, uint s) onlyutils {
        playerMsgs[playerIDs[sender]-1] = s;
    }
    
    function setNumCities(uint nc) onlyutils {
        numCities = nc;
    }
    
    function setUnit(uint cityID, uint i, uint unitType) onlyutils {
        cities[cityID].units[i] = unitType;
    }
    
    function setOwner(uint cityID, uint owner) onlyutils {
        cities[cityID].owner = owner;
    }
    
    function setName(uint cityID, string name) onlyutils {
        cities[cityID].name = name;
    }
    
    function setPreviousID(uint cityID, int previousID) onlyutils {
        cities[cityID].previousID = previousID;
    }
    
    function setNextID(uint cityID, int nextID) onlyutils {
        cities[cityID].nextID = nextID;
    }
    
    function setRowcol(uint cityID, uint[2] rowcol) onlyutils {
        cities[cityID].rowcol = rowcol;
    }
    
    function setMap(uint row, uint col, uint ind) onlyutils {
        map[row][col] = ind;
    }
    
    function setCapitol(uint playerID, uint capitol) onlyutils {
        players[playerID].capitol = capitol;
    }

    function setNumUnits(uint playerID, uint numUnits) onlyutils {
        players[playerID].numUnits = numUnits;
    }
    
    function setNumCities(uint playerID, uint numCities) onlyutils {
        players[playerID].numCities = numCities;
    }
    
    function setTreasury(uint playerID, uint treasury) onlyutils {
        players[playerID].treasury = treasury;
    }
    
    function setLastTimestamp(uint playerID, uint timestamp) onlyutils {
        players[playerID].lastTimestamp = timestamp;
    }
    
    function setBuilding(uint cityID, uint buildingType) onlyutils {
        cities[cityID].buildings[buildingType] = true;
        if(buildingType == 0) {
            quarryCities.push(cityID);
        } else if(buildingType == 1) {
            farmCities.push(cityID);
        } else if(buildingType == 2) {
            woodworksCities.push(cityID);
        } else if(buildingType == 3) {
            metalworksCities.push(cityID);
        } else if(buildingType == 4) {
            stablesCities.push(cityID);
        }
    }
    
    function pushCity() onlyutils {
        city.buildings[0] = false;
        city.buildings[1] = false;
        cities.push(city);
    }

}





contract EtherizationUtils2 {
    
    uint playerID;
    uint ownerS;
    uint ownerT;
    uint numUnitsS;
    uint numCitiesS;
    uint treasuryS;
    uint numUnitsT;
    uint numCitiesT;
    uint treasuryT;
    uint j;
    uint bestType;
    uint bestTypeInd;
    uint ran;
    bool win;
    bool cityCaptured = false;
    
    Etherization public e;
    
    address wizardAddress;
    
     
    modifier onlywizard { if (msg.sender == wizardAddress) _ }
    
    
    function EtherizationUtils2() {
        wizardAddress = msg.sender;
    }
    
    function sete(address a) onlywizard {
        e = Etherization(a);
    }
    
    function attack(uint source, uint target, uint[] unitIndxs) {
        uint[2] memory sRowcol;
        uint[2] memory tRowcol;
        uint[10] memory unitsS;
        uint[10] memory unitsT;
        
        playerID = e.getPlayerID(msg.sender);
        
        if(e.timePassed(playerID) < e.WAIT_TIME()) {
            e.setMsg(msg.sender, 2);
            return;        
        }
        
        (ownerS,,,unitsS,sRowcol,,) = e.getCity(source);
        (ownerT,,,unitsT,tRowcol,,) = e.getCity(target);
        (,,treasuryS,,numCitiesS,numUnitsS,) = e.players(ownerS);
        (,,treasuryT,,numCitiesT,numUnitsT,) = e.players(ownerT);
        if(playerID != ownerS || playerID == ownerT || int(sRowcol[0])-int(tRowcol[0]) > int(1) || int(sRowcol[0])-int(tRowcol[0]) < int(-1) || int(sRowcol[1])-int(tRowcol[1]) > int(1) || int(sRowcol[1])-int(tRowcol[1]) < int(-1)) {
            e.setMsg(msg.sender, 17);
            return;
        }

        cityCaptured = false;
        for(uint i=0; i<unitIndxs.length; i++) {
            bestType = 0;
            win = false;
            ran = uint32(block.blockhash(block.number-1-i))/42949673;  
             
            if(unitsS[unitIndxs[i]]==1) {
                bestType = 0;
                bestTypeInd = 0;
                for(j=0; j<unitsT.length; j++) {
                    if(unitsT[j] == 1 && bestType!=2) {
                        bestType = 1;
                        bestTypeInd = j;
                    } else if(unitsT[j] == 2) {
                        bestType = 2;
                        bestTypeInd = j;
                        break;
                    } else if(unitsT[j] == 3 && bestType!=2 && bestType!=1) {
                        bestType = 3;
                        bestTypeInd = j;
                    }
                }
                if(bestType==1) {
                    if(ran > 50) {
                        win = true;
                    }
                } else if(bestType==2) {
                    if(ran > 75) {
                        win = true;
                    }
                } else if(bestType==3) {
                    if(ran > 25) {
                        win = true;
                    }
                } else {
                    cityCaptured = true;
                    break;
                }
            }
             
            else if(unitsS[unitIndxs[i]]==2) {
                bestType = 0;
                bestTypeInd = 0;
                for(j=0; j<unitsT.length; j++) {
                    if(unitsT[j] == 2 && bestType!=3) {
                        bestType = 2;
                        bestTypeInd = j;
                    } else if(unitsT[j] == 3) {
                        bestType = 3;
                        bestTypeInd = j;
                        break;
                    } else if(unitsT[j] == 1 && bestType!=3 && bestType!=2) {
                        bestType = 1;
                        bestTypeInd = j;
                    }
                }
                if(bestType==1) {
                    if(ran > 25) {
                        win = true;
                    }
                } else if(bestType==2) {
                    if(ran > 50) {
                        win = true;
                    }
                } else if(bestType==3) {
                    if(ran > 75) {
                        win = true;
                    }
                } else {
                    cityCaptured = true;
                    break;
                }
            }
             
            else if(unitsS[unitIndxs[i]]==3) {
                bestType = 0;
                bestTypeInd = 0;
                for(j=0; j<unitsT.length; j++) {
                    if(unitsT[j] == 3 && bestType!=1) {
                        bestType = 3;
                        bestTypeInd = j;
                    } else if(unitsT[j] == 1) {
                        bestType = 1;
                        bestTypeInd = j;
                        break;
                    } else if(unitsT[j] == 2 && bestType!=1 && bestType!=3) {
                        bestType = 2;
                        bestTypeInd = j;
                    }
                }
                if(bestType==1) {
                    if(ran > 75) {
                        win = true;
                    }
                } else if(bestType==2) {
                    if(ran > 25) {
                        win = true;
                    }
                } else if(bestType==3) {
                    if(ran > 50) {
                        win = true;
                    }
                } else {
                    cityCaptured = true;
                    break;
                }
            }
             
            else {
                continue;
            }
            
            if(cityCaptured) {
                break;
            }
            if(win) {
                unitsT[bestTypeInd] = 0;  
                e.setUnit(target, bestTypeInd, 0);  
                numUnitsT--;
                e.setNumUnits(ownerT, numUnitsT);
            } else {
                unitsS[unitIndxs[i]] = 0;  
                e.setUnit(source, unitIndxs[i], 0);  
                numUnitsS--;
                e.setNumUnits(playerID, numUnitsS);
            }
        }
        
        if(cityCaptured) {
             
            j = 0;
            for(; i < unitIndxs.length; i++) {
                e.setUnit(target, j, unitsS[unitIndxs[i]]);
                e.setUnit(source, unitIndxs[i], 0);
                j++;
            }
            
             
            uint treasuryFraction = treasuryT/numCitiesT;
            e.setNumCities(ownerT, numCitiesT-1);
            e.setTreasury(ownerT, treasuryT-treasuryFraction);
            e.setTreasury(playerID, treasuryS+treasuryFraction);
            e.setNumCities(playerID, numCitiesS+1);
            
            int previousID;
            int nextID;
            uint capitol;
             
            (,,,,,,previousID,nextID) = e.getCity(target);
            if(previousID >= 0) {
                e.setNextID(uint(previousID), nextID);
                (,,,capitol,,,) = e.players(ownerT);
                if(capitol == target) {
                    e.setCapitol(capitol, uint(previousID));
                }
            }
            if(nextID >= 0) {
                e.setPreviousID(uint(nextID), previousID);
                if(capitol == target) {
                    e.setCapitol(capitol, uint(nextID));
                }
            }
            
            e.setOwner(target, ownerS);
            e.setMap(tRowcol[0], tRowcol[1], ownerS+1);
            
            (,,,,,,previousID,nextID) = e.getCity(source);
             
            e.setPreviousID(target, int(source));
            e.setNextID(target, nextID);
            if(nextID >= 0) {
                e.setPreviousID(uint(nextID), int(target));
            }
            e.setNextID(source, int(target));
            
            e.setMsg(msg.sender, 18 + tRowcol[0]*100 + tRowcol[1]*10000);
        } else {
            e.setMsg(msg.sender, 19 + tRowcol[0]*100 + tRowcol[1]*10000);
        }
        e.setLastTimestamp(playerID, now);
    }
    
    function buildCity(string cityName, uint[2] rowcol, uint[2] rowcolref) {
        playerID = e.getPlayerID(msg.sender);
        
        if(e.timePassed(playerID) < e.WAIT_TIME()) {
            e.setMsg(msg.sender, 2);
            return;        
        }
        
        uint treasury;
        uint numCities;
        uint numUnits;
        uint capitol;
        (,,treasury,capitol,numCities,numUnits,) = e.players(playerID);
        if(treasury < e.CITY_PRICE()) {
            e.setMsg(msg.sender, 6);
            return;
        }

        e.setTreasury(playerID, treasury-e.CITY_PRICE());
        
        if(rowcol[0]>33 || rowcol[1]>33 || rowcolref[0]>33 || rowcolref[1]>33 || int(rowcol[0])-int(rowcolref[0]) > int(1) || int(rowcol[0])-int(rowcolref[0]) < int(-1) || int(rowcol[1])-int(rowcolref[1]) > int(1) || int(rowcol[1])-int(rowcolref[1]) < int(-1) || e.map(rowcol[0],rowcol[1])>0 || e.map(rowcolref[0],rowcolref[1])<=0) {
            throw;
        }

         
        uint productionCut;
        uint owner;
        int i;
        productionCut = e.CITY_PRICE() / e.getQrLength();
        for(i=0; uint(i) < e.getQrLength(); i++) {
            (owner,) = e.cities(e.quarryCities(uint(i)));
            (,,treasury,,,,) = e.players(owner);
            e.setTreasury(owner, treasury+productionCut);
        }
        
        e.setNumCities(playerID, numCities+1);
        e.setNumUnits(playerID, numUnits+1);

        e.pushCity();
        e.setOwner(e.numCities(), playerID);
        e.setName(e.numCities(), cityName);
        e.setUnit(e.numCities(), 0, 1);    
        
        e.setRowcol(e.numCities(), rowcol);
        e.setMap(rowcol[0], rowcol[1], playerID+1);
        
         
        if(numCities<1) {
            e.setCapitol(playerID, e.numCities());
            e.setPreviousID(e.numCities(), -1);
        } else {
            int nextID;
            i = int(capitol);
            (,nextID) = e.getCity(uint(i));
            for(; nextID >= 0 ;) {
                i = nextID;
                (,nextID) = e.getCity(uint(i));
            }
            e.setNextID(uint(i), int(e.numCities()));
            e.setPreviousID(e.numCities(), i);
        }
        e.setNextID(e.numCities(), -1);

        e.setNumCities(e.numCities()+1);
        
        e.setMsg(msg.sender, 20 + rowcol[0]*100 + rowcol[1]*10000);
        e.setLastTimestamp(playerID, now);
    }
    
}