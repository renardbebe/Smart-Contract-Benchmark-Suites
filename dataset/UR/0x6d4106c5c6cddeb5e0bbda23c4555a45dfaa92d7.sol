 

pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external returns (bool);
    function balanceOf(address tokenOwner) external returns (uint);
}

contract CucuSale {
    address public beneficiary;
    uint public amountRaised;
    uint public price;
    uint public dynamicLocktime;  
    uint public globalLocktime;
     
    uint public lockType = 0;
    token public tokenReward;
    uint public exchangeRate;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public tokenBalanceOf;
    mapping(address => uint256) public timelocksOf;

    address[] public founders;
    address public owner;

    event FundTransfer(address backer, uint amount, uint exchangeRate, uint token, uint time, uint timelock, bool isContribution);
    event IsCharged(bool isCharged);
    event TokensClaimed(address founder, uint tokens);
    event TransferOwnership();
    event ChangeExchangeRate(uint oldExchangeRate, uint newExchangeRate);
    event NewGlobalLocktime(uint timelockUntil);
    event NewDynamicLocktime(uint timelockUntil);
    uint public tokenAvailable = 0;
    bool public charged = false;
    uint lastActionId = 0;


     
    constructor(
        address _beneficiary,
        address _addressOfTokenUsedAsReward,
        uint _globalLocktime,
        uint _dynamicLocktime,
        uint _exchangeRate
    ) public {
        beneficiary = _beneficiary;
        dynamicLocktime = _dynamicLocktime; 
        tokenReward = token(_addressOfTokenUsedAsReward);
        globalLocktime = now + _globalLocktime * 1 minutes;
        exchangeRate = _exchangeRate;
        owner = msg.sender;
    }

     
    function () payable public {
          require(charged);
          require(msg.value >= 10000000000);  
          uint am = (msg.value* exchangeRate * 100000000)/(1 ether);  
          require( tokenAvailable >= am);
          uint amount = msg.value;
          balanceOf[msg.sender] += amount;
          amountRaised += amount;
          tokenBalanceOf[msg.sender] += am;
          tokenAvailable -= am;

          if(timelocksOf[msg.sender] == 0){
            timelocksOf[msg.sender] = now + dynamicLocktime * 1 minutes;
          }

          emit FundTransfer(msg.sender, amount, exchangeRate, am, now, timelocksOf[msg.sender], true);
          founders.push(msg.sender);
    }

     
    modifier onlyOwner(){
      require(msg.sender == owner || msg.sender == beneficiary);
      _;
    }

     
    function doChargeCrowdsale(uint act) public onlyOwner{
      lastActionId = act;
      tokenAvailable = tokenReward.balanceOf(address(this));
      if(tokenAvailable > 0){
        charged = true;
        emit IsCharged(charged);
      }
    }

     
    function claimTokens(address adr) public{
      require(tokenBalanceOf[adr] > 0);

      if(lockType == 0){  
        require(now >= timelocksOf[adr]);
      }else if(lockType == 1){  
        require(now >= globalLocktime);
      }  

      if(tokenReward.transfer(adr, tokenBalanceOf[adr])){
        emit TokensClaimed(adr, tokenBalanceOf[adr]);
        tokenBalanceOf[adr] = 0;
        balanceOf[adr] = 0;
      }
    }

     
    function transferRaisedFunds(uint act) public onlyOwner {
        lastActionId = act;
        if (beneficiary.send(amountRaised)) {
           emit FundTransfer(beneficiary, amountRaised, exchangeRate, 0, now, 0, false);
        }
    }

     
    function transferOwnership(address newOwner) public onlyOwner{
      owner = newOwner;
      emit TransferOwnership();
    }

     
    function setExchangeRate(uint newExchangeRate) public onlyOwner{
      emit ChangeExchangeRate(exchangeRate, newExchangeRate);
      exchangeRate = newExchangeRate;
    }

     
    function setGlobalLocktime(uint mins) public onlyOwner{
      globalLocktime = now + mins * 1 minutes;
      emit NewGlobalLocktime(globalLocktime);
    }

     
    function setDynamicLocktime(uint mins) public onlyOwner{
      dynamicLocktime = now + mins * 1 minutes;
      emit NewDynamicLocktime(dynamicLocktime);
    }

     
    function setLockType(uint newType) public onlyOwner{
        require(newType == 0 || newType == 1 || newType == 2);
        lockType = newType;
    }

     
    function unlockTokensFor(address adr) public onlyOwner{
      timelocksOf[adr] = 1;
    }

     
    function resetLockFor(address adr) public onlyOwner{
      timelocksOf[adr] = 0;
    }

     
    function getLeftOver(uint act) public onlyOwner{
      lastActionId = act;
      if(tokenReward.transfer(beneficiary, tokenAvailable)){
        emit TokensClaimed(beneficiary, tokenAvailable);
        tokenAvailable = 0;
      }
    }
}