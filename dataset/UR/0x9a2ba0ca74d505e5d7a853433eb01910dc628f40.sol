 

 
contract ERC20 {
  uint public totalSupply;  
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract SafeMath {
  function safeMul(uint a, uint b) internal constant returns (uint) {
    uint c = a * b;

    assert(a == 0 || c / a == b);

    return c;
  }

  function safeDiv(uint a, uint b) internal constant returns (uint) {    
    uint c = a / b;

    return c;
  }

  function safeSub(uint a, uint b) internal constant returns (uint) {
    require(b <= a);

    return a - b;
  }

  function safeAdd(uint a, uint b) internal constant returns (uint) {
    uint c = a + b;

    assert(c>=a && c>=b);

    return c;
  }
}


 
contract Token is ERC20, SafeMath {

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) returns (bool success) {

    return doTransfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    allowed[_from][msg.sender] = safeSub(_allowance, _value);

    return doTransfer(_from, _to, _value);
  }

   
  function approve(address _spender, uint _value) public returns (bool success) {
    require(allowed[msg.sender][_spender] == 0 || _value == 0);

    allowed[msg.sender][_spender] = _value;

    Approval(msg.sender, _spender, _value);

    return true;
  }

  function doTransfer(address _from, address _to, uint _value) private returns (bool success) {
    balances[_from] = safeSub(balances[_from], _value);
    balances[_to] = safeAdd(balances[_to], _value);

    Transfer(_from, _to, _value);

    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract MintInterface {
  function mint(address recipient, uint amount) returns (bool success);
}


 
contract Owned {
    address public owner;  

    modifier onlyOwner() {
      require(msg.sender == owner);

        _;
    }

    function Owned() {
        owner = msg.sender;
    }

     
     
     
    function changeOwner(address newOwner) public onlyOwner {
      owner = newOwner;
    }
}

 
contract Minted is MintInterface, Owned {
  uint public numMinters;  
  bool public open;  
  mapping (address => bool) public minters;  

   
  event NewMinter(address who);

  modifier onlyMinters() {
    require(minters[msg.sender]);

    _;
  }

  modifier onlyIfOpen() {
    require(open);

    _;
  }

  function Minted() {
    open = true;
  }

   
   
   
   
  function addMinter(address _minter) public onlyOwner onlyIfOpen {
    if(!minters[_minter]) {
      minters[_minter] = true;
      numMinters++;

      NewMinter(_minter);
    }
  }

   
   
   
  function removeMinter(address _minter) public onlyOwner {
    if(minters[_minter]) {
      minters[_minter] = false;
      numMinters--;
    }
  }

   
   
   
  function endMinting() public onlyOwner {
    open = false;
  }
}

 
contract Pausable is Owned {
   
   
  uint public endBlock;

  modifier validUntil() {
    require(block.number <= endBlock || endBlock == 0);

    _;
  }

   
   
   
  function setEndBlock(uint block) public onlyOwner {
    endBlock = block;
  }
}


 
contract ProjectToken is Token, Minted, Pausable {
  string public name;  
  string public symbol;  
  uint public decimals;  

  uint public transferableBlock;  

  modifier lockUpPeriod() {
    require(block.number >= transferableBlock);

    _;
  }

  function ProjectToken(
    string _name,
    string _symbol,
    uint _decimals,
    uint _transferableBlock
  ) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    transferableBlock = _transferableBlock;
  }

   
   
  function mint(address recipient, uint amount)
    public
    onlyMinters
    returns (bool success)
  {
    totalSupply = safeAdd(totalSupply, amount);
    balances[recipient] = safeAdd(balances[recipient], amount);

    Transfer(0x0, recipient, amount);

    return true;
  }

   
  function approveAndCall(address _spender, uint256 _value)
    public
    returns (bool success)
  {
    if(super.approve(_spender, _value)){
      if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address)"))), msg.sender, _value, this))
        revert();

      return true;
    }
  }

   
   
   
   
  function transfer(address to, uint value)
    public
    lockUpPeriod
    validUntil
    returns (bool success)
  {
    if(super.transfer(to, value))
      return true;

    return false;
  }

   
   
   
   
  function transferFrom(address from, address to, uint value)
    public
    lockUpPeriod
    validUntil
    returns (bool success)
  {
    if(super.transferFrom(from, to, value))
      return true;

    return false;
  }

  function refundTokens(address _token, address _refund, uint _value) onlyOwner {

    Token(_token).transfer(_refund, _value);
  }

}