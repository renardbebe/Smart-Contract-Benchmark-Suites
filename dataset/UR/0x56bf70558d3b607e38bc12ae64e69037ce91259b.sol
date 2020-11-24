 

 
 
pragma solidity 0.5.3;
pragma experimental ABIEncoderV2;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
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

contract EIP20 is ERC20 {
    string public name;
    uint8 public decimals;
    string public symbol;
}

interface NonCompliantEIP20 {
    function transfer(address _to, uint256 _value) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
    function approve(address _spender, uint256 _value) external;
}

contract EIP20Wrapper {

    function eip20Transfer(
        address token,
        address to,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).transfer(to, value);

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

        require(result, "eip20Transfer failed");
    }

    function eip20TransferFrom(
        address token,
        address from,
        address to,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).transferFrom(from, to, value);

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

        require(result, "eip20TransferFrom failed");
    }

    function eip20Approve(
        address token,
        address spender,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).approve(spender, value);

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

        require(result, "eip20Approve failed");
    }
}

 
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

   
  function divCeil(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }

    return ((_a - 1) / _b) + 1;
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

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract BZxOwnable is Ownable {

    address public bZxContractAddress;

    event BZxOwnershipTransferred(address indexed previousBZxContract, address indexed newBZxContract);

     
    modifier onlyBZx() {
        require(msg.sender == bZxContractAddress, "only bZx contracts can call this function");
        _;
    }

     
    function transferBZxOwnership(address newBZxContractAddress) public onlyOwner {
        require(newBZxContractAddress != address(0) && newBZxContractAddress != owner, "transferBZxOwnership::unauthorized");
        emit BZxOwnershipTransferred(bZxContractAddress, newBZxContractAddress);
        bZxContractAddress = newBZxContractAddress;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0) && newOwner != bZxContractAddress, "transferOwnership::unauthorized");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ExchangeV2Interface {

    struct OrderV2 {
        address makerAddress;            
        address takerAddress;            
        address feeRecipientAddress;     
        address senderAddress;           
        uint256 makerAssetAmount;        
        uint256 takerAssetAmount;        
        uint256 makerFee;                
        uint256 takerFee;                
        uint256 expirationTimeSeconds;   
        uint256 salt;                    
        bytes makerAssetData;            
        bytes takerAssetData;            
    }

    struct FillResults {
        uint256 makerAssetFilledAmount;   
        uint256 takerAssetFilledAmount;   
        uint256 makerFeePaid;             
        uint256 takerFeePaid;             
    }

     
     
     
     
     
     
    function fillOrderNoThrow(
        OrderV2 memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature)
        public
        returns (FillResults memory fillResults);

     
     
     
     
     
     
    function marketSellOrdersNoThrow(
        OrderV2[] memory orders,
        uint256 takerAssetFillAmount,
        bytes[] memory signatures)
        public
        returns (FillResults memory totalFillResults);


     
     
     
     
     
    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        bytes calldata signature)
        external
        view
        returns (bool isValid);
}

contract BZxTo0xShared {
    using SafeMath for uint256;

     
     
     
     
     
     
    function _safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        require(
            !_isRoundingErrorFloor(
                numerator,
                denominator,
                target
            ),
            "ROUNDING_ERROR"
        );
        
        partialAmount = SafeMath.div(
            SafeMath.mul(numerator, target),
            denominator
        );
        return partialAmount;
    }

     
     
     
     
     
    function _isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );
        
         
         
         
         
         
         
         
         
         
         
         
         
         
        if (target == 0 || numerator == 0) {
            return false;
        }
        
         
         
         
         
         
         
         
         
         
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        isError = SafeMath.mul(1000, remainder) >= SafeMath.mul(numerator, target);
        return isError;
    }
}

