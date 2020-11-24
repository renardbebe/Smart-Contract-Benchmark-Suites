 

 

pragma solidity 0.5.9;

 
contract ERC20Plus {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    function mint(address _to, uint256 _amount) public returns (bool);
    function owner() public view returns (address);
    function transferOwnership(address newOwner) public;
    function name() public view returns (string memory);
    function symbol() public view returns (string memory);
    function decimals() public view returns (uint8);
    function paused() public view returns (bool);
}

 

pragma solidity ^0.5.9;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMul overflow!');

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, 'SafeDiv cannot divide by 0!');
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeSub underflow!');
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeAdd overflow!');

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'SafeMod cannot compute modulo of 0!');
        return a % b;
    }
}

 

pragma solidity 0.5.9;


 
contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Only owner is able call this function!");
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
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity 0.5.9;

 
contract Crowdsale {
     
    uint256 public startTime;
    uint256 public endTime;

     

     
     

     
    uint256 public weiRaised;


     
     
     
     
     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function initCrowdsale(uint256 _startTime, uint256 _endTime) public {
        require(
            startTime == 0 && endTime == 0,
            "Global variables must be empty when initializing crowdsale!"
        );
        require(_startTime >= now, "_startTime must be more than current time!");
        require(_endTime >= _startTime, "_endTime must be more than _startTime!");

        startTime = _startTime;
        endTime = _endTime;
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }
}

 

pragma solidity 0.5.9;





 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}

 

pragma solidity 0.5.9;



 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "must not be paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "must be paused");
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        _paused = false;
        emit Unpause();
    }
}

 

pragma solidity 0.5.9;

contract FundsSplitterInterface {
    function splitFunds() public payable;
    function splitStarFunds() public;
    function() external payable;
}

 

pragma solidity 0.5.9;

interface StarEthRateInterface {
    function decimalCorrectionFactor() external returns (uint256);
    function starEthRate() external returns (uint256);
}

 

pragma solidity 0.5.9;

 
interface TokenSaleInterface {
    function init
    (
        uint256 _startTime,
        uint256 _endTime,
        address[6] calldata _externalAddresses,
        uint256 _softCap,
        uint256 _crowdsaleCap,
        bool    _isWeiAccepted,
        bool    _isMinting,
        uint256[] calldata _targetRates,
        uint256[] calldata _targetRatesTimestamps
    )
    external;
}

 

pragma solidity 0.5.9;



 
contract Whitelist is Ownable {
    mapping(address => bool) public allowedAddresses;

    event WhitelistUpdated(uint256 timestamp, string operation, address indexed member);

     
    function addToWhitelist(address _address) external onlyOwner {
        allowedAddresses[_address] = true;
        emit WhitelistUpdated(now, "Added", _address);
    }

     
    function addManyToWhitelist(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowedAddresses[_addresses[i]] = true;
            emit WhitelistUpdated(now, "Added", _addresses[i]);
        }
    }

     
    function removeManyFromWhitelist(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowedAddresses[_addresses[i]] = false;
            emit WhitelistUpdated(now, "Removed", _addresses[i]);
        }
    }
}

 

