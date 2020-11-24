 

pragma solidity 0.4.24;

 
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor()
        public
    {
        owner = msg.sender;
    }

     
    modifier onlyOwner()
    {
        require(
            msg.sender == owner,
            "Only the owner of that contract can execute this method"
        );
        _;
    }

     
    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        require(
            newOwner != address(0x0),
            "Invalid address"
        );

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}
 
 
 
interface IOldERC20 {
	function transfer(address to, uint256 value)
        external;

	function transferFrom(address from, address to, uint256 value)
        external;

	function approve(address spender, uint256 value)
        external;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeOldERC20 {
	 
    function checkSuccess()
        private
        pure
		returns (bool)
	{
        uint256 returnValue = 0;

        assembly {
			 
			switch returndatasize

			 
			case 0x0 {
				returnValue := 1
			}

			 
			case 0x20 {
				 
				returndatacopy(0x0, 0x0, 0x20)

				 
				returnValue := mload(0x0)
			}

			 
			default { }
        }

        return returnValue != 0;
    }

    function transfer(address token, address to, uint256 amount) internal {
        IOldERC20(token).transfer(to, amount);
        require(checkSuccess(), "Transfer failed");
    }

    function transferFrom(address token, address from, address to, uint256 amount) internal {
        IOldERC20(token).transferFrom(from, to, amount);
        require(checkSuccess(), "Transfer From failed");
    }
}

library CrowdsaleLib {

    struct Crowdsale {
        uint256 startTime;
        uint256 endTime;
        uint256 capacity;
        uint256 leftAmount;
        uint256 tokenRatio;
        uint256 minContribution;
        uint256 maxContribution;
        uint256 weiRaised;
        address wallet;
    }

    function isValid(Crowdsale storage _self)
        internal
        view
        returns (bool)
    {
        return (
            (_self.startTime >= now) &&
            (_self.endTime >= _self.startTime) &&
            (_self.tokenRatio > 0) &&
            (_self.wallet != address(0))
        );
    }

    function isOpened(Crowdsale storage _self)
        internal
        view
        returns (bool)
    {
        return (now >= _self.startTime && now <= _self.endTime);
    }

    function createCrowdsale(
        address _wallet,
        uint256[8] _values
    )
        internal
        pure
        returns (Crowdsale memory)
    {
        return Crowdsale({
            startTime: _values[0],
            endTime: _values[1],
            capacity: _values[2],
            leftAmount: _values[3],
            tokenRatio: _values[4],
            minContribution: _values[5],
            maxContribution: _values[6],
            weiRaised: _values[7],
            wallet: _wallet
        });
    }
}

contract IUpgradableExchange {

    uint8 public VERSION;

    event FundsMigrated(address indexed user, address indexed exchangeAddress);

    function allowOrRestrictMigrations() external;

    function migrateFunds(address[] _tokens) external;

    function migrateEthers() private;

    function migrateTokens(address[] _tokens) private;

    function importEthers(address _user) external payable;

    function importTokens(address _tokenAddress, uint256 _tokenAmount, address _user) external;

}

 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
        external returns (bool);

