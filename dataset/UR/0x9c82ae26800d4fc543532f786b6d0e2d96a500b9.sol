 

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


contract Hgt is StandardToken, Pausable {

    string public name = "HelloGold Token";
    string public symbol = "HGT";
    uint256 public decimals = 18;

}

contract Hgs {
    struct CsAction {
      bool        passedKYC;
      bool        blocked;
    }


     
    mapping (address => CsAction) public permissions;
    mapping (address => uint256)  public deposits;
}

contract HelloGoldRound1Point5 is Ownable {

    using SafeMath for uint256;
    bool    public  started;
    uint256 public  startTime = 1505995200;  
    uint256 public  endTime = 1507204800;   
    uint256 public  weiRaised;
    uint256 public  lastSaleInHGT = 170000000 * 10 ** 8 ;
    uint256 public  hgtSold;
    uint256 public  r15Backers;

    uint256 public  rate = 12489 * 10 ** 8;
    Hgs     public  hgs = Hgs(0x574FB6d9d090042A04D0D12a4E87217f8303A5ca);
    Hgt     public  hgt = Hgt(0xba2184520A1cC49a6159c57e61E1844E085615B6);
    address public  multisig = 0xC03281aF336e2C25B41FF893A0e6cE1a932B23AF;  
    address public  reserves = 0xC03281aF336e2C25B41FF893A0e6cE1a932B23AF;  

 
 
 
 
 
 

     

     
     
     
     
     
     
     
     


 
 
 
 
 
 




    mapping (address => uint256) public deposits;
    mapping (address => bool) public upgraded;
    mapping (address => uint256) public upgradeHGT;

    modifier validPurchase() {
        bool passedKYC;
        bool blocked;
        require (msg.value >= 1 finney);
        require (started || (now > startTime));
        require (now <= endTime);
        require (hgtSold < lastSaleInHGT);
        (passedKYC,blocked) = hgs.permissions(msg.sender); 
        require (passedKYC);
        require (!blocked);


        _;
    }

 
    function HelloGoldRound1Point5() {
         
        deposits[0xA3f59EbC3bf8Fa664Ce12e2f841Fe6556289F053] = 30 ether;  
        upgraded[0xA3f59EbC3bf8Fa664Ce12e2f841Fe6556289F053] = true;
        upgraded[0x00f07DA332aa7751F9170430F6e4b354568c5B40] = true;
        upgraded[0x938CdFb9B756A5b6c8f3fBA535EC17700edD4c15] = true;
        upgraded[0xa6a777ed720746FBE7b6b908584CD3D533d307D3] = true;

         
    }

    function reCap(uint256 newCap) onlyOwner {
        lastSaleInHGT = newCap;
    }

    function startAndSetStopTime(uint256 period) onlyOwner {
        started = true;
        if (period == 0)
            endTime = now + 2 weeks;
        else
            endTime = now + period;
    }

     
     
     
     
     
    function upgradeOnePointZeroBalances() internal {
     
        if (upgraded[msg.sender]) {
            log0("account already upgraded");
            return;
        }
     
        uint256 deposited = hgs.deposits(msg.sender);
        if (deposited == 0)
            return;
     
        deposited = deposited.add(deposits[msg.sender]);
        if (deposited.add(msg.value) < 10 ether)
            return;
     
        uint256 hgtBalance = hgt.balanceOf(msg.sender);
        uint256 upgradedAmount = deposited.mul(rate).div(1 ether);
        if (hgtBalance < upgradedAmount) {
            uint256 diff = upgradedAmount.sub(hgtBalance);
            hgt.transferFrom(reserves,msg.sender,diff);
            hgtSold = hgtSold.add(diff);
            upgradeHGT[msg.sender] = upgradeHGT[msg.sender].add(diff);
            log0("upgraded R1 to 20%");
        }
        upgraded[msg.sender] = true;
    }

    function () payable validPurchase {
        if (deposits[msg.sender] == 0)
            r15Backers++;
        upgradeOnePointZeroBalances();
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        
        buyTokens(msg.sender,msg.value);
    }

    function buyTokens(address recipient, uint256 valueInWei) internal {
        uint256 numberOfTokens = valueInWei.mul(rate).div(1 ether);
        weiRaised = weiRaised.add(valueInWei);
        require(hgt.transferFrom(reserves,recipient,numberOfTokens));
        hgtSold = hgtSold.add(numberOfTokens);
        multisig.transfer(msg.value);
    }

    function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner {
        token.transfer(owner, amount);
    }

}