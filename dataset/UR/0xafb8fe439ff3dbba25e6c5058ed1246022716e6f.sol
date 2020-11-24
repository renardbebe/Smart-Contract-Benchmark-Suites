 

pragma solidity ^0.5.2;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

 
contract CryptoCardsPayroll is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    event PayeeAdded(address account, uint256 shares);
    event PayeeUpdated(address account, uint256 sharesAdded, uint256 totalShares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    uint256 private _totalReleasedAllTime;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

     
    constructor () public {}

     
    function () external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

     
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

     
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

     
    function totalReleasedAllTime() public view returns (uint256) {
        return _totalReleasedAllTime;
    }

     
    function totalFunds() public view returns (uint256) {
        return address(this).balance;
    }

     
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

     
    function sharePercentage(address account) public view returns (uint256) {
        if (_totalShares == 0 || _shares[account] == 0) { return 0; }
        return _shares[account].mul(100).div(_totalShares);
    }

     
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

     
    function available(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance.add(_totalReleased);
        uint256 totalCut = totalReceived.mul(_shares[account]).div(_totalShares);
        if (totalCut < _released[account]) { return 0; }
        return totalCut.sub(_released[account]);
    }

     
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

     
    function release() external nonReentrant {
        address payable account = address(uint160(msg.sender));
        require(_shares[account] > 0, "Account not eligible for payroll");

        uint256 payment = available(account);
        require(payment != 0, "No payment available for account");

        _release(account, payment);
    }

     
    function releaseAll() public onlyOwner {
        _releaseAll();
        _resetAll();
    }

     
    function addNewPayee(address account, uint256 shares_) public onlyOwner {
        require(account != address(0), "Invalid account");
        require(Address.isContract(account) == false, "Account cannot be a contract");
        require(shares_ > 0, "Shares must be greater than zero");
        require(_shares[account] == 0, "Payee already exists");
        require(_totalReleased == 0, "Must release all existing payments first");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares.add(shares_);
        emit PayeeAdded(account, shares_);
    }

     
    function increasePayeeShares(address account, uint256 shares_) public onlyOwner {
        require(account != address(0), "Invalid account");
        require(shares_ > 0, "Shares must be greater than zero");
        require(_shares[account] > 0, "Payee does not exist");
        require(_totalReleased == 0, "Must release all existing payments first");

        _shares[account] = _shares[account].add(shares_);
        _totalShares = _totalShares.add(shares_);
        emit PayeeUpdated(account, shares_, _shares[account]);
    }

     
    function _release(address payable account, uint256 payment) private {
        _released[account] = _released[account].add(payment);
        _totalReleased = _totalReleased.add(payment);
        _totalReleasedAllTime = _totalReleasedAllTime.add(payment);

        account.transfer(payment);
        emit PaymentReleased(account, payment);
    }

     
    function _releaseAll() private {
        for (uint256 i = 0; i < _payees.length; i++) {
            _release(address(uint160(_payees[i])), available(_payees[i]));
        }
    }

     
    function _resetAll() private {
        for (uint256 i = 0; i < _payees.length; i++) {
            _released[_payees[i]] = 0;
        }
        _totalReleased = 0;
    }
}