    function transferFrom(address from, address to, uint256 value)
        external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library OrderLib {

    struct Order {
        uint256 makerSellAmount;
        uint256 makerBuyAmount;
        uint256 nonce;
        address maker;
        address makerSellToken;
        address makerBuyToken;
    }

     
    function createHash(Order memory order)
        internal
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                order.maker,
                order.makerSellToken,
                order.makerSellAmount,
                order.makerBuyToken,
                order.makerBuyAmount,
                order.nonce,
                this
            )
        );
    }

     
    function createOrder(
        address[3] addresses,
        uint256[3] values
    )
        internal
        pure
        returns (Order memory)
    {
        return Order({
            maker: addresses[0],
            makerSellToken: addresses[1],
            makerSellAmount: values[0],
            makerBuyToken: addresses[2],
            makerBuyAmount: values[1],
            nonce: values[2]
        });
    }

}

 
library Math {

     
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns(uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b)
        internal
        pure
        returns(uint256)
    {
        return a / b;
    }

     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns(uint256)
    {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns(uint256 c)
    {
        c = a + b;
        assert(c >= a);
        return c;
    }

     
    function calculateRate(
        uint256 _numerator,
        uint256 _denominator
    )
        internal
        pure
        returns(uint256)
    {
        return div(mul(_numerator, 1e18), _denominator);
    }

     
    function calculateReferralFee(uint256 _fee, uint256 _referralFeeRate) internal pure returns (uint256) {
        return div(_fee, _referralFeeRate);
    }

     
    function calculateWdxFee(uint256 _etherAmount, uint256 _tokenRatio, uint256 _feeRate) internal pure returns (uint256) {
        return div(div(mul(_etherAmount, 1e18), _tokenRatio), mul(_feeRate, 2));
    }
}

 
contract Token is IERC20 {
    function getBonusFactor(uint256 _startTime, uint256 _endTime, uint256 _weiAmount)
        public view returns (uint256);

    function isUserWhitelisted(address _user)
        public view returns (bool);
}

contract Exchange is Ownable {

    using Math for uint256;

    using OrderLib for OrderLib.Order;

    uint256 public feeRate;

    mapping(address => mapping(address => uint256)) public balances;

    mapping(bytes32 => uint256) public filledAmounts;

    address constant public ETH = address(0x0);

    address public feeAccount;

    constructor(
        address _feeAccount,
        uint256 _feeRate
    )
        public
    {
        feeAccount = _feeAccount;
        feeRate = _feeRate;
    }

    enum ErrorCode {
        INSUFFICIENT_MAKER_BALANCE,
        INSUFFICIENT_TAKER_BALANCE,
        INSUFFICIENT_ORDER_AMOUNT
    }

    event Deposit(
        address indexed tokenAddress,
        address indexed user,
        uint256 amount,
        uint256 balance
    );

    event Withdraw(
        address indexed tokenAddress,
        address indexed user,
        uint256 amount,
        uint256 balance
    );

    event CancelOrder(
        address indexed makerBuyToken,
        address indexed makerSellToken,
        address indexed maker,
        bytes32 orderHash,
        uint256 nonce
    );

    event TakeOrder(
        address indexed maker,
        address taker,
        address indexed makerBuyToken,
        address indexed makerSellToken,
        uint256 takerGivenAmount,
        uint256 takerReceivedAmount,
        bytes32 orderHash,
        uint256 nonce
    );

    event Error(
        uint8 eventId,
        bytes32 orderHash
    );

     
    function setFee(uint256 _feeRate)
        external
        onlyOwner
    {
        feeRate = _feeRate;
    }

     
    function setFeeAccount(address _feeAccount)
        external
        onlyOwner
    {
        feeAccount = _feeAccount;
    }

     
    function depositEthers() external payable
    {
        address user = msg.sender;
        _depositEthers(user);
        emit Deposit(ETH, user, msg.value, balances[ETH][user]);
    }

     
    function depositEthersFor(
        address
        _beneficiary
    )
        external
        payable
    {
        _depositEthers(_beneficiary);
        emit Deposit(ETH, _beneficiary, msg.value, balances[ETH][_beneficiary]);
    }

     
    function depositTokens(
        address _tokenAddress,
        uint256 _amount
    )
        external
    {
        address user = msg.sender;
        _depositTokens(_tokenAddress, _amount, user);
        emit Deposit(_tokenAddress, user, _amount, balances[_tokenAddress][user]);
    }

         
    function depositTokensFor(
        address _tokenAddress,
        uint256 _amount,
        address _beneficiary
    )
        external
    {
        _depositTokens(_tokenAddress, _amount, _beneficiary);
        emit Deposit(_tokenAddress, _beneficiary, _amount, balances[_tokenAddress][_beneficiary]);
    }

     
    function _depositEthers(
        address
        _beneficiary
    )
        internal
    {
        balances[ETH][_beneficiary] = balances[ETH][_beneficiary].add(msg.value);
    }

     
    function _depositTokens(
        address _tokenAddress,
        uint256 _amount,
        address _beneficiary
    )
        internal
    {
        balances[_tokenAddress][_beneficiary] = balances[_tokenAddress][_beneficiary].add(_amount);

        require(
            Token(_tokenAddress).transferFrom(msg.sender, this, _amount),
            "Token transfer is not successfull (maybe you haven't used approve first?)"
        );
    }

     
    function withdrawEthers(uint256 _amount) external
    {
        address user = msg.sender;

        require(
            balances[ETH][user] >= _amount,
            "Not enough funds to withdraw."
        );

        balances[ETH][user] = balances[ETH][user].sub(_amount);

        user.transfer(_amount);

        emit Withdraw(ETH, user, _amount, balances[ETH][user]);
    }

     
    function withdrawTokens(
        address _tokenAddress,
        uint256 _amount
    )
        external
    {
        address user = msg.sender;

        require(
            balances[_tokenAddress][user] >= _amount,
            "Not enough funds to withdraw."
        );

        balances[_tokenAddress][user] = balances[_tokenAddress][user].sub(_amount);

        require(
            Token(_tokenAddress).transfer(user, _amount),
            "Token transfer is not successfull."
        );

        emit Withdraw(_tokenAddress, user, _amount, balances[_tokenAddress][user]);
    }

     
    function transfer(
        address _tokenAddress,
        address _to,
        uint256 _amount
    )
        external
    {
        address user = msg.sender;

        require(
            balances[_tokenAddress][user] >= _amount,
            "Not enough funds to transfer."
        );

        balances[_tokenAddress][user] = balances[_tokenAddress][user].sub(_amount);

        balances[_tokenAddress][_to] = balances[_tokenAddress][_to].add(_amount);
    }

     
    function takeOrder(
        OrderLib.Order memory _order,
        uint256 _takerSellAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        internal
        returns (uint256)
    {
        bytes32 orderHash = _order.createHash();

        require(
            ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash)), _v, _r, _s) == _order.maker,
            "Order maker is invalid."
        );

        if(balances[_order.makerBuyToken][msg.sender] < _takerSellAmount) {
            emit Error(uint8(ErrorCode.INSUFFICIENT_TAKER_BALANCE), orderHash);
            return 0;
        }

        uint256 receivedAmount = (_order.makerSellAmount.mul(_takerSellAmount)).div(_order.makerBuyAmount);

        if(balances[_order.makerSellToken][_order.maker] < receivedAmount) {
            emit Error(uint8(ErrorCode.INSUFFICIENT_MAKER_BALANCE), orderHash);
            return 0;
        }

        if(filledAmounts[orderHash].add(_takerSellAmount) > _order.makerBuyAmount) {
            emit Error(uint8(ErrorCode.INSUFFICIENT_ORDER_AMOUNT), orderHash);
            return 0;
        }

        filledAmounts[orderHash] = filledAmounts[orderHash].add(_takerSellAmount);

        balances[_order.makerBuyToken][msg.sender] = balances[_order.makerBuyToken][msg.sender].sub(_takerSellAmount);
        balances[_order.makerBuyToken][_order.maker] = balances[_order.makerBuyToken][_order.maker].add(_takerSellAmount);

        balances[_order.makerSellToken][msg.sender] = balances[_order.makerSellToken][msg.sender].add(receivedAmount);
        balances[_order.makerSellToken][_order.maker] = balances[_order.makerSellToken][_order.maker].sub(receivedAmount);

        emit TakeOrder(
            _order.maker,
            msg.sender,
            _order.makerBuyToken,
            _order.makerSellToken,
            _takerSellAmount,
            receivedAmount,
            orderHash,
            _order.nonce
        );

        return receivedAmount;
    }

     
    function cancelOrder(
        address[3] _orderAddresses,
        uint256[3] _orderValues,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
    {
        OrderLib.Order memory order = OrderLib.createOrder(_orderAddresses, _orderValues);
        bytes32 orderHash = order.createHash();

        require(
            ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash)), _v, _r, _s) == msg.sender,
            "Only order maker can cancel it."
        );

        filledAmounts[orderHash] = filledAmounts[orderHash].add(order.makerBuyAmount);

        emit CancelOrder(
            order.makerBuyToken,
            order.makerSellToken,
            msg.sender,
            orderHash,
            order.nonce
        );
    }

     
    function cancelMultipleOrders(
        address[3][] _orderAddresses,
        uint256[3][] _orderValues,
        uint8[] _v,
        bytes32[] _r,
        bytes32[] _s
    )
        external
    {
        for (uint256 index = 0; index < _orderAddresses.length; index++) {
            cancelOrder(
                _orderAddresses[index],
                _orderValues[index],
                _v[index],
                _r[index],
                _s[index]
            );
        }
    }
}

