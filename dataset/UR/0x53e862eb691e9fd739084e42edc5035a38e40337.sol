 

pragma solidity 0.5.3;

 
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

 
contract PaymentDistributor is Ownable {
    using SafeMath for uint256;

    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

     
    uint256 private _backupReleaseTime;

    uint256 private _totalReleased;
    mapping(address => uint256) private _released;

    uint256 private constant step1Fund = uint256(5000) * 10 ** 18;

    address payable private _beneficiary0;
    address payable private _beneficiary1;
    address payable private _beneficiary2;
    address payable private _beneficiary3;
    address payable private _beneficiary4;
    address payable private _beneficiaryBackup;

     
    constructor (address payable beneficiary0, address payable beneficiary1, address payable beneficiary2, address payable beneficiary3, address payable beneficiary4, address payable beneficiaryBackup, uint256 backupReleaseTime) public {
        _beneficiary0 = beneficiary0;
        _beneficiary1 = beneficiary1;
        _beneficiary2 = beneficiary2;
        _beneficiary3 = beneficiary3;
        _beneficiary4 = beneficiary4;
        _beneficiaryBackup = beneficiaryBackup;
        _backupReleaseTime = backupReleaseTime;
    }

     
    function () external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

     
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

     
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

     
    function beneficiary0() public view returns (address) {
        return _beneficiary0;
    }

     
    function beneficiary1() public view returns (address) {
        return _beneficiary1;
    }

     
    function beneficiary2() public view returns (address) {
        return _beneficiary2;
    }

     
    function beneficiary3() public view returns (address) {
        return _beneficiary3;
    }

     
    function beneficiary4() public view returns (address) {
        return _beneficiary4;
    }

     
    function beneficiaryBackup() public view returns (address) {
        return _beneficiaryBackup;
    }

     
    function backupReleaseTime() public view returns (uint256) {
        return _backupReleaseTime;
    }

     
    function sendToAccount(address payable account, uint256 amount) internal {
        require(amount > 0, 'The amount must be greater than zero.');

        _released[account] = _released[account].add(amount);
        _totalReleased = _totalReleased.add(amount);

        account.transfer(amount);
        emit PaymentReleased(account, amount);
    }

     
    function release(uint256 amount) onlyOwner public{
        require(address(this).balance >= amount, 'Balance must be greater than or equal to the amount.');
        uint256 _value = amount;
        if (_released[_beneficiary0] < step1Fund) {
            if (_released[_beneficiary0].add(_value) > step1Fund){
                uint256 _remainValue = step1Fund.sub(_released[_beneficiary0]);
                _value = _value.sub(_remainValue);
                sendToAccount(_beneficiary0, _remainValue);
            }
            else {
                sendToAccount(_beneficiary0, _value);
                _value = 0;
            }
        }

        if (_value > 0) {
            uint256 _value1 = _value.mul(10).div(100);           
            uint256 _value2 = _value.mul(7020).div(10000);       
            uint256 _value3 = _value.mul(1080).div(10000);       
            uint256 _value4 = _value.mul(9).div(100);            
            sendToAccount(_beneficiary1, _value1);
            sendToAccount(_beneficiary2, _value2);
            sendToAccount(_beneficiary3, _value3);
            sendToAccount(_beneficiary4, _value4);
        }
    }    

     
    function releaseBackup(uint256 amount) onlyOwner public{
        require(address(this).balance >= amount, 'Balance must be greater than or equal to the amount.');
        require(block.timestamp >= backupReleaseTime(), 'The transfer is possible only 2 months after the ICO.');
        sendToAccount(_beneficiaryBackup, amount);
    }
}