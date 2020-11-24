 

pragma solidity ^0.4.21;

 
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
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract OwnedByContract is Ownable{
    address public ownerContract;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwnerContract() {
        require(msg.sender == ownerContract);
        _;
    }

     
    function setMinterContract(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        require(isContract(newOwner));
        emit OwnershipTransferred(ownerContract, newOwner);
        ownerContract = newOwner;
    }

     
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { 
          size := extcodesize(addr)
        }
        return size > 0;
    }

}



 
contract MintableToken is StandardToken, OwnedByContract {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _amount) onlyOwnerContract canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() onlyOwnerContract canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
}

contract KEDToken is MintableToken {
    string public name = "KED Token";
    string public symbol = "KED";
    uint8 public decimals = 18;
    
    address private constant COMPANY_ADDRESS = 0x5EE25f44f1BbC961f1a85E83Dfd874588D47Cf56;
    address private constant REWARDS_ADDRESS = 0x364c74d196f04A6C3245B6Dab4E3ffEd73e1d49c;
    address private constant ADVISORS_ADDRESS = 0xdcf8c005a59Fdd3C234e678E1D73fbefF5168266;
    address private constant TEAM_ADDRESS = 0xDDfb1cf29156Fee19749a43305e7fda4B6D5ed24;
    address private constant PRE_ICO_ADDRESS = 0xaDceab807a8266E17bDfb80a183f203d719fD022;
    address private constant ICO_ADDRESS = 0x11c1696d460d71b7A8B3571b7A9967539e69bEa2;
    
    uint256 private constant COMPANY_AMOUNT = 66000000;
    uint256 private constant REWARDS_AMOUNT = 30000000;
    uint256 private constant ADVISORS_AMOUNT = 21000000;
    uint256 private constant TEAM_AMOUNT = 33000000;
    uint256 private constant PRE_ICO_AMOUNT = 50000000;
    uint256 private constant ICO_AMOUNT = 100000000;
    uint256 private constant SUPPLY_AMOUNT = 300000000;
    
    function KEDToken() public {
        uint256 decimalPlace = 10 ** uint(decimals);
        
        totalSupply_ = SUPPLY_AMOUNT * decimalPlace;
        
        initialTransfer(COMPANY_ADDRESS, COMPANY_AMOUNT, decimalPlace);
        initialTransfer(REWARDS_ADDRESS, REWARDS_AMOUNT, decimalPlace);
        initialTransfer(ADVISORS_ADDRESS, ADVISORS_AMOUNT, decimalPlace);
        initialTransfer(TEAM_ADDRESS, TEAM_AMOUNT, decimalPlace);
        initialTransfer(PRE_ICO_ADDRESS, PRE_ICO_AMOUNT, decimalPlace);
        initialTransfer(ICO_ADDRESS, ICO_AMOUNT, decimalPlace);
    }
    
     
    function initialTransfer(address _to, uint256 _amount, uint256 _decimalPlace) private { 
        balances[_to] = _amount.mul(_decimalPlace);
        Transfer(address(0), _to, balances[_to]);
    }
}