 

 

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

 

pragma solidity ^0.4.0;

interface IErc20Swap {
    function getRate(address src, address dst, uint256 srcAmount) external view returns(uint expectedRate, uint slippageRate);   
    function swap(address src, uint srcAmount, address dest, uint maxDestAmount, uint minConversionRate) external payable;
}

 

pragma solidity >=0.4.21 <0.6.0;

interface IKyberNetwork {

    function getExpectedRate(address src, address dest, uint srcQty) external view
        returns (uint expectedRate, uint slippageRate);

    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    ) external payable returns(uint256);
}

 

pragma solidity ^0.4.24;








 
contract KyberTokenSwap is Pausable, Destructible, IErc20Swap
{
  using SafeMath for uint;
  using SafeTransfer for ERC20;
  address constant ETHER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  uint constant expScale = 1e18;
  uint constant rateDecimals = 18;
  uint constant rateUnit = 10 ** rateDecimals;

  IKyberNetwork public kyberNetwork;

  address public wallet;
  address public kyberFeeWallet;

  uint public spreadDefault;
  mapping (address => mapping (address => uint)) spreadCustom;
  uint constant spreadDecimals = 6;
  uint constant spreadUnit = 10 ** spreadDecimals;

  event LogWithdrawToken(
    address indexed _from,
    address indexed _token,
    uint amount
  );

  event LogTokenSwap(
    address indexed _userAddress,
    address indexed _userSentTokenAddress,
    uint _userSentTokenAmount,
    address indexed _userReceivedTokenAddress,
    uint _userReceivedTokenAmount
  );

  event LogFee(address token, uint amount);

  event UnexpectedIntialBalance(address token, uint amount);

  constructor(
    address _kyberNetwork,
    address _wallet,
    address _kyberFeeWallet,
    uint _spread
  )
    public
  {
    require(_wallet != address(0), "_wallet == address(0)");
    require(_kyberNetwork != address(0), "_kyberNetwork == address(0)");
    require(_spread < spreadUnit, "spread >= spreadUnit");
    wallet = _wallet;
    spreadDefault = _spread;
    kyberNetwork = IKyberNetwork(_kyberNetwork);
    kyberFeeWallet = _kyberFeeWallet;
  }

  function() external payable {
     
  }

  function setWallet(address _wallet) public onlyOwner {
    require(_wallet != address(0), "_wallet == address(0)");
    wallet = _wallet;
  }

  function setKyberFeeWallet(address _wallet) public onlyOwner {
    kyberFeeWallet = _wallet;
  }

  function setSpreadDefault(uint _spread) public onlyOwner {
    require(_spread < spreadUnit, "spread >= spreadUnit");
    spreadDefault = _spread;
  }

   
  function setSpread(address tokenA, address tokenB, uint spread) public onlyOwner {
    uint value = spread > spreadUnit ? spreadUnit : spread;
    spreadCustom[tokenA][tokenB] = value;
    spreadCustom[tokenB][tokenA] = value;
  }

  function getSpread(address tokenA, address tokenB) public view returns(uint) {
    uint value = spreadCustom[tokenA][tokenB];
    if (value == 0) return spreadDefault;
    if (value >= spreadUnit) return 0;
    else return value;
  }

   
  function withdrawToken(address _tokenAddress)
    public
    onlyOwner
  {
    uint tokenBalance;
    if (_tokenAddress == ETHER || _tokenAddress == address(0)) {
      tokenBalance = address(this).balance;
      msg.sender.transfer(tokenBalance);
    } else {
      tokenBalance = ERC20(_tokenAddress).balanceOf(address(this));
      ERC20(_tokenAddress)._safeTransfer(msg.sender, tokenBalance);
    }
    emit LogWithdrawToken(msg.sender, _tokenAddress, tokenBalance);
  }

   
  function getRate(address src, address dest, uint256 srcAmount) external view
    returns(uint expectedRate, uint slippageRate)
  {
    (uint256 kExpected, uint256 kSplippage) = kyberNetwork.getExpectedRate(src, dest, srcAmount);
    uint256 spread = getSpread(src, dest);
    expectedRate = kExpected.mul(spreadUnit - spread).div(spreadUnit);
    slippageRate = kSplippage.mul(spreadUnit - spread).div(spreadUnit);
  }

  function _freeUnexpectedTokens(address token) private {
    uint256 unexpectedBalance = token == ETHER
      ? address(this).balance.sub(msg.value)
      : ERC20(token).balanceOf(address(this));
    if (unexpectedBalance > 0) {
      _transfer(token, wallet, unexpectedBalance);
      emit UnexpectedIntialBalance(token, unexpectedBalance);
    }
  }

  function swap(address src, uint srcAmount, address dest, uint maxDestAmount, uint minConversionRate) public payable {
    require(src != dest, "src == dest");
    require(srcAmount > 0, "srcAmount == 0");

     
    _freeUnexpectedTokens(src);
    _freeUnexpectedTokens(dest);

    if (src == ETHER) {
      require(msg.value == srcAmount, "msg.value != srcAmount");
    } else {
      require(
        ERC20(src).allowance(msg.sender, address(this)) >= srcAmount,
        "ERC20 allowance < srcAmount"
      );
       
      require(
        ERC20(src)._safeTransferFrom(msg.sender, address(this), srcAmount),
        "cannot transfer src token from msg.sender to this"
      );
    }

 
 

    uint256 spread = getSpread(src, dest);

    uint256 destTradedAmount = _callKyberNetworkTrade(src, srcAmount, dest, maxDestAmount, minConversionRate, spread);

    uint256 notTraded = _myBalance(src);
    uint256 srcTradedAmount = srcAmount.sub(notTraded);
    require(srcTradedAmount > 0, "no traded tokens");
    uint256 minDestAmount = srcTradedAmount.mul(minConversionRate).div(expScale);
    require(
      minDestAmount <= destTradedAmount,
      "applied rate below minConversionRate"
    );
    require(
      _myBalance(dest) >= destTradedAmount,
      "No enough dest tokens after trade"
    );
     
    uint256 toUserAmount = _payFee(dest, destTradedAmount, spread);
    _transfer(dest, msg.sender, toUserAmount);
     
    if (notTraded > 0) {
      _transfer(src, msg.sender, notTraded);
    }

    emit LogTokenSwap(
      msg.sender,
      src,
      srcTradedAmount,
      dest,
      toUserAmount
    );
  }

  function _callKyberNetworkTrade(address src, uint srcAmount, address dest, uint maxDestAmount, uint minConversionRate, uint spread) private returns(uint256) {
     
    uint256 adaptedMinRate = minConversionRate.mul(spreadUnit).div(spreadUnit - spread);
    uint256 adaptedMaxDestAmount = maxDestAmount.mul(spreadUnit).div(spreadUnit - spread);
    if (src == ETHER) {
      return kyberNetwork.trade
        .value(srcAmount)(src, srcAmount, dest, address(this), adaptedMaxDestAmount, adaptedMinRate, kyberFeeWallet);
    } else {
      if (ERC20(src).allowance(address(this), address(kyberNetwork)) > 0) {
        ERC20(src)._safeApprove(address(kyberNetwork), 0);
      }
      ERC20(src)._safeApprove(address(kyberNetwork), srcAmount);
      return kyberNetwork.trade(src, srcAmount, dest, address(this), adaptedMaxDestAmount, adaptedMinRate, kyberFeeWallet);
    }
  }

  function _payFee(address token, uint destTradedAmount, uint spread) private returns(uint256 toUserAmount) {
    uint256 fee = destTradedAmount.mul(spread).div(spreadUnit);
    toUserAmount = destTradedAmount.sub(fee);
     
    if (fee > 0) {
      _transfer(token, wallet, fee);
      emit LogFee(token, fee);
    }
  }

  function _myBalance(address token) private view returns(uint256) {
    return token == ETHER
      ? address(this).balance
      : ERC20(token).balanceOf(address(this));
  }

  function _transfer(address token, address recipient, uint256 amount) private {
    if (token == ETHER) {
      recipient.transfer(amount);
    } else {
      require(ERC20(token)._safeTransfer(recipient, amount), "cannot transfer tokens");
    }
  }

}