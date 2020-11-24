 

pragma solidity 0.4.25;


 
contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

     
    function claimOwnership() public onlyPendingOwner {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


 
contract Manageable is Ownable {
    mapping(address => bool) public listOfManagers;

    event ManagerAdded(address manager);
    event ManagerRemoved(address manager);

    modifier onlyManager() {
        require(listOfManagers[msg.sender]);
        _;
    }

    function addManager(address _manager) public onlyOwner returns (bool success) {
        require(_manager != address(0));
        require(!listOfManagers[_manager]);

        listOfManagers[_manager] = true;
        emit ManagerAdded(_manager);

        return true;
    }

    function removeManager(address _manager) public onlyOwner returns (bool) {
        require(listOfManagers[_manager]);

        listOfManagers[_manager] = false;
        emit ManagerRemoved(_manager);

        return true;
    }
}


 
contract Freezable is Manageable {
    mapping(address => bool) public freeze;

    event AccountFrozen(address account);
    event AccountUnfrozen(address account);

    modifier whenNotFrozen() {
        require(!freeze[msg.sender]);
        _;
    }

    function freezeAccount(address _account) public onlyManager returns (bool) {
        require(!freeze[_account]);

        freeze[_account] = true;
        emit AccountFrozen(_account);

        return true;
    }

    function freezeAccounts(address[] _accounts) public onlyManager returns (bool) {

        for (uint i = 0; i < _accounts.length; i++) {
            if (!freeze[_accounts[i]]) {
                freeze[_accounts[i]] = true;
                emit AccountFrozen(_accounts[i]);
            }
        }

        return true;
    }

    function unfreezeAccount (address _account) public onlyManager returns (bool) {
        require(freeze[_account]);

        freeze[_account] = false;
        emit AccountUnfrozen(_account);

        return true;
    }



    function unfreezeAccounts(address[] _accounts) public onlyManager returns (bool) {

        for (uint i = 0; i < _accounts.length; i++) {
            if (freeze[_accounts[i]]) {
                freeze[_accounts[i]] = false;
                emit AccountUnfrozen(_accounts[i]);
            }
        }

        return true;
    }
}


contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address who, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed who, address indexed spender, uint256 value);
}


contract Hearts is ERC20, Freezable {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;
    mapping(address => mapping (address => uint256)) public allowed;
    uint256 totalSupply_;

    string public name = hex"F09F929A";
    string public symbol = hex"F09F929A";
    uint8 public decimals = 18;

    constructor() public { }

     
    function mint(address _account, uint256 _amount) external onlyManager {
        require(_account != address(0));
        totalSupply_ = totalSupply_.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

     
    function multiMint(address[] _accounts, uint256[] _amounts) external onlyManager {
        require(_accounts.length > 0);
        for (uint i = 0; i < _accounts.length; i++) {
            totalSupply_ = totalSupply_.add(_amounts[i]);
            balances[_accounts[i]] = balances[_accounts[i]].add(_amounts[i]);
            emit Transfer(address(0), _accounts[i], _amounts[i]);
        }
    }

     
    function reclaimToken(ERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

     
    function transfer(address _to, uint256 _value) public whenNotFrozen returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotFrozen returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public whenNotFrozen returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _who, address _spender) public view returns (uint256) {
        return allowed[_who][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public whenNotFrozen returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotFrozen returns (bool) {
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