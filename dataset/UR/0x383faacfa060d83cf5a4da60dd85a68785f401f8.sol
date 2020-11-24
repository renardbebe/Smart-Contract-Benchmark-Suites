 

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



 
contract OwnableMintable {
  address public owner;
  address public mintOwner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event MintOwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
    mintOwner = msg.sender;
  }

  

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onlyMintOwner() {
    require(msg.sender == mintOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function transferMintOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit MintOwnershipTransferred(mintOwner, newOwner);
    mintOwner = newOwner;
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



 
contract HSYToken is ERC20, OwnableMintable {
  using SafeMath for uint256;


  string public constant name = "HSYToken";   
  string public constant symbol = "HSY";     
  uint8 public constant decimals = 18;       

   
  uint256  hardCap_ = 244000000 * (10**uint256(18));
  

   
  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) internal allowed;

   
  event Mint(address indexed to, uint256 amount);
  event PauseMinting(); 
  event UnPauseMinting(); 

   
  bool public pauseMinting = false;

   
  uint256 totalSupply_ = 9999999999999999999999;


   
  constructor() public {
    
  }


   
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length >= size + 4);
    _;
  } 
 

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function hardCap() public view returns (uint256) {
    return hardCap_;
  }
 
   
  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
    return _transfer(msg.sender, _to, _value); 
  }


   
  function _transfer(address _from, address _to, uint _value) internal returns (bool){
      require(_to != address(0));  
      require(_value <= balances[msg.sender]);   

       
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      emit Transfer(_from, _to, _value);
      return true;
  }


   
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {

    require(_to != address(0));                      
    require(_value <= balances[_from]);              
    require(_value <= allowed[_from][msg.sender]);   


     
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true; 
  }

   

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }



   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }



   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }



   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }



   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

 

   
  modifier canMint() {
    require(!pauseMinting);
    _;
  }
  

   
  function mint(address _to, uint256 _amount) onlyMintOwner canMint public returns (bool) {
    require(_to != address(0));  
    require(totalSupply_.add(_amount) <= hardCap_);

    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    emit Mint(_to, _amount); 
    emit Transfer(address(0), _to, _amount);
    return true;
  }



   
  function toggleMinting()  onlyOwner public {
    if(pauseMinting){
      pauseMinting = false;
      emit UnPauseMinting();
    }else{
      pauseMinting = true;
      emit PauseMinting();
    }     
  }


   
  function refundOtherTokens(address _recipient, ERC20 _token)  onlyOwner public {
    require(_token != this);
    uint256 balance = _token.balanceOf(this);
    require(_token.transfer(_recipient, balance));
  }

 
}