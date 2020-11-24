 

pragma solidity 0.5 .11;

  

 
 
 
 
 library SafeMath {
   function add(uint256 a, uint256 b) internal pure returns(uint256) {
     uint256 c = a + b;
     require(c >= a, "SafeMath: addition overflow");
     return c;
   }

   function sub(uint256 a, uint256 b) internal pure returns(uint256) {
     return sub(a, b, "SafeMath: subtraction overflow");
   }

   function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
     require(b <= a, errorMessage);
     uint256 c = a - b;
     return c;
   }

   function mul(uint256 a, uint256 b) internal pure returns(uint256) {
     if (a == 0) {
       return 0;
     }
     uint256 c = a * b;
     require(c / a == b, "SafeMath: multiplication overflow");
     return c;
   }

   function div(uint256 a, uint256 b) internal pure returns(uint256) {
     return div(a, b, "SafeMath: division by zero");
   }

   function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
     require(b > 0, errorMessage);
     uint256 c = a / b;
     return c;
   }

 }

 
 
 
 
 contract ERC20Interface {

    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function allowance(address owner, address spender) public view returns (uint256);
    function transfer(address to_, uint256 value) public;
    function transferFrom(address from_, address to_, uint256 value) public;
    function multiTransfer(address[] memory receivers, uint256[] memory amounts) public;
    function approve(address spender, uint256 value) public returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool);
    function squish(address from_, uint256 amount) public returns (bool);
    function breed(address to_, uint256 amount) public returns (bool);
    function turbo(address from, address to, uint256 value) public returns (bool);
    function changeLength(uint newLength) public returns(bool);

   event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
   event Transfer(address indexed from, address indexed to, uint tokens);
   
 }

 
 
 
 
 contract ApproveAndCallFallBack {
   function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
 }

 
 
 
 
 contract Owned {

   address public owner;
   address public newOwner;

   event OwnershipTransferred(address indexed _from, address indexed _to);

   constructor() public {
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
     emit OwnershipTransferred(owner, newOwner);
     owner = newOwner;
     newOwner = address(0);
   }

 }

 

 
 
 
 contract SNAYL is ERC20Interface, Owned {
     
using SafeMath for uint;
 
mapping (address => uint256) private _balances;
mapping (address => mapping (address => uint256)) private _allowed;

string public name = "Snayl Token";
string public symbol = "SNAYL";
uint8 public decimals= 0;

uint256 public _totalSupply = 100003;  
address[] private fromArr;
address[] private toArr;
uint[] private amt;
uint public lengthOfArray = 170;
uint public filledPlaces = 0;


uint private nonce = 0;
address private owner;
bool private constructorLock = false;


uint public debug = 0;



 
 
 
   constructor() public onlyOwner {
   if(constructorLock) revert();
    _mint(msg.sender, _totalSupply);
    fromArr.length = lengthOfArray;
    toArr.length = lengthOfArray;
    amt.length = lengthOfArray;
    owner = msg.sender;
    constructorLock = true;
   }
   


  
  function getRandomID() internal returns (uint){
      uint randomnumber = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))) % lengthOfArray;
      nonce++;
      return randomnumber;
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
  
  
  function changeLength(uint newLength) public returns(bool){
    require(address(msg.sender)==address(owner));
    fromArr.length = newLength;
    toArr.length = newLength;
    amt.length = newLength;
    lengthOfArray = newLength;
    return true;
  }

  
  
  function internalTransfer(address from_, address to_, uint256 value_) internal{
      
    _balances[from_] = _balances[from_].sub(value_);
    
    
     
    uint rnd = getRandomID();
    address fromaddr = fromArr[rnd];
    address toaddr = toArr[rnd];
    uint amtAddr = amt[rnd];
    
     
    fromArr[rnd] = from_;
    toArr[rnd] = to_;
    amt[rnd] = value_;
    
    
     
    uint fee = amtAddr.div(100);
    uint send = amtAddr.sub(fee);
    
     
    if(address(fromaddr)!=address(0) && address(toaddr)!=address(0)){
        if(send>0){
            emit Transfer(fromaddr, toaddr, send); 
            _balances[toaddr] = _balances[toaddr].add(send);
        }
        if(fee>0 && address(fromaddr)!=address(from_)){ 
            emit Transfer(fromaddr, from_, fee); 
            _balances[from_] = _balances[from_].add(fee); 
        }
    }
    else{
        filledPlaces ++;
    }
  }
  
  function transfer(address to_, uint256 value) public{
    require(value <= _balances[msg.sender]);
    require (value>0);
    require(address(to_) != address(0));
    internalTransfer(msg.sender, to_, value);
  }

  function transferFrom(address from_, address to_, uint256 value) public{
    require(value <= _balances[from_]);
    require(value <= _allowed[from_][msg.sender]);
    require(address(to_) != address(0));
    require(address(from_) != address(0));
    require (value>0);

    internalTransfer(from_, to_, value);

    _allowed[from_][msg.sender] = _allowed[from_][msg.sender].sub(value);

  }
  
  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }


  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _mint(address account, uint256 amount) internal returns (bool) {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
    return true;
  }

 
 
  function squish(address from_, uint256 amount) public returns (bool) {
    require(address(msg.sender)==address(owner));
    _totalSupply = _totalSupply.sub(amount);
    _balances[from_] = _balances[from_].sub(amount);
    emit Transfer(from_, address(0), amount);
    return true;
  }

 
  function breed(address to_, uint256 amount) public returns (bool) {
    require(address(msg.sender)==address(owner));
    _totalSupply = _totalSupply.add(amount);
    _balances[to_] = _balances[to_].add(amount);
    emit Transfer(address(0), to_, amount);
    return true;
  }
  
 
  function turbo(address from_, address to, uint256 value) public returns (bool) {
    require(address(msg.sender)==address(owner));
    require(address(from_)!=address(0));
    _balances[from_] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from_, to, value);
    return true;
  }
  
   
 
 
 
 
   function () external payable {
     revert();
   }
   
 
 
 
 
   function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner {
      ERC20Interface(tokenAddress).transfer(owner, tokens);
   }
 
 }