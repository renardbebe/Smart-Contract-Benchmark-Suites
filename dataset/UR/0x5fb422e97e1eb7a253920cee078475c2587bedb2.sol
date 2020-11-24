 

pragma solidity 0.5.7;

 
library SafeMath {

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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 
contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0));
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Caller is not the owner");
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
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
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
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

 
 interface GoldRubleBonusStorage {
     function sendBonus(address account, uint256 amount) external;
     function RS_transferOwnership(address newOwner) external;
     function RS_changeInterval(uint256 newInterval) external;
     function RS_addReferrer(address referrer) external;
     function RS_referrerOf(address player) external view returns(address);
     function RS_interval() external view returns(uint256);
 }


 
contract INVEST is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

     
    IERC20 private _token;

     
    GoldRubleBonusStorage private _GRBS;

     
    address payable private _wallet;

     
    uint256 private _weiRaised;

     
    uint256 private _reserve;

     
    uint256 private _rate = 2e15;

     
    uint256 private _minimum = 0.5 ether;

     
    uint256 private _share = 1000000000000000;

     
    uint256 private _bonusPerShare = 50000000000000;

     
    uint256 private _delay;

     
    mapping (address => User) users;
    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        uint256 reserved;
    }
    struct Deposit {
        uint256 amount;
        uint256 endtime;
        uint256 delay;
    }

     
    bool public paused;

    modifier notPaused() {
        require(!paused);
        _;
    }

     
    bool public refRequired;

     
    enum ReferrerSystem {OFF, ON}
    ReferrerSystem public RS = ReferrerSystem.OFF;

     
    bool public referralMode;

     
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 delay);
    event Withdrawn(address indexed account, uint256 amount);

     
    constructor(uint256 rate, address payable wallet, IERC20 token, address initialOwner, address GRBSAddr) public Ownable(initialOwner) {
        require(rate != 0, "Rate is 0");
        require(wallet != address(0), "Wallet is the zero address");
        require(address(token) != address(0), "Token is the zero address");

        _rate = rate;
        _wallet = wallet;
        _token = token;
        _GRBS = GoldRubleBonusStorage(GRBSAddr);
    }

     
    function() external payable {
        if (msg.value > 0) {
            buyTokens(msg.sender);
        } else {
            withdraw();
        }
    }

     
    function buyTokens(address beneficiary) public notPaused nonReentrant payable {
        require(beneficiary != address(0), "Beneficiary is the zero address");
        require(msg.value >= _minimum, "Wei amount is less than minimum");
        if (refRequired) {
            require(_GRBS.RS_referrerOf(beneficiary) != address(0));
        }

        uint256 weiAmount = msg.value;

        uint256 tokens = getTokenAmount(weiAmount);
        require(tokens <= _token.balanceOf(address(this)).sub(_reserve));

        _weiRaised = _weiRaised.add(weiAmount);

        _wallet.transfer(weiAmount);

        if (_delay == 0) {
            _token.transfer(beneficiary, tokens);
        } else {
            createDeposit(beneficiary, tokens);
        }

        if (_GRBS.RS_referrerOf(beneficiary) != address(0)) {
            if (RS == ReferrerSystem.ON) {
                _GRBS.sendBonus(_GRBS.RS_referrerOf(beneficiary), tokens.div(_share).mul(_bonusPerShare));
                if (referralMode) {
                    _GRBS.sendBonus(beneficiary, tokens.div(_share).mul(_bonusPerShare));
                }
            }
        } else if (msg.data.length == 20) {
            addReferrer();
        }

        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens, _delay);
    }

     
    function createDeposit(address account, uint256 amount) internal {
        if (users[account].checkpoint > 0) {
            users[account].reserved += getDividends(account);
        }
        users[account].checkpoint = block.timestamp;
        users[account].deposits.push(Deposit(amount, block.timestamp.add(_delay), _delay));

        _reserve = _reserve.add(amount);
    }

     
    function withdraw() public {
        uint256 payout = getDividends(msg.sender);
        if (users[msg.sender].reserved > 0) {
            users[msg.sender].reserved = 0;
        }
        if (payout != 0) {
            users[msg.sender].checkpoint = block.timestamp;
            _token.transfer(msg.sender, payout);

            _reserve = _reserve.sub(payout);
            emit Withdrawn(msg.sender, payout);
        }
    }

     
    function addReferrer() internal {
        address referrer = bytesToAddress(bytes(msg.data));
        if (referrer != msg.sender) {
            uint256 interval = _GRBS.RS_interval();
            _GRBS.RS_changeInterval(0);
            _GRBS.RS_addReferrer(referrer);
            _GRBS.RS_changeInterval(interval);
        }
    }

     
    function bytesToAddress(bytes memory source) internal pure returns(address parsedReferrer) {
        assembly {
            parsedReferrer := mload(add(source,0x14))
        }
    }

     
    function getTokenAmount(uint256 weiAmount) public view returns(uint256) {
        return weiAmount.mul(_rate).div(1e18);
    }

     
    function getDividends(address account) public view returns(uint256) {
        uint256 payout = users[account].reserved;
        for (uint256 i = 0; i < users[account].deposits.length; i++) {
            if (block.timestamp < users[account].deposits[i].endtime) {
                payout += (users[account].deposits[i].amount).mul(block.timestamp.sub(users[account].checkpoint)).div(users[account].deposits[i].delay);
            } else if (users[account].checkpoint < users[account].deposits[i].endtime) {
                payout += (users[account].deposits[i].amount).mul(users[account].deposits[i].endtime.sub(users[account].checkpoint)).div(users[account].deposits[i].delay);
            }
        }
        return payout;
    }

     
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate != 0, "New rate is 0");

        _rate = newRate;
    }

     
    function setShare(uint256 newShare) external onlyOwner {
        require(newShare != 0, "New share value is 0");

        _share = newShare;
    }

     
    function setBonus(uint256 newBonus) external onlyOwner {
        require(newBonus != 0, "New bonus value is 0");

        _bonusPerShare = newBonus;
    }

     
    function setWallet(address payable newWallet) external onlyOwner {
        require(newWallet != address(0), "New wallet is the zero address");

        _wallet = newWallet;
    }

     
    function setDelayPeriod(uint256 newDelay) external onlyOwner {

        _delay = newDelay;
    }

     
    function setMinimum(uint256 newMinimum) external onlyOwner {
        require(newMinimum != 0, "New parameter value is 0");

        _minimum = newMinimum;
    }

     
    function pause() external onlyOwner {

        paused = true;
    }

     
    function unpause() external onlyOwner {

        paused = false;
    }

     
    function switchRefSys() external onlyOwner {

        if (RS == ReferrerSystem.ON) {
            RS = ReferrerSystem.OFF;
        } else {
            RS = ReferrerSystem.ON;
        }
    }

     
    function switchRequiringOfRef() external onlyOwner {

        if (refRequired == true) {
            refRequired = false;
        } else {
            refRequired = true;
        }
    }

     
    function switchReferralMode() external onlyOwner {

        if (referralMode == true) {
            referralMode = false;
        } else {
            referralMode = true;
        }
    }

     
    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {

        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);

    }

     
    function token() public view returns (IERC20) {
        return _token;
    }

     
    function GRBS() public view returns (GoldRubleBonusStorage) {
        return _GRBS;
    }

     
    function wallet() public view returns (address payable) {
        return _wallet;
    }

     
    function rate() public view returns (uint256) {
        return _rate;
    }

     
    function share() public view returns (uint256) {
        return _share;
    }

     
    function bonusPerShare() public view returns (uint256) {
        return _bonusPerShare;
    }

     
    function minimum() public view returns (uint256) {
        return _minimum;
    }

     
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

     
    function reserved() public view returns (uint256) {
        return _reserve;
    }

     
    function delay() public view returns (uint256) {
        return _delay;
    }

}