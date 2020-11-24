 

pragma solidity 0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
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
    require(msg.sender == owner);
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
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
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
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function approve(address _spender, uint _value) external;
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
          address[5] orderAddresses,
          uint[6] orderValues,
          uint fillTakerTokenAmount,
          bool shouldThrowOnInsufficientBalanceOrAllowance,
          uint8 v,
          bytes32 r,
          bytes32 s)
          external
          returns (uint filledTakerTokenAmount);

    function fillOrdersUpTo(
        address[5][] orderAddresses,
        uint[6][] orderValues,
        uint fillTakerTokenAmount,
        bool shouldThrowOnInsufficientBalanceOrAllowance,
        uint8[] v,
        bytes32[] r,
        bytes32[] s)
        external
        returns (uint);

    function isValidSignature(
        address signer,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s)
        external
        constant
        returns (bool);
}

contract BZxTo0x is EIP20Wrapper, BZxOwnable {
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
        public {
        revert();
    }

   function take0xTrade(
        address trader,
        address vaultAddress,
        uint sourceTokenAmountToUse,
        bytes orderData0x,  
        bytes signature0x)  
        public
        onlyBZx
        returns (
            address destTokenAddress,
            uint destTokenAmount,
            uint sourceTokenUsedAmount)
    {
        (address[5][] memory orderAddresses0x, uint[6][] memory orderValues0x) = getOrderValuesFromData(orderData0x);

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
        bytes orderData0x)
        public
        pure
        returns (
            address[5][] orderAddresses,
            uint[6][] orderValues) 
    {
        address maker;
        address taker;
        address makerToken;
        address takerToken;
        address feeRecipient;
        uint makerTokenAmount;
        uint takerTokenAmount;
        uint makerFee;
        uint takerFee;
        uint expirationTimestampInSec;
        uint salt;
        orderAddresses = new address[5][](orderData0x.length/352);
        orderValues = new uint[6][](orderData0x.length/352);
        for (uint i = 0; i < orderData0x.length/352; i++) {
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
        bytes signatures)
        public
        pure
        returns (
            uint8[] vs,
            bytes32[] rs,
            bytes32[] ss)
    {
        vs = new uint8[](signatures.length/65);
        rs = new bytes32[](signatures.length/65);
        ss = new bytes32[](signatures.length/65);
        for (uint i = 0; i < signatures.length/65; i++) {
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

     
     
     
     
     
    function getPartialAmount(uint numerator, uint denominator, uint target)
        public
        pure
        returns (uint)
    {
        return SafeMath.div(SafeMath.mul(numerator, target), denominator);
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
        uint value)
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
        uint sourceTokenAmountToUse,
        address[5][] orderAddresses0x,
        uint[6][] orderValues0x,
        bytes signature)
        internal
        returns (uint sourceTokenUsedAmount, uint destTokenAmount) 
    {
        uint[3] memory summations;  

        for (uint i = 0; i < orderAddresses0x.length; i++) {
            summations[0] += orderValues0x[0][1];  
            summations[1] += orderValues0x[0][0];  
            
            if (orderAddresses0x[i][4] != address(0) &&  
                    orderValues0x[i][3] > 0  
            ) {
                summations[2] += orderValues0x[i][3];  
            }
        }
        if (summations[2] > 0) {
             
            eip20TransferFrom(
                zrxTokenContract,
                trader,
                this,
                summations[2]);
        }

        (uint8[] memory v, bytes32[] memory r, bytes32[] memory s) = getSignatureParts(signature);

         
         
        eip20Approve(
            orderAddresses0x[0][3],
            tokenTransferProxyContract,
            EIP20(orderAddresses0x[0][3]).allowance(this, tokenTransferProxyContract).add(sourceTokenAmountToUse));

        if (orderAddresses0x.length > 0) {
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

        destTokenAmount = getPartialAmount(
            sourceTokenUsedAmount,
            summations[0],  
            summations[1]   
        );
    }
}