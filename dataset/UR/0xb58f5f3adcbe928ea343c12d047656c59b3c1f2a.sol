 

pragma solidity ^0.4.18;

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

interface UnicornDividendTokenInterface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function getHolder(uint256) external view returns (address);
    function getHoldersCount() external view returns (uint256);
}

contract DividendManager {
    using SafeMath for uint256;

     
    UnicornDividendTokenInterface unicornDividendToken;

     
    mapping (address => uint256) public pendingWithdrawals;

     
    event WithdrawalAvailable(address indexed holder, uint256 amount);

     
    event WithdrawalPayed(address indexed holder, uint256 amount);

     
    event DividendPayment(uint256 paymentPerShare);

     
    function DividendManager(address _unicornDividendToken) public{
         
        unicornDividendToken = UnicornDividendTokenInterface(_unicornDividendToken);
    }

    uint256 public retainedEarning = 0;


     
     

    function () public payable {
        payDividend();
    }

    function payDividend() public payable {
        retainedEarning = retainedEarning.add(msg.value);
        require(retainedEarning > 0);

         
        uint256 totalSupply = unicornDividendToken.totalSupply();
        uint256 paymentPerShare = retainedEarning.div(totalSupply);
        if (paymentPerShare > 0) {
            uint256 totalPaidOut = 0;
             
            for (uint256 i = 1; i <= unicornDividendToken.getHoldersCount(); i++) {
                address holder = unicornDividendToken.getHolder(i);
                uint256 withdrawal = paymentPerShare * unicornDividendToken.balanceOf(holder);
                pendingWithdrawals[holder] = pendingWithdrawals[holder].add(withdrawal);
                WithdrawalAvailable(holder, withdrawal);
                totalPaidOut = totalPaidOut.add(withdrawal);
            }
            retainedEarning = retainedEarning.sub(totalPaidOut);
        }
        DividendPayment(paymentPerShare);
    }

     
    function withdrawDividend() public {
        uint amount = pendingWithdrawals[msg.sender];
        require (amount > 0);
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
        WithdrawalPayed(msg.sender, amount);
    }
}