contract DailyVolumeUpdater is Ownable {

    using Math for uint256;

    uint256 public dailyVolume;

    uint256 public dailyVolumeCap;

    uint256 private lastDay;

    constructor()
        public
    {
        dailyVolume = 0;
        dailyVolumeCap = 1000 ether;
        lastDay = today();
    }

     
    function setDailyVolumeCap(uint256 _dailyVolumeCap)
        public
        onlyOwner
    {
        dailyVolumeCap = _dailyVolumeCap;
    }

     
    function updateVolume(uint256 _volume)
        internal
    {
        if(today() > lastDay) {
            dailyVolume = _volume;
            lastDay = today();
        } else {
            dailyVolume = dailyVolume.add(_volume);
        }
    }

     
    function isVolumeReached()
        internal
        view
        returns(bool)
    {
        return dailyVolume >= dailyVolumeCap;
    }

     
    function today()
        private
        view
        returns(uint256)
    {
        return block.timestamp.div(1 days);
    }
}

contract DiscountTokenExchange is Exchange, DailyVolumeUpdater {

    uint256 internal discountTokenRatio;

    uint256 private minimumTokenAmountForUpdate;

    address public discountTokenAddress;

    bool internal initialized = false;

    constructor(
        address _discountTokenAddress,
        uint256 _discountTokenRatio
    )
        public
    {
        discountTokenAddress = _discountTokenAddress;
        discountTokenRatio = _discountTokenRatio;
    }

    modifier onlyOnce() {
        require(
            initialized == false,
            "Exchange is already initialized"
        );
        _;
    }

     
    function setDiscountToken(
        address _discountTokenAddress,
        uint256 _discountTokenRatio,
        uint256 _minimumTokenAmountForUpdate
    )
        public
        onlyOwner
        onlyOnce
    {
        discountTokenAddress = _discountTokenAddress;
        discountTokenRatio = _discountTokenRatio;
        minimumTokenAmountForUpdate = _minimumTokenAmountForUpdate;
        initialized = true;
    }

     
    function updateTokenRatio(
        uint256 _etherAmount,
        uint256 _tokenAmount
    )
        internal
    {
        if(_tokenAmount >= minimumTokenAmountForUpdate) {
            discountTokenRatio = _etherAmount.calculateRate(_tokenAmount);
        }
    }

     
    function setMinimumTokenAmountForUpdate(
        uint256 _minimumTokenAmountForUpdate
    )
        external
        onlyOwner
    {
        minimumTokenAmountForUpdate = _minimumTokenAmountForUpdate;
    }

     
    function takeSellTokenOrder(
        address[3] _orderAddresses,
        uint256[3] _orderValues,
        uint256 _takerSellAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        require(
            _orderAddresses[1] == discountTokenAddress,
            "Should sell WeiDex Tokens"
        );

        require(
            0 < takeOrder(OrderLib.createOrder(_orderAddresses, _orderValues), _takerSellAmount, _v, _r, _s),
            "Trade failure"
        );
        updateVolume(_takerSellAmount);
        updateTokenRatio(_orderValues[1], _orderValues[0]);
    }

     
    function takeBuyTokenOrder(
        address[3] _orderAddresses,
        uint256[3] _orderValues,
        uint256 _takerSellAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        require(
            _orderAddresses[2] == discountTokenAddress,
            "Should buy WeiDex Tokens"
        );

        uint256 receivedAmount = takeOrder(OrderLib.createOrder(_orderAddresses, _orderValues), _takerSellAmount, _v, _r, _s);
        require(0 < receivedAmount, "Trade failure");
        updateVolume(receivedAmount);
        updateTokenRatio(_orderValues[0], _orderValues[1]);
    }
}

