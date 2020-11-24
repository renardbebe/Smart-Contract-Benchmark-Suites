 

pragma solidity 0.5.4;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


 
contract ERC20  {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
library SafeERC20 {
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 value
    )
    internal
    {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require(token.approve(spender, value));
    }
}


 
contract Crowdsale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;


     
    ERC20 public token;

     
    address payable public wallet;

     
    uint256 public weiRaised;
    uint256 public tokensSold;

    uint256 public cap = 30000000 ether;  

    mapping (uint => uint) prices;
    mapping (address => address) referrals;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Finalized();
     

    constructor(address payable _wallet, address _token) public {
        require(_wallet != address(0));
        require(_token != address(0));

        wallet = _wallet;
        token = ERC20(_token);

        prices[1] = 75000000000000000;
        prices[2] = 105000000000000000;
        prices[3] = 120000000000000000;
        prices[4] = 135000000000000000;

    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender, bytesToAddress(msg.data));
    }

     
    function buyTokens(address _beneficiary, address _referrer) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens;
        uint256 bonus;
        uint256 price;
        (tokens, bonus, price) = _getTokenAmount(weiAmount);

        require(tokens >= 10 ether);

        price = tokens.div(1 ether).mul(price);
        uint256 _diff =  weiAmount.sub(price);

        if (_diff > 0) {
            weiAmount = weiAmount.sub(_diff);
            msg.sender.transfer(_diff);
        }


        if (_referrer != address(0) && _referrer != _beneficiary) {
            referrals[_beneficiary] = _referrer;
        }

        if (referrals[_beneficiary] != address(0)) {
            uint refTokens = valueFromPercent(tokens, 1000);
            _processPurchase(referrals[_beneficiary], refTokens);
            tokensSold = tokensSold.add(refTokens);
        }

        tokens = tokens.add(bonus);

        require(tokensSold.add(tokens) <= cap);

         
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokens);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _forwardFunds(weiAmount);
    }

     
     
     

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal pure {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }


     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256, uint256, uint256) {
        if (block.timestamp >= 1551387600 && block.timestamp < 1554066000) {
            return _calculateTokens(_weiAmount, 1);
        } else if (block.timestamp >= 1554066000 && block.timestamp < 1556658000) {
            return _calculateTokens(_weiAmount, 2);
        } else if (block.timestamp >= 1556658000 && block.timestamp < 1559336400) {
            return _calculateTokens(_weiAmount, 3);
        } else if (block.timestamp >= 1559336400 && block.timestamp < 1561928400) {
            return _calculateTokens(_weiAmount, 4);
        } else return (0,0,0);

    }


    function _calculateTokens(uint256 _weiAmount, uint _stage) internal view returns (uint256, uint256, uint256) {
        uint price = prices[_stage];
        uint tokens = _weiAmount.div(price);
        uint bonus;
        if (tokens >= 10 && tokens <= 100) {
            bonus = 1000;
        } else if (tokens > 100 && tokens <= 1000) {
            bonus = 1500;
        } else if (tokens > 1000 && tokens <= 10000) {
            bonus = 2000;
        } else if (tokens > 10000 && tokens <= 100000) {
            bonus = 2500;
        } else if (tokens > 100000 && tokens <= 1000000) {
            bonus = 3000;
        } else if (tokens > 1000000 && tokens <= 10000000) {
            bonus = 3500;
        } else if (tokens > 10000000) {
            bonus = 4000;
        }

        bonus = valueFromPercent(tokens, bonus);
        return (tokens.mul(1 ether), bonus.mul(1 ether), price);

    }

     
    function _forwardFunds(uint _weiAmount) internal {
        wallet.transfer(_weiAmount);
    }


     
    function capReached() public view returns (bool) {
        return tokensSold >= cap;
    }

     
    function finalize() onlyOwner public {
        finalization();
        emit Finalized();
    }

     
    function finalization() internal {
        token.safeTransfer(wallet, token.balanceOf(address(this)));
    }


    function updatePrice(uint _stage, uint _newPrice) onlyOwner external {
        prices[_stage] = _newPrice;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

     
    function valueFromPercent(uint _value, uint _percent) internal pure returns (uint amount)    {
        uint _amount = _value.mul(_percent).div(10000);
        return (_amount);
    }
}