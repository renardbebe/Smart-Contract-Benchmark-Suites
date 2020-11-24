 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract  DividendToken is IERC20 {
    function totalSupplyAt(uint _blockNumber) external view returns(uint);
    function balanceOfAt(address _owner, uint _blockNumber) external view returns (uint);
}


contract DividendManager is Ownable {
    using SafeMath for uint;

    event DividendDeposited(address indexed _depositor, uint256 _blockNumber, uint256 _amount, uint256 _totalSupply, uint256 _dividendIndex);
    event DividendClaimed(address indexed _claimer, uint256 _dividendIndex, uint256 _claim);
    event DividendRecycled(address indexed _recycler, uint256 _blockNumber, uint256 _amount, uint256 _totalSupply, uint256 _dividendIndex);

    DividendToken public dividendToken;

    uint256 public RECYCLE_TIME = 365 days;

    struct Dividend {
        uint256 blockNumber;
        uint256 timestamp;
        uint256 amount;
        uint256 claimedAmount;
        uint256 totalSupply;
        bool recycled;
        mapping(address => bool) claimed;
    }

    Dividend[] public dividends;

    uint public allocatedValue;

    mapping(address => uint256) dividendsClaimed;

    modifier validDividendIndex(uint256 _dividendIndex) {
        require(_dividendIndex < dividends.length);
        _;
    }

    constructor (DividendToken _dividendToken) public {
        dividendToken = _dividendToken;
    }

    function () external payable {
    }

    function dividendsCount() external view returns (uint) {
        return dividends.length;
    }

    function unallocatedValue() public view returns (uint) {
        return address(this).balance.sub(allocatedValue);
    }

    function allocateDividend() public {
        uint balance = unallocatedValue();
        require(balance > 0);
        _depositDividend(balance);
    }

    function depositDividend() public payable {
        _depositDividend(msg.value);
    }

    function _depositDividend(uint value) internal {
        require(value > 0);
        uint256 currentSupply = dividendToken.totalSupplyAt(block.number);
        uint256 dividendIndex = dividends.length;
        uint256 blockNumber = block.number - 1;
        dividends.push(
            Dividend(
                blockNumber,
                now,
                value,
                0,
                currentSupply,
                false
            )
        );
        allocatedValue = allocatedValue.add(value);
        emit DividendDeposited(msg.sender, blockNumber, msg.value, currentSupply, dividendIndex);
    }

    function provisionDividend(uint256 _dividendIndex) public view returns (uint provisionAmount){
        if (_dividendIndex >= dividends.length ) {
            return 0;
        }
        Dividend storage dividend = dividends[_dividendIndex];
        if (dividend.claimed[msg.sender] || dividend.recycled) {
            return 0;
        }
        uint256 balance = dividendToken.balanceOfAt(msg.sender, dividend.blockNumber);
        provisionAmount = balance.mul(dividend.amount).div(dividend.totalSupply);
    }

    function provisionDividendAll() public view returns (uint provisionAmount) {
        if (dividendsClaimed[msg.sender] == dividends.length) {
            return 0;
        }
        for (uint i = dividendsClaimed[msg.sender]; i < dividends.length; i++) {
            if ((dividends[i].claimed[msg.sender] == false) && (dividends[i].recycled == false)) {
                provisionAmount = provisionAmount.add(provisionDividend(i));
            }
        }
    }

    function _claimDividend(uint256 _dividendIndex) internal returns (uint claim){
        Dividend storage dividend = dividends[_dividendIndex];
        require(dividend.claimed[msg.sender] == false);
        require(dividend.recycled == false);
        uint256 balance = dividendToken.balanceOfAt(msg.sender, dividend.blockNumber);
        claim = balance.mul(dividend.amount).div(dividend.totalSupply);
        dividend.claimed[msg.sender] = true;
        dividend.claimedAmount = dividend.claimedAmount.add(claim);
    }

    function claimDividend(uint256 _dividendIndex) validDividendIndex(_dividendIndex) public {
        uint claim = _claimDividend(_dividendIndex);

        if (claim > 0) {
            allocatedValue = allocatedValue.sub(claim);
            msg.sender.transfer(claim);
            emit DividendClaimed(msg.sender, _dividendIndex, claim);
        }
        if (dividendsClaimed[msg.sender] == _dividendIndex) {
            dividendsClaimed[msg.sender] = _dividendIndex + 1;
        }
    }

    function claimDividendAll() public {
        require(dividendsClaimed[msg.sender] < dividends.length);
        uint claimSum;
        uint claim;
        for (uint i = dividendsClaimed[msg.sender]; i < dividends.length; i++) {
            if ((dividends[i].claimed[msg.sender] == false) && (dividends[i].recycled == false)) {
                claim = _claimDividend(i);
                dividendsClaimed[msg.sender] = i + 1;
                if (claim > 0) {
                    claimSum = claimSum.add(claim);
                    emit DividendClaimed(msg.sender, i, claim);
                }
            }
        }
        if (claimSum > 0) {
            allocatedValue = allocatedValue.sub(claimSum);
            msg.sender.transfer(claimSum);
        }
    }

    function recycleDividend(uint256 _dividendIndex) onlyOwner validDividendIndex(_dividendIndex) public {
        Dividend storage dividend = dividends[_dividendIndex];
        require(dividend.recycled == false);
        require(dividend.timestamp < now.sub(RECYCLE_TIME));
        dividends[_dividendIndex].recycled = true;
        uint256 currentSupply = dividendToken.totalSupplyAt(block.number);
        uint256 remainingAmount = dividend.amount.sub(dividend.claimedAmount);
        uint256 dividendIndex = dividends.length;
        uint256 blockNumber = block.number - 1;
        dividends.push(
            Dividend(
                blockNumber,
                now,
                remainingAmount,
                0,
                currentSupply,
                false
            )
        );
        emit DividendRecycled(msg.sender, blockNumber, remainingAmount, currentSupply, dividendIndex);
    }
}