pragma solidity 0.5.9;








 
contract TokenSale is FinalizableCrowdsale, Pausable {
    uint256 public softCap;
    uint256 public crowdsaleCap;
    uint256 public tokensSold;

     
    uint256 public currentTargetRateIndex;
    uint256[] public targetRates;
    uint256[] public targetRatesTimestamps;

     
    uint256 public starRaised;
    address public tokenOwnerAfterSale;
    bool public isWeiAccepted;
    bool public isMinting;
    bool private isInitialized;

     
    Whitelist public whitelist;
    ERC20Plus public starToken;
    FundsSplitterInterface public wallet;
    StarEthRateInterface public starEthRateInterface;

     
    ERC20Plus public tokenOnSale;

     
    mapping (address => uint256) public ethInvestments;
    mapping (address => uint256) public starInvestments;

    event TokenRateChanged(uint256 previousRate, uint256 newRate);
    event TokenStarRateChanged(uint256 previousStarRate, uint256 newStarRate);
    event TokenPurchaseWithStar(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
    function init(
        uint256 _startTime,
        uint256 _endTime,
        address[6] calldata _externalAddresses,  
        uint256 _softCap,
        uint256 _crowdsaleCap,
        bool    _isWeiAccepted,
        bool    _isMinting,
        uint256[] calldata _targetRates,
        uint256[] calldata _targetRatesTimestamps
    )
        external
    {
        require(!isInitialized, "Contract instance was initialized already!");
        isInitialized = true;

        require(
            _externalAddresses[0] != address(0) &&
            _externalAddresses[1] != address(0) &&
            _externalAddresses[2] != address(0) &&
            _externalAddresses[4] != address(0) &&
            _externalAddresses[5] != address(0) &&
            _crowdsaleCap != 0,
            "Parameter variables cannot be empty!"
        );

        require(
            _softCap < _crowdsaleCap,
            "SoftCap should be smaller than crowdsaleCap!"
        );

        currentTargetRateIndex = 0;
        initCrowdsale(_startTime, _endTime);
        tokenOnSale = ERC20Plus(_externalAddresses[2]);
        whitelist = Whitelist(_externalAddresses[0]);
        starToken = ERC20Plus(_externalAddresses[1]);
        wallet = FundsSplitterInterface(uint160(_externalAddresses[5]));
        tokenOwnerAfterSale = _externalAddresses[3];
        starEthRateInterface = StarEthRateInterface(_externalAddresses[4]);
        isWeiAccepted = _isWeiAccepted;
        isMinting = _isMinting;
        _owner = tx.origin;

        uint8 decimals = tokenOnSale.decimals();
        softCap = _softCap.mul(10 ** uint256(decimals));
        crowdsaleCap = _crowdsaleCap.mul(10 ** uint256(decimals));

        targetRates = _targetRates;
        targetRatesTimestamps = _targetRatesTimestamps;

        if (isMinting) {
            require(tokenOwnerAfterSale != address(0), "tokenOwnerAfterSale cannot be empty when minting tokens!");
            require(tokenOnSale.paused(), "Company token must be paused upon initialization!");
        } else {
            require(tokenOwnerAfterSale == address(0), "tokenOwnerAfterSale must be empty when minting tokens!");
        }

        verifyTargetRates();
    }

    modifier isWhitelisted(address beneficiary) {
        require(
            whitelist.allowedAddresses(beneficiary),
            "Beneficiary not whitelisted!"
        );

        _;
    }

     
    function () external payable {
        revert("No fallback function defined!");
    }

     
    function buyTokens(address beneficiary)
        public
        payable
        whenNotPaused
        isWhitelisted(beneficiary)
    {
        require(beneficiary != address(0), "Purchaser address cant be zero!");
        require(validPurchase(), "TokenSale over or not yet started!");
        require(tokensSold < crowdsaleCap, "All tokens sold!");
        if (isMinting) {
            require(tokenOnSale.owner() == address(this), "The token owner must be contract address!");
        }

        checkForNewRateAndUpdate();

        if (!isWeiAccepted) {
            require(msg.value == 0, "Only purchases with STAR are allowed!");
        } else if (msg.value > 0) {
            buyTokensWithWei(beneficiary);
        }

         
        uint256 starAllocationToTokenSale
            = starToken.allowance(msg.sender, address(this));

        if (starAllocationToTokenSale > 0) {
            uint256 decimalCorrectionFactor =
                starEthRateInterface.decimalCorrectionFactor();
            uint256 starEthRate = starEthRateInterface.starEthRate();
            uint256 ethRate = targetRates[currentTargetRateIndex];

             
            uint256 decimals = uint256(tokenOnSale.decimals());
            uint256 tokens = (starAllocationToTokenSale
                .mul(ethRate)
                .mul(starEthRate))
                .mul(10 ** decimals)  
                .div(decimalCorrectionFactor)
                .div(1e18);  

             
            if (tokensSold.add(tokens) > crowdsaleCap) {
                tokens = crowdsaleCap.sub(tokensSold);

                starAllocationToTokenSale = tokens
                    .mul(1e18)
                    .mul(decimalCorrectionFactor)
                    .div(ethRate)
                    .div(starEthRate)
                    .div(10 ** decimals);
            }

             
            starRaised = starRaised.add(starAllocationToTokenSale);
            starInvestments[beneficiary] = starInvestments[beneficiary].add(starAllocationToTokenSale);

            tokensSold = tokensSold.add(tokens);
            sendPurchasedTokens(beneficiary, tokens);
            emit TokenPurchaseWithStar(msg.sender, beneficiary, starAllocationToTokenSale, tokens);

            forwardsStarFunds(starAllocationToTokenSale);
        }
    }

     
    function buyTokensWithWei(address beneficiary)
        internal
    {
        uint256 weiAmount = msg.value;
        uint256 weiRefund;

        uint256 ethRate = targetRates[currentTargetRateIndex];

         
        uint256 decimals = uint256(tokenOnSale.decimals());
        uint256 tokens = weiAmount
            .mul(ethRate)
            .mul(10 ** decimals)  
            .div(1e18);   

         
        if (tokensSold.add(tokens) > crowdsaleCap) {
            tokens = crowdsaleCap.sub(tokensSold);
            weiAmount = tokens.mul(1e18).div(ethRate).div(10 ** decimals);

            weiRefund = msg.value.sub(weiAmount);
        }

         
        weiRaised = weiRaised.add(weiAmount);
        ethInvestments[beneficiary]
            = ethInvestments[beneficiary].add(weiAmount);

        tokensSold = tokensSold.add(tokens);
        sendPurchasedTokens(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardsWeiFunds(weiRefund);
    }

     
    function sendPurchasedTokens(
        address _beneficiary,
        uint256 _tokens
    ) internal {
        if (isMinting) {
            tokenOnSale.mint(_beneficiary, _tokens);
        } else {
            tokenOnSale.transfer(_beneficiary, _tokens);
        }
    }

     
     
    function hasReachedSoftCap() public view returns (bool) {
        if (tokensSold >= softCap) return true;

        return false;
    }

     
     
    function hasEnded() public view returns (bool) {
        if (tokensSold >= crowdsaleCap) return true;

        return super.hasEnded();
    }

     
    function validPurchase() internal view returns (bool) {
        return now >= startTime && now <= endTime;
    }

     
    function forwardsWeiFunds(uint256 _weiRefund) internal {
        if (softCap == 0 || hasReachedSoftCap()) {
            if (_weiRefund > 0) msg.sender.transfer(_weiRefund);

            _forwardAnyFunds();
        }
    }

     
    function forwardsStarFunds(uint256 _value) internal {
        if (softCap > 0 && !hasReachedSoftCap()) {
            starToken.transferFrom(msg.sender, address(this), _value);
        } else {
            starToken.transferFrom(msg.sender, address(wallet), _value);

            _forwardAnyFunds();
        }
    }

     
    function withdrawUserFunds() public {
        require(hasEnded(), "Can only withdraw funds for ended sales!");
        require(
            !hasReachedSoftCap(),
            "Can only withdraw funds for sales that didn't reach soft cap!"
        );

        uint256 investedEthRefund = ethInvestments[msg.sender];
        uint256 investedStarRefund = starInvestments[msg.sender];

        require(
            investedEthRefund > 0 || investedStarRefund > 0,
            "You don't have any funds in the contract!"
        );

         
        ethInvestments[msg.sender] = 0;
        starInvestments[msg.sender] = 0;

        if (investedEthRefund > 0) {
            msg.sender.transfer(investedEthRefund);
        }
        if (investedStarRefund > 0) {
            starToken.transfer(msg.sender, investedStarRefund);
        }
    }

    function verifyTargetRates() internal view {
        require(
            targetRates.length == targetRatesTimestamps.length,
            'Target rates and target rates timestamps lengths should match!'
        );

        require(targetRates.length > 0, 'Target rates cannot be empty!');
        require(
            targetRatesTimestamps[0] == startTime,
            'First target rate timestamp should match startTime!'
        );

        for (uint256 i = 0; i < targetRates.length; i++) {
            if (i > 0) {
                require(
                    targetRatesTimestamps[i-1] < targetRatesTimestamps[i],
                    'Target rates timestamps should be sorted from low to high!'
                );
            }

            if (i == targetRates.length - 1) {
               require(
                    targetRatesTimestamps[i] < endTime,
                    'All target rate timestamps should be before endTime!'
                );
            }

            require(targetRates[i] > 0, 'All target rates must be above 0!');
        }
    }

     
    function getCurrentRate() public view returns (uint256, uint256) {
        for (
            uint256 i = currentTargetRateIndex + 1;
            i < targetRatesTimestamps.length;
            i++
        ) {
            if (now < targetRatesTimestamps[i]) {
                return (targetRates[i - 1], i - 1);
            }
        }

        return (
            targetRates[targetRatesTimestamps.length - 1],
            targetRatesTimestamps.length - 1
        );
    }

     
    function checkForNewRateAndUpdate() public {
        (, uint256 targetRateIndex) = getCurrentRate();  

        if (targetRateIndex > currentTargetRateIndex) {
            currentTargetRateIndex = targetRateIndex;
        }
    }

     
    function finalization() internal {
        uint256 remainingTokens = isMinting
            ? crowdsaleCap.sub(tokensSold)
            : tokenOnSale.balanceOf(address(this));

        if (remainingTokens > 0) {
            sendPurchasedTokens(address(wallet), remainingTokens);
        }
        if (isMinting) {
            tokenOnSale.transferOwnership(tokenOwnerAfterSale);
        }

        super.finalization();
    }

     
    function getWhitelistAddress() external view returns (address) {
        return address(whitelist);
    }

     
    function getStarTokenAddress() external view returns (address) {
        return address(starToken);
    }

     
    function getWalletAddress() external view returns (address) {
        return address(wallet);
    }

     
    function getStarEthRateInterfaceAddress() external view returns (address) {
        return address(starEthRateInterface);
    }

     
    function getTokenOnSaleAddress() external view returns (address) {
        return address(tokenOnSale);
    }

    function _forwardAnyFunds() private {
         
        uint256 ethBalance = address(this).balance;
        uint256 starBalance = starToken.balanceOf(address(this));

        if (ethBalance > 0) {
            address(wallet).transfer(ethBalance);
        }

        if (starBalance > 0) {
            starToken.transfer(address(wallet), starBalance);
        }

        uint256 ethBalanceWallet = address(wallet).balance;
        uint256 starBalanceWallet = starToken.balanceOf(address(wallet));

        if (ethBalanceWallet > 0) {
            wallet.splitFunds();
        }

        if (starBalanceWallet > 0) {
            wallet.splitStarFunds();
        }
    }
}