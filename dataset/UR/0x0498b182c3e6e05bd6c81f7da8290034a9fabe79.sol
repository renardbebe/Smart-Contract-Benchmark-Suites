 

pragma solidity ^0.4.15;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
library Utils {

     
    function isContract(address _addr) constant internal returns (bool) {
        uint size;

        assembly {
            size := extcodesize(_addr)
        }

        return (_addr == 0) ? false : size > 0;
    }
}

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
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

   
  function transferOwnership(address newOwner) onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() onlyPendingOwner {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = 0x0;
  }
}

 
contract Burnable {

    event Burn(address who, uint256 amount);

    modifier onlyBurners {
        require(isBurner(msg.sender));
        _;
    }
    function burn(address target, uint256 amount) external onlyBurners returns (bool);
    function setBurner(address who, bool auth) returns (bool);
    function isBurner(address who) constant returns (bool);
}

 
contract Lockable {

    uint256 public lockExpiration;

     
    function Lockable(uint256 _lockExpiration) {
        lockExpiration = _lockExpiration;
    }

    function isLocked(address who) constant returns (bool);
}

 
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract LWFToken is ERC20, Burnable, Lockable(1535760000), Claimable {
using SafeMath for uint256;

     
    struct Snapshot {
        uint256 block;
        uint256 balance;
    }

    struct Account {
        uint256 balance;
        Snapshot[] history;  
        mapping(address => uint256) allowed;
        bool isSet;
    }

    address[] accountsList;

    mapping(address => Account) accounts;

    bool public maintenance;

     
    mapping(address => bool) burners;  
    bool public burnAllowed;

     
    mapping(address => bool) locked;  

     
    string public name = "LWF";
    string public symbol = "LWF";
    string public version = "release-1.1";

    uint256 public decimals = 2;

     
    modifier disabledInMaintenance() {
        if (maintenance)
            revert();
        _;
    }

     
    modifier onlyUnderMaintenance() {
        if (!maintenance)
            revert();
        _;
    }

     
    modifier trackNewUsers (address _recipient) {
        if (!accounts[_recipient].isSet) {
            accounts[_recipient].isSet = true;
            accountsList.push(_recipient);
        }
        _;
    }

     
    function LWFToken() {
        totalSupply = 30 * (10**6) * (10**decimals);

        burnAllowed = true;
        maintenance = false;

        require(_setup(0x927Dc9F1520CA2237638D0D3c6910c14D9a285A8, 2700000000, false));

        require(_setup(0x7AE7155fF280D5da523CDDe3855b212A8381F9E8, 30000000, false));
        require(_setup(0x796d507A80B13c455c2C1D121eDE4bccca59224C, 263000000, true));

        require(_setup(0xD77d620EC9774295ad8263cBc549789EE39C0BC0, 1000000, true));
        require(_setup(0x574B35eC5650BE0aC217af9AFCfe1c7a3Ff0BecD, 1000000, true));
        require(_setup(0x7c5a61f34513965AA8EC090011721a0b0A9d4D3a, 1000000, true));
        require(_setup(0x0cDBb03DD2E8226A6c3a54081E93750B4f85DB92, 1000000, true));
        require(_setup(0x03b6cF4A69fF306B3df9B9CeDB6Dc4ED8803cBA7, 1000000, true));
        require(_setup(0xe2f7A1218E5d4a362D1bee8d2eda2cd285aAE87A, 1000000, true));
        require(_setup(0xAcceDE2eFD2765520952B7Cb70406A43FC17e4fb, 1000000, true));
    }

     
    function accountsListLength() external constant returns (uint256) {
        return accountsList.length;
    }

     
    function getAccountAddress(uint256 _index) external constant returns (address) {
        return accountsList[_index];
    }

     
    function isSet(address _address) external constant returns (bool) {
        return accounts[_address].isSet;
    }

     
    function balanceAt(address _owner, uint256 _block) external constant returns (uint256 balance) {
        uint256 i = accounts[_owner].history.length;
        do {
            i--;
        } while (i > 0 && accounts[_owner].history[i].block > _block);
        uint256 matchingBlock = accounts[_owner].history[i].block;
        uint256 matchingBalance = accounts[_owner].history[i].balance;
        return (i == 0 && matchingBlock > _block) ? 0 : matchingBalance;
    }

     
    function burn(address _address, uint256 _amount) onlyBurners disabledInMaintenance external returns (bool) {
        require(burnAllowed);

        var _balance = accounts[_address].balance;
        accounts[_address].balance = _balance.sub(_amount);

         
        require(_updateHistory(_address));

        totalSupply = totalSupply.sub(_amount);
        Burn(_address,_amount);
        Transfer(_address, 0x0, _amount);
        return true;
    }

     
    function transfer(address _recipient, uint256 _amount) returns (bool) {
        require(!isLocked(msg.sender));
        return _transfer(msg.sender,_recipient,_amount);
    }

     
    function transferFrom(address _from, address _to, uint256 _amount) returns (bool) {
        require(!isLocked(_from));
        require(_to != address(0));

        var _allowance = accounts[_from].allowed[msg.sender];

         
         
        accounts[_from].allowed[msg.sender] = _allowance.sub(_amount);
        return _transfer(_from, _to, _amount);
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {
         
         
         
        require((_value == 0) || (accounts[msg.sender].allowed[_spender] == 0));

        accounts[msg.sender].allowed[_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function increaseApproval(address _spender, uint _addedValue) returns (bool success) {
        uint256 _allowance = accounts[msg.sender].allowed[_spender];
        accounts[msg.sender].allowed[_spender] = _allowance.add(_addedValue);
        Approval(msg.sender, _spender, accounts[msg.sender].allowed[_spender]);
        return true;
    }

     
    function decreaseApproval (address _spender, uint _subtractedValue) returns (bool success) {
        uint oldValue = accounts[msg.sender].allowed[_spender];
        accounts[msg.sender].allowed[_spender] = (_subtractedValue > oldValue) ? 0 : oldValue.sub(_subtractedValue);
        Approval(msg.sender, _spender, accounts[msg.sender].allowed[_spender]);
        return true;
    }

     
    function setBurner(address _address, bool _auth) onlyOwner returns (bool) {
        require(burnAllowed);
        assert(Utils.isContract(_address));
        burners[_address] = _auth;
        return true;
    }

     
    function isBurner(address _address) constant returns (bool) {
        return burnAllowed ? burners[_address] : false;
    }

     
    function isLocked(address _address) constant returns (bool) {
        return now >= lockExpiration ? false : locked[_address];
    }

     
    function burnFeatureDeactivation() onlyOwner returns (bool) {
        require(burnAllowed);
        burnAllowed = false;
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return accounts[_owner].balance;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return accounts[_owner].allowed[_spender];
    }

     
    function setMaintenance(bool _state) onlyOwner returns (bool) {
        maintenance = _state;
        return true;
    }

     
    function maintenanceSetAccountsList(address[] _accountsList) onlyOwner onlyUnderMaintenance returns (bool) {
        accountsList = _accountsList;
        return true;
    }

     
    function maintenanceDeactivateUser(address _user) onlyOwner onlyUnderMaintenance returns (bool) {
        accounts[_user].isSet = false;
        delete accounts[_user].history;
        return true;
    }

     
    function _setup(address _address, uint256 _amount, bool _lock) internal returns (bool) {
        locked[_address] = _lock;
        accounts[_address].balance = _amount;
        accounts[_address].isSet = true;
        require(_updateHistory(_address));
        accountsList.push(_address);
        Transfer(this, _address, _amount);
        return true;
    }

     
    function _transfer(address _from, address _recipient, uint256 _amount) internal disabledInMaintenance trackNewUsers(_recipient) returns (bool) {

        accounts[_from].balance = balanceOf(_from).sub(_amount);
        accounts[_recipient].balance = balanceOf(_recipient).add(_amount);

         
        require(_updateHistory(_from));
        require(_updateHistory(_recipient));

        Transfer(_from, _recipient, _amount);
        return true;
    }

     
    function _updateHistory(address _address) internal returns (bool) {
        accounts[_address].history.push(Snapshot(block.number, balanceOf(_address)));
        return true;
    }

}