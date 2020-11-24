 

 
 
pragma solidity 0.5.3;


 
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

interface ExchangeInterface {
    event LogError(uint8 indexed errorId, bytes32 indexed orderHash);

    function fillOrder(
          address[5] calldata orderAddresses,
          uint256[6] calldata orderValues,
          uint256 fillTakerTokenAmount,
          bool shouldThrowOnInsufficientBalanceOrAllowance,
          uint8 v,
          bytes32 r,
          bytes32 s)
          external
          returns (uint256 filledTakerTokenAmount);

    function fillOrdersUpTo(
        address[5][] calldata orderAddresses,
        uint256[6][] calldata orderValues,
        uint256 fillTakerTokenAmount,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s)
        external
        returns (uint256);

    function isValidSignature(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s)
        external
        view
        returns (bool);
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

contract BZxTo0x is BZxTo0xShared, EIP20Wrapper, BZxOwnable {
    using SafeMath for uint256;

    address public exchangeContract;
    address public zrxTokenContract;
    address public tokenTransferProxyContract;

    constructor(
        address _exchange,
        address _zrxToken,
        address _proxy)
        public
    {
        exchangeContract = _exchange;
        zrxTokenContract = _zrxToken;
        tokenTransferProxyContract = _proxy;
    }

    function()
        external {
        revert();
    }

   function take0xTrade(
        address trader,
        address vaultAddress,
        uint256 sourceTokenAmountToUse,
        bytes memory orderData0x,  
        bytes memory signature0x)  
        public
        onlyBZx
        returns (
            address destTokenAddress,
            uint256 destTokenAmount,
            uint256 sourceTokenUsedAmount)
    {
        (address[5][] memory orderAddresses0x, uint256[6][] memory orderValues0x) = getOrderValuesFromData(orderData0x);

        (sourceTokenUsedAmount, destTokenAmount) = _take0xTrade(
            trader,
            sourceTokenAmountToUse,
            orderAddresses0x,
            orderValues0x,
            signature0x);

        if (sourceTokenUsedAmount < sourceTokenAmountToUse) {
             
            revert("BZxTo0x::take0xTrade: sourceTokenUsedAmount < sourceTokenAmountToUse");
        }

         
        eip20Transfer(
            orderAddresses0x[0][2],
            vaultAddress,
            destTokenAmount);

        destTokenAddress = orderAddresses0x[0][2];  
    }

    function getOrderValuesFromData(
        bytes memory orderData0x)
        public
        pure
        returns (
            address[5][] memory orderAddresses,
            uint256[6][] memory orderValues)
    {
        address maker;
        address taker;
        address makerToken;
        address takerToken;
        address feeRecipient;
        uint256 makerTokenAmount;
        uint256 takerTokenAmount;
        uint256 makerFee;
        uint256 takerFee;
        uint256 expirationTimestampInSec;
        uint256 salt;
        orderAddresses = new address[5][](orderData0x.length/352);
        orderValues = new uint256[6][](orderData0x.length/352);
        for (uint256 i = 0; i < orderData0x.length/352; i++) {
            assembly {
                maker := mload(add(orderData0x, add(mul(i, 352), 32)))
                taker := mload(add(orderData0x, add(mul(i, 352), 64)))
                makerToken := mload(add(orderData0x, add(mul(i, 352), 96)))
                takerToken := mload(add(orderData0x, add(mul(i, 352), 128)))
                feeRecipient := mload(add(orderData0x, add(mul(i, 352), 160)))
                makerTokenAmount := mload(add(orderData0x, add(mul(i, 352), 192)))
                takerTokenAmount := mload(add(orderData0x, add(mul(i, 352), 224)))
                makerFee := mload(add(orderData0x, add(mul(i, 352), 256)))
                takerFee := mload(add(orderData0x, add(mul(i, 352), 288)))
                expirationTimestampInSec := mload(add(orderData0x, add(mul(i, 352), 320)))
                salt := mload(add(orderData0x, add(mul(i, 352), 352)))
            }
            orderAddresses[i] = [
                maker,
                taker,
                makerToken,
                takerToken,
                feeRecipient
            ];
            orderValues[i] = [
                makerTokenAmount,
                takerTokenAmount,
                makerFee,
                takerFee,
                expirationTimestampInSec,
                salt
            ];
        }
    }

     
    function getSignatureParts(
        bytes memory signatures)
        public
        pure
        returns (
            uint8[] memory vs,
            bytes32[] memory rs,
            bytes32[] memory ss)
    {
        vs = new uint8[](signatures.length/65);
        rs = new bytes32[](signatures.length/65);
        ss = new bytes32[](signatures.length/65);
        for (uint256 i = 0; i < signatures.length/65; i++) {
            uint8 v;
            bytes32 r;
            bytes32 s;
            assembly {
                r := mload(add(signatures, add(mul(i, 65), 32)))
                s := mload(add(signatures, add(mul(i, 65), 64)))
                v := mload(add(signatures, add(mul(i, 65), 65)))
            }
            if (v < 27) {
                v = v + 27;
            }
            vs[i] = v;
            rs[i] = r;
            ss[i] = s;
        }
    }

    function set0xExchange (
        address _exchange)
        public
        onlyOwner
    {
        exchangeContract = _exchange;
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
        tokenTransferProxyContract = _proxy;
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

    function _take0xTrade(
        address trader,
        uint256 sourceTokenAmountToUse,
        address[5][] memory orderAddresses0x,
        uint256[6][] memory orderValues0x,
        bytes memory signature)
        internal
        returns (uint256 sourceTokenUsedAmount, uint256 destTokenAmount)
    {
        uint256[4] memory summations;  
        summations[3] = sourceTokenAmountToUse;  

        for (uint256 i = 0; i < orderAddresses0x.length; i++) {
             
            require(orderAddresses0x[i][2] == orderAddresses0x[0][2], "makerToken must be the same for each order");  

            summations[0] = summations[0].add(orderValues0x[i][1]);  
            summations[1] = summations[1].add(orderValues0x[i][0]);  

             
            if (summations[3] > 0 && orderAddresses0x[i][4] != address(0) &&  
                    orderValues0x[i][3] > 0  
            ) {
                if (summations[3] >= orderValues0x[i][1]) {
                    summations[2] = summations[2].add(orderValues0x[i][3]);  
                    summations[3] = summations[3].sub(orderValues0x[i][1]);  
                } else {
                    summations[2] = summations[2].add(_safeGetPartialAmountFloor(
                        summations[3],
                        orderValues0x[i][1],  
                        orderValues0x[i][3]  
                    ));
                    summations[3] = 0;
                }
            }
        }

        if (summations[2] > 0) {
             
            eip20TransferFrom(
                zrxTokenContract,
                trader,
                address(this),
                summations[2]);
        }

        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = getSignatureParts(signature);

         
         
        uint256 tempAllowance = EIP20(orderAddresses0x[0][3]).allowance(address(this), tokenTransferProxyContract);
        if (tempAllowance < sourceTokenAmountToUse) {
            if (tempAllowance > 0) {
                 
                eip20Approve(
                    orderAddresses0x[0][3],
                    tokenTransferProxyContract,
                    0);
            }

            eip20Approve(
                orderAddresses0x[0][3],
                tokenTransferProxyContract,
                sourceTokenAmountToUse);
        }

        if (orderAddresses0x.length > 1) {
            sourceTokenUsedAmount = ExchangeInterface(exchangeContract).fillOrdersUpTo(
                orderAddresses0x,
                orderValues0x,
                sourceTokenAmountToUse,
                false,  
                v,
                r,
                s);
        } else {
            sourceTokenUsedAmount = ExchangeInterface(exchangeContract).fillOrder(
                orderAddresses0x[0],
                orderValues0x[0],
                sourceTokenAmountToUse,
                false,  
                v[0],
                r[0],
                s[0]);
        }

        destTokenAmount = _safeGetPartialAmountFloor(
            sourceTokenUsedAmount,
            summations[0],  
            summations[1]   
        );
    }
}