 

pragma solidity ^0.4.15;





contract ContractReceiver {   
    function tokenFallback(address _from, uint _value, bytes _data){
    }
}

  

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  
  function name() constant returns (string _name);
  function symbol() constant returns (string _symbol);
  function decimals() constant returns (uint8 _decimals);
  function totalSupply() constant returns (uint256 _supply);

  function transfer(address to, uint value) returns (bool ok);
  function transfer(address to, uint value, bytes data) returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) returns (bool ok);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

 

contract GXVCToken {

     
    string public name;
    string public symbol;
    uint8 public decimals; 
    string public version = 'v0.2';
    uint256 public totalSupply;
    bool locked;

    address rootAddress;
    address Owner;
    uint multiplier = 10000000000;  
    address swapperAddress;  

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) freezed; 


  	event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     

    modifier onlyOwner() {
        if ( msg.sender != rootAddress && msg.sender != Owner ) revert();
        _;
    }

    modifier onlyRoot() {
        if ( msg.sender != rootAddress ) revert();
        _;
    }

    modifier isUnlocked() {
    	if ( locked && msg.sender != rootAddress && msg.sender != Owner ) revert();
		_;    	
    }

    modifier isUnfreezed(address _to) {
    	if ( freezed[msg.sender] || freezed[_to] ) revert();
    	_;
    }


     
    function safeAdd(uint x, uint y) internal returns (uint z) {
        require((z = x + y) >= x);
    }
    function safeSub(uint x, uint y) internal returns (uint z) {
        require((z = x - y) <= x);
    }


     
    function GXVCToken() {        
        locked = true;
        totalSupply = 160000000 * multiplier;  
        name = 'Genevieve VC'; 
        symbol = 'GXVC'; 
        decimals = 10; 
        rootAddress = msg.sender;        
        Owner = msg.sender;       
        balances[rootAddress] = totalSupply; 
        allowed[rootAddress][swapperAddress] = totalSupply;
    }


	 

	function name() constant returns (string _name) {
	      return name;
	  }
	function symbol() constant returns (string _symbol) {
	      return symbol;
	  }
	function decimals() constant returns (uint8 _decimals) {
	      return decimals;
	  }
	function totalSupply() constant returns (uint256 _totalSupply) {
	      return totalSupply;
	  }


     

    function changeRoot(address _newrootAddress) onlyRoot returns(bool){
    		allowed[rootAddress][swapperAddress] = 0;  
            rootAddress = _newrootAddress;
            allowed[_newrootAddress][swapperAddress] = totalSupply;  
            return true;
    }


     

    function changeOwner(address _newOwner) onlyOwner returns(bool){
            Owner = _newOwner;
            return true;
    }

    function changeSwapperAdd(address _newSwapper) onlyOwner returns(bool){
    		allowed[rootAddress][swapperAddress] = 0;  
            swapperAddress = _newSwapper;
            allowed[rootAddress][_newSwapper] = totalSupply;  
            return true;
    }
       
    function unlock() onlyOwner returns(bool) {
        locked = false;
        return true;
    }

    function lock() onlyOwner returns(bool) {
        locked = true;
        return true;
    }

    function freeze(address _address) onlyOwner returns(bool) {
        freezed[_address] = true;
        return true;
    }

    function unfreeze(address _address) onlyOwner returns(bool) {
        freezed[_address] = false;
        return true;
    }

    function burn(uint256 _value) onlyOwner returns(bool) {
    	bytes memory empty;
        if ( balances[msg.sender] < _value ) revert();
        balances[msg.sender] = safeSub( balances[msg.sender] , _value );
        totalSupply = safeSub( totalSupply,  _value );
        Transfer(msg.sender, 0x0, _value , empty);
        return true;
    }


     
    function isFreezed(address _address) constant returns(bool) {
        return freezed[_address];
    }

    function isLocked() constant returns(bool) {
        return locked;
    }

   

   
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) isUnlocked isUnfreezed(_to) returns (bool success) {
      
    if(isContract(_to)) {
        if (balances[msg.sender] < _value) return false;
        balances[msg.sender] = safeSub( balances[msg.sender] , _value );
        balances[_to] = safeAdd( balances[_to] , _value );
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}

   
  function transfer(address _to, uint _value, bytes _data) isUnlocked isUnfreezed(_to) returns (bool success) {
      
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
}


   
   
  function transfer(address _to, uint _value) isUnlocked isUnfreezed(_to) returns (bool success) {

    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
}

 
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
      }
      return (length>0);
    }

   
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balances[msg.sender] < _value) return false;
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }
  
   
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balances[msg.sender] < _value) return false;
    balances[msg.sender] = safeSub(balances[msg.sender] , _value);
    balances[_to] = safeAdd(balances[_to] , _value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    return true;
}


    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {

        if ( locked && msg.sender != swapperAddress ) return false; 
        if ( freezed[_from] || freezed[_to] ) return false;  
        if ( balances[_from] < _value ) return false;  
		if ( _value > allowed[_from][msg.sender] ) return false;  

        balances[_from] = safeSub(balances[_from] , _value);  
        balances[_to] = safeAdd(balances[_to] , _value);  

        allowed[_from][msg.sender] = safeSub( allowed[_from][msg.sender] , _value );

        bytes memory empty;

        if ( isContract(_to) ) {
	        ContractReceiver receiver = ContractReceiver(_to);
	    	receiver.tokenFallback(_from, _value, empty);
		}

        Transfer(_from, _to, _value , empty);
        return true;
    }


    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }


    function approve(address _spender, uint _value) returns(bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns(uint256) {
        return allowed[_owner][_spender];
    }
}
 

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract Dec {
    function decimals() public view returns (uint8);
}