contract ReferralExchange is Exchange {

    uint256 public referralFeeRate;

    mapping(address => address) public referrals;

    constructor(
        uint256 _referralFeeRate
    )
        public
    {
        referralFeeRate = _referralFeeRate;
    }

    event ReferralBalanceUpdated(
        address refererAddress,
        address referralAddress,
        address tokenAddress,
        uint256 feeAmount,
        uint256 referralFeeAmount
    );

    event ReferralDeposit(
        address token,
        address indexed user,
        address indexed referrer,
        uint256 amount,
        uint256 balance
    );

     
    function depositEthers(address _referrer)
        external
        payable
    {
        address user = msg.sender;

        require(
            0x0 == referrals[user],
            "This user already have a referrer."
        );

        super._depositEthers(user);
        referrals[user] = _referrer;
        emit ReferralDeposit(ETH, user, _referrer, msg.value, balances[ETH][user]);
    }

     
    function depositTokens(
        address _tokenAddress,
        uint256 _amount,
        address _referrer
    )
        external
    {
        address user = msg.sender;

        require(
            0x0 == referrals[user],
            "This user already have a referrer."
        );

        super._depositTokens(_tokenAddress, _amount, user);
        referrals[user] = _referrer;
        emit ReferralDeposit(_tokenAddress, user, _referrer, _amount, balances[_tokenAddress][user]);
    }

     
    function setReferralFee(uint256 _referralFeeRate)
        external
        onlyOwner
    {
        referralFeeRate = _referralFeeRate;
    }

     
    function getReferrer(address _user)
        internal
        view
        returns(address referrer)
    {
        return referrals[_user] != address(0x0) ? referrals[_user] : feeAccount;
    }
}

