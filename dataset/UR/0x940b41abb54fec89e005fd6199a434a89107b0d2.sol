 

 

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

  function _safeApprove(
    address _token,
    address _spender,
    uint256 _value
  )
  internal
  returns (bool result)
  {
    IBadERC20(_token).approve(_spender, _value);

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

 

pragma solidity ^0.4.0;

interface ICToken {
    function exchangeRateStored() external view returns (uint);

    function transfer(address dst, uint256 amount) external returns (bool);
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);

 
}

 

pragma solidity ^0.4.0;


contract  ICErc20 is ICToken {
    function underlying() external view returns (address);

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
 
 
 
 
 
}

 

pragma solidity ^0.4.24;




 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

pragma solidity ^0.4.0;

interface IErc20Swap {
    function getRate(address src, address dst, uint256 srcAmount) external view returns(uint expectedRate, uint slippageRate);   
    function swap(address src, uint srcAmount, address dest, uint maxDestAmount, uint minConversionRate) external payable;
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




contract Withdrawable is Ownable {
  using SafeTransfer for ERC20;
  address constant ETHER = address(0);

  event LogWithdrawToken(
    address indexed _from,
    address indexed _token,
    uint amount
  );

   
  function withdrawToken(address _tokenAddress) public onlyOwner {
    uint tokenBalance;
    if (_tokenAddress == ETHER) {
      tokenBalance = address(this).balance;
      msg.sender.transfer(tokenBalance);
    } else {
      tokenBalance = ERC20(_tokenAddress).balanceOf(address(this));
      ERC20(_tokenAddress)._safeTransfer(msg.sender, tokenBalance);
    }
    emit LogWithdrawToken(msg.sender, _tokenAddress, tokenBalance);
  }

}

 

pragma solidity ^0.4.24;











 
contract WrappedTokenSwap is Ownable, Withdrawable, Pausable, Destructible, IErc20Swap
{
  using SafeMath for uint;
  using SafeTransfer for ERC20;
  address constant ETHER = address(0);
  uint constant rateDecimals = 18;
  uint constant rateUnit = 10 ** rateDecimals;

  address public wallet;

  uint public spread;
  uint constant spreadDecimals = 6;
  uint constant spreadUnit = 10 ** spreadDecimals;

  event LogTokenSwap(
    address indexed _userAddress,
    address indexed _userSentTokenAddress,
    uint _userSentTokenAmount,
    address indexed _userReceivedTokenAddress,
    uint _userReceivedTokenAmount
  );

  event LogFee(address token, uint amount);

   
  function underlyingTokenAddress() public view returns(address);
  function wrappedTokenAddress() public view returns(address);
  function wrap(uint unwrappedAmount) private returns(bool);
  function unwrap(uint wrappedAmount) private returns(bool);
  function getExchangedAmount(uint _amount, bool _isUnwrap) private view returns(uint);

   
  constructor(
    address _wallet,
    uint _spread
  )
    public
  {
    require(_wallet != address(0), "_wallet == address(0)");
    wallet = _wallet;
    spread = _spread;
  }

  function() external {
    revert("fallback function not allowed");
  }

  function setWallet(address _wallet) public onlyOwner {
    require(_wallet != address(0), "_wallet == address(0)");
    wallet = _wallet;
  }

  function setSpread(uint _spread) public onlyOwner {
    spread = _spread;
  }



  function getRate(address src, address dst, uint256 srcAmount) public view
    returns(uint expectedRate, uint slippageRate)   
  {
    address wrapped = wrappedTokenAddress();
    address underlying = underlyingTokenAddress();
    require((src == wrapped && dst == underlying) || (src == underlying && dst == wrapped), "Wrong tokens pair");
    expectedRate = slippageRate = getAmount(srcAmount, src == wrapped);
  }

   

  function buyRate() public view returns(uint rate) {
    (rate,) = getRate(underlyingTokenAddress(), wrappedTokenAddress(), rateUnit);
  }

  function buyRateDecimals() public pure returns(uint) {
    return rateDecimals;
  }

  function sellRate() public view returns(uint rate) {
    (rate,) = getRate(wrappedTokenAddress(), underlyingTokenAddress(), rateUnit);
  }

  function sellRateDecimals() public pure returns(uint) {
    return rateDecimals;
  }

   

  function _getFee(uint underlyingTokenTotal) internal view returns(uint) {
    return underlyingTokenTotal.mul(spread).div(spreadUnit);
  }

   
  function getAmount(uint _offerTokenAmount, bool _isUnwrap)
    public view returns(uint toUserAmount)
  {
    if (_isUnwrap) {
      uint amount = getExchangedAmount(_offerTokenAmount, _isUnwrap);
       
      toUserAmount = amount.sub(_getFee(amount));
    } else {
       
      uint fee = _getFee(_offerTokenAmount);
      toUserAmount = getExchangedAmount(_offerTokenAmount.sub(fee), _isUnwrap);
    }
  }

   
  function swapToken (
    address _userOfferTokenAddress,
    uint _userOfferTokenAmount
  )
    public
    whenNotPaused
    returns (bool)
  {
    swap(
      _userOfferTokenAddress,
      _userOfferTokenAmount,
      _userOfferTokenAddress == wrappedTokenAddress()
        ? underlyingTokenAddress()
        : wrappedTokenAddress(),
      0,
      0
    );
    return true;
  }

  function swap(address src, uint srcAmount, address dest, uint  , uint  ) public payable
    whenNotPaused
  {
    require(msg.value == 0, "ethers not supported");
    require(srcAmount != 0, "srcAmount == 0");
    require(
      ERC20(src).allowance(msg.sender, address(this)) >= srcAmount,
      "ERC20 allowance < srcAmount"
    );
    address underlying = underlyingTokenAddress();
    address wrapped = wrappedTokenAddress();
    require((src == wrapped && dest == underlying) || (src == underlying && dest == wrapped), "Wrong tokens pair");
    bool isUnwrap = src == wrapped;
    uint toUserAmount;
    uint fee;

     
    ERC20(src)._safeTransferFrom(msg.sender, address(this), srcAmount);

    if (isUnwrap) {
      require(unwrap(srcAmount), "cannot unwrap the token");
      uint unwrappedAmount = getExchangedAmount(srcAmount, isUnwrap);
      require(
        ERC20(underlying).balanceOf(address(this)) >= unwrappedAmount,
        "No enough underlying tokens after redeem"
      );
      fee = _getFee(unwrappedAmount);
      toUserAmount = unwrappedAmount.sub(fee);
      require(toUserAmount > 0, "toUserAmount must be greater than 0");
      require(
        ERC20(underlying)._safeTransfer(msg.sender, toUserAmount),
        "cannot transfer underlying token to the user"
      );
    } else {
      fee = _getFee(srcAmount);
      uint toSwap = srcAmount.sub(fee);
      require(wrap(toSwap), "cannot wrap the token");
      toUserAmount = getExchangedAmount(toSwap, isUnwrap);
      require(ERC20(wrapped).balanceOf(address(this)) >= toUserAmount, "No enough wrapped tokens after wrap");
      require(toUserAmount > 0, "toUserAmount must be greater than 0");
      require(
        ERC20(wrapped)._safeTransfer(msg.sender, toUserAmount),
        "cannot transfer the wrapped token to the user"
      );
    }
     
    if (fee > 0) {
      require(
        ERC20(underlying)._safeTransfer(wallet, fee),
        "cannot transfer the underlying token to the wallet for the fees"
      );
      emit LogFee(address(underlying), fee);
    }

    emit LogTokenSwap(
      msg.sender,
      src,
      srcAmount,
      dest,
      toUserAmount
    );
  }


}

 

pragma solidity ^0.4.24;






 
contract CErc20Swap is WrappedTokenSwap
{
  using SafeMath for uint;
  using SafeTransfer for ERC20;
  uint constant expScale = 1e18;

  ICErc20 public cToken;

   
  constructor(
    address _cTokenAddress,
    address _wallet,
    uint _spread
  )
    public WrappedTokenSwap(_wallet, _spread)
  {
    cToken = ICErc20(_cTokenAddress);
  }

  function underlyingTokenAddress() public view returns(address) {
    return cToken.underlying();
  }

  function wrappedTokenAddress() public view returns(address) {
    return address(cToken);
  }

  function wrap(uint unwrappedAmount) private returns(bool) {
    require(
      ERC20(cToken.underlying())._safeApprove(address(cToken), unwrappedAmount),
      "Cannot approve underlying token for mint"
    );
    return cToken.mint(unwrappedAmount) == 0;
  }

  function unwrap(uint wrappedAmount) private returns(bool) {
    return cToken.redeem(wrappedAmount) == 0;
  }

  function getExchangedAmount(uint _amount, bool _isUnwrap) private view returns(uint) {
    uint rate = cToken.exchangeRateStored();
    return _isUnwrap
      ? _amount.mul(rate).div(expScale)
      : _amount.mul(expScale).div(rate);
  }

}