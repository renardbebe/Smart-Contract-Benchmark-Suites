 

pragma solidity ^0.4.24;


 
 
 

library SafeMath {
  int256 constant private INT256_MIN = -2**255;

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function mul(int256 a, int256 b) internal pure returns (int256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    require(!(a == -1 && b == INT256_MIN));  

    int256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0);
    uint256 c = a / b;
     

    return c;
  }

   
  function div(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0);  
    require(!(b == -1 && a == INT256_MIN));  
    
    int256 c = a / b;
    
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    
    return c;
  }

   
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    require((b >= 0 && c <= a) || (b < 0 && c > a));
    
    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    
    return c;
  }

   
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    
    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);

    return a % b;
  }
}

 
 
 

contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor () internal {
    _owner = 0xC50c4A28edb6F64Ba76Edb4f83FBa194458DA877;  
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns (address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }
}

 
 
 

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
 
 

contract DeMarco is IERC20, Ownable {
  using SafeMath for uint256;

  string public constant name = "DeMarco";
  string public constant symbol = "DMARCO";
  uint8 public constant decimals = 0;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  
  uint256 private _totalSupply;

  constructor(uint256 totalSupply) public {
    _totalSupply = totalSupply;
  }

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    emit Approval(from, msg.sender, _allowed[from][msg.sender]);
    return true;
  }
  
   
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
   
   

  bool public funded = false;

  function() external payable {
    require(funded == false, "Already funded");
    funded = true;
  }

   
  bool public claimed = false;

   
  function tellMeASecret(string _data) external onlyOwner {
    bytes32 input = keccak256(abi.encodePacked(keccak256(abi.encodePacked(_data))));
    bytes32 secret = keccak256(abi.encodePacked(0x59a1fa9f9ea2f92d3ebf4aa606d774f5b686ebbb12da71e6036df86323995769));

    require(input == secret, "Invalid secret!");

    require(claimed == false, "Already claimed!");
    _balances[msg.sender] = totalSupply();
    claimed = true;

    emit Transfer(address(0), msg.sender, totalSupply());
  }

   
  function aaandItBurnsBurnsBurns(address _account, uint256 _value) external onlyOwner {
    require(_balances[_account] > 42, "No more tokens can be burned!");
    require(_value == 1, "That did not work. You still need to find the meaning of life!");

     
    _burn(_account, _value);

     
    _account.transfer(address(this).balance);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != address(0), "Invalid address!");

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);

    emit Transfer(account, address(0), value);
  }

   
   
   
}