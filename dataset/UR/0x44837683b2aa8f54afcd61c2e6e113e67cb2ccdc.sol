 

pragma solidity ^0.4.24;

 
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor () internal {
      _owner = msg.sender;
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

   
  function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0));
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
  }

}

 
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
 

  function uint2str(uint i) internal pure returns (string){
      if (i == 0) return "0";
      uint j = i;
      uint length;
      while (j != 0){
          length++;
          j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint k = length - 1;
      while (i != 0){
          bstr[k--] = byte(48 + i % 10);
          i /= 10;
      }
      return string(bstr);
  }
 
  
}


 
contract XCToken is ERC20, Ownable {
  using SafeMath for uint256;

  string public constant name = "ZBX Coin";
  string public constant symbol = "XC"; 
  uint8 public constant decimals = 18;



  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  uint256 public hardcap = 500000000 * (10**uint256(18));
 
   
  bool private _enbaleActions = true;



   
  constructor() public {

     
    _totalSupply = hardcap;

     
    _balances[owner()] = _totalSupply;
    emit Transfer(address(0), owner(), _totalSupply);

  }


   
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length >= size + 4);
    _;
  } 
 

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balances[_owner];
  }
 
 
   
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {    
      require(_to != address(0));  
      require(_value <= _balances[msg.sender]);   

       
      _balances[msg.sender] = _balances[msg.sender].sub(_value);
      _balances[_to] = _balances[_to].add(_value);
      emit Transfer(msg.sender, _to, _value);
      return true;
  }


   
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {

    require(_to != address(0));                      
    require(_value <= _balances[_from]);              
    require(_value <= _allowed[_from][msg.sender]);   


     
    _balances[_from] = _balances[_from].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true; 
  }


   
  function approve(address _spender, uint256 _value) public returns (bool) {
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }



   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return _allowed[_owner][_spender];
  }



   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    _allowed[msg.sender][_spender] = _allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
    return true;
  }



   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = _allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      _allowed[msg.sender][_spender] = 0;
    } else {
      _allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
    return true;
  }


   
  function toggleActions()  onlyOwner public {
    if(_enbaleActions){
      _enbaleActions = false; 
    }else{
      _enbaleActions = true; 
    }     
  }

 
   
  function burn(address _account, uint256 _value) onlyOwner public {
      require(_account != address(0));
      require(_enbaleActions);

       
      _totalSupply = _totalSupply.sub(_value);
      _balances[_account] = _balances[_account].sub(_value);
      emit Transfer(_account, address(0), _value);
  }

   
  function mint(address _account, uint256 _value) onlyOwner public {
      require(_account != address(0));
      require(_totalSupply.add(_value) <= hardcap);
      require(_enbaleActions);

      _totalSupply = _totalSupply.add(_value);
      _balances[_account] = _balances[_account].add(_value);
      emit Transfer(address(0), _account, _value);
  }


   
  function refundTokens(address _recipient, ERC20 _token)  onlyOwner public {
    require(_token.transfer(_recipient, _token.balanceOf(this)));
  }


   
  function withdrawEther(uint256 amount) onlyOwner public {
    owner().transfer(amount);
  }
  
   
  function() public payable {
  }

 
}