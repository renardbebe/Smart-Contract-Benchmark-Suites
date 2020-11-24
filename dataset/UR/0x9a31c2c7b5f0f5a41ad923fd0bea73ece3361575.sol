 

pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

 mapping (address => uint) public pendingWithdrawals;
   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }



function withdraw() {
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

}
 

contract AirDrop is Ownable {

  Token token;

  event TransferredToken(address indexed to, uint256 value);
  event FailedTransfer(address indexed to, uint256 value);

  modifier whenDropIsActive() {
    assert(isActive());

    _;
  }
address public creator;
  function AirDrop () {
      address _tokenAddr = creator;  
      token = Token(_tokenAddr);
  }

  function isActive() constant returns (bool) {
    return (
        tokensAvailable() > 0  
    );
  }
   
  function sendTokens(address[] dests, uint256[] values) whenDropIsActive onlyOwner external {
    uint256 i = 0;
    while (i < dests.length) {
        uint256 toSend = values[i] ;
        sendInternally(dests[i] , toSend, values[i]);
        i++;
    }
  }

   
  function sendTokensSingleValue(address[] dests, uint256 value) whenDropIsActive onlyOwner external {
    uint256 i = 0;
    uint256 toSend = value;
    while (i < dests.length) {
        sendInternally(dests[i] , toSend, value);
        i++;
    }
  }  

  function sendInternally(address recipient, uint256 tokensToSend, uint256 valueToPresent) internal {
    if(recipient == address(0)) return;

    if(tokensAvailable() >= tokensToSend) {
      token.transfer(recipient, tokensToSend);
      TransferredToken(recipient, valueToPresent);
    } else {
      FailedTransfer(recipient, valueToPresent); 
    }
  }   


  function tokensAvailable() constant returns (uint256) {
    return token.balanceOf(this);
  }

  function destroy() onlyOwner {
    uint256 balance = tokensAvailable();
    require (balance > 0);
    token.transfer(owner, balance);
    selfdestruct(owner);
  }
}
contract Claimable is Ownable {
    address public pendingOwner;

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() onlyPendingOwner public {
        OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }


}


contract EtherToFARM is Ownable {
 using SafeMath for uint;
 using SafeMath for uint256;


uint256 public totalSupply; 
uint remaining;
uint price;

mapping (address => uint) investors;  

 function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
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

function transfer(address _to, uint256 _value) returns (bool success) {}

function ()  payable { 

    uint256 remaining;
    uint256 totalSupply;
    uint price;
    assert(remaining < totalSupply);
    uint FarmCoin = div(msg.value,price);  
    assert(FarmCoin < sub(totalSupply,remaining));  
    add(investors[msg.sender],FarmCoin);
    remaining = add(remaining, FarmCoin);
    transfer(msg.sender, FarmCoin);
}

function setPrice(uint _price)
{  
    uint price;
    price = _price;
}

function giveReward(address _payer,uint _payment) public payable returns (bool _success){
        uint tokenamount = _payment / price;
        return transfer(_payer,tokenamount);
    }    
}

contract PayToken is EtherToFARM {
 function() public payable{
         if(msg.sender!=owner)
       giveReward(msg.sender,msg.value);
}
}

contract Token is EtherToFARM {

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}



contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
         
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}



 
contract FarmCoin is StandardToken {

   
     

     
    string public name = 'FarmCoin';                    
    uint8 public decimals = 18;                 
    string public symbol = 'FARM';                  
    string public version = 'H1.0';        

 
 
 

 

    function FarmCoin(
        ) {
        balances[msg.sender] = 5000000000000000000000000;                
        totalSupply = 5000000000000000000000000;                         
        name = "FarmCoin";                                    
        decimals = 18;                             
        symbol = "FARM";                                
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

         
         
         
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert; }
        return true;
    }
}


contract FarmCoinSale is FarmCoin {

    uint256 public maxMintable;
    uint256 public totalMinted;
    uint256 public decimals = 18;
    uint public endBlock;
    uint public startBlock;
    uint256 public exchangeRate;
    uint public startTime;
    bool public isFunding;
    address public ETHWallet;
    uint256 public heldTotal;

    bool private configSet;
    address public creator;

    mapping (address => uint256) public heldTokens;
    mapping (address => uint) public heldTimeline;

    event Contribution(address from, uint256 amount);
    event ReleaseTokens(address from, uint256 amount);

 
  uint256 constant public START = 1517461200000;  
  uint256 constant public END = 1522555200000;  

 
     
  function getRate() constant returns (uint256 rate) {
    if      (now < START)            return rate = 840;  
    else if (now <= START +  6 days) return rate = 810;  
    else if (now <= START + 13 days) return rate = 780;  
    else if (now <= START + 20 days) return rate = 750;  
    else if (now <= START + 28 days) return rate = 720;  
    return rate = 600;  
  }


    function FarmCoinSale() {
        startBlock = block.number;
        maxMintable = 5000000000000000000000000;  
        ETHWallet = 0x3b444fC8c2C45DCa5e6610E49dC54423c5Dcd86E;
        isFunding = true;
        
        creator = msg.sender;
        createHeldCoins();
        startTime = 1517461200000;
        exchangeRate= 600;
        }

 
     
     
     
    function setup(address TOKEN, uint endBlockTime) {
        require(!configSet);
        endBlock = endBlockTime;
        configSet = true;
    }

    function closeSale() external {
      require(msg.sender==creator);
      isFunding = false;
    }

     
     
    function contribute() external payable {
        require(msg.value>0);
        require(isFunding);
        require(block.number <= endBlock);
        uint256 amount = msg.value * exchangeRate;
        uint256 total = totalMinted + amount;
        require(total<=maxMintable);
        totalMinted += total;
        ETHWallet.transfer(msg.value);
        Contribution(msg.sender, amount);
    }

    function deposit() payable {
      create(msg.sender);
    }
    function register(address sender) payable {
    }
    function () payable {
    }
  
    function create(address _beneficiary) payable{
    uint256 amount = msg.value;
     
    }

    function withdraw() {
    require ( msg.sender == owner );
    msg.sender.transfer(this.balance);
}
     
    function updateRate(uint256 rate) external {
        require(msg.sender==creator);
        require(isFunding);
        exchangeRate = rate;
    }

     
    function changeCreator(address _creator) external {
        require(msg.sender==creator);
        creator = _creator;
    }

     
    function changeTransferStats(bool _allowed) external {
        require(msg.sender==creator);
     }

     
     
    function createHeldCoins() internal {
         
        createHoldToken(msg.sender, 1000);
        createHoldToken(0xd9710D829fa7c36E025011b801664009E4e7c69D, 100000000000000000000000);
        createHoldToken(0xd9710D829fa7c36E025011b801664009E4e7c69D, 100000000000000000000000);
    }

     
    function createHoldToken(address _to, uint256 amount) internal {
        heldTokens[_to] = amount;
        heldTimeline[_to] = block.number + 0;
        heldTotal += amount;
        totalMinted += heldTotal;
    }

     
    function releaseHeldCoins() external {
        uint256 held = heldTokens[msg.sender];
        uint heldBlock = heldTimeline[msg.sender];
        require(!isFunding);
        require(held >= 0);
        require(block.number >= heldBlock);
        heldTokens[msg.sender] = 0;
        heldTimeline[msg.sender] = 0;
        ReleaseTokens(msg.sender, held);
    }

}