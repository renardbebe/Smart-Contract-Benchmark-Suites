 

pragma solidity 0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

   
contract ForeignToken {
  function balanceOf(address _owner) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
}

  contract Eurno is ERC20Basic, Ownable, ForeignToken {
    using SafeMath for uint256;

    string public constant name = "Eurno";
    string public constant symbol = "ENO";
    uint public constant decimals = 8;
    uint256 public totalSupply = 28e14;
    uint256 internal functAttempts;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);  
    event Burn(address indexed burner, uint256 value);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;
   
     
    modifier onlyOnce(){
        require(functAttempts <= 0);
        _;
    }

   
  constructor() public {
    balances[msg.sender] = balances[msg.sender].add(totalSupply);  
    emit Transfer(this, owner, totalSupply);  
  }
  
   
  function totalSupply() public view returns (uint256) {
    return totalSupply;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  
   
  function distAirdrop(address _to, uint256 _value) onlyOwner onlyOnce public returns (bool) {
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    functAttempts = 1;
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
  
    
  function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
    ForeignToken token = ForeignToken(_tokenContract);
    uint256 amount = token.balanceOf(address(this));
    return token.transfer(owner, amount);
    }

   
  function() public payable {
  }
  
   
  function withdraw() onlyOwner public {
    uint256 etherBalance = address(this).balance;
    owner.transfer(etherBalance);
    }
    
   
  function burn(uint256 _value) onlyOwner public {
    _burn(msg.sender, _value);
  }
  
   
  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }

}