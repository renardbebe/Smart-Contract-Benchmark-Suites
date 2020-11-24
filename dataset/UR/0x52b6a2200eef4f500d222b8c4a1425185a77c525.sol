 

pragma solidity ^0.4.13;

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract NeuroChainClausius is Owned, ERC20Interface {

   
  using SafeMath for uint;
   
  mapping(address => uint256) balances;
   
  mapping(address => mapping (address => uint256)) allowed;
   
  mapping(address => bool) public freezeBypassing;
   
  mapping(address => string) public neuroChainAddresses;
   
  event NeuroChainAddressSet(
    address ethAddress,
    string neurochainAddress,
    uint timestamp,
    bool isForcedChange
  );
   
  event FreezeStatusChanged(
    bool toStatus,
    uint timestamp
  );
   
  string public symbol = "NCC";
   
  string public name = "NeuroChain Clausius";
   
  uint8 public decimals = 18;
   
  uint public _totalSupply = 657440000 * 10**uint(decimals);
   
  uint public _circulatingSupply = 0;
   
  bool public tradingLive = false;
   
  address public icoContractAddress;
   
  function distributeSupply(
    address to,
    uint tokens
  )
  public onlyOwner returns (bool success)
  {
    uint tokenAmount = tokens.mul(10**uint(decimals));
    require(_circulatingSupply.add(tokenAmount) <= _totalSupply);
    _circulatingSupply = _circulatingSupply.add(tokenAmount);
    balances[to] = tokenAmount;
    return true;
  }
   
  function allowFreezeBypass(
    address sender
  )
  public onlyOwner returns (bool success)
  {
    freezeBypassing[sender] = true;
    return true;
  }
   
  function setTradingStatus(
    bool isLive
  )
  public onlyOwner
  {
    tradingLive = isLive;
    FreezeStatusChanged(tradingLive, block.timestamp);
  }
   
   
  modifier tokenTradingMustBeLive(address sender) {
    require(tradingLive || freezeBypassing[sender]);
    _;
  }
   
  function setIcoContractAddress(
    address contractAddress
  )
  public onlyOwner
  {
    freezeBypassing[contractAddress] = true;
    icoContractAddress = contractAddress;
  }
   
  modifier onlyIcoContract() {
    require(msg.sender == icoContractAddress);
    _;
  }
   
  function setNeuroChainAddress(
    string neurochainAddress
  )
  public
  {
    neuroChainAddresses[msg.sender] = neurochainAddress;
    NeuroChainAddressSet(
      msg.sender,
      neurochainAddress,
      block.timestamp,
      false
    );
  }
   
  function forceNeuroChainAddress(
    address ethAddress,
    string neurochainAddress
  )
  public onlyIcoContract
  {
    neuroChainAddresses[ethAddress] = neurochainAddress;
    NeuroChainAddressSet(
      ethAddress,
      neurochainAddress,
      block.timestamp,
      true
    );
  }
   
  function totalSupply() public constant returns (uint) {
    return _totalSupply;
  }
   
  function balanceOf(
    address tokenOwner
  )
  public constant returns (uint balance)
  {
    return balances[tokenOwner];
  }
   
  function transfer(
    address to,
    uint tokens
  )
  public tokenTradingMustBeLive(msg.sender) returns (bool success)
  {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    Transfer(msg.sender, to, tokens);
    return true;
  }
   
  function transferFrom(
    address from,
    address to,
    uint tokens
  )
  public tokenTradingMustBeLive(from) returns (bool success)
  {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    Transfer(from, to, tokens);
    return true;
  }
   
  function approve(
    address spender,
    uint tokens
  )
  public returns (bool success)
  {
    allowed[msg.sender][spender] = tokens;
    Approval(msg.sender, spender, tokens);
    return true;
  }
   
  function allowance(
    address tokenOwner,
    address spender
  )
  public constant returns (uint remaining)
  {
    return allowed[tokenOwner][spender];
  }
   
  function approveAndCall(
    address spender,
    uint tokens,
    bytes data
  )
  public returns (bool success)
  {
    allowed[msg.sender][spender] = tokens;
    Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
    return true;
  }
   
  function transferAnyERC20Token(
    address tokenAddress,
    uint tokens
  )
  public onlyOwner returns (bool success)
  {
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

     
    uint constant ETHER_PRECISION = 10 ** 18;
    function ediv(uint x, uint y) internal pure returns (uint z) {
         
         
        z = add(mul(x, ETHER_PRECISION), y / 2) / y;
    }
}