contract UpgradableExchange is Exchange {

    uint8 constant public VERSION = 0;

    address public newExchangeAddress;

    bool public isMigrationAllowed;

    event FundsMigrated(address indexed user, address indexed exchangeAddress);

     
    function setNewExchangeAddress(address _newExchangeAddress)
        external
        onlyOwner
    {
        newExchangeAddress = _newExchangeAddress;
    }

     
    function allowOrRestrictMigrations()
        external
        onlyOwner
    {
        isMigrationAllowed = !isMigrationAllowed;
    }

     
    function migrateFunds(address[] _tokens) external {

        require(
            false != isMigrationAllowed,
            "Fund migration is not allowed"
        );

        require(
            IUpgradableExchange(newExchangeAddress).VERSION() > VERSION,
            "New exchange version should be greater than the current version."
        );

        migrateEthers();

        migrateTokens(_tokens);

        emit FundsMigrated(msg.sender, newExchangeAddress);
    }

     
    function migrateEthers() private {

        uint256 etherAmount = balances[ETH][msg.sender];
        if (etherAmount > 0) {
            balances[ETH][msg.sender] = 0;

            IUpgradableExchange(newExchangeAddress).importEthers.value(etherAmount)(msg.sender);
        }
    }

     
    function migrateTokens(address[] _tokens) private {

        for (uint256 index = 0; index < _tokens.length; index++) {

            address tokenAddress = _tokens[index];

            uint256 tokenAmount = balances[tokenAddress][msg.sender];

            if (0 == tokenAmount) {
                continue;
            }

            require(
                Token(tokenAddress).approve(newExchangeAddress, tokenAmount),
                "Approve failed"
            );

            balances[tokenAddress][msg.sender] = 0;

            IUpgradableExchange(newExchangeAddress).importTokens(tokenAddress, tokenAmount, msg.sender);
        }
    }
}

