 

pragma solidity ^0.5.2;

contract ERC20TokenInterface {

    function totalSupply () external view returns (uint);
    function balanceOf (address tokenOwner) external view returns (uint balance);
    function transfer (address to, uint tokens) external returns (bool success);
    function transferFrom (address from, address to, uint tokens) external returns (bool success);

}

library SafeMath {

    function mul (uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div (uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub (uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add (uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

}

 
contract CliffTokenVesting {

    using SafeMath for uint256;

    event Released(address beneficiary, uint256 amount);

     
    struct Beneficiary {
        uint256 start;
        uint256 duration;
        uint256 cliff;
        uint256 totalAmount;
        uint256 releasedAmount;
    }
    mapping (address => Beneficiary) public beneficiary;

     
    ERC20TokenInterface public token;

    uint256 public nonce = 142816;

     
    modifier isVestedAccount (address account) { require(beneficiary[account].start != 0); _; }

     
    constructor (ERC20TokenInterface tokenAddress) public {
        require(tokenAddress != ERC20TokenInterface(0x0));
        token = tokenAddress;
    }

     
    function releasableAmount (address account) public view returns (uint256) {
        return vestedAmount(account).sub(beneficiary[account].releasedAmount);
    }

     
    function release (address account) public isVestedAccount(account) {
        uint256 unreleased = releasableAmount(account);
        require(unreleased > 0);
        beneficiary[account].releasedAmount = beneficiary[account].releasedAmount.add(unreleased);
        token.transfer(account, unreleased);
        emit Released(account, unreleased);
        if (beneficiary[account].releasedAmount == beneficiary[account].totalAmount) {  
            delete beneficiary[account];
        }
    }

     
    function addBeneficiary (
        address account,
        uint256 start,
        uint256 duration,
        uint256 cliff,
        uint256 amount
    ) public {
        require(amount != 0 && start != 0 && account != address(0x0) && cliff < duration && beneficiary[account].start == 0);
        require(token.transferFrom(msg.sender, address(this), amount));
        beneficiary[account] = Beneficiary({
            start: start,
            duration: duration,
            cliff: start.add(cliff),
            totalAmount: amount,
            releasedAmount: 0
        });
    }

     
    function vestedAmount (address account) private view returns (uint256) {
        if (block.timestamp < beneficiary[account].cliff) {
            return 0;
        } else if (block.timestamp >= beneficiary[account].start.add(beneficiary[account].duration)) {
            return beneficiary[account].totalAmount;
        } else {
            return beneficiary[account].totalAmount.mul(
                block.timestamp.sub(beneficiary[account].start)
            ).div(beneficiary[account].duration);
        }
    }

}