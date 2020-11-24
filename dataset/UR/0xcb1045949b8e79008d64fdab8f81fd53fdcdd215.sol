 

pragma solidity ^0.4.24;

 

 
contract Initializable {

   
  bool private initialized;

   
  bool private initializing;

   
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

   
  function isConstructor() private view returns (bool) {
     
     
     
     
     
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

   
  uint256[50] private ______gap;
}

 

 
contract Ownable is Initializable {
  address private _owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  function initialize(address sender) public initializer {
    _owner = sender;
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
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

  uint256[50] private ______gap;
}

 

 
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

 

 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(account) }
    return size > 0;
  }
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

 

 
library SafeERC20 {
     
    function safeTransfer(IERC20 _token, address _to, uint256 _value) internal returns (bool) {
        uint256 prevBalance = _token.balanceOf(address(this));

        require(prevBalance >= _value, "Insufficient funds");

        bool success = address(_token).call(
            abi.encodeWithSignature("transfer(address,uint256)", _to, _value)
        );

        if (!success) {
            return false;
        }

        require(prevBalance - _value == _token.balanceOf(address(this)), "Transfer failed");

        return true;
    }

     
    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to, 
        uint256 _value
    ) internal returns (bool) 
    {
        uint256 prevBalance = _token.balanceOf(_from);

        require(prevBalance >= _value, "Insufficient funds");
        require(_token.allowance(_from, address(this)) >= _value, "Insufficient allowance");

        _token.transferFrom(_from, _to, _value);

        require(prevBalance - _value == _token.balanceOf(_from), "Transfer failed");

        return true;
    }

    
    function safeApprove(IERC20 _token, address _spender, uint256 _value) internal returns (bool) {
        bool success = address(_token).call(abi.encodeWithSelector(
            _token.approve.selector,
            _spender,
            _value
        )); 

        if (!success) {
            return false;
        }

        require(_token.allowance(address(this), _spender) == _value, "Approve failed");

        return true;
    }

    
    function clearApprove(IERC20 _token, address _spender) internal returns (bool) {
        bool success = safeApprove(_token, _spender, 0);

        if (!success) {
            return safeApprove(_token, _spender, 1);
        }

        return true;
    }
}

 

contract ITokenConverter {    
    using SafeMath for uint256;

     
    function convert(
        IERC20 _srcToken,
        IERC20 _destToken,
        uint256 _srcAmount,
        uint256 _destAmount
        ) external returns (uint256);

     
    function getExpectedRate(IERC20 _srcToken, IERC20 _destToken, uint256 _srcAmount) 
        public view returns(uint256 expectedRate, uint256 slippageRate);
}

 

 
contract ERC20 is IERC20 {
    function burn(uint256 _value) public;
}


 
contract LANDRegistry {
    function assignMultipleParcels(int[] x, int[] y, address beneficiary) external;
}


