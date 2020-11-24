 

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

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
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

 
contract Crowdsale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    IERC20 private _token;

     
    address payable private _wallet;

     
     
     
     
    uint256 private _rate;

     
    uint256 private _weiRaised;

     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    constructor (uint256 rate, address payable wallet, IERC20 token) public {
        require(rate > 0);
        require(wallet != address(0));
        require(address(token) != address(0));

        _rate = rate;
        _wallet = wallet;
        _token = token;
    }

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function token() public view returns (IERC20) {
        return _token;
    }

     
    function wallet() public view returns (address payable) {
        return _wallet;
    }

     
    function rate() public view returns (uint256) {
        return _rate;
    }

     
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

     
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0));
        require(weiAmount != 0);
    }

     
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
         
    }

     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

     
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

     
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
         
    }

     
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

     
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}

 
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;

     
    modifier onlyWhileOpen {
        require(isOpen());
        _;
    }

     
    constructor (uint256 openingTime, uint256 closingTime) public {
         
        require(openingTime >= block.timestamp);
        require(closingTime > openingTime);

        _openingTime = openingTime;
        _closingTime = closingTime;
    }

     
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

     
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

     
    function isOpen() public view returns (bool) {
         
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

     
    function hasClosed() public view returns (bool) {
         
        return block.timestamp > _closingTime;
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        super._preValidatePurchase(beneficiary, weiAmount);
    }
}

 
library Math {
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

 
contract AllowanceCrowdsale is Crowdsale {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private _tokenWallet;

     
    constructor (address tokenWallet) public {
        require(tokenWallet != address(0));
        _tokenWallet = tokenWallet;
    }

     
    function tokenWallet() public view returns (address) {
        return _tokenWallet;
    }

     
    function remainingTokens() public view returns (uint256) {
        return Math.min(token().balanceOf(_tokenWallet), token().allowance(_tokenWallet, address(this)));
    }

     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        token().safeTransferFrom(_tokenWallet, beneficiary, tokenAmount);
    }
}

 
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _cap;

     
    constructor (uint256 cap) public {
        require(cap > 0);
        _cap = cap;
    }

     
    function cap() public view returns (uint256) {
        return _cap;
    }

     
    function capReached() public view returns (bool) {
        return weiRaised() >= _cap;
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiRaised().add(weiAmount) <= _cap);
    }
}

 
contract BitherPlatformCrowdsale is AllowanceCrowdsale, TimedCrowdsale, CappedCrowdsale {

    uint256 constant private CAP_IN_WEI = 300000 ether;

    uint256 constant private BTR_PRIVATE_SALE_RATE = 110;
    uint256 constant private BTR_PRESALE_RATE_DAY_1 = 110;
    uint256 constant private BTR_PRESALE_RATE_DAY_2_TO_5 = 109;
    uint256 constant private BTR_PRESALE_RATE_DAY_6_TO_9 = 108;
    uint256 constant private BTR_PRESALE_RATE_DAY_10_TO_13 = 107;

    uint256 constant private BTR_CROWDSALE_ROUND1_RATE_DAY_1_FIRST_2_HOURS = 110;
    uint256 constant private BTR_CROWDSALE_ROUND1_RATE_DAY_1_TO_14 = 107;
    uint256 constant private BTR_CROWDSALE_ROUND1_RATE_DAY_15_TO_28 = 106;

    uint256 constant private BTR_CROWDSALE_ROUND2_RATE_DAY_1_FIRST_2_HOURS = 110;
    uint256 constant private BTR_CROWDSALE_ROUND2_RATE_DAY_1_TO_7 = 106;
    uint256 constant private BTR_CROWDSALE_ROUND2_RATE_DAY_8_TO_14 = 104;
    uint256 constant private BTR_CROWDSALE_ROUND2_RATE_DAY_15_TO_21 = 102;
    uint256 constant private BTR_CROWDSALE_ROUND2_RATE_DAY_22_TO_28 = 100;

    uint256 constant private BRP_PRIVATE_SALE_RATE = 1400;
    uint256 constant private BRP_PRESALE_RATE_FIRST_2_HOURS = 1400;
    uint256 constant private BRP_PRESALE_RATE_DAY_1_TO_5 = 1380;
    uint256 constant private BRP_PRESALE_RATE_DAY_6_TO_13 = 1360;

    uint256 constant private BRP_CROWDSALE_ROUND1_RATE_DAY_1_TO_7 = 1340;
    uint256 constant private BRP_CROWDSALE_ROUND1_RATE_DAY_8_TO_21 = 1320;
    uint256 constant private BRP_CROWDSALE_ROUND1_RATE_DAY_22_TO_28 = 1300;

    uint256 constant private BRP_CROWDSALE_ROUND2_RATE_DAY_1_TO_7 = 1240;
    uint256 constant private BRP_CROWDSALE_ROUND2_RATE_DAY_8_TO_14 = 1160;
    uint256 constant private BRP_CROWDSALE_ROUND2_RATE_DAY_15_TO_21 = 1080;
    uint256 constant private BRP_CROWDSALE_ROUND2_RATE_DAY_22_TO_28 = 1000;

    IERC20 private _rentalProcessorToken;
    uint256 private _privateSaleClosingTime;  
    uint256 private _presaleOpeningTime;  
    uint256 private _crowdsaleRound1OpeningTime;  
    uint256 private _crowdsaleRound2OpeningTime;  

     
    event RentalProcessorTokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    constructor(IERC20 bitherToken, IERC20 rentalProcessorToken, address bitherTokensOwner, address payable etherBenefactor, uint256 preSaleOpeningTime)
        Crowdsale(BTR_PRIVATE_SALE_RATE, etherBenefactor, bitherToken)
        AllowanceCrowdsale(bitherTokensOwner)
        TimedCrowdsale(now, preSaleOpeningTime + 14 weeks)
        CappedCrowdsale(CAP_IN_WEI)
        public
    {
        _rentalProcessorToken = rentalProcessorToken;

        _privateSaleClosingTime = preSaleOpeningTime - 38 hours;
        _presaleOpeningTime = preSaleOpeningTime;
        _crowdsaleRound1OpeningTime = preSaleOpeningTime + 4 weeks;
        _crowdsaleRound2OpeningTime = preSaleOpeningTime + 10 weeks;
    }

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);

        if (now < _privateSaleClosingTime) {
            require(weiAmount >= 50 ether, "Not enough Eth. Contributions must be 50 Eth minimum during the private sale");
        } else {
            require(weiAmount >= 100 finney, "Not enough Eth. Contributions must be 0.1 Eth minimum during the presale and crowdsale (Round 1 and Round 2)");
        }

        if (now > _privateSaleClosingTime && now < _presaleOpeningTime) {
            revert("Private sale has ended and the presale is yet to begin");
        } else if (now > _presaleOpeningTime + 13 days && now < _crowdsaleRound1OpeningTime) {
            revert("Presale has ended and the crowdsale (Round 1) is yet to begin");
        } else if (now > _crowdsaleRound1OpeningTime + 4 weeks && now < _crowdsaleRound2OpeningTime) {
            revert("crowdsale (Round 1) has ended and the crowdsale (Round 2) is yet to begin");
        }
    }

     
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {

        if (now < _privateSaleClosingTime) {
            return weiAmount.mul(BTR_PRIVATE_SALE_RATE);
        } else if (now < _presaleOpeningTime + 1 days) {
            return weiAmount.mul(BTR_PRESALE_RATE_DAY_1);
        } else if (now < _presaleOpeningTime + 5 days) {
            return weiAmount.mul(BTR_PRESALE_RATE_DAY_2_TO_5);
        } else if (now < _presaleOpeningTime + 9 days) {
            return weiAmount.mul(BTR_PRESALE_RATE_DAY_6_TO_9);
        } else if (now < _presaleOpeningTime + 13 days) {
            return weiAmount.mul(BTR_PRESALE_RATE_DAY_10_TO_13);

        } else if (now < _crowdsaleRound1OpeningTime + 2 hours) {
            return weiAmount.mul(BTR_CROWDSALE_ROUND1_RATE_DAY_1_FIRST_2_HOURS);
        } else if (now < _crowdsaleRound1OpeningTime + 2 weeks) {
            return weiAmount.mul(BTR_CROWDSALE_ROUND1_RATE_DAY_1_TO_14);
        } else if (now < _crowdsaleRound1OpeningTime + 4 weeks) {
            return weiAmount.mul(BTR_CROWDSALE_ROUND1_RATE_DAY_15_TO_28);

        } else if (now < _crowdsaleRound2OpeningTime + 2 hours) {
            return weiAmount.mul(BTR_CROWDSALE_ROUND2_RATE_DAY_1_FIRST_2_HOURS);
        } else if (now < _crowdsaleRound2OpeningTime + 1 weeks) {
            return weiAmount.mul(BTR_CROWDSALE_ROUND2_RATE_DAY_1_TO_7);
        } else if (now < _crowdsaleRound2OpeningTime + 2 weeks) {
            return weiAmount.mul(BTR_CROWDSALE_ROUND2_RATE_DAY_8_TO_14);
        } else if (now < _crowdsaleRound2OpeningTime + 3 weeks) {
            return weiAmount.mul(BTR_CROWDSALE_ROUND2_RATE_DAY_15_TO_21);
        } else if (now < closingTime()) {
            return weiAmount.mul(BTR_CROWDSALE_ROUND2_RATE_DAY_22_TO_28);
        }
    }

     
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        super._deliverTokens(beneficiary, tokenAmount);

        uint256 weiAmount = msg.value;
        uint256 brpTokenAmount = getBrpTokenAmount(weiAmount);

        _rentalProcessorToken.safeTransferFrom(tokenWallet(), beneficiary, brpTokenAmount);

        emit RentalProcessorTokensPurchased(msg.sender, beneficiary, weiAmount, brpTokenAmount);
    }

     
    function getBrpTokenAmount(uint256 weiAmount) private view returns (uint256) {

        if (now < _privateSaleClosingTime) {
            return weiAmount.mul(BRP_PRIVATE_SALE_RATE);

        } else if (now < _presaleOpeningTime + 2 hours) {
            return weiAmount.mul(BRP_PRESALE_RATE_FIRST_2_HOURS);
        } else if (now < _presaleOpeningTime + 5 days) {
            return weiAmount.mul(BRP_PRESALE_RATE_DAY_1_TO_5);
        } else if (now < _presaleOpeningTime + 13 days) {
            return weiAmount.mul(BRP_PRESALE_RATE_DAY_6_TO_13);

        } else if (now < _crowdsaleRound1OpeningTime + 1 weeks) {
            return weiAmount.mul(BRP_CROWDSALE_ROUND1_RATE_DAY_1_TO_7);
        } else if (now < _crowdsaleRound1OpeningTime + 3 weeks) {
            return weiAmount.mul(BRP_CROWDSALE_ROUND1_RATE_DAY_8_TO_21);
        } else if (now <= _crowdsaleRound1OpeningTime + 4 weeks) {
            return weiAmount.mul(BRP_CROWDSALE_ROUND1_RATE_DAY_22_TO_28);
        
        } else if (now < _crowdsaleRound2OpeningTime + 1 weeks) {
            return weiAmount.mul(BRP_CROWDSALE_ROUND2_RATE_DAY_1_TO_7);
        } else if (now < _crowdsaleRound2OpeningTime + 2 weeks) {
            return weiAmount.mul(BRP_CROWDSALE_ROUND2_RATE_DAY_8_TO_14);
        } else if (now < _crowdsaleRound2OpeningTime + 3 weeks) {
            return weiAmount.mul(BRP_CROWDSALE_ROUND2_RATE_DAY_15_TO_21);
        } else if (now <= closingTime()) {
            return weiAmount.mul(BRP_CROWDSALE_ROUND2_RATE_DAY_22_TO_28);
        }
    }
}