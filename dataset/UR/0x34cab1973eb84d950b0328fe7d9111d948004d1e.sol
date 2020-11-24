 

pragma solidity ^0.4.21;

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
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
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
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

    mapping(address => mapping(address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
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

}

 
library LockAddressInfo {
    struct info {
        address _address;
        uint256 amount;
        bool isLocked;
        uint releaseTime;
    }
}


 
contract EDiamondToken is StandardToken, Ownable {

    using LockAddressInfo for LockAddressInfo.info;
    using SafeMath for uint256;

    string public name = "eDiamond";
    string public symbol = "EDD";
    uint public decimals = 18;
    uint public INITIAL_SUPPLY = 10900000000 * (10 ** decimals);  

     
    mapping(address => LockAddressInfo.info) LOCKED_ACCOUNTS;

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        setInitLockedAccount();
    }

     
    function setInitLockedAccount() internal {
        LOCKED_ACCOUNTS[0x18dd6FbE4000C1d707d61deBF5352ef86Cd7f12a].isLocked = true;
        LOCKED_ACCOUNTS[0x18dd6FbE4000C1d707d61deBF5352ef86Cd7f12a].amount = 10000 * (10 ** decimals);
        LOCKED_ACCOUNTS[0x18dd6FbE4000C1d707d61deBF5352ef86Cd7f12a].releaseTime = block.timestamp + 60 * 60 * 24 * 60;
    }

    function judgeEnableForTransfer(address _from, uint256 _value) public view returns (bool) {
        if (!LOCKED_ACCOUNTS[_from].isLocked || block.timestamp > LOCKED_ACCOUNTS[_from].releaseTime) {
            return true;
        }
        uint256 availableMaxTransferAmount = balances[_from].sub(LOCKED_ACCOUNTS[_from].amount);
        return availableMaxTransferAmount >= _value;
    }

    function addLockedAccount(address _to, uint256 _amount, uint _releaseTime) public onlyOwner returns (bool) {
        require(!LOCKED_ACCOUNTS[_to].isLocked);
        LOCKED_ACCOUNTS[_to].isLocked = true;
        LOCKED_ACCOUNTS[_to].amount = _amount;
        LOCKED_ACCOUNTS[_to].releaseTime = _releaseTime;
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(judgeEnableForTransfer(msg.sender, _value));
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(judgeEnableForTransfer(_from, _value));
        return super.transferFrom(_from, _to, _value);
    }

}