contract ExchangeOffering is Exchange {

    using CrowdsaleLib for CrowdsaleLib.Crowdsale;

    mapping(address => CrowdsaleLib.Crowdsale) public crowdsales;

    mapping(address => mapping(address => uint256)) public userContributionForProject;

    event TokenPurchase(
        address indexed project,
        address indexed contributor,
        uint256 tokens,
        uint256 weiAmount
    );

    function registerCrowdsale(
        address _project,
        address _projectWallet,
        uint256[8] _values
    )
        public
        onlyOwner
    {
        crowdsales[_project] = CrowdsaleLib.createCrowdsale(_projectWallet, _values);

        require(
            crowdsales[_project].isValid(),
            "Crowdsale is not active."
        );

         
        require(
            getBonusFactor(_project, crowdsales[_project].minContribution) >= 0,
            "The project should have *getBonusFactor* function implemented. The function should return the bonus percentage depending on the start/end date and contribution amount. Should return 0 if there is no bonus."
        );

         
        require(
            isUserWhitelisted(_project, this),
            "The project should have *isUserWhitelisted* function implemented. This contract address should be whitelisted"
        );
    }

    function buyTokens(address _project)
       public
       payable
    {
        uint256 weiAmount = msg.value;

        address contributor = msg.sender;

        address crowdsaleWallet = crowdsales[_project].wallet;

        require(
            isUserWhitelisted(_project, contributor), "User is not whitelisted"
        );

        require(
            validContribution(_project, contributor, weiAmount),
            "Contribution is not valid: Check minimum/maximum contribution amount or if crowdsale cap is reached"
        );

        uint256 tokens = weiAmount.mul(crowdsales[_project].tokenRatio);

        uint256 bonus = getBonusFactor(_project, weiAmount);

        uint256 bonusAmount = tokens.mul(bonus).div(100);

        uint256 totalPurchasedTokens = tokens.add(bonusAmount);

        crowdsales[_project].leftAmount = crowdsales[_project].leftAmount.sub(totalPurchasedTokens);

        require(Token(_project).transfer(contributor, totalPurchasedTokens), "Transfer failed");

        crowdsales[_project].weiRaised = crowdsales[_project].weiRaised.add(weiAmount);

        userContributionForProject[_project][contributor] = userContributionForProject[_project][contributor].add(weiAmount);

        balances[ETH][crowdsaleWallet] = balances[ETH][crowdsaleWallet].add(weiAmount);

        emit TokenPurchase(_project, contributor, totalPurchasedTokens, weiAmount);
    }

    function withdrawWhenFinished(address _project) public {

        address crowdsaleWallet = crowdsales[_project].wallet;

        require(
            msg.sender == crowdsaleWallet,
            "Only crowdsale owner can withdraw funds that are left."
        );

        require(
            !crowdsales[_project].isOpened(),
            "You can't withdraw funds yet. Crowdsale should end first."
        );

        uint256 leftAmount = crowdsales[_project].leftAmount;

        crowdsales[_project].leftAmount = 0;

        require(Token(_project).transfer(crowdsaleWallet, leftAmount), "Transfer failed");
    }

    function saleOpen(address _project)
        public
        view
        returns(bool)
    {
        return crowdsales[_project].isOpened();
    }

    function getBonusFactor(address _project, uint256 _weiAmount)
        public
        view
        returns(uint256)
    {
        return Token(_project).getBonusFactor(crowdsales[_project].startTime, crowdsales[_project].endTime, _weiAmount);
    }

    function isUserWhitelisted(address _project, address _user)
        public
        view
        returns(bool)
    {
        return Token(_project).isUserWhitelisted(_user);
    }

    function validContribution(
        address _project,
        address _user,
        uint256 _weiAmount
    )
        private
        view
        returns(bool)
    {
        if (saleOpen(_project)) {
             
            if (_weiAmount < crowdsales[_project].minContribution) {
                return false;
            }

             
            if (userContributionForProject[_project][_user].add(_weiAmount) > crowdsales[_project].maxContribution) {
                return false;
            }

             
            if (crowdsales[_project].capacity < crowdsales[_project].weiRaised.add(_weiAmount)) {
                return false;
            }
        } else {
            return false;
        }

        return msg.value != 0;  
    }
}