contract LANDAuctionStorage {
    uint256 constant public PERCENTAGE_OF_TOKEN_BALANCE = 5;
    uint256 constant public MAX_DECIMALS = 18;

    enum Status { created, finished }

    struct Func {
        uint256 slope;
        uint256 base;
        uint256 limit;
    }

    struct Token {
        uint256 decimals;
        bool shouldBurnTokens;
        bool shouldForwardTokens;
        address forwardTarget;
        bool isAllowed;
    }

    uint256 public conversionFee = 105;
    uint256 public totalBids = 0;
    Status public status;
    uint256 public gasPriceLimit;
    uint256 public landsLimitPerBid;
    ERC20 public manaToken;
    LANDRegistry public landRegistry;
    ITokenConverter public dex;
    mapping (address => Token) public tokensAllowed;
    uint256 public totalManaBurned = 0;
    uint256 public totalLandsBidded = 0;
    uint256 public startTime;
    uint256 public endTime;

    Func[] internal curves;
    uint256 internal initialPrice;
    uint256 internal endPrice;
    uint256 internal duration;

    event AuctionCreated(
      address indexed _caller,
      uint256 _startTime,
      uint256 _duration,
      uint256 _initialPrice,
      uint256 _endPrice
    );

    event BidConversion(
      uint256 _bidId,
      address indexed _token,
      uint256 _requiredManaAmountToBurn,
      uint256 _amountOfTokenConverted,
      uint256 _requiredTokenBalance
    );

    event BidSuccessful(
      uint256 _bidId,
      address indexed _beneficiary,
      address indexed _token,
      uint256 _pricePerLandInMana,
      uint256 _manaAmountToBurn,
      int[] _xs,
      int[] _ys
    );

    event AuctionFinished(
      address indexed _caller,
      uint256 _time,
      uint256 _pricePerLandInMana
    );

    event TokenBurned(
      uint256 _bidId,
      address indexed _token,
      uint256 _total
    );

    event TokenTransferred(
      uint256 _bidId,
      address indexed _token,
      address indexed _to,
      uint256 _total
    );

    event LandsLimitPerBidChanged(
      address indexed _caller,
      uint256 _oldLandsLimitPerBid, 
      uint256 _landsLimitPerBid
    );

    event GasPriceLimitChanged(
      address indexed _caller,
      uint256 _oldGasPriceLimit,
      uint256 _gasPriceLimit
    );

    event DexChanged(
      address indexed _caller,
      address indexed _oldDex,
      address indexed _dex
    );

    event TokenAllowed(
      address indexed _caller,
      address indexed _address,
      uint256 _decimals,
      bool _shouldBurnTokens,
      bool _shouldForwardTokens,
      address indexed _forwardTarget
    );

    event TokenDisabled(
      address indexed _caller,
      address indexed _address
    );

    event ConversionFeeChanged(
      address indexed _caller,
      uint256 _oldConversionFee,
      uint256 _conversionFee
    );
}

 

