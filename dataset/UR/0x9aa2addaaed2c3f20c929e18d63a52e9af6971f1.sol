 

 

pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

pragma solidity ^0.4.24;



 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

pragma solidity ^0.4.24;

 
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
    require(msg.sender == owner, "msg.sender not owner");
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
    require(_newOwner != address(0), "_newOwner == 0");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

pragma solidity ^0.4.24;


 
contract Destructible is Ownable {
   
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

 

pragma solidity ^0.4.24;

 
interface IWallet {

  function transferAssetTo(
    address _assetAddress,
    address _to,
    uint _amount
  ) external payable returns (bool);

  function withdrawAsset(
    address _assetAddress,
    uint _amount
  ) external returns (bool);

  function setTokenSwapAllowance (
    address _tokenSwapAddress,
    bool _allowance
  ) external returns(bool);
}

 

pragma solidity ^0.4.24;



 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused, "The contract is paused");
    _;
  }

   
  modifier whenPaused() {
    require(paused, "The contract is not paused");
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

pragma solidity ^0.4.24;

 
interface IBadERC20 {
    function transfer(address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function transferFrom(
      address from,
      address to,
      uint256 value
    ) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(
      address who
    ) external view returns (uint256);

    function allowance(
      address owner,
      address spender
    ) external view returns (uint256);

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

 

pragma solidity ^0.4.24;


 
library SafeTransfer {
 

  function _safeTransferFrom(
    address _tokenAddress,
    address _from,
    address _to,
    uint256 _value
  )
    internal
    returns (bool result)
  {
    IBadERC20(_tokenAddress).transferFrom(_from, _to, _value);

    assembly {
      switch returndatasize()
      case 0 {                       
        result := not(0)             
      }
      case 32 {                      
        returndatacopy(0, 0, 32)
        result := mload(0)           
      }
      default {                      
        revert(0, 0)
      }
    }
  }

   
  function _safeTransfer(
    address _tokenAddress,
    address _to,
    uint _amount
  )
    internal
    returns (bool result)
  {
    IBadERC20(_tokenAddress).transfer(_to, _amount);

    assembly {
      switch returndatasize()
      case 0 {                       
        result := not(0)             
      }
      case 32 {                      
        returndatacopy(0, 0, 32)
        result := mload(0)           
      }
      default {                      
        revert(0, 0)
      }
    }
  }
}

 

pragma solidity ^0.4.24;







 
contract TokenSwap is
  Pausable,
  Destructible
{
  using SafeMath for uint;

  address public baseTokenAddress;
  address public quoteTokenAddress;

  address public wallet;

  uint public buyRate;
  uint public buyRateDecimals;
  uint public sellRate;
  uint public sellRateDecimals;

  event LogWithdrawToken(
    address indexed _from,
    address indexed _token,
    uint amount
  );
  event LogSetWallet(address indexed _wallet);
  event LogSetBaseTokenAddress(address indexed _token);
  event LogSetQuoteTokenAddress(address indexed _token);
  event LogSetRateAndRateDecimals(
    uint _buyRate,
    uint _buyRateDecimals,
    uint _sellRate,
    uint _sellRateDecimals
  );
  event LogSetNumberOfZeroesFromLastDigit(
    uint _numberOfZeroesFromLastDigit
  );
  event LogTokenSwap(
    address indexed _userAddress,
    address indexed _userSentTokenAddress,
    uint _userSentTokenAmount,
    address indexed _userReceivedTokenAddress,
    uint _userReceivedTokenAmount
  );

   
  constructor(
    address _baseTokenAddress,
    address _quoteTokenAddress,
    address _wallet,
    uint _buyRate,
    uint _buyRateDecimals,
    uint _sellRate,
    uint _sellRateDecimals
  )
    public
  {
    require(_wallet != address(0), "_wallet == address(0)");
    baseTokenAddress = _baseTokenAddress;
    quoteTokenAddress = _quoteTokenAddress;
    wallet = _wallet;
    buyRate = _buyRate;
    buyRateDecimals = _buyRateDecimals;
    sellRate = _sellRate;
    sellRateDecimals = _sellRateDecimals;
  }

  function() external {
    revert("fallback function not allowed");
  }

   
  function setBaseTokenAddress(address _baseTokenAddress)
    public
    onlyOwner
    returns (bool)
  {
    baseTokenAddress = _baseTokenAddress;
    emit LogSetBaseTokenAddress(_baseTokenAddress);
    return true;
  }

   
  function setQuoteTokenAddress(address _quoteTokenAddress)
    public
    onlyOwner
    returns (bool)
  {
    quoteTokenAddress = _quoteTokenAddress;
    emit LogSetQuoteTokenAddress(_quoteTokenAddress);
    return true;
  }

   
  function setWallet(address _wallet)
    public
    onlyOwner
    returns (bool)
  {
    require(_wallet != address(0), "_wallet == address(0)");
    wallet = _wallet;
    emit LogSetWallet(_wallet);
    return true;
  }

   
  function setRateAndRateDecimals(
    uint _buyRate,
    uint _buyRateDecimals,
    uint _sellRate,
    uint _sellRateDecimals
  )
    public
    onlyOwner
    returns (bool)
  {
    require(_buyRate != buyRate, "_buyRate == buyRate");
    require(_buyRate != 0, "_buyRate == 0");
    require(_sellRate != sellRate, "_sellRate == sellRate");
    require(_sellRate != 0, "_sellRate == 0");
    buyRate = _buyRate;
    sellRate = _sellRate;
    buyRateDecimals = _buyRateDecimals;
    sellRateDecimals = _sellRateDecimals;
    emit LogSetRateAndRateDecimals(
      _buyRate,
      _buyRateDecimals,
      _sellRate,
      _sellRateDecimals
    );
    return true;
  }

   
  function withdrawToken(address _tokenAddress)
    public
    onlyOwner
    returns(bool)
  {
    uint tokenBalance;
    if (isETH(_tokenAddress)) {
      tokenBalance = address(this).balance;
      msg.sender.transfer(tokenBalance);
    } else {
      tokenBalance = ERC20(_tokenAddress).balanceOf(address(this));
      require(
        SafeTransfer._safeTransfer(_tokenAddress, msg.sender, tokenBalance),
        "withdraw transfer failed"
      );
    }
    emit LogWithdrawToken(msg.sender, _tokenAddress, tokenBalance);
    return true;
  }

   

  function isBuy(address _offerTokenAddress)
    public
    view
    returns (bool)
  {
    return _offerTokenAddress == quoteTokenAddress;
  }

   

  function isETH(address _tokenAddress)
    public
    pure
    returns (bool)
  {
    return _tokenAddress == address(0);
  }

   

  function isOfferInPair(address _offerTokenAddress)
    public
    view
    returns (bool)
  {
    return _offerTokenAddress == quoteTokenAddress ||
      _offerTokenAddress == baseTokenAddress;
  }

   
  function getAmount(
    uint _offerTokenAmount,
    bool _isBuy
  )
    public
    view
    returns(uint)
  {
    uint amount;
    if (_isBuy) {
      amount = _offerTokenAmount.mul(buyRate).div(10 ** buyRateDecimals);
    } else {
      amount = _offerTokenAmount.mul(sellRate).div(10 ** sellRateDecimals);
    }
    return amount;
  }

   
  function swapToken (
    address _userOfferTokenAddress,
    uint _userOfferTokenAmount
  )
    public
    whenNotPaused
    payable
    returns (bool)
  {
    require(_userOfferTokenAmount != 0, "_userOfferTokenAmount == 0");
     
    require(
      isOfferInPair(_userOfferTokenAddress),
      "_userOfferTokenAddress not in pair"
    );
     
    if (isETH(_userOfferTokenAddress)) {
      require(_userOfferTokenAmount == msg.value, "msg.value != _userOfferTokenAmount");
    } else {
      require(msg.value == 0, "msg.value != 0");
    }
    bool isUserBuy = isBuy(_userOfferTokenAddress);
    uint toWalletAmount = _userOfferTokenAmount;
    uint toUserAmount = getAmount(
      _userOfferTokenAmount,
      isUserBuy
    );
    require(toUserAmount > 0, "toUserAmount must be greater than 0");
    if (isUserBuy) {
       
      require(
        _transferAmounts(
          msg.sender,
          wallet,
          quoteTokenAddress,
          toWalletAmount
        ),
        "the transfer from of the quote the user to the TokenSwap SC failed"
      );
       
      require(
        _transferAmounts(
          wallet,
          msg.sender,
          baseTokenAddress,
          toUserAmount
        ),
        "the transfer of the base from the TokenSwap SC to the user failed"
      );
      emit LogTokenSwap(
        msg.sender,
        quoteTokenAddress,
        toWalletAmount,
        baseTokenAddress,
        toUserAmount
      );
    } else {
       
      require(
        _transferAmounts(
          msg.sender,
          wallet,
          baseTokenAddress,
          toWalletAmount
        ),
        "the transfer of the base from the user to the TokenSwap SC failed"
      );
       
      require(
        _transferAmounts(
          wallet,
          msg.sender,
          quoteTokenAddress,
          toUserAmount
        ),
        "the transfer of the quote from the TokenSwap SC to the user failed"
      );
      emit LogTokenSwap(
        msg.sender,
        baseTokenAddress,
        toWalletAmount,
        quoteTokenAddress,
        toUserAmount
      );
    }
    return true;
  }

   
  function _transferAmounts(
    address _from,
    address _to,
    address _tokenAddress,
    uint _amount
  )
    private
    returns (bool)
  {
    if (isETH(_tokenAddress)) {
      if (_from == wallet) {
        require(
          IWallet(_from).transferAssetTo(
            _tokenAddress,
            _to,
            _amount
          ),
          "trasnsferAssetTo failed"
        );
      } else {
        _to.transfer(_amount);
      }
    } else {
      if (_from == wallet) {
        require(
          IWallet(_from).transferAssetTo(
            _tokenAddress,
            _to,
            _amount
          ),
          "trasnsferAssetTo failed"
        );
      } else {
        require(
          SafeTransfer._safeTransferFrom(
            _tokenAddress,
            _from,
            _to,
            _amount
        ),
          "transferFrom reserve to _receiver failed"
        );
      }
    }
    return true;
  }
}