contract OldERC20ExchangeSupport is Exchange, ReferralExchange {

     
    function depositOldTokens(
        address _tokenAddress,
        uint256 _amount
    )
        external
    {
        address user = msg.sender;
        _depositOldTokens(_tokenAddress, _amount, user);
        emit Deposit(_tokenAddress, user, _amount, balances[_tokenAddress][user]);
    }

     
    function depositOldTokens(
        address _tokenAddress,
        uint256 _amount,
        address _referrer
    )
        external
    {
        address user = msg.sender;

        require(
            0x0 == referrals[user],
            "This user already have a referrer."
        );

        _depositOldTokens(_tokenAddress, _amount, user);
        referrals[user] = _referrer;
        emit ReferralDeposit(_tokenAddress, user, _referrer, _amount, balances[_tokenAddress][user]);
    }

         
    function depositOldTokensFor(
        address _tokenAddress,
        uint256 _amount,
        address _beneficiary
    )
        external
    {
        _depositOldTokens(_tokenAddress, _amount, _beneficiary);
        emit Deposit(_tokenAddress, _beneficiary, _amount, balances[_tokenAddress][_beneficiary]);
    }

     
    function withdrawOldTokens(
        address _tokenAddress,
        uint256 _amount
    )
        external
    {
        address user = msg.sender;

        require(
            balances[_tokenAddress][user] >= _amount,
            "Not enough funds to withdraw."
        );

        balances[_tokenAddress][user] = balances[_tokenAddress][user].sub(_amount);

        SafeOldERC20.transfer(_tokenAddress, user, _amount);

        emit Withdraw(_tokenAddress, user, _amount, balances[_tokenAddress][user]);
    }

     
    function _depositOldTokens(
        address _tokenAddress,
        uint256 _amount,
        address _beneficiary
    )
        internal
    {
        balances[_tokenAddress][_beneficiary] = balances[_tokenAddress][_beneficiary].add(_amount);

        SafeOldERC20.transferFrom(_tokenAddress, msg.sender, this, _amount);
    }
}