contract LANDAuction is Ownable, LANDAuctionStorage {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for ERC20;

     
    constructor(
        uint256[] _xPoints, 
        uint256[] _yPoints, 
        uint256 _startTime,
        uint256 _landsLimitPerBid,
        uint256 _gasPriceLimit,
        ERC20 _manaToken,
        LANDRegistry _landRegistry,
        address _dex
    ) public {
        require(
            PERCENTAGE_OF_TOKEN_BALANCE == 5, 
            "Balance of tokens required should be equal to 5%"
        );
         
        Ownable.initialize(msg.sender);

         
        require(_startTime > block.timestamp, "Started time should be after now");
        startTime = _startTime;

         
        require(
            address(_landRegistry).isContract(),
            "The LANDRegistry token address must be a deployed contract"
        );
        landRegistry = _landRegistry;

        setDex(_dex);

         
        allowToken(
            address(_manaToken), 
            18,
            true, 
            false, 
            address(0)
        );
        manaToken = _manaToken;

         
        duration = _xPoints[_xPoints.length - 1];
        require(duration > 1 days, "The duration should be greater than 1 day");

         
        _setCurve(_xPoints, _yPoints);

         
        setLandsLimitPerBid(_landsLimitPerBid);
        setGasPriceLimit(_gasPriceLimit);
        
         
        status = Status.created;      

        emit AuctionCreated(
            msg.sender,
            startTime,
            duration,
            initialPrice, 
            endPrice
        );
    }

     
    function bid(
        int[] _xs, 
        int[] _ys, 
        address _beneficiary, 
        ERC20 _fromToken
    )
        external 
    {
        _validateBidParameters(
            _xs, 
            _ys, 
            _beneficiary, 
            _fromToken
        );
        
        uint256 bidId = _getBidId();
        uint256 bidPriceInMana = _xs.length.mul(getCurrentPrice());
        uint256 manaAmountToBurn = bidPriceInMana;

        if (address(_fromToken) != address(manaToken)) {
            require(
                address(dex).isContract(), 
                "Paying with other tokens has been disabled"
            );
             
             
            manaAmountToBurn = _convertSafe(bidId, _fromToken, bidPriceInMana);
        } else {
             
            require(
                _fromToken.safeTransferFrom(msg.sender, address(this), bidPriceInMana),
                "Insuficient balance or unauthorized amount (transferFrom failed)"
            );
        }

         
        _processFunds(bidId, _fromToken);

         
        landRegistry.assignMultipleParcels(_xs, _ys, _beneficiary);

        emit BidSuccessful(
            bidId,
            _beneficiary,
            _fromToken,
            getCurrentPrice(),
            manaAmountToBurn,
            _xs,
            _ys
        );  

         
        _updateStats(_xs.length, manaAmountToBurn);        
    }

     
    function _validateBidParameters(
        int[] _xs, 
        int[] _ys, 
        address _beneficiary, 
        ERC20 _fromToken
    ) internal view 
    {
        require(startTime <= block.timestamp, "The auction has not started");
        require(
            status == Status.created && 
            block.timestamp.sub(startTime) <= duration, 
            "The auction has finished"
        );
        require(tx.gasprice <= gasPriceLimit, "Gas price limit exceeded");
        require(_beneficiary != address(0), "The beneficiary could not be the 0 address");
        require(_xs.length > 0, "You should bid for at least one LAND");
        require(_xs.length <= landsLimitPerBid, "LAND limit exceeded");
        require(_xs.length == _ys.length, "X values length should be equal to Y values length");
        require(tokensAllowed[address(_fromToken)].isAllowed, "Token not allowed");
        for (uint256 i = 0; i < _xs.length; i++) {
            require(
                -150 <= _xs[i] && _xs[i] <= 150 && -150 <= _ys[i] && _ys[i] <= 150,
                "The coordinates should be inside bounds -150 & 150"
            );
        }
    }

     
    function getCurrentPrice() public view returns (uint256) { 
         
        if (startTime == 0 || startTime >= block.timestamp) {
            return initialPrice;
        }

         
        uint256 timePassed = block.timestamp - startTime;
        if (timePassed >= duration) {
            return endPrice;
        }

        return _getPrice(timePassed);
    }

     
    function _convertSafe(
        uint256 _bidId,
        ERC20 _fromToken,
        uint256 _bidPriceInMana
    ) internal returns (uint256 requiredManaAmountToBurn)
    {
        requiredManaAmountToBurn = _bidPriceInMana;
        Token memory fromToken = tokensAllowed[address(_fromToken)];

        uint256 bidPriceInManaPlusSafetyMargin = _bidPriceInMana.mul(conversionFee).div(100);

         
        uint256 tokenRate = getRate(manaToken, _fromToken, bidPriceInManaPlusSafetyMargin);

         
        uint256 requiredTokenBalance = 0;
        
        if (fromToken.shouldBurnTokens || fromToken.shouldForwardTokens) {
            requiredTokenBalance = _calculateRequiredTokenBalance(requiredManaAmountToBurn, tokenRate);
            requiredManaAmountToBurn = _calculateRequiredManaAmount(_bidPriceInMana);
        }

         
        uint256 tokensToConvertPlusSafetyMargin = bidPriceInManaPlusSafetyMargin
            .mul(tokenRate)
            .div(10 ** 18);

         
        if (MAX_DECIMALS > fromToken.decimals) {
            requiredTokenBalance = _normalizeDecimals(
                fromToken.decimals, 
                requiredTokenBalance
            );
            tokensToConvertPlusSafetyMargin = _normalizeDecimals(
                fromToken.decimals,
                tokensToConvertPlusSafetyMargin
            );
        }

         
        require(
            _fromToken.safeTransferFrom(msg.sender, address(this), tokensToConvertPlusSafetyMargin),
            "Transfering the totalPrice in token to LANDAuction contract failed"
        );
        
         
        uint256 finalTokensToConvert = tokensToConvertPlusSafetyMargin.sub(requiredTokenBalance);

         
        require(_fromToken.safeApprove(address(dex), finalTokensToConvert), "Error approve");

         
        uint256 change = dex.convert(
                _fromToken,
                manaToken,
                finalTokensToConvert,
                requiredManaAmountToBurn
        );

        
        if (change > 0) {
             
            require(
                _fromToken.safeTransfer(msg.sender, change),
                "Transfering the change to sender failed"
            );
        }

         
        require(_fromToken.clearApprove(address(dex)), "Error remove approval");

        emit BidConversion(
            _bidId,
            address(_fromToken),
            requiredManaAmountToBurn,
            tokensToConvertPlusSafetyMargin.sub(change),
            requiredTokenBalance
        );
    }

     
    function getRate(
        IERC20 _srcToken, 
        IERC20 _destToken, 
        uint256 _srcAmount
    ) public view returns (uint256 rate) 
    {
        (rate,) = dex.getExpectedRate(_srcToken, _destToken, _srcAmount);
    }

     
    function _calculateRequiredTokenBalance(
        uint256 _totalPrice,
        uint256 _tokenRate
    ) 
    internal pure returns (uint256) 
    {
        return _totalPrice.mul(_tokenRate)
            .div(10 ** 18)
            .mul(PERCENTAGE_OF_TOKEN_BALANCE)
            .div(100);
    }

     
    function _calculateRequiredManaAmount(
        uint256 _totalPrice
    ) 
    internal pure returns (uint256)
    {
        return _totalPrice.mul(100 - PERCENTAGE_OF_TOKEN_BALANCE).div(100);
    }

     
    function _processFunds(uint256 _bidId, ERC20 _token) internal {
         
        _burnTokens(_bidId, manaToken);

         
        Token memory token = tokensAllowed[address(_token)];
        if (_token != manaToken) {
            if (token.shouldBurnTokens) {
                _burnTokens(_bidId, _token);
            }
            if (token.shouldForwardTokens) {
                _forwardTokens(_bidId, token.forwardTarget, _token);
            }   
        }
    }

     
    function _getPrice(uint256 _time) internal view returns (uint256) {
        for (uint256 i = 0; i < curves.length; i++) {
            Func storage func = curves[i];
            if (_time < func.limit) {
                return func.base.sub(func.slope.mul(_time));
            }
        }
        revert("Invalid time");
    }

     
    function _burnTokens(uint256 _bidId, ERC20 _token) private {
        uint256 balance = _token.balanceOf(address(this));

         
        require(balance > 0, "Balance to burn should be > 0");
        
        _token.burn(balance);

        emit TokenBurned(_bidId, address(_token), balance);

         
        balance = _token.balanceOf(address(this));
        require(balance == 0, "Burn token failed");
    }

     
    function _forwardTokens(uint256 _bidId, address _address, ERC20 _token) private {
        uint256 balance = _token.balanceOf(address(this));

         
        require(balance > 0, "Balance to burn should be > 0");
        
        _token.safeTransfer(_address, balance);

        emit TokenTransferred(
            _bidId, 
            address(_token), 
            _address,balance
        );

         
        balance = _token.balanceOf(address(this));
        require(balance == 0, "Transfer token failed");
    }

     
    function setConversionFee(uint256 _fee) external onlyOwner {
        require(_fee < 200 && _fee >= 100, "Conversion fee should be >= 100 and < 200");
        emit ConversionFeeChanged(msg.sender, conversionFee, _fee);
        conversionFee = _fee;
    }

     
    function finishAuction() public onlyOwner {
        require(status != Status.finished, "The auction is finished");

        uint256 currentPrice = getCurrentPrice();

        status = Status.finished;
        endTime = block.timestamp;

        emit AuctionFinished(msg.sender, block.timestamp, currentPrice);
    }

     
    function setLandsLimitPerBid(uint256 _landsLimitPerBid) public onlyOwner {
        require(_landsLimitPerBid > 0, "The LAND limit should be greater than 0");
        emit LandsLimitPerBidChanged(msg.sender, landsLimitPerBid, _landsLimitPerBid);
        landsLimitPerBid = _landsLimitPerBid;
    }

     
    function setGasPriceLimit(uint256 _gasPriceLimit) public onlyOwner {
        require(_gasPriceLimit > 0, "The gas price should be greater than 0");
        emit GasPriceLimitChanged(msg.sender, gasPriceLimit, _gasPriceLimit);
        gasPriceLimit = _gasPriceLimit;
    }

     
    function setDex(address _dex) public onlyOwner {
        require(_dex != address(dex), "The dex is the current");
        if (_dex != address(0)) {
            require(_dex.isContract(), "The dex address must be a deployed contract");
        }
        emit DexChanged(msg.sender, dex, _dex);
        dex = ITokenConverter(_dex);
    }

     
    function allowToken(
        address _address,
        uint256 _decimals,
        bool _shouldBurnTokens,
        bool _shouldForwardTokens,
        address _forwardTarget
    ) 
    public onlyOwner 
    {
        require(
            _address.isContract(),
            "Tokens allowed should be a deployed ERC20 contract"
        );
        require(
            _decimals > 0 && _decimals <= MAX_DECIMALS,
            "Decimals should be greather than 0 and less or equal to 18"
        );
        require(
            !(_shouldBurnTokens && _shouldForwardTokens),
            "The token should be either burned or transferred"
        );
        require(
            !_shouldForwardTokens || 
            (_shouldForwardTokens && _forwardTarget != address(0)),
            "The token should be transferred to a deployed contract"
        );
        require(
            _forwardTarget != address(this) && _forwardTarget != _address, 
            "The forward target should be different from  this contract and the erc20 token"
        );
        
        require(!tokensAllowed[_address].isAllowed, "The ERC20 token is already allowed");

        tokensAllowed[_address] = Token({
            decimals: _decimals,
            shouldBurnTokens: _shouldBurnTokens,
            shouldForwardTokens: _shouldForwardTokens,
            forwardTarget: _forwardTarget,
            isAllowed: true
        });

        emit TokenAllowed(
            msg.sender, 
            _address, 
            _decimals,
            _shouldBurnTokens,
            _shouldForwardTokens,
            _forwardTarget
        );
    }

     
    function disableToken(address _address) public onlyOwner {
        require(
            tokensAllowed[_address].isAllowed,
            "The ERC20 token is already disabled"
        );
        delete tokensAllowed[_address];
        emit TokenDisabled(msg.sender, _address);
    }

     
    function _setCurve(uint256[] _xPoints, uint256[] _yPoints) internal {
        uint256 pointsLength = _xPoints.length;
        require(pointsLength == _yPoints.length, "Points should have the same length");
        for (uint256 i = 0; i < pointsLength - 1; i++) {
            uint256 x1 = _xPoints[i];
            uint256 x2 = _xPoints[i + 1];
            uint256 y1 = _yPoints[i];
            uint256 y2 = _yPoints[i + 1];
            require(x1 < x2, "X points should increase");
            require(y1 > y2, "Y points should decrease");
            (uint256 base, uint256 slope) = _getFunc(
                x1, 
                x2, 
                y1, 
                y2
            );
            curves.push(Func({
                base: base,
                slope: slope,
                limit: x2
            }));
        }

        initialPrice = _yPoints[0];
        endPrice = _yPoints[pointsLength - 1];
    }

     
    function _getFunc(
        uint256 _x1,
        uint256 _x2,
        uint256 _y1, 
        uint256 _y2
    ) internal pure returns (uint256 base, uint256 slope) 
    {
        base = ((_x2.mul(_y1)).sub(_x1.mul(_y2))).div(_x2.sub(_x1));
        slope = (_y1.sub(_y2)).div(_x2.sub(_x1));
    }

     
    function _getBidId() private view returns (uint256) {
        return totalBids;
    }

     
    function _normalizeDecimals(
        uint256 _decimals, 
        uint256 _value
    ) 
    internal pure returns (uint256 _result) 
    {
        _result = _value.div(10**MAX_DECIMALS.sub(_decimals));
    }

     
    function _updateStats(uint256 _landsBidded, uint256 _manaAmountBurned) private {
        totalBids = totalBids.add(1);
        totalLandsBidded = totalLandsBidded.add(_landsBidded);
        totalManaBurned = totalManaBurned.add(_manaAmountBurned);
    }
}