 

pragma solidity 0.4.21;


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


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}



contract CryptoRoboticsToken {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function burn(uint256 value) public;
}


contract ICOContract {
    function setTokenCountFromPreIco(uint256 value) public;
}


contract Crowdsale is Ownable {
    using SafeMath for uint256;

     
    CryptoRoboticsToken public token;
    ICOContract ico;

     
    address public wallet;

     
    uint256 public weiRaised;

    uint256 public openingTime;
    uint256 public closingTime;

    bool public isFinalized = false;

    uint public tokenPriceInWei = 105 szabo;

    uint256 public cap = 1008 ether;


    event Finalized();
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    modifier onlyWhileOpen {
        require(now >= openingTime && now <= closingTime);
        _;
    }


    function Crowdsale(CryptoRoboticsToken _token) public
    {
        require(_token != address(0));


        wallet = 0xc17324BA51303105cCF7cb8850d1e1B4a6e6f064;
        token = _token;
        openingTime = now;
        closingTime = 1526601600;
    }


    function () external payable {
        buyTokens(msg.sender);
    }


    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

        uint _diff =  weiAmount % tokenPriceInWei;

        if (_diff > 0) {
            msg.sender.transfer(_diff);
            weiAmount = weiAmount.sub(_diff);
        }

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);


        _forwardFunds(weiAmount);
    }


    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view onlyWhileOpen {
        require(_beneficiary != address(0));
        require(weiRaised.add(_weiAmount) <= cap);
        require(_weiAmount >= 20 ether);
    }


    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }


    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _tokenAmount = _tokenAmount * 1 ether;
        _deliverTokens(_beneficiary, _tokenAmount);
    }


    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint _tokens = _weiAmount.div(tokenPriceInWei);
        return _tokens;
    }


    function _forwardFunds(uint _weiAmount) internal {
        wallet.transfer(_weiAmount);
    }


    function hasClosed() public view returns (bool) {
        return now > closingTime;
    }

    function capReached() public view returns (bool) {
        return weiRaised >= cap;
    }

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasClosed() || capReached());

        finalization();
        emit Finalized();

        isFinalized = true;
    }


    function setIco(address _ico) onlyOwner public {
        ico = ICOContract(_ico);
    }


    function finalization() internal {
        uint _balance = token.balanceOf(this);
        if (_balance > 0) {
            token.transfer(address(ico), _balance);
            ico.setTokenCountFromPreIco(_balance);
        }
    }
}