contract WeiDex is DiscountTokenExchange, ReferralExchange, UpgradableExchange, ExchangeOffering, OldERC20ExchangeSupport  {

    mapping(bytes4 => bool) private allowedMethods;

    function () public payable {
        revert("Cannot send Ethers to the contract, use depositEthers");
    }

    constructor(
        address _feeAccount,
        uint256 _feeRate,
        uint256 _referralFeeRate,
        address _discountTokenAddress,
        uint256 _discountTokenRatio
    )
        public
        Exchange(_feeAccount, _feeRate)
        ReferralExchange(_referralFeeRate)
        DiscountTokenExchange(_discountTokenAddress, _discountTokenRatio)
    {
         
    }

     
    function allowOrRestrictMethod(
        bytes4 _methodId,
        bool _allowed
    )
        external
        onlyOwner
    {
        allowedMethods[_methodId] = _allowed;
    }

     
    function takeAllOrRevert(
        address[3][] _orderAddresses,
        uint256[3][] _orderValues,
        uint256[] _takerSellAmount,
        uint8[] _v,
        bytes32[] _r,
        bytes32[] _s,
        bytes4 _methodId
    )
        external
    {
        require(
            allowedMethods[_methodId],
            "Can't call this method"
        );

        for (uint256 index = 0; index < _orderAddresses.length; index++) {
            require(
                address(this).delegatecall(
                _methodId,
                _orderAddresses[index],
                _orderValues[index],
                _takerSellAmount[index],
                _v[index],
                _r[index],
                _s[index]
                ),
                "Method call failed"
            );
        }
    }

     
    function takeAllPossible(
        address[3][] _orderAddresses,
        uint256[3][] _orderValues,
        uint256[] _takerSellAmount,
        uint8[] _v,
        bytes32[] _r,
        bytes32[] _s,
        bytes4 _methodId
    )
        external
    {
        require(
            allowedMethods[_methodId],
            "Can't call this method"
        );

        for (uint256 index = 0; index < _orderAddresses.length; index++) {
            address(this).delegatecall(
            _methodId,
            _orderAddresses[index],
            _orderValues[index],
            _takerSellAmount[index],
            _v[index],
            _r[index],
            _s[index]
            );
        }
    }

     
    function takeBuyOrder(
        address[3] _orderAddresses,
        uint256[3] _orderValues,
        uint256 _takerSellAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        external
    {
        require(
            _orderAddresses[1] == ETH,
            "Base currency must be ether's (0x0)"
        );

        OrderLib.Order memory order = OrderLib.createOrder(_orderAddresses, _orderValues);
        uint256 receivedAmount = takeOrder(order, _takerSellAmount, _v, _r, _s);

        require(0 < receivedAmount, "Trade failure");

        updateVolume(receivedAmount);

        if (!isVolumeReached()) {
            takeFee(order.maker, msg.sender, order.makerBuyToken, _takerSellAmount, receivedAmount);
        }
    }

     
    function takeSellOrder(
        address[3] _orderAddresses,
        uint256[3] _orderValues,
        uint256 _takerSellAmount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
    {
        require(
            _orderAddresses[2] == ETH,
            "Base currency must be ether's (0x0)"
        );

        OrderLib.Order memory order = OrderLib.createOrder(_orderAddresses, _orderValues);

        uint256 receivedAmount = takeOrder(order, _takerSellAmount, _v, _r, _s);

        require(0 < receivedAmount, "Trade failure");

        updateVolume(_takerSellAmount);

        if (!isVolumeReached()) {
            takeFee(order.maker, msg.sender, order.makerSellToken, receivedAmount, _takerSellAmount);
        }
    }

     
    function takeFee(
        address _maker,
        address _taker,
        address _tokenAddress,
        uint256 _tokenFulfilledAmount,
        uint256 _etherFulfilledAmount
    )
        private
    {
        uint256 _feeRate = feeRate;  
        uint256 feeInWdx = _etherFulfilledAmount.calculateWdxFee(discountTokenRatio, feeRate);

        takeFee(_maker, ETH, _etherFulfilledAmount.div(_feeRate), feeInWdx);
        takeFee(_taker, _tokenAddress, _tokenFulfilledAmount.div(_feeRate), feeInWdx);
    }

     
    function takeFee(
        address _user,
        address _tokenAddress,
        uint256 _tokenFeeAmount,
        uint256 _wdxFeeAmount
        )
        private
    {
        if(balances[discountTokenAddress][_user] >= _wdxFeeAmount) {
            takeFee(_user, discountTokenAddress, _wdxFeeAmount);
        } else {
            takeFee(_user, _tokenAddress, _tokenFeeAmount);
        }
    }

     
    function takeFee(
        address _user,
        address _tokenAddress,
        uint256 _fullFee
        )
        private
    {
        address _feeAccount = feeAccount;  
        address referrer = getReferrer(_user);
        uint256 referralFee = _fullFee.calculateReferralFee(referralFeeRate);

        balances[_tokenAddress][_user] = balances[_tokenAddress][_user].sub(_fullFee);

        if(referrer == _feeAccount) {
            balances[_tokenAddress][_feeAccount] = balances[_tokenAddress][_feeAccount].add(_fullFee);
        } else {
            balances[_tokenAddress][_feeAccount] = balances[_tokenAddress][_feeAccount].add(_fullFee.sub(referralFee));
            balances[_tokenAddress][referrer] = balances[_tokenAddress][referrer].add(referralFee);
        }
        emit ReferralBalanceUpdated(referrer, _user, _tokenAddress, _fullFee, referralFee);
    }
}