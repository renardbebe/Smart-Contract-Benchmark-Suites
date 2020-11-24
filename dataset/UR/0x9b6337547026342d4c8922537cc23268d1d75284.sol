 

pragma solidity ^0.4.16;
contract Ownable {
    address public owner;


    modifier onlyOwner() {
        if (msg.sender == owner)
            _;
        else {
            revert();
        }
    }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

   
  function unpause() public  onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}
contract Mortal is Ownable {

    function kill()  public {
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }
}
contract UserTokensControl is Ownable{
    uint256 isUserAbleToTransferTime = 1579174400000; 
    modifier isUserAbleToTransferCheck(uint balance,uint _value) {
      if(msg.sender == 0x3b06AC092339D382050C892aD035b5F140B7C628){
         if(now<isUserAbleToTransferTime){
             revert();
         }
         _;
      }else {
          _;
      }
    }
   
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic, Pausable , UserTokensControl{
  using SafeMath for uint256;
 
  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public whenNotPaused isUserAbleToTransferCheck(balances[msg.sender],_value) returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  
   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused isUserAbleToTransferCheck(balances[msg.sender],_value) returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
   
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract Potentium is StandardToken, Mortal {
    string public constant name = "POTENTIAM";
    uint public constant decimals = 18;
    string public constant symbol = "PTM";
    address companyReserve;
    uint saleEndDate;
    uint public amountRaisedInWei;
    uint public priceOfToken=1041600000000000; 
    address[] allParticipants;
    uint tokenSales=0;
     mapping(address => uint256)public  balancesHold;
    event TokenHold( address indexed to, uint256 value);
    mapping (address => bool) isParticipated;
    uint public icoStartDate;
    uint public icoWeek1Bonus = 10;
    uint public icoWeek2Bonus = 7;
    uint public icoWeek3Bonus = 5;
    uint public icoWeek4Bonus = 3;
    function Potentium()  public {
      totalSupply=100000000 *(10**decimals);   
       owner = msg.sender;
       companyReserve=0x3b06AC092339D382050C892aD035b5F140B7C628;
       balances[msg.sender] = 75000000 * (10**decimals);
       balances[companyReserve] = 25000000 * (10**decimals);  
      saleEndDate =  1520554400000;   
    }

    
    function() payable whenNotPaused public {
        require(msg.sender !=0x0);
        require(now<=saleEndDate);
        require(msg.value >=40000000000000000);  
        require(tokenSales<=(60000000 * (10 ** decimals)));
        uint256 tokens = (msg.value * (10 ** decimals)) / priceOfToken;
        uint256 bonusTokens = 0;
        if(now <1513555100000){
            bonusTokens = (tokens * 40) /100;  
        }else if(now <1514760800000) {
            bonusTokens = (tokens * 35) /100;  
        }else if(now <1515369600000){
            bonusTokens = (tokens * 30) /100;  
        }else if(now <1515974400000){
            bonusTokens = (tokens * 25) /100;  
        }
        else if(now <1516578400000){
            bonusTokens = (tokens * 20) /100;  
        }else if(now <1517011400000){
              bonusTokens = (tokens * 15) /100;  
        }
        else if(now>=icoStartDate){
            if(now <= (icoStartDate + 1 * 7 days) ){
                bonusTokens = (tokens * icoWeek1Bonus) /100; 
            }
            else if(now <= (icoStartDate + 2 * 7 days) ){
                bonusTokens = (tokens * icoWeek2Bonus) /100; 
            }
           else if(now <= (icoStartDate + 3 * 7 days) ){
                bonusTokens = (tokens * icoWeek3Bonus) /100; 
            }
           else if(now <= (icoStartDate + 4 * 7 days) ){
                bonusTokens = (tokens * icoWeek4Bonus) /100; 
            }
            
        }
        tokens +=bonusTokens;
        tokenSales+=tokens;
        balancesHold[msg.sender]+=tokens;
        amountRaisedInWei = amountRaisedInWei + msg.value;
        if(!isParticipated[msg.sender]){
            allParticipants.push(msg.sender);
        }
        TokenHold(msg.sender,tokens); 
    }
    function distributeTokensAfterIcoByOwner()public onlyOwner{
        for (uint i = 0; i < allParticipants.length; i++) {
                    address userAdder=allParticipants[i];
                    var tokens = balancesHold[userAdder];
                    if(tokens>0){
                    allowed[owner][userAdder] += tokens;
                    transferFrom(owner, userAdder, tokens);
                    balancesHold[userAdder] = 0;
                     }
                 }
    }
     
   function extendSaleEndDate(uint saleEndTimeInMIllis)public onlyOwner{
       saleEndDate = saleEndTimeInMIllis;
   }
   function setIcoStartDate(uint icoStartDateInMilli)public onlyOwner{
       icoStartDate = icoStartDateInMilli;
   }
    function setICOWeek1Bonus(uint bonus)public onlyOwner{
       icoWeek1Bonus= bonus;
   }
     function setICOWeek2Bonus(uint bonus)public onlyOwner{
       icoWeek2Bonus= bonus;
   }
     function setICOWeek3Bonus(uint bonus)public onlyOwner{
       icoWeek3Bonus= bonus;
   }
     function setICOWeek4Bonus(uint bonus)public onlyOwner{
       icoWeek4Bonus= bonus;
   }
   function rateForOnePTM(uint rateInWei) public onlyOwner{
       priceOfToken = rateInWei;
   }

    
    
    function getCountPartipants() public constant returns (uint count){
       return allParticipants.length;
    }
    function getParticipantIndexAddress(uint index)public constant returns (address){
        return allParticipants[index];
    }
     
    function transferFundToAccount(address _accountByOwner) public onlyOwner {
        require(amountRaisedInWei > 0);
        _accountByOwner.transfer(amountRaisedInWei);
        amountRaisedInWei = 0;
    }

    function resetTokenOfAddress(address _userAdd)public onlyOwner {
      uint256 userBal=  balances[_userAdd] ;
      balances[_userAdd] = 0;
      balances[owner] +=userBal;
    }
     
    function transferLimitedFundToAccount(address _accountByOwner, uint256 balanceToTransfer) public onlyOwner   {
        require(amountRaisedInWei > balanceToTransfer);
        _accountByOwner.transfer(balanceToTransfer);
        amountRaisedInWei -= balanceToTransfer;
    }
}