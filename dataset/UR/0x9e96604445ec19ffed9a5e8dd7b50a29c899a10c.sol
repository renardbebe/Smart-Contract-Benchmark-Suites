 

pragma solidity ^0.4.18;


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

contract Distributable is Ownable {

    address public distributor;

    function setDistributor(address _distributor) public onlyOwner {
        distributor = _distributor;
    }

    modifier onlyOwnerOrDistributor(){
        require(msg.sender == owner || msg.sender == distributor);
        _;
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

contract ERC223Interface {
    function transfer(address to, uint value, bytes data) returns (bool);
     
}


contract ERC223ReceivingContract {
 
    function tokenFallback(address _from, uint _value, bytes _data);
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



 
contract ERC223Token is ERC223Interface, StandardToken {
    using SafeMath for uint;
    bool public transfersEnabled = false;

     
    function transfer(address _to, uint _value, bytes _data) returns (bool) {
        require(transfersEnabled);
         
         
        uint codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if (codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transfer(address _to, uint _value) returns (bool) {
        require(transfersEnabled);
         
         
        bytes memory empty;
        return transfer(_to, _value, empty);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transfersEnabled);
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(transfersEnabled);
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        require(transfersEnabled);
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        require(transfersEnabled);
        return super.decreaseApproval(_spender, _subtractedValue);
    }

}

contract COSSToken is ERC223Token, Ownable, Distributable {

    event RevenueShareIdentifierCreated (
        address indexed _address,
        string _identifier);

    string public name    = "COSS";
    string public symbol  = "COSS";
    uint256 public decimals = 18;

    using SafeMath for uint;

    address public oldTokenAddress;

    mapping (address => string) public revenueShareIdentifierList;

    function COSSToken() {
        owner = msg.sender;
        totalSupply_ = 200000000 * (10 ** decimals);
    }

    function setOldTokenAddress(address _oldTokenAddress) public onlyOwner {
        oldTokenAddress = _oldTokenAddress;
    }

    function replaceToken(address[] _addresses) public onlyOwnerOrDistributor {
        uint256 addressCount = _addresses.length;
        for (uint256 i = 0; i < addressCount; i++) {
            address currentAddress = _addresses[i];
            uint256 balance = ERC20(oldTokenAddress).balanceOf(currentAddress);
            balances[currentAddress] = balance;
        }
    }
    
    function replaceTokenFix(address[] _addresses, uint256[] _balances) public onlyOwnerOrDistributor {
        uint256 addressCount = _addresses.length;
        for (uint256 i = 0; i < addressCount; i++) {
            address currentAddress = _addresses[i];
            uint256 balance = _balances[i];
            balances[currentAddress] = balance;
        }
    }

    function() payable {

    }

    function activateRevenueShareIdentifier(string _revenueShareIdentifier) {
        revenueShareIdentifierList[msg.sender] = _revenueShareIdentifier;
        RevenueShareIdentifierCreated(msg.sender, _revenueShareIdentifier);
    }

    function sendTokens(address _destination, address _token, uint256 _amount) public onlyOwnerOrDistributor {
         ERC20(_token).transfer(_destination, _amount);
    }

    function sendEther(address _destination, uint256 _amount) payable public onlyOwnerOrDistributor {
        _destination.transfer(_amount);
    }

    function setTransfersEnabled() public onlyOwner {
        transfersEnabled = true;
    }

}