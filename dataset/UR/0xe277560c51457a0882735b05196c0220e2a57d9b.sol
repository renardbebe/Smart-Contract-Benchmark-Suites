 

pragma solidity ^0.4.15;

 
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


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract NonZero {

 
    modifier nonZeroAddress(address _to) {
        require(_to != 0x0);
        _;
    }

    modifier nonZeroAmount(uint _amount) {
        require(_amount > 0);
        _;
    }

    modifier nonZeroValue() {
        require(msg.value > 0);
        _;
    }

}


contract TripCoin is ERC20, Ownable, NonZero {

    using SafeMath for uint;

 
    string public constant name = "TripCoin";
    string public constant symbol = "TRIP";

    uint8 public decimals = 3;
    
     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowed;

 
    
     
    uint256 public TripCoinTeamSupply;
     
    uint256 public ReserveSupply;
     
    uint256 public presaleSupply;

    uint256 public icoSupply;
     
    uint256 public incentivisingEffortsSupply;
     
    uint256 public presaleStartsAt;
    uint256 public presaleEndsAt;
    uint256 public icoStartsAt;
    uint256 public icoEndsAt;
   
     
    address public TripCoinTeamAddress;
     
    address public ReserveAddress;
     
    address public incentivisingEffortsAddress;

     
    bool public presaleFinalized = false;
     
    bool public icoFinalized = false;
     
    uint256 public weiRaised = 0;

 

     
    event icoFinalized(uint tokensRemaining);
     
    event PresaleFinalized(uint tokensRemaining);
     
    event AmountRaised(address beneficiary, uint amountRaised);
     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

 

 

     
    modifier onlypresale() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyico() {
        require(msg.sender == owner);
        _;
    }

 

     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        require(balanceOf(msg.sender) >= _amount);
        addToBalance(_to, _amount);
        decrementBalance(msg.sender, _amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        require(allowance(_from, msg.sender) >= _amount);
        decrementBalance(_from, _amount);
        addToBalance(_to, _amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool success) {
        require((_value == 0) || (allowance(msg.sender, _spender) == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

 

     
    function TripCoin() {
        presaleStartsAt = 1509271200;                                           
        presaleEndsAt = 1509875999;                                           
        icoStartsAt = 1509876000;                                              
        icoEndsAt = 1511863200;                                                
           

        totalSupply = 200000000000;                                                    
        TripCoinTeamSupply = 20000000000;                                               
        ReserveSupply = 60000000000;                                                 
        incentivisingEffortsSupply = 20000000000;                                     
        presaleSupply = 60000000000;                                                 
        icoSupply = 40000000000;                                                     
       
       
        TripCoinTeamAddress = 0xD7741E3819434a91F25b8C8e30Ba124D1EDe6B03;              
        ReserveAddress = 0x51Ff33A5C5350E62F9a974108e4B93EDC5C26359;                
        incentivisingEffortsAddress = 0x4B8849c93b90Fe2446D8fc27FEc25Dc3386b1e75;    

        addToBalance(incentivisingEffortsAddress, incentivisingEffortsSupply);     
        addToBalance(ReserveAddress, ReserveSupply); 
        addToBalance(owner, presaleSupply.add(icoSupply)); 
        
        addToBalance(TripCoinTeamAddress, TripCoinTeamSupply); 
    }

  

     
    function transferFromPresale(address _to, uint256 _amount) onlyOwner nonZeroAmount(_amount) nonZeroAddress(_to) returns (bool success) {
        require(balanceOf(owner) >= _amount);
        decrementBalance(owner, _amount);
        addToBalance(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }
       
    function transferFromIco(address _to, uint256 _amount) onlyOwner nonZeroAmount(_amount) nonZeroAddress(_to) returns (bool success) {
        require(balanceOf(owner) >= _amount);
        decrementBalance(owner, _amount);
        addToBalance(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }
    function getRate() public constant returns (uint price) {
        if (now > presaleStartsAt && now < presaleEndsAt ) {
           return 1500; 
        } else if (now > icoStartsAt && now < icoEndsAt) {
           return 1000; 
        } 
    }       
    
     function buyTokens(address _to) nonZeroAddress(_to) nonZeroValue payable {
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount * getRate();
        weiRaised = weiRaised.add(weiAmount);
        
        owner.transfer(msg.value);
        TokenPurchase(_to, weiAmount, tokens);
    }
    
     function () payable {
        buyTokens(msg.sender);
    }
   

    

     
    function addToBalance(address _address, uint _amount) internal {
    	balances[_address] = balances[_address].add(_amount);
    }

     
    function decrementBalance(address _address, uint _amount) internal {
    	balances[_address] = balances[_address].sub(_amount);
    }
}