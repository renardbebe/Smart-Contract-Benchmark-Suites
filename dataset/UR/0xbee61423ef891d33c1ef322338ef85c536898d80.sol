 

pragma solidity ^0.4.23;
 

 

contract Ownable {
    
    address owner;
    address ownerMoney;   
     
 

         
    constructor() public {
        owner = msg.sender;
        ownerMoney = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

 

    function transferMoney(address _add) public  onlyOwner {
        if (_add != address(0)) {
            ownerMoney = _add;
        }
    }
    
 
    function transferOwner(address _add) public onlyOwner {
        if (_add != address(0)) {
            owner = _add;
        }
    } 
      
    function getOwnerMoney() public view onlyOwner returns(address) {
        return ownerMoney;
    } 
 
}

 


 
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);
 
   
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    constructor() public {
        addAddressToWhitelist(msg.sender);   
    }

   
    function addAddressToWhitelist(address addr) public onlyOwner returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    function getInWhitelist(address addr) public view returns(bool) {
        return whitelist[addr];
    }

     
    function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

     
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

     
    function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }
}
 
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
  
}


contract StorageInterface { 
    function setBunnyCost(uint32 _bunnyID, uint _money) external;
    function getBunnyCost(uint32 _bunnyID) public view returns (uint money);
    function deleteBunnyCost(uint32 _bunnyID) external; 
    function isPauseSave() public  view returns(bool);
}




 
 
contract PublicInterface { 
    function transferFrom(address _from, address _to, uint32 _tokenId) public returns (bool);
    function ownerOf(uint32 _tokenId) public view returns (address owner);
    function isUIntPublic() public view returns(bool); 
    function getRabbitMother( uint32 mother) public view returns(uint32[5]);
    function getRabbitMotherSumm(uint32 mother) public view returns(uint count);
}

