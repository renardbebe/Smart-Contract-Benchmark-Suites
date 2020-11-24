 

pragma solidity ^0.4.17;


 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

 
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


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}


 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(0X0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}



contract HydroCoin is MintableToken, Pausable {
  string public name = "H2O Token";
  string public symbol = "H2O";
  uint256 public decimals = 18;

   


    event Ev(string message, address whom, uint256 val);

    struct XRec {
        bool inList;
        address next;
        address prev;
        uint256 val;
    }

    struct QueueRecord {
        address whom;
        uint256 val;
    }

    address public first = 0x0;
    address public last = 0x0;
    bool    public queueMode;
    uint256 public pos;

    mapping (address => XRec) public theList;

    QueueRecord[]  theQueue;

    function startQueueing() onlyOwner {
        queueMode = true;
        pos = 0;
    }

    function stopQueueing(uint256 num) onlyOwner {
        queueMode = false;
        for (uint256 i = 0; i < num; i++) {
            if (pos >= theQueue.length) {
                delete theQueue;
                return;
            }
            update(theQueue[pos].whom,theQueue[pos].val);
            pos++;
        }
        queueMode = true;
    } 

   function queueLength() constant returns (uint256) {
        return theQueue.length;
    }

    function addRecToQueue(address whom, uint256 val) internal {
        theQueue.push(QueueRecord(whom,val));
    }

     
    function add(address whom, uint256 value) internal {
        theList[whom] = XRec(true,0x0,last,value);
        if (last != 0x0) {
            theList[last].next = whom;
        } else {
            first = whom;
        }
        last = whom;
        Ev("add",whom,value);
    }

    function remove(address whom) internal {
        if (first == whom) {
            first = theList[whom].next;
            theList[whom] = XRec(false,0x0,0x0,0);
            return;
        }
        address next = theList[whom].next;
        address prev = theList[whom].prev;
        if (prev != 0x0) {
            theList[prev].next = next;
        }
        if (next != 0x0) {
            theList[next].prev = prev;
        }
        theList[whom] =XRec(false,0x0,0x0,0);
        Ev("remove",whom,0);
    }

    function update(address whom, uint256 value) internal {
        if (queueMode) {
            addRecToQueue(whom,value);
            return;
        }
        if (value != 0) {
            if (!theList[whom].inList) {
                add(whom,value);
            } else {
                theList[whom].val = value;
                Ev("update",whom,value);
            }
            return;
        }
        if (theList[whom].inList) {
                remove(whom);
        }
    }




 


   
  function transfer(address _to, uint _value) whenNotPaused returns (bool) {
      bool result = super.transfer(_to, _value);
      update(msg.sender,balances[msg.sender]);
      update(_to,balances[_to]);
      return result;
  }

   
  function transferFrom(address _from, address _to, uint _value) whenNotPaused returns (bool) {
      bool result = super.transferFrom(_from, _to, _value);
      update(_from,balances[_from]);
      update(_to,balances[_to]);
      return result;
  }

  
 
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
      bool result = super.mint(_to,_amount);
      update(_to,balances[_to]);
      return result;
  }

  function emergencyERC20Drain( ERC20 token, uint amount ) {
      token.transfer(owner, amount);
  }
 
}


contract HydroCoinCrowdsale is Ownable, Pausable {
  using SafeMath for uint256;

   
  HydroCoin public token;

   
  uint256 public startTimestamp;
  uint256 public endTimestamp;

   
  address public hardwareWallet;


  mapping (address => uint256) public deposits;
  uint256 public numberOfPurchasers;

   
  uint[] rates = [120,115,110,105];
  uint256 public rate;

   
  uint256 public weiRaised;
  uint256 public tokensSold;

  uint256 public minContribution = 1 finney;

  uint256 public hardcap = 25000000 * 10 ** 18;  
  uint256 public coinsToSell;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event MainSaleClosed();

  uint256 public weiRaisedInPresale  = 0 ether;
  uint256 public tokensSoldInPresale = 0 * 10 ** 18;

 

  mapping (address => bool) public registered;
  address public registrar;
  function setReg(address _newReg) onlyOwner {
    registrar = _newReg;
  }

  function register(address participant) {
    require(msg.sender == registrar);
    registered[participant] = true;
  }

 

  function setCoin(HydroCoin _coin) onlyOwner {
    token = _coin;
  }

  function setWallet(address _wallet) onlyOwner {
    hardwareWallet = _wallet;
  }

  function setTokensSoldInPresale(uint256 presale) onlyOwner {
    tokensSoldInPresale = presale;
    coinsToSell = hardcap.sub(tokensSoldInPresale);
  }

  function HydroCoinCrowdsale() {
    startTimestamp = 1508320800;
    endTimestamp = startTimestamp + 4 weeks;
    rate = 120;
    hardwareWallet = 0xa92F40333Ba51f169FC2791c5534E01a87dF21e3;
    token = HydroCoin(0xFeeD1a53bd53FFE453D265FC6E70dD85f8e993b6);
    tokensSoldInPresale = 1187481740794000000000000;  
    coinsToSell = hardcap.sub(tokensSoldInPresale);



    minContribution = 1 finney;

    require(startTimestamp >= now);
    require(endTimestamp >= startTimestamp);
  }

   
  modifier validPurchase {
     
    require(registered[msg.sender]);
     
    require(now >= startTimestamp);
    require(now < endTimestamp);
    require(msg.value >= minContribution);
    rate = rates[(now - startTimestamp) / (1 weeks)];
    uint256 thisGuysTokens = rate.mul(msg.value);
    require(tokensSold.add(thisGuysTokens) <= coinsToSell);
    _;
  }

   
  function hasEnded() public constant returns (bool) {
    if (now > endTimestamp) 
        return true;
    if (tokensSold >= coinsToSell - minContribution.mul(120))
      return true;
    return false;
  }

   
  function buyTokens(address beneficiary) payable validPurchase {
    require(beneficiary != 0x0);

    uint256 weiAmount = msg.value;

    if (deposits[msg.sender] == 0) {
        numberOfPurchasers++;
    }
    deposits[msg.sender] = weiAmount.add(deposits[msg.sender]);
    
    rate = rates[(now - startTimestamp) / (1 weeks)];
     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokens);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    hardwareWallet.transfer(msg.value);
  }

   
  function finishMinting() public onlyOwner {
    require(hasEnded());
    uint issuedTokenSupply = token.totalSupply();
    uint restrictedTokens = 100000000 * 10 ** 18;  
    restrictedTokens = restrictedTokens.sub(issuedTokenSupply);
    token.mint(hardwareWallet, restrictedTokens);
    token.finishMinting();
    token.transferOwnership(owner);
    MainSaleClosed();
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

    function emergencyERC20Drain( ERC20 theToken, uint amount ) {
        theToken.transfer(owner, amount);
    }


}