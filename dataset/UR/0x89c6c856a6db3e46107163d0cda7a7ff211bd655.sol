 

pragma solidity ^0.4.18;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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



 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
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





 
contract Allowable is Ownable {

     
    mapping (address => bool) public permissions;

     
    modifier isAllowed(address _operator) {
        require(permissions[_operator] || _operator == owner);
        _;
    }

     
    function allow(address _operator) external onlyOwner {
        permissions[_operator] = true;
    }

     
    function deny(address _operator) external onlyOwner {
        permissions[_operator] = false;
    }
}




 
contract Operable is Ownable {
    address public operator;

    event OperatorRoleTransferred(address indexed previousOperator, address indexed newOperator);


     
    function Operable() public {
        operator = msg.sender;
    }

     
    modifier onlyOperator() {
        require(msg.sender == operator || msg.sender == owner);
        _;
    }

     
    function transferOperatorRole(address newOperator) public onlyOwner {
        require(newOperator != address(0));
        OperatorRoleTransferred(operator, newOperator);
        operator = newOperator;
    }
}


 
contract DaricoEcosystemToken is BurnableToken, StandardToken, Allowable, Operable {
    using SafeMath for uint256;

     
    string public constant name= "Darico Ecosystem Coin";
     
    string public constant symbol= "DEC";
     
    uint256 public constant decimals = 18;

     
    bool public isActive = false;

     
    function DaricoEcosystemToken(address _saleWallet, 
                                  address _reserveWallet, 
                                  address _teamWallet, 
                                  address _otherWallet) public {
        totalSupply_ = uint256(120000000).mul(10 ** decimals);

        configureWallet(_saleWallet, uint256(72000000).mul(10 ** decimals));
        configureWallet(_reserveWallet, uint256(18000000).mul(10 ** decimals));
        configureWallet(_teamWallet, uint256(18000000).mul(10 ** decimals));
        configureWallet(_otherWallet, uint256(12000000).mul(10 ** decimals));
    }

      
    modifier whenActive(address _from){
        if (!permissions[_from]) {            
            require(isActive);            
        }
        _;
    }

     
    function activate() onlyOwner public {
        isActive = true;
    }

     
    function transfer(address _to, uint256 _value) public whenActive(msg.sender) returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenActive(_from) returns (bool) {        
        return super.transferFrom(_from, _to, _value);
    }

     
    function burn(uint256 _value) public onlyOperator {
        super.burn(_value);
    }

     
    function configureWallet(address _wallet, uint256 _amount) private {
        require(_wallet != address(0));
        permissions[_wallet] = true;
        balances[_wallet] = _amount;
        Transfer(address(0), _wallet, _amount);
    }
}