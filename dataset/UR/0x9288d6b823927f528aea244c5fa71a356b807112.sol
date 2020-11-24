 

pragma solidity ^0.4.24;

 

 
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
    address public collector;
    address public distributor;
    address public freezer;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event CollectorshipTransferred(address indexed previousCollector, address indexed newCollector);
    event DistributorshipTransferred(address indexed previousDistributor, address indexed newDistributor);
    event FreezershipTransferred(address indexed previousFreezer, address indexed newFreezer);

     
    constructor() public {
        owner = msg.sender;
        collector = msg.sender;
        distributor = msg.sender;
        freezer = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyCollector() {
        require(msg.sender == collector);
        _;
    }

     
    modifier onlyDistributor() {
        require(msg.sender == distributor);
        _;
    }

     
    modifier onlyFreezer() {
        require(msg.sender == freezer);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(isNonZeroAccount(newOwner));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

     
    function transferCollectorship(address newCollector) onlyOwner public {
        require(isNonZeroAccount(newCollector));
        emit CollectorshipTransferred(collector, newCollector);
        collector = newCollector;
    }

     
    function transferDistributorship(address newDistributor) onlyOwner public {
        require(isNonZeroAccount(newDistributor));
        emit DistributorshipTransferred(distributor, newDistributor);
        distributor = newDistributor;
    }

     
    function transferFreezership(address newFreezer) onlyOwner public {
        require(isNonZeroAccount(newFreezer));
        emit FreezershipTransferred(freezer, newFreezer);
        freezer = newFreezer;
    }

     
    function isNonZeroAccount(address _addr) internal pure returns (bool is_nonzero_account) {
        return _addr != address(0);
    }
}

 
contract ERC20 {
    uint public totalSupply;

    function balanceOf(address who) public view returns (uint);
    function totalSupply() public view returns (uint256 _supply);
    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
contract JCT is ERC20, Ownable {
    using SafeMath for uint256;

    string public name = "JCT";
    string public symbol = "JCT";
    uint8 public decimals = 8;
    uint256 public totalSupply = 18e7 * 1e8;
    address public relay;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public unlockUnixTime;

    event FrozenFunds(address indexed target, bool frozen);
    event LockedFunds(address indexed target, uint256 locked);

     
    constructor(address founder, address _relay) public {
        owner = founder;
        collector = founder;
        distributor = founder;
        freezer = founder;

        balanceOf[founder] = totalSupply;

        relay = _relay;
    }

    modifier onlyAuthorized() {
        require(msg.sender == relay || checkMessageData(msg.sender));
        _;
    }

    function name() public view returns (string _name) {
        return name;
    }

    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

     
    function freezeAccounts(address[] targets, bool isFrozen) onlyFreezer public {
        require(targets.length > 0);

        for (uint j = 0; j < targets.length; j++) {
            require(isNonZeroAccount(targets[j]));
            frozenAccount[targets[j]] = isFrozen;
            emit FrozenFunds(targets[j], isFrozen);
        }
    }

     
    function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
        require(hasSameArrayLength(targets, unixTimes));

        for(uint j = 0; j < targets.length; j++){
            require(unlockUnixTime[targets[j]] < unixTimes[j]);
            unlockUnixTime[targets[j]] = unixTimes[j];
            emit LockedFunds(targets[j], unixTimes[j]);
        }
    }

     
    function transfer(address _to, uint _value) public returns (bool success) {
        require(hasEnoughBalance(msg.sender, _value)
                && isAvailableAccount(msg.sender)
                && isAvailableAccount(_to));

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(isNonZeroAccount(_to)
                && hasEnoughBalance(_from, _value)
                && hasEnoughAllowance(_from, msg.sender, _value)
                && isAvailableAccount(_from)
                && isAvailableAccount(_to));

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveTokenCollection(address _claimedSender, address _spender, uint256 _value) onlyAuthorized public returns (bool success) {
        require(isAvailableAccount(_claimedSender)
                && isAvailableAccount(msg.sender));
        allowance[_claimedSender][_spender] = _value;
        emit Approval(_claimedSender, _spender, _value);
        return true;
    }    

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

     
    function collectTokens(address[] addresses, uint[] amounts) onlyCollector public returns (bool) {
        require(hasSameArrayLength(addresses, amounts));

        uint256 totalAmount = 0;

        for (uint j = 0; j < addresses.length; j++) {
            require(amounts[j] > 0
                    && isNonZeroAccount(addresses[j])
                    && isAvailableAccount(addresses[j])
                    && hasEnoughAllowance(addresses[j], msg.sender, amounts[j]));

            require(hasEnoughBalance(addresses[j], amounts[j]));
            balanceOf[addresses[j]] = balanceOf[addresses[j]].sub(amounts[j]);
            allowance[addresses[j]][msg.sender] = allowance[addresses[j]][msg.sender].sub(amounts[j]);
            totalAmount = totalAmount.add(amounts[j]);
            emit Transfer(addresses[j], msg.sender, amounts[j]);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].add(totalAmount);
        return true;
    }

     
    function distributeTokens(address[] addresses, uint[] amounts) onlyDistributor public returns (bool) {
        require(hasSameArrayLength(addresses, amounts)
                && isAvailableAccount(msg.sender));

        uint256 totalAmount = 0;

        for(uint j = 0; j < addresses.length; j++){
            require(amounts[j] > 0
                    && isNonZeroAccount(addresses[j])
                    && isAvailableAccount(addresses[j]));

            totalAmount = totalAmount.add(amounts[j]);
        }
        require(hasEnoughBalance(msg.sender, totalAmount));

        for (j = 0; j < addresses.length; j++) {
            balanceOf[addresses[j]] = balanceOf[addresses[j]].add(amounts[j]);
            emit Transfer(msg.sender, addresses[j], amounts[j]);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }

     
    function isAvailableAccount(address _addr) public view returns (bool is_valid_account) {
        return isUnLockedAccount(_addr) && isUnfrozenAccount(_addr);
    }

     
    function isUnLockedAccount(address _addr) public view returns (bool is_unlocked_account) {
        return now > unlockUnixTime[_addr];
    }

     
    function isUnfrozenAccount(address _addr) public view returns (bool is_unfrozen_account) {
        return frozenAccount[_addr] == false;
    }

     
    function hasEnoughBalance(address _addr, uint256 _value) public view returns (bool has_enough_balance) {
        return _value > 0 && balanceOf[_addr] >= _value;
    }

     
    function hasEnoughAllowance(address _owner, address _spender, uint256 _value) public view returns (bool has_enough_balance) {
        return allowance[_owner][_spender] >= _value;
    }    

     
    function hasSameArrayLength(address[] addresses, uint[] amounts) private pure returns (bool has_same_array_length) {
        return addresses.length > 0 && addresses.length == amounts.length;
    }

     
     
    function checkMessageData(address a) private pure returns (bool t) {
        if (msg.data.length < 36) return false;
        assembly {
            let mask := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            t := eq(a, and(mask, calldataload(4)))
        }
    }    
}