contract ERC20 {
    function transfer(address,uint256);
}

contract KeeToken {
     

    function icoBalanceOf(address from, address ico) external view returns (uint) ;


}

contract KeeHole {
    using SafeMath for uint256;
    
    KeeToken  token;

    uint256   pos;
    uint256[] slots;
    uint256[] bonuses;

    uint256 threshold;
    uint256 maxTokensInTier;
    uint256 rate;
    uint256 tokenDiv;

    function KeeHole() public {
        token = KeeToken(0x72D32ac1c5E66BfC5b08806271f8eEF915545164);
        slots.push(100);
        slots.push(200);
        slots.push(500);
        slots.push(1200);
        bonuses.push(5);
        bonuses.push(3);
        bonuses.push(2);
        bonuses.push(1);
        threshold = 5;
        rate = 10000;
        tokenDiv = 100000000;  
        maxTokensInTier = 25000 * (10 ** 10);
    }

    mapping (address => bool) hasParticipated;

     
     
    function getBonusAmount(uint256 amount) public returns (uint256 bonus) {
        if (hasParticipated[msg.sender])
            return 0;
        if ( token.icoBalanceOf(msg.sender,this) < threshold )
            return 0;
        if (pos>=slots.length)
            return 0;
        bonus = (amount.mul(bonuses[pos])).div(100);
        slots[pos]--;
        if (slots[pos] == 0) 
            pos++;
        bonus = Math.min256(maxTokensInTier,bonus);
        hasParticipated[msg.sender] = true;
        return;
    }

     
    function getTokenAmount(uint256 ethDeposit) public returns (uint256 numTokens) {
        numTokens = (ethDeposit.mul(rate)).div(tokenDiv);
        numTokens = numTokens.add(getBonusAmount(numTokens));
    }


}

contract GenevieveCrowdsale is Ownable, Pausable, KeeHole {
  using SafeMath for uint256;

   
  GXVCToken public token;
  KeeHole public keeCrytoken;

   
  address public tokenSpender;

   
  uint256 public startTimestamp;
  uint256 public endTimestamp;

   
  address public hardwareWallet;

  mapping (address => uint256) public deposits;
  uint256 public numberOfPurchasers;

   
  
  

   
  uint256 public weiRaised;
  uint256 public weiToRaise;
  uint256 public tokensSold;

  uint256 public minContribution = 1 finney;


  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event MainSaleClosed();

  uint256 public weiRaisedInPresale  = 0 ether;
  uint256 public tokensSoldInPresale = 0 * 10 ** 18;

 

  mapping (address => bool) public registered;
  address public registrar;
  function setReg(address _newReg) external onlyOwner {
    registrar = _newReg;
  }

  function register(address participant) external {
    require(msg.sender == registrar);
    registered[participant] = true;
  }

 

  function setCoin(GXVCToken _coin) external onlyOwner {
    token = _coin;
  }

  function setWallet(address _wallet) external onlyOwner {
    hardwareWallet = _wallet;
  }

  function GenevieveCrowdsale() public {
    token = GXVCToken(0x22F0AF8D78851b72EE799e05F54A77001586B18A);
    startTimestamp = 1516453200;
    endTimestamp = 1519563600;
    hardwareWallet = 0x6Bc63d12D5AAEBe4dc86785053d7E4f09077b89E;
    tokensSoldInPresale = 0;  
    weiToRaise = 10000 * (10 ** 18);
    tokenSpender = 0x6835706E8e58544deb6c4EC59d9815fF6C20417f;  

    minContribution = 1 finney;
    require(startTimestamp >= now);
    require(endTimestamp >= startTimestamp);
  }

   
  modifier validPurchase {
     
    require(registered[msg.sender]);
     
    require(now >= startTimestamp);
    require(now < endTimestamp);
    require(msg.value >= minContribution);
    require(weiRaised.add(msg.value) <= weiToRaise);
    _;
  }

   
  function hasEnded() public constant returns (bool) {
    if (now > endTimestamp) 
        return true;
    if (weiRaised >= weiToRaise.sub(minContribution))
      return true;
    return false;
  }

   
  function buyTokens(address beneficiary, uint256 weiAmount) 
    internal 
    validPurchase 
    whenNotPaused
  {

    require(beneficiary != 0x0);

    if (deposits[beneficiary] == 0) {
        numberOfPurchasers++;
    }
    deposits[beneficiary] = weiAmount.add(deposits[beneficiary]);
    
     
    uint256 tokens = getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokens);

    require(token.transferFrom(tokenSpender, beneficiary, tokens));
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    hardwareWallet.transfer(this.balance);
  }

   
  function () public payable {
    buyTokens(msg.sender,msg.value);
  }

    function emergencyERC20Drain( ERC20 theToken, uint amount ) {
        theToken.transfer(owner, amount);
    }


}