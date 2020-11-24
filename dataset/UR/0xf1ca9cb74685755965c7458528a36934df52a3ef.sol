 

pragma solidity 0.4.24;


 
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

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
}


 
 
 
contract Ownable {
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


 
 
 
contract ERC20Basic {
    event Transfer(address indexed from, address indexed to, uint value);

    function totalSupply() public view returns (uint256 supply);

    function balanceOf(address who) public view returns (uint256 balance);

    function transfer(address to, uint256 value) public returns (bool success);
}


 
 
contract ERC20 is ERC20Basic {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256 remaining);

    function transferFrom(address from, address to, uint256 value) public returns (bool success);

    function approve(address spender, uint256 value) public returns (bool success);
}


 
 
contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;

     
    modifier onlyPayloadSize(uint256 size) {
        require(!(msg.data.length < size + 4));
        _;
    }

     
     
     
    function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}


 
 
 
 
contract StandardToken is BasicToken, ERC20 {
    mapping(address => mapping(address => uint256)) public allowed;
    uint256 public constant MAX_UINT256 = 2 ** 256 - 1;

     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool success) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        uint256 _allowance = allowed[_from][msg.sender];
        require(_value <= _allowance);

         
        if (_allowance < MAX_UINT256)
            allowed[_from][msg.sender] = _allowance.sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
     
     
     
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}


 
 
 
 
contract UpgradedStandardToken is StandardToken {
    function transferByLegacy(address from, address to, uint256 value) public returns (bool success);

    function transferFromByLegacy(address sender, address from, address spender, uint256 value) public returns (bool success);

    function approveByLegacy(address from, address spender, uint256 value) public returns (bool success);

    function increaseApprovalByLegacy(address from, address spender, uint256 value) public returns (bool success);

    function decreaseApprovalByLegacy(address from, address spender, uint256 value) public returns (bool success);
}


 
 
 
 
contract UpgradeableStandardToken is StandardToken {
    address public upgradeAddress;
    uint256 public upgradeTimestamp;

     
    constructor() public {
        upgradeAddress = address(0);
         
        upgradeTimestamp = MAX_UINT256;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (now > upgradeTimestamp) {
            return UpgradedStandardToken(upgradeAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (now > upgradeTimestamp) {
            return UpgradedStandardToken(upgradeAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

     
    function balanceOf(address who) public view returns (uint256 balance) {
        if (now > upgradeTimestamp) {
            return UpgradedStandardToken(upgradeAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

     
    function approve(address _spender, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool success) {
        if (now > upgradeTimestamp) {
            return UpgradedStandardToken(upgradeAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        if (now > upgradeTimestamp) {
            return UpgradedStandardToken(upgradeAddress).increaseApprovalByLegacy(msg.sender, _spender, _addedValue);
        } else {
            return super.increaseApproval(_spender, _addedValue);
        }
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        if (now > upgradeTimestamp) {
            return UpgradedStandardToken(upgradeAddress).decreaseApprovalByLegacy(msg.sender, _spender, _subtractedValue);
        } else {
            return super.decreaseApproval(_spender, _subtractedValue);
        }
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        if (now > upgradeTimestamp) {
            return StandardToken(upgradeAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

     
    function upgrade(address _upgradeAddress) public onlyOwner {
        require(now < upgradeTimestamp);
        require(_upgradeAddress != address(0));

        upgradeAddress = _upgradeAddress;
        upgradeTimestamp = now.add(12 weeks);
        emit Upgrading(_upgradeAddress, upgradeTimestamp);
    }

     
    event Upgrading(address newAddress, uint256 timestamp);
}


 
contract AVINOCToken is UpgradeableStandardToken {
    string public constant name = "AVINOC Token";
    string public constant symbol = "AVINOC";
    uint8 public constant decimals = 18;
    uint256 public constant decimalFactor = 10 ** uint256(decimals);
    uint256 public constant TOTAL_SUPPLY = 1000000000 * decimalFactor;

    constructor() public {
        balances[owner] = TOTAL_SUPPLY;
    }

     
    function() public payable {
        revert();
    }

     
    function totalSupply() public view returns (uint256) {
        return TOTAL_SUPPLY;
    }
}