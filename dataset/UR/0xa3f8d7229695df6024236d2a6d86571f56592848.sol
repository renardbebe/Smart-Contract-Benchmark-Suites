 

 

pragma solidity ^0.4.26;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity ^0.4.26;

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

pragma solidity ^0.4.26;



contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner(), "Permission denied");
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract MiningBankToken is IERC20, Ownable {
  using SafeMath for uint;

  mapping (address => uint) private _balances;
  mapping (address => mapping (address => uint)) private _allowed;

  string public constant name = "Mining Bank";
  string public constant symbol = "MGB";
  uint256 public constant decimals = 18;
  uint256 private _totalSupply = 100*10**8 * 10**(decimals);

  constructor() public {
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint) {
    return _totalSupply;
  }

  function balanceOf(address _who) public view returns (uint) {
    return _balances[_who];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint value) public stoppable personalStoppable(msg.sender) returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint value) public stoppable personalStoppable(msg.sender) returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint value
  )
    public stoppable personalStoppable(from) returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
    _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  bool public stopped = true;  
  mapping(address => bool) personalStopped;  
   

  modifier stoppable {
    require(!stopped, "transfer stopped");
    _;
  }

  modifier personalStoppable(address _who) {
    require(!personalStopped[_who], "personal transfer stopped");
    _;
  }

  function start() public onlyOwner {
    stopped = false;
  }

  function stop() public onlyOwner {
    stopped = true;
  }

   
  function setPersonalStart(address _who) public onlyOwner returns (bool) {
    personalStopped[_who] = false;

    return true;
  }

   
  function setPersonalStop(address _who) public onlyOwner returns (bool) {
    personalStopped[_who] = true;
    return true;
  }

   
  function setPeopleTransferStop(address[] _whos) onlyOwner public returns (bool){  
    require(_whos.length > 0, "address length >0");
    require(_whos.length < 101, "address length <101");

    for (uint i = 0; i < _whos.length; i++){
      personalStopped[_whos[i]] = true;
    }

    return true;
  }

   
  function setPeopleTransferStart(address[] _whos) onlyOwner public returns (bool){  
    require(_whos.length > 0, "address length >0");
    require(_whos.length < 101, "address length <101");

    for (uint i = 0; i < _whos.length; i++){
      personalStopped[_whos[i]] = false;
    }

    return true;
  }

   
  function getPersonalTransferState(address _who) onlyOwner public view returns(bool) {
    return personalStopped[_who];
  }

}