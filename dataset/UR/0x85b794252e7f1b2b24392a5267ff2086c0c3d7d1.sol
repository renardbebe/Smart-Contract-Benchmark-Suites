 

pragma solidity ^0.4.15;


contract Token {
    uint256 public totalSupply;

    function balanceOf(address who) constant returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value) returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


 
contract Ownable {
    address public owner;


     
    function Ownable() {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}


 
contract Pausable is Ownable {
    event Pause();

    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused {
        paused = false;
        Unpause();
    }
}


contract CashPokerProPreICO is Ownable, Pausable {
    using SafeMath for uint;

     
    address public tokenWallet;

    uint public tokensSold;

    uint public weiRaised;

    uint public investorCount;

    Token public token;

    uint constant minInvest = 0.01 ether;

    uint constant tokensLimit = 10000000 * 1 ether;

     
    uint256 public startTime = 1503770400;  
    uint256 public endTime = 1504893600;  

    uint price = 0.00017 * 1 ether;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function CashPokerProPreICO() {
        tokenWallet = msg.sender;
    }

    function setToken(address newToken) onlyOwner {
        token = Token(newToken);
    }

    function setTokenWallet(address newTokenWallet) onlyOwner {
        tokenWallet = newTokenWallet;
    }

     
    function() payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) whenNotPaused payable {
        require(startTime <= now && now <= endTime);

        uint weiAmount = msg.value;

        require(weiAmount >= minInvest);

        uint tokenAmountEnable = tokensLimit.sub(tokensSold);

        require(tokenAmountEnable > 0);

        uint tokenAmount = weiAmount / price * 1 ether;

        if (tokenAmount > tokenAmountEnable) {
            tokenAmount = tokenAmountEnable;
            weiAmount = tokenAmount * price / 1 ether;
            msg.sender.transfer(msg.value - weiAmount);
        }

        if (token.balanceOf(beneficiary) == 0) investorCount++;

        weiRaised = weiRaised.add(weiAmount);

        require(token.transferFrom(tokenWallet, beneficiary, tokenAmount));

        tokensSold = tokensSold.add(tokenAmount);

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
    }

    function withdrawal(address to) onlyOwner {
        to.transfer(this.balance);
    }

    function transfer(address to, uint amount) onlyOwner {
        uint tokenAmountEnable = tokensLimit.sub(tokensSold);

        if (amount > tokenAmountEnable) amount = tokenAmountEnable;

        require(token.transferFrom(tokenWallet, to, amount));

        tokensSold = tokensSold.add(amount);
    }
}