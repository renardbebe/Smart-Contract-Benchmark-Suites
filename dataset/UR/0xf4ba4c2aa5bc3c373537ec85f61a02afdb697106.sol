 

 

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






 
contract Wallet is IWallet, Destructible {
  using SafeMath for uint;

  mapping (address => bool) public isTokenSwapAllowed;

  event LogTransferAssetTo(
    address indexed _assetAddress,
    address indexed _to,
    uint _amount
  );
  event LogWithdrawAsset(
    address indexed _assetAddress,
    address indexed _from,
    uint _amount
  );
  event LogSetTokenSwapAllowance(
    address indexed _tokenSwapAddress,
    bool _allowance
  );

  constructor(address[] memory _tokenSwapContractsAddress) public {
    for (uint i = 0; i < _tokenSwapContractsAddress.length; i++) {
      isTokenSwapAllowed[_tokenSwapContractsAddress[i]] = true;
    }
  }

   
  modifier onlyTokenSwapAllowed() {
    require(
      isTokenSwapAllowed[msg.sender],
      "msg.sender is not one of the allowed TokenSwap smart contract"
    );
    _;
  }

   
  function() external payable {}

   
  function transferAssetTo(
    address _assetAddress,
    address _to,
    uint _amount
  )
    external
    payable
    onlyTokenSwapAllowed
    returns (bool)
  {
    require(_to != address(0), "_to == 0");
    if (isETH(_assetAddress)) {
      require(address(this).balance >= _amount, "ETH balance not sufficient");
      _to.transfer(_amount);
    } else {
      require(
        IBadERC20(_assetAddress).balanceOf(address(this)) >= _amount,
        "Token balance not sufficient"
      );
      require(
        SafeTransfer._safeTransfer(
          _assetAddress,
          _to,
          _amount
        ),
        "Token transfer failed"
      );
    }
    emit LogTransferAssetTo(_assetAddress, _to, _amount);
    return true;
  }

   
  function withdrawAsset(
    address _assetAddress,
    uint _amount
  )
    external
    onlyOwner
    returns(bool)
  {
    if (isETH(_assetAddress)) {
      require(
        address(this).balance >= _amount,
        "ETH balance not sufficient"
      );
      msg.sender.transfer(_amount);
    } else {
      require(
        IBadERC20(_assetAddress).balanceOf(address(this)) >= _amount,
        "Token balance not sufficient"
      );
      require(
        SafeTransfer._safeTransfer(
          _assetAddress,
          msg.sender,
          _amount
        ),
        "Token transfer failed"
      );
    }
    emit LogWithdrawAsset(_assetAddress, msg.sender, _amount);
    return true;
  }

   
  function setTokenSwapAllowance (
    address _tokenSwapAddress,
    bool _allowance
  ) external onlyOwner returns(bool) {
    emit LogSetTokenSwapAllowance(
      _tokenSwapAddress,
      _allowance
    );
    isTokenSwapAllowed[_tokenSwapAddress] = _allowance;
    return true;
  }

   
  function isETH(address _tokenAddress)
    public
    pure
    returns (bool)
  {
    return _tokenAddress == 0;
  }
}