 

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

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 

contract BitMilleCrowdsale {
    using SafeMath for uint256;

     
    ERC20 public token;

     
    address public wallet;

     
    uint256 public weiRaised;

    uint256 public openingTime;
    uint256 public closingTime;

     
    modifier onlyWhileOpen {
        require(now >= openingTime && now <= closingTime);
        _;
    }

     
    modifier onlyAfterClosing {
        require(now > closingTime);
        _;
    }

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function BitMilleCrowdsale() public {
        wallet = 0x468E9A02c233C3DBb0A1b7F8bd8F8E9f36cbA952;
        token = ERC20(0xabb3148a39fb97af1295c5ee03e713d6ed54fd92);
        openingTime = 1520946000;
        closingTime = 1523970000;
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

     
    function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
         
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
         
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {

        uint256 period = 7 days;
        uint256 perc;

        if ((now >= openingTime) && (now < openingTime + period)) {
            perc = 10;
        } else if ((now >= openingTime + period) && (now < openingTime + period * 2)) {
            perc = 9;
        } else if ((now >= openingTime + period * 2) && (now < openingTime + period * 3)) {
            perc = 8;
        } else {
            perc = 7;
        }

        return _weiAmount.mul(perc).div(100000);

    }

     
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function hasClosed() public view returns (bool) {
        return now > closingTime;
    }

    function withdrawTokens() public onlyAfterClosing returns (bool) {
        token.transfer(wallet, token.balanceOf(this));
        return true;
    }

}