contract Market  is Whitelist { 
           
    using SafeMath for uint256;
    
    event StopMarket(uint32 bunnyId);
    event StartMarket(uint32 bunnyId, uint money, uint timeStart, uint stepTimeSale);
    event BunnyBuy(uint32 bunnyId, uint money);  
    event Tournament(address who, uint bank, uint timeLeft, uint timeRange);
    
    event OwnBank(uint bankMoney, uint countInvestor, address lastOwner, uint addTime, uint stepTime);
    event MotherMoney(uint32 motherId, uint32 bunnyId, uint money);
     


    bool public pause = false; 
    
    
    uint public stepTimeSale = 1;
 

    uint public minPrice = 0.0001 ether;
    uint reallyPrice = 0.0001 ether;
    uint public rangePrice = 20;


    uint public minTimeBank = 12*60*60;
    uint public maxTimeBank = 13*60*60;
    uint public currentTimeBank = maxTimeBank;
    uint public rangeTimeBank = 2;


    uint public coefficientTimeStep = 5;
    uint public commission = 5;
    uint public commission_mom = 5;
    uint public percentBank = 10;

     
 
    uint public added_to_the_bank = 0;

    uint public marketCount = 0; 
    uint public numberOfWins = 0;  
    uint public getMoneyCount = 0;

    string public advertising = "Your advertisement here!";
 
     
   
     
     
 
     
    uint public lastmoney = 0;   
    uint public totalClosedBID = 0;

     
    
    mapping (uint32 => uint) public timeCost;

    
    address public lastOwner;
    uint public bankMoney;
    uint public lastSaleTime;

    address public pubAddress;
    address public storageAddress;
    PublicInterface publicContract; 
    StorageInterface storageContract; 

 
 

    constructor() public { 
        transferContract(0x35Ea9df0B7E2E450B1D129a6F81276103b84F3dC); 
        transferStorage(0x8AC4Da82C4a1E0C1578558C5C685F8AE790dA5a3);
    }

    function setRangePrice(uint _rangePrice) public onlyWhitelisted {
        require(_rangePrice > 0);
        rangePrice = _rangePrice;
    }

    function setReallyPrice(uint _reallyPrice) public onlyWhitelisted {
        require(_reallyPrice > 0);
        reallyPrice = _reallyPrice;
    }

 


    function setStepTimeSale(uint _stepTimeSale) public onlyWhitelisted {
        require(_stepTimeSale > 0);
        stepTimeSale = _stepTimeSale;
    }

    function setRangeTimeBank(uint _rangeTimeBank) public onlyWhitelisted {
        require(_rangeTimeBank > 0);
        rangeTimeBank = _rangeTimeBank;
    }

     
    function setMinTimeBank(uint _minTimeBank) public onlyWhitelisted {
        require(_minTimeBank > 0);
        minTimeBank = _minTimeBank;
    }

     
    function setMaxTimeBank(uint _maxTimeBank) public onlyWhitelisted {
        require(_maxTimeBank > 0);
        maxTimeBank = _maxTimeBank;
    }

     
    function setCoefficientTimeStep(uint _coefficientTimeStep) public onlyWhitelisted {
        require(_coefficientTimeStep > 0);
        coefficientTimeStep = _coefficientTimeStep;
    }

 

    function setPercentCommission(uint _commission) public onlyWhitelisted {
        require(_commission > 0);
        commission = _commission;
    }

    function setPercentBank(uint _percentBank) public onlyWhitelisted {
        require(_percentBank > 0);
        percentBank = _percentBank; 
    }
     
    function setMinPrice(uint _minPrice) public onlyWhitelisted {
        require(_minPrice > 0);
        minPrice = _minPrice;
        
    }

    function setCurrentTimeBank(uint _currentTimeBank) public onlyWhitelisted {
        require(_currentTimeBank > 0);
        currentTimeBank = _currentTimeBank;
    }
 
 
     
  function startMarketOwner(uint32 _bunnyId, uint _money) public  onlyWhitelisted {
        require(checkContract());
        require(isPauseSave());
        require(currentPrice(_bunnyId) != _money);
        require(storageContract.isPauseSave());
          
       
        timeCost[_bunnyId] = block.timestamp;
        storageContract.setBunnyCost(_bunnyId, _money);
        emit StartMarket(_bunnyId, currentPrice(_bunnyId), block.timestamp, stepTimeSale);
        marketCount++;
    }
 
     
    function transferContract(address _pubAddress) public onlyWhitelisted {
        require(_pubAddress != address(0)); 
        pubAddress = _pubAddress;
        publicContract = PublicInterface(_pubAddress);
    } 

     
    function transferStorage(address _storageAddress) public onlyWhitelisted {
        require(_storageAddress != address(0)); 
        storageAddress = _storageAddress;
        storageContract = StorageInterface(_storageAddress);
    } 
 
    function setPause() public onlyWhitelisted {
        pause = !pause;
    }

    function isPauseSave() public  view returns(bool){
        return !pause;
    }

     
    function currentPrice(uint32 _bunnyid) public view returns(uint) { 
        require(storageContract.isPauseSave());
        uint money = storageContract.getBunnyCost(_bunnyid);
        if (money > 0) {
             
            uint percOne = money.div(100);
             
            
            uint commissionMoney = percOne.mul(commission);
            money = money.add(commissionMoney); 

            uint commissionMom = percOne.mul(commission_mom);
            money = money.add(commissionMom); 

            uint percBank = percOne.mul(percentBank);
            money = money.add(percBank); 

            return money;
        }
    } 

    function getReallyPrice() public view returns (uint) {
        return reallyPrice;
    }

     
  function startMarket(uint32 _bunnyId, uint _money) public{
        require(checkContract());
        require(isPauseSave());
        require(currentPrice(_bunnyId) != _money);
        require(storageContract.isPauseSave());
        require(_money >= reallyPrice);

        require(publicContract.ownerOf(_bunnyId) == msg.sender);

        timeCost[_bunnyId] = block.timestamp;

        storageContract.setBunnyCost(_bunnyId, _money);
        
        emit StartMarket(_bunnyId, currentPrice(_bunnyId), block.timestamp, stepTimeSale);
        marketCount++;
    }

     
    function stopMarket(uint32 _bunnyId) public returns(uint) {
        require(checkContract());
        require(isPauseSave());
        require(publicContract.ownerOf(_bunnyId) == msg.sender);
        require(storageContract.isPauseSave());

        storageContract.deleteBunnyCost(_bunnyId);
        emit StopMarket(_bunnyId);
        return marketCount--;
    }

    function timeBunny(uint32 _bunnyId) public view returns(bool can, uint timeleft) {
        uint _tmp = timeCost[_bunnyId].add(stepTimeSale);
        if (timeCost[_bunnyId] > 0 && block.timestamp >= _tmp) {
            can = true;
            timeleft = 0;
        } else { 
            can = false; 
            _tmp = _tmp.sub(block.timestamp);
            if (_tmp > 0) {
                timeleft = _tmp;
            } else {
                timeleft = 0;
            }
        } 
    }

    function transferFromBunny(uint32 _bunnyId) public {
        require(checkContract());
        publicContract.transferFrom(publicContract.ownerOf(_bunnyId), msg.sender, _bunnyId); 
    }


 
     
    function buyBunny(uint32 _bunnyId) public payable {
        require(isPauseSave());
        require(checkContract());
        require(publicContract.ownerOf(_bunnyId) != msg.sender);
        require(storageContract.isPauseSave());
        lastmoney = currentPrice(_bunnyId);
        require(msg.value >= lastmoney && 0 != lastmoney);

        bool can;
        (can,) = timeBunny(_bunnyId);
        require(can); 
         
        totalClosedBID++;
         
         
 
        checkTimeWin();
        sendMoney(publicContract.ownerOf(_bunnyId), lastmoney);

        publicContract.transferFrom(publicContract.ownerOf(_bunnyId), msg.sender, _bunnyId); 
        sendMoneyMother(_bunnyId);
        stopMarket(_bunnyId);
        changeReallyPrice();
        changeReallyTime();
        lastOwner = msg.sender; 
        lastSaleTime = block.timestamp; 
        emit OwnBank(bankMoney, added_to_the_bank, lastOwner, lastSaleTime, currentTimeBank);
        emit BunnyBuy(_bunnyId, lastmoney);
    }  

    
    function changeReallyTime() internal {
        if (rangeTimeBank > 0) {
            uint tmp = added_to_the_bank.div(rangeTimeBank);
            tmp = maxTimeBank.sub(tmp);

            if (currentTimeBank > minTimeBank) { 
                currentTimeBank = tmp;
            }
        } 
    }
 
    function changeReallyPrice() internal {
        if (added_to_the_bank > 0 && rangePrice > 0) {
            uint tmp = added_to_the_bank.div(rangePrice);
            reallyPrice = minPrice.mul(tmp);  
        } 
    }
  

     
    function sendMoneyMother(uint32 _bunnyId) internal {
        uint money = storageContract.getBunnyCost(_bunnyId);
        if (money > 0) { 
            uint procentOne = (money.div(100)); 
             
            uint32[5] memory mother;
            mother = publicContract.getRabbitMother(_bunnyId);
            uint motherCount = publicContract.getRabbitMotherSumm(_bunnyId);
            if (motherCount > 0) {
                uint motherMoney = (procentOne*commission_mom).div(motherCount);
                    for (uint m = 0; m < 5; m++) {
                        if (mother[m] != 0) {
                            publicContract.ownerOf(mother[m]).transfer(motherMoney);
                            emit MotherMoney(mother[m], _bunnyId, motherMoney);
                        }
                    }
                } 
        }
    }


     
    function sendMoney(address _to, uint256 _money) internal { 
        if (_money > 0) { 
            uint procentOne = (_money/100); 
            _to.transfer(procentOne * (100-(commission+percentBank+commission_mom)));
            addBank(procentOne*percentBank);
            ownerMoney.transfer(procentOne*commission);  
        }
    }



    function checkTimeWin() internal {
        if (lastSaleTime + currentTimeBank < block.timestamp) {
            win(); 
        }
        lastSaleTime = block.timestamp;
    }

    
    function win() internal {
         
         
        if (address(this).balance > 0 && address(this).balance >= bankMoney && lastOwner != address(0)) { 
            advertising = "";
            added_to_the_bank = 0;
            reallyPrice = minPrice;
            currentTimeBank = maxTimeBank;

            lastOwner.transfer(bankMoney);
            numberOfWins = numberOfWins.add(1); 
            emit Tournament (lastOwner, bankMoney, lastSaleTime, block.timestamp);
            bankMoney = 0;
        }
    }    
    
    
     
    function addCountInvestors(uint countInvestors) public onlyWhitelisted  { 
        added_to_the_bank = countInvestors;
    }

         
    function addBank(uint _money) internal { 
        bankMoney = bankMoney.add(_money);
        added_to_the_bank = added_to_the_bank.add(1);
    }
     
 
    function ownerOf(uint32 _bunnyId) public  view returns(address) {
        return publicContract.ownerOf(_bunnyId);
    } 
    
     
    function checkContract() public view returns(bool) {
        return publicContract.isUIntPublic(); 
    }

    function buyAdvert(string _text)  public payable { 
        require(msg.value > (reallyPrice*2));
        require(checkContract());
        advertising = _text;
        addBank(msg.value); 
    }
 
     
    function noAdvert() public onlyWhitelisted {
        advertising = "";
    } 
 
     
    function getMoney(uint _value) public onlyWhitelisted {
        require(address(this).balance >= _value); 
        ownerMoney.transfer(_value);
         
        getMoneyCount = getMoneyCount.add(_value);
    }
     
    function getProperty() public view 
    returns(
            uint tmp_currentTimeBank,
            uint tmp_stepTimeSale,
            uint tmp_minPrice,
            uint tmp_reallyPrice,
            
            uint tmp_added_to_the_bank,
            uint tmp_marketCount, 
            uint tmp_numberOfWins,
            uint tmp_getMoneyCount,
            uint tmp_lastmoney,   
            uint tmp_totalClosedBID,
            uint tmp_bankMoney,
            uint tmp_lastSaleTime
            )
            {
                tmp_currentTimeBank = currentTimeBank;
                tmp_stepTimeSale = stepTimeSale;
                tmp_minPrice = minPrice;
                tmp_reallyPrice = reallyPrice;
                tmp_added_to_the_bank = added_to_the_bank;
                tmp_marketCount = marketCount; 
                tmp_numberOfWins = numberOfWins;
                tmp_getMoneyCount = getMoneyCount;

                tmp_lastmoney = lastmoney;   
                tmp_totalClosedBID = totalClosedBID;
                tmp_bankMoney = bankMoney;
                tmp_lastSaleTime = lastSaleTime;
    }

}