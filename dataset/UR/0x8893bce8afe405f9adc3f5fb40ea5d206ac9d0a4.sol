 

pragma solidity ^0.5.0;

 
library SafeMath {
     
     function add(uint256 a, uint256 b) internal pure returns (uint256) {
         uint256 c = a + b;
         require(c >= a, "SafeMath: addition overflow");

         return c;
     }

     
     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
         require(b <= a, "SafeMath: subtraction overflow");
         uint256 c = a - b;

         return c;
     }

     
     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
     function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
         require(b != 0, "SafeMath: modulo by zero");
         return a % b;
     }
}

contract Six {

    using SafeMath for uint256;

 
uint8 public decimals = 18;
string public name = "SIX-Token";
string public symbol = "SIX";
uint256 public totalSupply= 666 *(10**uint256(decimals));


mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;


 
address public owner;

 
bool public mintingFinished = false;

 
event Transfer(address indexed from, address indexed to, uint256 value);
event Mint(address indexed minter, uint256 value);
event Burn(address indexed from, uint256 value);
event Approval(address indexed _owner, address indexed _spender, uint256 value);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event MintFinished();

     
     constructor() public {
        owner = address(0x04a9A45b18d568C2eBDb78C92d16821f9ED97F8F);
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0),owner,totalSupply);
    }

   

  function transfer(address _to, uint256 _value) public returns (bool){

      require(_to != address(0));
      require(_value <= balanceOf[msg.sender]);
      balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
      balanceOf[_to] = balanceOf[_to].add(_value);
      emit Transfer(msg.sender, _to, _value);
      return true;
  }


 

function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    
require(_to != address(0));
require(_value <= allowance[_from][msg.sender]);
require(_value <= balanceOf[_from]);
allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
balanceOf[_from] = balanceOf[_from].sub(_value);
balanceOf[_to] = balanceOf[_to].add(_value);
emit Transfer(_from, _to, _value);
return true;
}

 
function approve(address _spender, uint256 _value) public returns (bool) {
    
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
}

 
function burn(uint256 _value) public returns (bool) {
    
    require(balanceOf[msg.sender] >= _value);
    balanceOf[msg.sender] =balanceOf[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
}

 
function mint(uint256 _value) public returns (bool) {
    require(!mintingFinished);
    require(msg.sender == owner);
    balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
    totalSupply = totalSupply.add(_value);
    emit Mint(msg.sender, _value);
    emit Transfer(address(0),msg.sender,_value);
    return true;
}

 

function finishMinting() public returns (bool) {
    require(msg.sender == owner);
    require(!mintingFinished);
    mintingFinished = true;
    emit MintFinished();
    return true;
}



 
function transferOwnership(address _newOwner) public {
    require(msg.sender == owner);
    owner = _newOwner;
    emit OwnershipTransferred(msg.sender,owner);
}
}