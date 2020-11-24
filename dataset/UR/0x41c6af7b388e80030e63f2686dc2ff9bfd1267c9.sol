 

pragma solidity ^0.4.23;

 
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

  function kill() public onlyOwner {
    selfdestruct(owner);
  }
} 


library XTVNetworkUtils {
  function verifyXTVSignatureAddress(bytes32 hash, bytes memory sig) internal pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    if (sig.length != 65) {
      return (address(0));
    }

     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    if (v < 27) {
      v += 27;
    }

    if (v != 27 && v != 28) {
      return (address(0));
    }

    bytes32 prefixedHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );

     
    return ecrecover(prefixedHash, v, r, s);
  }
} 




contract XTVNetworkGuard {
  mapping(address => bool) xtvNetworkEndorser;

  modifier validateSignature(
    string memory message,
    bytes32 verificationHash,
    bytes memory xtvSignature
  ) {
    bytes32 xtvVerificationHash = keccak256(abi.encodePacked(verificationHash, message));

    require(verifyXTVSignature(xtvVerificationHash, xtvSignature));
    _;
  }

  function setXTVNetworkEndorser(address _addr, bool isEndorser) public;

  function verifyXTVSignature(bytes32 hash, bytes memory sig) public view returns (bool) {
    address signerAddress = XTVNetworkUtils.verifyXTVSignatureAddress(hash, sig);

    return xtvNetworkEndorser[signerAddress];
  }
}
 




 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
 




 


 
contract ERC20 {
  bool public paused = false;
  bool public mintingFinished = false;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) internal allowed;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function allowance(address _owner, address spender) public view returns (uint256);
  function increaseApproval(address spender, uint addedValue) public returns (bool);
  function decreaseApproval(address spender, uint subtractedValue) public returns (bool);

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Buy(address indexed _recipient, uint _amount);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event Pause();
  event Unpause();
}

contract ERC20Token is ERC20, Ownable {
  using SafeMath for uint256;

   
   
  function totalSupply() public view returns (uint256) { return totalSupply_; }

   
  function balanceOf(address _owner) public view returns (uint256) { return balances[_owner]; }

   
  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
    allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];

    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
 
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

     
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}



contract XTVToken is XTVNetworkGuard, ERC20Token {
  using SafeMath for uint256;

  string public constant name = "XTV";
  string public constant symbol = "XTV";
  uint public constant decimals = 18;

  address public fullfillTeamAddress;
  address public fullfillFounder;
  address public fullfillAdvisors;
  address public XTVNetworkContractAddress;

  bool public airdropActive;
  uint public startTime;
  uint public endTime;
  uint public XTVAirDropped;
  uint public XTVBurned;
  mapping(address => bool) public claimed;
  
  uint256 private constant TOKEN_MULTIPLIER = 1000000;
  uint256 private constant DECIMALS = 10 ** decimals;
  uint256 public constant INITIAL_SUPPLY = 500 * TOKEN_MULTIPLIER * DECIMALS;
  uint256 public constant EXPECTED_TOTAL_SUPPLY = 1000 * TOKEN_MULTIPLIER * DECIMALS;

   
  uint256 public constant ALLOC_TEAM = 330 * TOKEN_MULTIPLIER * DECIMALS;
   
  uint256 public constant ALLOC_ADVISORS = 70 * TOKEN_MULTIPLIER * DECIMALS;
   
  uint256 public constant ALLOC_FOUNDER = 100 * TOKEN_MULTIPLIER * DECIMALS;
   
  uint256 public constant ALLOC_AIRDROP = 500 * TOKEN_MULTIPLIER * DECIMALS;

  uint256 public constant AIRDROP_CLAIM_AMMOUNT = 500 * DECIMALS;

  modifier isAirdropActive() {
    require(airdropActive);
    _;
  }

  modifier canClaimTokens() {
    uint256 remainingSupply = balances[address(0)];

    require(!claimed[msg.sender] && remainingSupply > AIRDROP_CLAIM_AMMOUNT);
    _;
  }

  constructor(
    address _fullfillTeam,
    address _fullfillFounder,
    address _fullfillAdvisors
  ) public {
    owner = msg.sender;
    fullfillTeamAddress = _fullfillTeam;
    fullfillFounder = _fullfillFounder;
    fullfillAdvisors = _fullfillAdvisors;

    airdropActive = true;
    startTime = block.timestamp;
    endTime = startTime + 365 days;

    balances[_fullfillTeam] = ALLOC_TEAM;
    balances[_fullfillFounder] = ALLOC_FOUNDER;
    balances[_fullfillAdvisors] = ALLOC_ADVISORS;

    balances[address(0)] = ALLOC_AIRDROP;

    totalSupply_ = EXPECTED_TOTAL_SUPPLY;

    emit Transfer(address(this), address(0), ALLOC_AIRDROP);
  }

  function setXTVNetworkEndorser(address _addr, bool isEndorser) public onlyOwner {
    xtvNetworkEndorser[_addr] = isEndorser;
  }

   
  function claim(
    string memory token,
    bytes32 verificationHash,
    bytes memory xtvSignature
  ) 
    public
    isAirdropActive
    canClaimTokens
    validateSignature(token, verificationHash, xtvSignature)
    returns (uint256)
  {
    claimed[msg.sender] = true;

    balances[address(0)] = balances[address(0)].sub(AIRDROP_CLAIM_AMMOUNT);
    balances[msg.sender] = balances[msg.sender].add(AIRDROP_CLAIM_AMMOUNT);

    XTVAirDropped = XTVAirDropped.add(AIRDROP_CLAIM_AMMOUNT);

    emit Transfer(address(0), msg.sender, AIRDROP_CLAIM_AMMOUNT);

    return balances[msg.sender];
  }

   
  function burnTokens() public onlyOwner {
    require(block.timestamp > endTime);

    uint256 remaining = balances[address(0)];

    airdropActive = false;

    XTVBurned = remaining;
  }

  function setXTVNetworkContractAddress(address addr) public onlyOwner {
    XTVNetworkContractAddress = addr;
  }

  function setXTVTokenAirdropStatus(bool _status) public onlyOwner {
    airdropActive = _status;
  }
}