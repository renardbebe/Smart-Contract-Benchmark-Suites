 

pragma solidity ^0.4.11;

contract SafeMath {

    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a && c >= b);
        return c;
    }
}

contract AlsToken {
    function balanceOf(address _owner) public constant returns (uint256);
    function transfer(address receiver, uint amount) public;
}

contract Owned {

    address internal owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function getOwner() public constant returns (address currentOwner) {
        return owner;
    }
}

contract AlsIco is Owned, SafeMath {

     
     
    uint256 public constant crowdsaleStartTime = 1513782000;

     
     
    uint256 public constant crowdsaleEndTime = 1519138800;

     
    uint256 private constant oneThousandAls = uint256(10) ** 21;

    uint public amountRaised;
    uint public tokensSold;
    AlsToken public alsToken;

    event FundTransfer(address backer, uint amount, bool isContribution);

    function AlsIco() public {
        alsToken = AlsToken(0xbCeC57361649E5dA917efa9F992FBCA0a2529350);
    }

    modifier onlyAfterStart() {
        require(now >= crowdsaleStartTime);
        _;
    }

    modifier onlyBeforeEnd() {
        require(now <= crowdsaleEndTime);
        _;
    }

     
    function getPrice() public constant onlyAfterStart onlyBeforeEnd returns (uint256) {
        if (tokensSold < 1600 * oneThousandAls) {
             
            return 17000;
        } else if (tokensSold < 8000 * oneThousandAls) {
             
            return 13000;
        } else if (tokensSold < 16000 * oneThousandAls) {
             
            return 11000;
        } else if (tokensSold < 40000 * oneThousandAls) {
             
            return 10500;
        } else {
             
            return 10000;
        }
    }

    function () payable public onlyAfterStart onlyBeforeEnd {
        uint256 availableTokens = alsToken.balanceOf(this);
        require (availableTokens > 0);

        uint256 etherAmount = msg.value;
        require(etherAmount > 0);

        uint256 price = getPrice();
        uint256 tokenAmount = safeMul(etherAmount, price);

        if (tokenAmount <= availableTokens) {
            amountRaised = safeAdd(amountRaised, etherAmount);
            tokensSold = safeAdd(tokensSold, tokenAmount);

            alsToken.transfer(msg.sender, tokenAmount);
            FundTransfer(msg.sender, etherAmount, true);
        } else {
            uint256 etherToSpend = safeDiv(availableTokens, price);
            amountRaised = safeAdd(amountRaised, etherToSpend);
            tokensSold = safeAdd(tokensSold, availableTokens);

            alsToken.transfer(msg.sender, availableTokens);
            FundTransfer(msg.sender, etherToSpend, true);

             
            uint256 amountToRefund = safeSub(etherAmount, etherToSpend);
            msg.sender.transfer(amountToRefund);
        }
    }

    function withdrawEther(uint _amount) external onlyOwner {
        require(this.balance >= _amount);
        owner.transfer(_amount);
        FundTransfer(owner, _amount, false);
    }
}