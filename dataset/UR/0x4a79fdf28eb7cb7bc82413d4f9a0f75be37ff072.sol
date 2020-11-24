 

pragma solidity ^0.4.24;

 

 
contract Ownable {
    address public owner;

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

 

contract RHEM {
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract Locker2 is Ownable {
    RHEM private _rhem;
    mapping(address => uint256) private _lockedBalances;
    bool private _isLocked = true;
    uint256 private _totalLockedBalance;

    event Add(address indexed to, uint256 value);
    event Unlock();

    constructor(address _t) public {
        require(_t != address(0));
        _rhem = RHEM(_t);
    }

     
    function rhem() public view returns(RHEM) {
        return _rhem;
    }

     
    function isLocked() public view returns(bool) {
        return _isLocked;
    }

     
    function totalLockedBalance() public view returns(uint256 balance) {
        return _totalLockedBalance;
    }

     
    function getContractRhemBalance() public view returns(uint256 balance) {
        return _rhem.balanceOf(address(this));
    }

     
    function lockedBalanceOf(address _beneficiary) public view returns(uint256 lockedBalance) {
        return _lockedBalances[_beneficiary];
    }

     
    function lockedBalancesOf(address[] _beneficiaries) public view returns(uint256[] lockedBalances) {
        uint i = 0;
        uint256[] memory amounts = new uint256[](_beneficiaries.length);

        for (i; i < _beneficiaries.length; i++) {
            amounts[i] = _lockedBalances[_beneficiaries[i]];
        }

        return amounts;
    }

     

     
    function addLockedBalance(address _beneficiary, uint256 _value) public onlyOwner returns(bool success) {
        require(_isLocked);
        require(_beneficiary != address(0));
        require(_value > 0);

        uint256 amount = _lockedBalances[_beneficiary];
        amount += _value;
        require(amount > 0);

        uint256 currentBalance = getContractRhemBalance();
        _totalLockedBalance += _value;
        require(_totalLockedBalance > 0);
        require(_totalLockedBalance <= currentBalance);

        _lockedBalances[_beneficiary] = amount;
        emit Add(_beneficiary, _value);

        return true;
    }

    function addLockedBalances(address[] _beneficiaries, uint256[] _amounts) public onlyOwner returns(bool success) {
        require(_isLocked);

        uint i = 0;

        for (i; i < _beneficiaries.length; i++) {
            addLockedBalance(_beneficiaries[i], _amounts[i]);
        }

        return true;
    }

     

     
    function unlock() public onlyOwner {
        require(_isLocked);

        _isLocked = false;

        emit Unlock();
    }

     

     
    function releaseBalance() public returns(bool success) {
        require(!_isLocked);
        require(_lockedBalances[msg.sender] > 0);

        uint256 amount = _lockedBalances[msg.sender];
        delete _lockedBalances[msg.sender];

        _totalLockedBalance -= amount;

        require(_rhem.transfer(msg.sender, amount));

        return true;
    }

     
    function releaseBalanceFrom(address _beneficiary) public onlyOwner returns(bool success) {
        require(!_isLocked);
        require(_lockedBalances[_beneficiary] > 0);

        uint256 amount = _lockedBalances[_beneficiary];
        delete _lockedBalances[_beneficiary];

        _totalLockedBalance -= amount;

        require(_rhem.transfer(_beneficiary, amount));

        return true;
    }

     
    function releaseBalancesFrom(address[] _beneficiaries) public onlyOwner returns(bool success) {
        require(!_isLocked);

        uint i = 0;

        for (i; i < _beneficiaries.length; i++) {
            releaseBalanceFrom(_beneficiaries[i]);
        }

        return true;
    }
}