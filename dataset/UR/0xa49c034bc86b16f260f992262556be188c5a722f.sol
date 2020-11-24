 

pragma solidity ^0.4.23;
 

contract Ownable {
    
    address owner;
    address ownerMoney;   
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 

         
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
    event AddBank(uint bankMoney, uint countInvestor, address lastOwner, uint addTime, uint stepTime);

    event OwnBank(uint bankMoney, uint countInvestor, address lastOwner, uint addTime, uint stepTime);

    event MotherMoney(uint32 motherId, uint32 bunnyId, uint money);
     


    bool public pause = false; 
    
    uint stepTimeBank = 12*60*60; 
    uint stepTimeSale = 1;
 


    uint minPrice = 0.0001 ether;
    uint reallyPrice = 0.0001 ether;
    uint rangePrice = 20;

    uint minTimeBank = 12*60*60;
    uint coefficientTimeStep = 5;
 
    uint public commission = 5;
    uint public commission_mom = 5;
    uint public percentBank = 10;

     
 
    uint public added_to_the_bank = 0;

    uint public marketCount = 0; 
    uint public numberOfWins = 0;  
    uint public getMoneyCount = 0;

    string public advertising = "Your advertisement here!";

     uint sec = 1;
     
   
     
     
 
     
    uint public lastmoney = 0;   
    uint public totalClosedBID = 0;

     
    mapping (uint32 => uint) public bunnyCost;
    mapping (uint32 => uint) public timeCost;

    
    address public lastOwner;
    uint public bankMoney;
    uint public lastSaleTime;

    address public pubAddress;
    PublicInterface publicContract; 


     
    function getProperty() public view 
    returns(
            uint tmp_stepTimeBank,
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
                tmp_stepTimeBank = stepTimeBank;
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


    constructor() public { 
        transferContract(0x35Ea9df0B7E2E450B1D129a6F81276103b84F3dC);
    }

    function setRangePrice(uint _rangePrice) public onlyWhitelisted {
        require(_rangePrice > 0);
        rangePrice = _rangePrice;
    }


    function setStepTimeSale(uint _stepTimeSale) public onlyWhitelisted {
        require(_stepTimeSale > 0);
        stepTimeSale = _stepTimeSale;
    }

 

     
    function setMinTimeBank(uint _minTimeBank) public onlyWhitelisted {
        require(_minTimeBank > 0);
        minTimeBank = _minTimeBank;
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

    function setStepTime(uint _stepTimeBank) public onlyWhitelisted {
        require(_stepTimeBank > 0);
        stepTimeBank = _stepTimeBank;
    }
 
 
 
     
    function transferContract(address _pubAddress) public onlyWhitelisted {
        require(_pubAddress != address(0)); 
        pubAddress = _pubAddress;
        publicContract = PublicInterface(_pubAddress);
    } 
 
    function setPause() public onlyWhitelisted {
        pause = !pause;
    }

    function isPauseSave() public  view returns(bool){
        return !pause;
    }

     
    function currentPrice(uint32 _bunnyid) public view returns(uint) { 
        uint money = bunnyCost[_bunnyid];
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

     
  function startMarket(uint32 _bunnyId, uint _money) public returns (uint) {
        require(checkContract());
        require(isPauseSave());

        require(_money >= reallyPrice);

        require(publicContract.ownerOf(_bunnyId) == msg.sender);
        bunnyCost[_bunnyId] = _money;
        timeCost[_bunnyId] = block.timestamp;
        
        emit StartMarket(_bunnyId, currentPrice(_bunnyId), block.timestamp, stepTimeSale);
        return marketCount++;
    }

     
    function stopMarket(uint32 _bunnyId) public returns(uint) {
        require(checkContract());
        require(isPauseSave());
        require(publicContract.ownerOf(_bunnyId) == msg.sender);
        bunnyCost[_bunnyId] = 0;
        emit StopMarket(_bunnyId);
        return marketCount--;
    }
 
 
    function changeReallyPrice() internal {
        if (added_to_the_bank > 0 && rangePrice > 0 && added_to_the_bank > rangePrice) {
            uint tmp = added_to_the_bank.div(rangePrice);
            tmp = reallyPrice.div(tmp); 
            reallyPrice = reallyPrice.add(tmp);
        } 
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
        lastOwner = msg.sender; 
        lastSaleTime = block.timestamp; 

        emit OwnBank(bankMoney, added_to_the_bank, lastOwner, lastSaleTime, stepTimeBank);
        emit BunnyBuy(_bunnyId, lastmoney);
    }  
     
    function sendMoneyMother(uint32 _bunnyId) internal {
        if (bunnyCost[_bunnyId] > 0) { 
            uint procentOne = (bunnyCost[_bunnyId].div(100)); 
             
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
        if (lastSaleTime + stepTimeBank < block.timestamp) {
            win(); 
        }
        lastSaleTime = block.timestamp;
    }
    function win() internal {
         
         
        if (address(this).balance > 0 && address(this).balance >= bankMoney && lastOwner != address(0)) { 
            advertising = "";
            added_to_the_bank = 0;
            reallyPrice = minPrice;
            lastOwner.transfer(bankMoney);
            numberOfWins = numberOfWins.add(1); 
            emit Tournament (lastOwner, bankMoney, lastSaleTime, block.timestamp);
            bankMoney = 0;
        }
    }    
    
         
    function addBank(uint _money) internal { 
        bankMoney = bankMoney.add(_money);
        added_to_the_bank = added_to_the_bank.add(1);

        emit AddBank(bankMoney, added_to_the_bank, lastOwner, block.timestamp, stepTimeBank);

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
 
     
    function getMoney(uint _value) public onlyOwner {
        require(address(this).balance >= _value); 
        ownerMoney.transfer(_value);
         
        getMoneyCount = getMoneyCount.add(_value);
    }
}