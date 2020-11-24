 

pragma solidity ^0.4.18;

contract KryptoArmy {

    address ceoAddress = 0x46d9112533ef677059c430E515775e358888e38b;
    address cfoAddress = 0x23a49A9930f5b562c6B1096C3e6b5BEc133E8B2E;

    modifier onlyCeo() {
        require (msg.sender == ceoAddress);
        _;
    }

     
    struct Army {
        string name;             
        string idArmy;           
        uint experiencePoints;   
        uint256 price;           
        uint attackBonus;        
        uint defenseBonus;       
        bool isForSale;          
        address ownerAddress;    
        uint soldiersCount;      
    } 
    Army[] armies;
    
     
    struct Battle {
        uint idArmyAttacking;    
        uint idArmyDefensing;    
        uint idArmyVictorious;   
    } 

    Battle[] battles;

     
    mapping (address => uint) public ownerToArmy;        
    mapping (address => uint) public ownerArmyCount;     

     
    mapping (uint => uint) public armyDronesCount;
    mapping (uint => uint) public armyPlanesCount;
    mapping (uint => uint) public armyHelicoptersCount;
    mapping (uint => uint) public armyTanksCount;
    mapping (uint => uint) public armyAircraftCarriersCount;
    mapping (uint => uint) public armySubmarinesCount;
    mapping (uint => uint) public armySatelitesCount;

     
    mapping (uint => uint) public armyCountBattlesWon;
    mapping (uint => uint) public armyCountBattlesLost;

     
    function _createArmy(string _name, string _idArmy, uint _price, uint _attackBonus, uint _defenseBonus) public onlyCeo {

         
        armies.push(Army(_name, _idArmy, 0, _price, _attackBonus, _defenseBonus, true, address(this), 0));
    }

     
    function purchaseArmy(uint _armyId) public payable {
         
        require(msg.value == armies[_armyId].price);
        require(msg.value > 0);
        
         
        if(armies[_armyId].ownerAddress != address(this)) {
            uint CommissionOwnerValue = msg.value - (msg.value / 10);
            armies[_armyId].ownerAddress.transfer(CommissionOwnerValue);
        }

         
        _ownershipArmy(_armyId);
    }

     
    function purchaseSoldiers(uint _armyId, uint _countSoldiers) public payable {
         
        require(msg.value > 0);
        uint256 msgValue = msg.value;

        if(msgValue == 1000000000000000 && _countSoldiers == 1) {
             
            armies[_armyId].soldiersCount = armies[_armyId].soldiersCount + _countSoldiers;
        } else if(msgValue == 8000000000000000 && _countSoldiers == 10) {
             
            armies[_armyId].soldiersCount = armies[_armyId].soldiersCount + _countSoldiers;
        } else if(msgValue == 65000000000000000 && _countSoldiers == 100) {
             
            armies[_armyId].soldiersCount = armies[_armyId].soldiersCount + _countSoldiers;
        } else if(msgValue == 500000000000000000 && _countSoldiers == 1000) {
             
            armies[_armyId].soldiersCount = armies[_armyId].soldiersCount + _countSoldiers;
        }
    }

     
    function purchaseWeapons(uint _armyId, uint _weaponId, uint _bonusAttack, uint _bonusDefense ) public payable {
         
        uint isValid = 0;
        uint256 msgValue = msg.value;

        if(msgValue == 10000000000000000 && _weaponId == 0) {
            armyDronesCount[_armyId]++;
            isValid = 1;
        } else if(msgValue == 25000000000000000 && _weaponId == 1) {
             armyPlanesCount[_armyId]++;
            isValid = 1;
        } else if(msgValue == 25000000000000000 && _weaponId == 2) {
            armyHelicoptersCount[_armyId]++;
            isValid = 1;
        } else if(msgValue == 45000000000000000 && _weaponId == 3) {
            armyTanksCount[_armyId]++;
            isValid = 1;
        } else if(msgValue == 100000000000000000 && _weaponId == 4) {
            armyAircraftCarriersCount[_armyId]++;
            isValid = 1;
        } else if(msgValue == 100000000000000000 && _weaponId == 5) {
            armySubmarinesCount[_armyId]++;
            isValid = 1;
        } else if(msgValue == 120000000000000000 && _weaponId == 6) {
            armySatelitesCount[_armyId]++;
            isValid = 1;
        } 

         
        if(isValid == 1) {
            armies[_armyId].attackBonus = armies[_armyId].attackBonus + _bonusAttack;
            armies[_armyId].defenseBonus = armies[_armyId].defenseBonus + _bonusDefense;
        }
    }

     
    function _ownershipArmy(uint armyId) private {

         
        require (ownerArmyCount[msg.sender] == 0);

         
        require(armies[armyId].isForSale == true);
        
         
        require(armies[armyId].price == msg.value);

         
        ownerArmyCount[armies[armyId].ownerAddress]--;
        
         
        armies[armyId].ownerAddress = msg.sender;
        ownerToArmy[msg.sender] = armyId;

         
        ownerArmyCount[msg.sender]++;

         
        armies[armyId].isForSale = false;
    }

     
    function startNewBattle(uint _idArmyAttacking, uint _idArmyDefensing, uint _randomIndicatorAttack, uint _randomIndicatorDefense) public returns(uint) {

         
        require (armies[_idArmyAttacking].ownerAddress == msg.sender);

         
        uint ScoreAttack = armies[_idArmyAttacking].attackBonus * (armies[_idArmyAttacking].soldiersCount/3) + armies[_idArmyAttacking].soldiersCount  + _randomIndicatorAttack; 

         
        uint ScoreDefense = armies[_idArmyAttacking].defenseBonus * (armies[_idArmyDefensing].soldiersCount/2) + armies[_idArmyDefensing].soldiersCount + _randomIndicatorDefense; 

        uint VictoriousArmy;
        uint ExperiencePointsGained;
        if(ScoreDefense >= ScoreAttack) {
            VictoriousArmy = _idArmyDefensing;
            ExperiencePointsGained = armies[_idArmyAttacking].attackBonus + 2;
            armies[_idArmyDefensing].experiencePoints = armies[_idArmyDefensing].experiencePoints + ExperiencePointsGained;

             
            armyCountBattlesWon[_idArmyDefensing]++;
            armyCountBattlesLost[_idArmyAttacking]++;
        } else {
            VictoriousArmy = _idArmyAttacking;
            ExperiencePointsGained = armies[_idArmyDefensing].defenseBonus + 2;
            armies[_idArmyAttacking].experiencePoints = armies[_idArmyAttacking].experiencePoints + ExperiencePointsGained;

             
            armyCountBattlesWon[_idArmyAttacking]++;
            armyCountBattlesLost[_idArmyDefensing]++;
        }
        
         
        battles.push(Battle(_idArmyAttacking, _idArmyDefensing, VictoriousArmy));  
        
         
        return (VictoriousArmy);
    }

     
    function ownerSellArmy(uint _armyId, uint256 _amount) public {
         
        require (armies[_armyId].ownerAddress == msg.sender);
        require (_amount > 0);
        require (armies[_armyId].isForSale == false);

        armies[_armyId].isForSale = true;
        armies[_armyId].price = _amount;
    }
    
     
    function ownerCancelArmyMarketplace(uint _armyId) public {
        require (armies[_armyId].ownerAddress == msg.sender);
        require (armies[_armyId].isForSale == true);
        armies[_armyId].isForSale = false;
    }

     
    function getArmyFullData(uint armyId) public view returns(string, string, uint, uint256, uint, uint, bool) {
        string storage ArmyName = armies[armyId].name;
        string storage ArmyId = armies[armyId].idArmy;
        uint ArmyExperiencePoints = armies[armyId].experiencePoints;
        uint256 ArmyPrice = armies[armyId].price;
        uint ArmyAttack = armies[armyId].attackBonus;
        uint ArmyDefense = armies[armyId].defenseBonus;
        bool ArmyIsForSale = armies[armyId].isForSale;
        return (ArmyName, ArmyId, ArmyExperiencePoints, ArmyPrice, ArmyAttack, ArmyDefense, ArmyIsForSale);
    }

     
    function getArmyOwner(uint armyId) public view returns(address, bool) {
        return (armies[armyId].ownerAddress, armies[armyId].isForSale);
    }

     
    function getSenderArmyDetails() public view returns(uint, string) {
        uint ArmyId = ownerToArmy[msg.sender];
        string storage ArmyName = armies[ArmyId].name;
        return (ArmyId, ArmyName);
    }
    
     
    function getSenderArmyCount() public view returns(uint) {
        uint ArmiesCount = ownerArmyCount[msg.sender];
        return (ArmiesCount);
    }

     
    function getArmySoldiersCount(uint armyId) public view returns(uint) {
        uint SoldiersCount = armies[armyId].soldiersCount;
        return (SoldiersCount);
    }

     
    function getWeaponsArmy1(uint armyId) public view returns(uint, uint, uint, uint)  {
        uint CountDrones = armyDronesCount[armyId];
        uint CountPlanes = armyPlanesCount[armyId];
        uint CountHelicopters = armyHelicoptersCount[armyId];
        uint CountTanks = armyTanksCount[armyId];
        return (CountDrones, CountPlanes, CountHelicopters, CountTanks);
    }
    function getWeaponsArmy2(uint armyId) public view returns(uint, uint, uint)  {
        uint CountAircraftCarriers = armyAircraftCarriersCount[armyId];
        uint CountSubmarines = armySubmarinesCount[armyId];
        uint CountSatelites = armySatelitesCount[armyId];
        return (CountAircraftCarriers, CountSubmarines, CountSatelites);
    }

     
    function getArmyBattles(uint _armyId) public view returns(uint, uint) {
        return (armyCountBattlesWon[_armyId], armyCountBattlesLost[_armyId]);
    }
    
     
    function getDetailsBattles(uint battleId) public view returns(uint, uint, uint, string, string) {
        return (battles[battleId].idArmyAttacking, battles[battleId].idArmyDefensing, battles[battleId].idArmyVictorious, armies[battles[battleId].idArmyAttacking].idArmy, armies[battles[battleId].idArmyDefensing].idArmy);
    }
    
     
    function getBattlesCount() public view returns(uint) {
        return (battles.length);
    }

     
    function withdraw(uint amount, uint who) public onlyCeo returns(bool) {
        require(amount <= this.balance);
        if(who == 0) {
            ceoAddress.transfer(amount);
        } else {
            cfoAddress.transfer(amount);
        }
        
        return true;
    }
    
     
    function KryptoArmy() public onlyCeo {

       
        _createArmy("United States", "USA", 550000000000000000, 8, 9);

         
        _createArmy("North Korea", "NK", 500000000000000000, 10, 5);

         
        _createArmy("Russia", "RUS", 450000000000000000, 8, 7);

         
        _createArmy("China", "CHN", 450000000000000000, 7, 8);

         
        _createArmy("Japan", "JPN", 420000000000000000, 7, 7);

         
        _createArmy("France", "FRA", 400000000000000000, 6, 8);

         
        _createArmy("Germany", "GER", 400000000000000000, 7, 6);

         
        _createArmy("India", "IND", 400000000000000000, 7, 6);

         
        _createArmy("United Kingdom", "UK", 350000000000000000, 5, 7);

         
        _createArmy("South Korea", "SK", 350000000000000000, 6, 6);

         
        _createArmy("Turkey", "TUR", 300000000000000000, 7, 4);

         
         
    }
}