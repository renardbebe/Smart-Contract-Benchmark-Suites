 

pragma solidity ^0.4.19;

 
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




 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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



 
contract Flex is StandardToken, Ownable {
  string public name = 'Flex';
  string public symbol = 'FLX';
  uint public decimals = 18;
  uint public INITIAL_SUPPLY = 0;   

   
  address[] mintDelegates;    
  address[] burnDelegates;    

   
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed burner, uint256 value);
  event ApproveMintDelegate(address indexed mintDelegate);
  event RevokeMintDelegate(address indexed mintDelegate);
  event ApproveBurnDelegate(address indexed burnDelegate);
  event RevokeBurnDelegate(address indexed burnDelegate);


   
  function Flex () public {
    totalSupply_ = INITIAL_SUPPLY;
  }


   
  modifier onlyOwnerOrMintDelegate() {
    bool allowedToMint = false;

    if(msg.sender==owner) {
      allowedToMint = true;
    }
    else {
      for(uint i=0; i<mintDelegates.length; i++) {
        if(mintDelegates[i]==msg.sender) {
          allowedToMint = true;
          break;
        }
      }
    }

    require(allowedToMint==true);
    _;
  }

   
  modifier onlyOwnerOrBurnDelegate() {
    bool allowedToBurn = false;

    if(msg.sender==owner) {
      allowedToBurn = true;
    }
    else {
      for(uint i=0; i<burnDelegates.length; i++) {
        if(burnDelegates[i]==msg.sender) {
          allowedToBurn = true;
          break;
        }
      }
    }

    require(allowedToBurn==true);
    _;
  }

   
  function getMintDelegates() public view returns (address[]) {
    return mintDelegates;
  }

   
  function getBurnDelegates() public view returns (address[]) {
    return burnDelegates;
  }

   
  function approveMintDelegate(address _mintDelegate) onlyOwner public returns (bool) {
    bool delegateFound = false;
    for(uint i=0; i<mintDelegates.length; i++) {
      if(mintDelegates[i]==_mintDelegate) {
        delegateFound = true;
        break;
      }
    }

    if(!delegateFound) {
      mintDelegates.push(_mintDelegate);
    }

    ApproveMintDelegate(_mintDelegate);
    return true;
  }

   
  function revokeMintDelegate(address _mintDelegate) onlyOwner public returns (bool) {
    uint length = mintDelegates.length;
    require(length > 0);

    address lastDelegate = mintDelegates[length-1];
    if(_mintDelegate == lastDelegate) {
      delete mintDelegates[length-1];
      mintDelegates.length--;
    }
    else {
       
      for(uint i=0; i<length; i++) {
        if(mintDelegates[i]==_mintDelegate) {
          mintDelegates[i] = lastDelegate;
          delete mintDelegates[length-1];
          mintDelegates.length--;
          break;
        }
      }
    }

    RevokeMintDelegate(_mintDelegate);
    return true;
  }

   
  function approveBurnDelegate(address _burnDelegate) onlyOwner public returns (bool) {
    bool delegateFound = false;
    for(uint i=0; i<burnDelegates.length; i++) {
      if(burnDelegates[i]==_burnDelegate) {
        delegateFound = true;
        break;
      }
    }

    if(!delegateFound) {
      burnDelegates.push(_burnDelegate);
    }

    ApproveBurnDelegate(_burnDelegate);
    return true;
  }

   
  function revokeBurnDelegate(address _burnDelegate) onlyOwner public returns (bool) {
    uint length = burnDelegates.length;
    require(length > 0);

    address lastDelegate = burnDelegates[length-1];
    if(_burnDelegate == lastDelegate) {
      delete burnDelegates[length-1];
      burnDelegates.length--;
    }
    else {
       
      for(uint i=0; i<length; i++) {
        if(burnDelegates[i]==_burnDelegate) {
          burnDelegates[i] = lastDelegate;
          delete burnDelegates[length-1];
          burnDelegates.length--;
          break;
        }
      }
    }

    RevokeBurnDelegate(_burnDelegate);
    return true;
  }


   
  function mint(uint256 _amount) onlyOwnerOrMintDelegate public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[msg.sender] = balances[msg.sender].add(_amount);

     
    Mint(msg.sender, _amount);
    Transfer(address(0), msg.sender, _amount);

    return true;
  }

   
  function burn(uint256 _value) onlyOwnerOrBurnDelegate public returns (bool) {
    require(_value <= balances[msg.sender]);

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);

     
    Burn(burner, _value);
    Transfer(burner, address(0), _value);

    return true;
  }
}