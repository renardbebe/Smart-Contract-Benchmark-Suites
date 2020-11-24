 

pragma solidity ^0.4.13;

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

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}

contract LuckchemyToken is BurnableToken, StandardToken, Claimable {

    bool public released = false;

    string public constant name = "Luckchemy";

    string public constant symbol = "LUK";

    uint8 public constant decimals = 8;

    uint256 public CROWDSALE_SUPPLY;

    uint256 public OWNERS_AND_PARTNERS_SUPPLY;

    address public constant OWNERS_AND_PARTNERS_ADDRESS = 0x603a535a1D7C5050021F9f5a4ACB773C35a67602;

     
    uint256 public addressCount = 0;

     
    mapping(uint256 => address) public addressMap;
    mapping(address => bool) public addressAvailabilityMap;

     
    mapping(address => bool) public blacklist;

     
    address public serviceAgent;

    event Release();
    event BlacklistAdd(address indexed addr);
    event BlacklistRemove(address indexed addr);

     
    modifier canTransfer() {
        require(released || msg.sender == owner);
        _;
    }

     
    modifier onlyServiceAgent(){
        require(msg.sender == serviceAgent);
        _;
    }


    function LuckchemyToken() public {

        totalSupply_ = 1000000000 * (10 ** uint256(decimals));
        CROWDSALE_SUPPLY = 700000000 * (10 ** uint256(decimals));
        OWNERS_AND_PARTNERS_SUPPLY = 300000000 * (10 ** uint256(decimals));

        addAddressToUniqueMap(msg.sender);
        addAddressToUniqueMap(OWNERS_AND_PARTNERS_ADDRESS);

        balances[msg.sender] = CROWDSALE_SUPPLY;

        balances[OWNERS_AND_PARTNERS_ADDRESS] = OWNERS_AND_PARTNERS_SUPPLY;

        owner = msg.sender;

        Transfer(0x0, msg.sender, CROWDSALE_SUPPLY);

        Transfer(0x0, OWNERS_AND_PARTNERS_ADDRESS, OWNERS_AND_PARTNERS_SUPPLY);
    }

    function transfer(address _to, uint256 _value) public canTransfer returns (bool success) {
         
        addAddressToUniqueMap(_to);

         
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool success) {
         
        addAddressToUniqueMap(_to);

         
        return super.transferFrom(_from, _to, _value);
    }

     
    function releaseTokenTransfer() public onlyOwner {
        released = true;
        Release();
    }

     
    function addBlacklistItem(address _blackAddr) public onlyServiceAgent {
        blacklist[_blackAddr] = true;

        BlacklistAdd(_blackAddr);
    }

     
    function removeBlacklistItem(address _blackAddr) public onlyServiceAgent {
        delete blacklist[_blackAddr];
    }

     
    function addAddressToUniqueMap(address _addr) private returns (bool) {
        if (addressAvailabilityMap[_addr] == true) {
            return true;
        }

        addressAvailabilityMap[_addr] = true;
        addressMap[addressCount++] = _addr;

        return true;
    }

     
    function getUniqueAddressByIndex(uint256 _addressIndex) public view returns (address) {
        return addressMap[_addressIndex];
    }

     
    function changeServiceAgent(address _addr) public onlyOwner {
        serviceAgent = _addr;
    }

}