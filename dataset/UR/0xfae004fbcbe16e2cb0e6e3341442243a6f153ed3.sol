 

 
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


 

contract Ownable {
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
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
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}


 
contract Stoppable is Pausable {
  event Stop();

  bool public stopped = false;


   
  modifier whenNotStopped() {
    require(!stopped);
    _;
  }

   
  modifier whenStopped() {
    require(stopped);
    _;
  }

   
  function stop() public onlyOwner whenNotStopped {
    stopped = true;
    emit Stop();
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


 
contract e2pAirEscrow is Stoppable {
  
  address public TOKEN_ADDRESS;  
  uint public CLAIM_AMOUNT;  
  uint public CLAIM_AMOUNT_ETH;  
  address public AIRDROPPER;  
  address public AIRDROP_TRANSIT_ADDRESS;  
                                           
  

    
  mapping (address => bool) usedTransitAddresses;
  
    
  constructor(address _tokenAddress,
              uint _claimAmount, 
              uint _claimAmountEth, 
              address _airdropTransitAddress) public payable {
    AIRDROPPER = msg.sender;
    TOKEN_ADDRESS = _tokenAddress;
    CLAIM_AMOUNT = _claimAmount;
    CLAIM_AMOUNT_ETH = _claimAmountEth;
    AIRDROP_TRANSIT_ADDRESS = _airdropTransitAddress;
  }

    
  function verifySignature(
			   address _transitAddress,
			   address _addressSigned,
			   uint8 _v,
			   bytes32 _r,
			   bytes32 _s)
    public pure returns(bool success) {
    bytes32 prefixedHash = keccak256("\x19Ethereum Signed Message:\n32", _addressSigned);
    address retAddr = ecrecover(prefixedHash, _v, _r, _s);
    return retAddr == _transitAddress;
  }
  
 
  function checkWithdrawal(
            address _recipient, 
		    address _transitAddress,
		    uint8 _keyV, 
		    bytes32 _keyR,
			bytes32 _keyS,
			uint8 _recipientV, 
		    bytes32 _recipientR,
			bytes32 _recipientS) 
    public view returns(bool success) {
    
         
        require(usedTransitAddresses[_transitAddress] == false);

         
        require(verifySignature(AIRDROP_TRANSIT_ADDRESS, _transitAddress, _keyV, _keyR, _keyS));
    
         
        require(verifySignature(_transitAddress, _recipient, _recipientV, _recipientR, _recipientS));
        
         
        require(address(this).balance >= CLAIM_AMOUNT_ETH);
        
        return true;
  }
  
   
  function withdraw(
		    address _recipient, 
		    address _transitAddress,
		    uint8 _keyV, 
		    bytes32 _keyR,
			bytes32 _keyS,
			uint8 _recipientV, 
		    bytes32 _recipientR,
			bytes32 _recipientS
		    )
    public
    whenNotPaused
    whenNotStopped
    returns (bool success) {
    
    require(checkWithdrawal(_recipient, 
		    _transitAddress,
		    _keyV, 
		    _keyR,
			_keyS,
			_recipientV, 
		    _recipientR,
			_recipientS));
        

     
    usedTransitAddresses[_transitAddress] = true;

     
    StandardToken token = StandardToken(TOKEN_ADDRESS);
    token.transferFrom(AIRDROPPER, _recipient, CLAIM_AMOUNT);
    
     
    if (CLAIM_AMOUNT_ETH > 0) {
        _recipient.transfer(CLAIM_AMOUNT_ETH);
    }
    
    return true;
  }

  
  function isLinkClaimed(address _transitAddress) 
    public view returns (bool claimed) {
        return usedTransitAddresses[_transitAddress];
  }

    
  function getEtherBack() public returns (bool success) { 
    require(msg.sender == AIRDROPPER);
      
    AIRDROPPER.transfer(address(this).balance);
      
    return true;
  }
}