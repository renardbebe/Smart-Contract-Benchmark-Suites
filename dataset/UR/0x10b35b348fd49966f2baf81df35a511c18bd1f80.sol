 

pragma solidity 0.4.18;


 
contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  function Pausable() public {}

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    Unpause();
  }
}


 
contract SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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


contract Denaro is Pausable, SafeMath {

  uint256 public totalSupply;

  mapping(address => uint) public balances;
  mapping (address => mapping (address => uint)) public allowed;

   
  string public constant name = "Denaro";
  string public constant symbol = "DNO";
  uint8 public constant decimals = 7;
  
   
  bool public mintingFinished = false;
  uint256 public constant MINTING_LIMIT = 100000000 * (uint256(10) ** decimals);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  function Denaro() public {}

  function() public payable {
    revert();
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function transfer(address _to, uint _value) public whenNotPaused returns (bool) {

    balances[msg.sender] = sub(balances[msg.sender], _value);
    balances[_to] = add(balances[_to], _value);

    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = add(balances[_to], _value);
    balances[_from] = sub(balances[_from], _value);
    allowed[_from][msg.sender] = sub(_allowance, _value);

    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) public whenNotPaused returns (bool) {
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) public onlyOwner canMint {
    totalSupply = add(totalSupply, _amount);
    require(totalSupply <= MINTING_LIMIT);
    
    balances[_to] = add(balances[_to], _amount);
    Mint(_to, _amount);
  }

  function finishMinting() public onlyOwner {
    require(!mintingFinished);
    mintingFinished = true;
    MintFinished();
  }

}