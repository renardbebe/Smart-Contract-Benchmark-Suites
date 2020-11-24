 

pragma solidity ^0.4.25;

 

 
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

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

     
    address private _wallet;

     
     
     
     
    uint256 private _rate;

     
    uint256 private _weiRaised;

     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

     
    constructor (uint256 rate, address wallet, IERC20 token) internal {
        require(rate > 0);
        require(wallet != address(0));
        require(token != address(0));

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

     
    function wallet() public view returns (address) {
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

 
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _cap;

     
    constructor (uint256 cap) internal {
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

 
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;

     
    modifier onlyWhileOpen {
        require(isOpen());
        _;
    }

     
    constructor (uint256 openingTime, uint256 closingTime) internal {
         
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

 
contract FthCrowdsale is CappedCrowdsale, TimedCrowdsale {
    using SafeMath for uint256;

    uint256 constant MIN_WEI_AMOUNT = 0.1 ether;

    uint256 private _rewardPeriod;
    uint256 private _unlockPeriod;

    struct Contribution {
        uint256 contributeTime;
        uint256 buyTokenAmount;
        uint256 rewardTokenAmount;
        uint256 lastWithdrawTime;
        uint256 withdrawPercent;
    }

    mapping(address => Contribution[]) private _contributions;

    constructor (
        uint256 rewardPeriod,
        uint256 unlockPeriod,
        uint256 cap,
        uint256 openingTime,
        uint256 closingTime,
        uint256 rate,
        address wallet,
        IERC20 token
    )
        public
        CappedCrowdsale(cap)
        TimedCrowdsale(openingTime, closingTime)
        Crowdsale(rate, wallet, token)
    {
        _rewardPeriod = rewardPeriod;
        _unlockPeriod = unlockPeriod;
    }

    function contributionsOf(address beneficiary)
        public
        view
        returns (
            uint256[] memory contributeTimes,
            uint256[] memory buyTokenAmounts,
            uint256[] memory rewardTokenAmounts,
            uint256[] memory lastWithdrawTimes,
            uint256[] memory withdrawPercents
        )
    {
        Contribution[] memory contributions = _contributions[beneficiary];

        uint256 length = contributions.length;

        contributeTimes = new uint256[](length);
        buyTokenAmounts = new uint256[](length);
        rewardTokenAmounts = new uint256[](length);
        lastWithdrawTimes = new uint256[](length);
        withdrawPercents = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            contributeTimes[i] = contributions[i].contributeTime;
            buyTokenAmounts[i] = contributions[i].buyTokenAmount;
            rewardTokenAmounts[i] = contributions[i].rewardTokenAmount;
            lastWithdrawTimes[i] = contributions[i].lastWithdrawTime;
            withdrawPercents[i] = contributions[i].withdrawPercent;
        }
    }

    function withdrawTokens(address beneficiary) public {
        require(isOver());

        if (msg.sender == beneficiary && msg.sender == wallet()) {
            _withdrawTokensToWallet();
        } else {
            _withdrawTokensTo(beneficiary);
        }
    }

    function unlockBalanceOf(address beneficiary) public view returns (uint256) {
        uint256 unlockBalance = 0;

        Contribution[] memory contributions = _contributions[beneficiary];

        for (uint256 i = 0; i < contributions.length; i++) {
            uint256 unlockPercent = _unlockPercent(contributions[i]);

            if (unlockPercent == 0) {
                continue;
            }

            unlockBalance = unlockBalance.add(
                contributions[i].buyTokenAmount.mul(unlockPercent).div(100)
            ).add(
                contributions[i].rewardTokenAmount.mul(unlockPercent).div(100)
            );
        }

        return unlockBalance;
    }

    function rewardTokenAmount(uint256 buyTokenAmount) public view returns (uint256) {
        if (!isOpen()) {
            return 0;
        }

        uint256 rewardTokenPercent = 0;

         
        uint256 timePeriod = block.timestamp.sub(openingTime()).div(_rewardPeriod);

        if (timePeriod < 1) {
            rewardTokenPercent = 15;
        } else if (timePeriod < 2) {
            rewardTokenPercent = 10;
        } else if (timePeriod < 3) {
            rewardTokenPercent = 5;
        } else {
            return 0;
        }

        return buyTokenAmount.mul(rewardTokenPercent).div(100);
    }

    function rewardPeriod() public view returns (uint256) {
        return _rewardPeriod;
    }

    function unlockPeriod() public view returns (uint256) {
        return _unlockPeriod;
    }

    function isOver() public view returns (bool) {
        return capReached() || hasClosed();
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(weiAmount >= MIN_WEI_AMOUNT);

        super._preValidatePurchase(beneficiary, weiAmount);
    }

    function _processPurchase(address beneficiary, uint256 buyTokenAmount) internal {
        Contribution[] storage contributions = _contributions[beneficiary];
        require(contributions.length < 100);

        contributions.push(Contribution({
             
            contributeTime: block.timestamp,
            buyTokenAmount: buyTokenAmount,
            rewardTokenAmount: rewardTokenAmount(buyTokenAmount),
            lastWithdrawTime: 0,
            withdrawPercent: 0
        }));
    }

    function _withdrawTokensToWallet() private {
        uint256 balanceTokenAmount = token().balanceOf(address(this));
        require(balanceTokenAmount > 0);

        _deliverTokens(wallet(), balanceTokenAmount);
    }

    function _withdrawTokensTo(address beneficiary) private {
        uint256 unlockBalance = unlockBalanceOf(beneficiary);
        require(unlockBalance > 0);

        Contribution[] storage contributions = _contributions[beneficiary];

        for (uint256 i = 0; i < contributions.length; i++) {
            uint256 unlockPercent = _unlockPercent(contributions[i]);

            if (unlockPercent == 0) {
                continue;
            }

             
            contributions[i].lastWithdrawTime = block.timestamp;
            contributions[i].withdrawPercent = contributions[i].withdrawPercent.add(unlockPercent);
        }

        _deliverTokens(beneficiary, unlockBalance);
    }

    function _unlockPercent(Contribution memory contribution) private view returns (uint256) {
        if (contribution.withdrawPercent >= 100) {
            return 0;
        }

        uint256 baseTimestamp = contribution.contributeTime;

        if (contribution.lastWithdrawTime > baseTimestamp) {
            baseTimestamp = contribution.lastWithdrawTime;
        }

         
        uint256 period = block.timestamp.sub(baseTimestamp);

        if (period < _unlockPeriod) {
            return 0;
        }

        uint256 unlockPercent = period.div(_unlockPeriod).sub(1).mul(10);

        if (contribution.withdrawPercent == 0) {
            unlockPercent = unlockPercent.add(50);
        } else {
            unlockPercent = unlockPercent.add(10);
        }

        uint256 max = 100 - contribution.withdrawPercent;

        if (unlockPercent > max) {
            unlockPercent = max;
        }

        return unlockPercent;
    }
}