contract BZxTo0xV2 is BZxTo0xShared, EIP20Wrapper, BZxOwnable {
    using SafeMath for uint256;

    event LogFillResults(
        uint256 makerAssetFilledAmount,
        uint256 takerAssetFilledAmount,
        uint256 makerFeePaid,
        uint256 takerFeePaid
    );

    bool public DEBUG = false;

    address public exchangeV2Contract;
    address public zrxTokenContract;
    address public erc20ProxyContract;

    constructor(
        address _exchangeV2,
        address _zrxToken,
        address _proxy)
        public
    {
        exchangeV2Contract = _exchangeV2;
        zrxTokenContract = _zrxToken;
        erc20ProxyContract = _proxy;
    }

    function()
        external {
        revert();
    }

     
    function take0xV2Trade(
        address trader,
        address vaultAddress,
        uint256 sourceTokenAmountToUse,
        ExchangeV2Interface.OrderV2[] memory orders0x,  
        bytes[] memory signatures0x)  
        public
        onlyBZx
        returns (
            address destTokenAddress,
            uint256 destTokenAmount,
            uint256 sourceTokenUsedAmount)
    {
        address sourceTokenAddress;

         
        (destTokenAddress, sourceTokenAddress) = getV2Tokens(orders0x[0]);

        (sourceTokenUsedAmount, destTokenAmount) = _take0xV2Trade(
            trader,
            sourceTokenAddress,
            sourceTokenAmountToUse,
            orders0x,
            signatures0x);

        if (sourceTokenUsedAmount < sourceTokenAmountToUse) {
             
            revert("BZxTo0xV2::take0xTrade: sourceTokenUsedAmount < sourceTokenAmountToUse");
        }

         
        eip20Transfer(
            destTokenAddress,
            vaultAddress,
            destTokenAmount);
    }

     
     
     
     
     
    function getPartialAmount(uint256 numerator, uint256 denominator, uint256 target)
        public
        pure
        returns (uint256)
    {
        return SafeMath.div(SafeMath.mul(numerator, target), denominator);
    }

     
     
     
    function getV2Tokens(
        ExchangeV2Interface.OrderV2 memory order)
        public
        pure
        returns (
            address makerTokenAddress,
            address takerTokenAddress)
    {
        bytes memory makerAssetData = order.makerAssetData;
        bytes memory takerAssetData = order.takerAssetData;
        bytes4 makerProxyID;
        bytes4 takerProxyID;

         
        assembly {
            makerProxyID := mload(add(makerAssetData, 32))
            takerProxyID := mload(add(takerAssetData, 32))

            makerTokenAddress := mload(add(makerAssetData, 36))
            takerTokenAddress := mload(add(takerAssetData, 36))
        }

         
        require(makerProxyID == 0xf47261b0 && takerProxyID == 0xf47261b0, "BZxTo0xV2::getV2Tokens: 0x V2 orders must use ERC20 tokens");
    }

    function set0xV2Exchange (
        address _exchange)
        public
        onlyOwner
    {
        exchangeV2Contract = _exchange;
    }

    function setZRXToken (
        address _zrxToken)
        public
        onlyOwner
    {
        zrxTokenContract = _zrxToken;
    }

    function set0xTokenProxy (
        address _proxy)
        public
        onlyOwner
    {
        erc20ProxyContract = _proxy;
    }

    function approveFor (
        address token,
        address spender,
        uint256 value)
        public
        onlyOwner
        returns (bool)
    {
        eip20Approve(
            token,
            spender,
            value);

        return true;
    }

    function toggleDebug (
        bool isDebug)
        public
        onlyOwner
    {
        DEBUG = isDebug;
    }

    function _take0xV2Trade(
        address trader,
        address sourceTokenAddress,
        uint256 sourceTokenAmountToUse,
        ExchangeV2Interface.OrderV2[] memory orders0x,  
        bytes[] memory signatures0x)
        internal
        returns (uint256 sourceTokenUsedAmount, uint256 destTokenAmount)
    {
        uint256 zrxTokenAmount = 0;
        uint256 takerAssetRemaining = sourceTokenAmountToUse;
        for (uint256 i = 0; i < orders0x.length; i++) {
             
             
             
             
            if (i > 0)
                orders0x[i].makerAssetData = orders0x[0].makerAssetData;

             
            if (takerAssetRemaining > 0 && orders0x[i].takerFee > 0) {  
                if (takerAssetRemaining >= orders0x[i].takerAssetAmount) {
                    zrxTokenAmount = zrxTokenAmount.add(orders0x[i].takerFee);
                    takerAssetRemaining = takerAssetRemaining.sub(orders0x[i].takerAssetAmount);
                } else {
                    zrxTokenAmount = zrxTokenAmount.add(_safeGetPartialAmountFloor(
                        takerAssetRemaining,
                        orders0x[i].takerAssetAmount,
                        orders0x[i].takerFee
                    ));
                    takerAssetRemaining = 0;
                }
            }
        }

        if (zrxTokenAmount > 0) {
             
            eip20TransferFrom(
                zrxTokenContract,
                trader,
                address(this),
                zrxTokenAmount);
        }

         
        uint256 tempAllowance = EIP20(sourceTokenAddress).allowance(address(this), erc20ProxyContract);
        if (tempAllowance < sourceTokenAmountToUse) {
            if (tempAllowance > 0) {
                 
                eip20Approve(
                    sourceTokenAddress,
                    erc20ProxyContract,
                    0);
            }

            eip20Approve(
                sourceTokenAddress,
                erc20ProxyContract,
                sourceTokenAmountToUse);
        }

        ExchangeV2Interface.FillResults memory fillResults;
        if (orders0x.length > 1) {
            fillResults = ExchangeV2Interface(exchangeV2Contract).marketSellOrdersNoThrow(
                orders0x,
                sourceTokenAmountToUse,
                signatures0x);
        } else {
            fillResults = ExchangeV2Interface(exchangeV2Contract).fillOrderNoThrow(
                orders0x[0],
                sourceTokenAmountToUse,
                signatures0x[0]);
        }

        if (zrxTokenAmount > 0 && fillResults.takerFeePaid < zrxTokenAmount) {
             
            eip20Transfer(
                zrxTokenContract,
                trader,
                zrxTokenAmount.sub(fillResults.takerFeePaid));
        }

        if (DEBUG) {
            emit LogFillResults(
                fillResults.makerAssetFilledAmount,
                fillResults.takerAssetFilledAmount,
                fillResults.makerFeePaid,
                fillResults.takerFeePaid
            );
        }

        sourceTokenUsedAmount = fillResults.takerAssetFilledAmount;
        destTokenAmount = fillResults.makerAssetFilledAmount;
    }
}