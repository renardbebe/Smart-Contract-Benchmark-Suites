 

pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
     
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }
}

 
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function decimals() public view returns (uint256);

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

 

library Utils {

    uint256 constant internal PRECISION = (10**18);
    uint256 constant internal MAX_QTY   = (10**28);  
    uint256 constant internal MAX_RATE  = (PRECISION * 10**6);  
    uint256 constant internal MAX_DECIMALS = 18;
    uint256 constant internal ETH_DECIMALS = 18;
    uint256 constant internal MAX_UINT = 2**256-1;

     
    function precision() internal pure returns (uint256) { return PRECISION; }
    function max_qty() internal pure returns (uint256) { return MAX_QTY; }
    function max_rate() internal pure returns (uint256) { return MAX_RATE; }
    function max_decimals() internal pure returns (uint256) { return MAX_DECIMALS; }
    function eth_decimals() internal pure returns (uint256) { return ETH_DECIMALS; }
    function max_uint() internal pure returns (uint256) { return MAX_UINT; }

     
     
     
     
     
    function getDecimals(address token)
        internal
        view
        returns (uint256 decimals)
    {
        bytes4 functionSig = bytes4(keccak256("decimals()"));

         
         
        assembly {
             
            let ptr := mload(0x40)
             
            mstore(ptr,functionSig)
            let functionSigLength := 0x04
            let wordLength := 0x20

            let success := call(
                                5000,  
                                token,  
                                0,  
                                ptr,  
                                functionSigLength,  
                                ptr,  
                                wordLength  
                               )

            switch success
            case 0 {
                decimals := 0  
            }
            case 1 {
                decimals := mload(ptr)  
            }
            mstore(0x40,add(ptr,0x04))  
        }
    }

     
     
     
     
     
     
    function tokenAllowanceAndBalanceSet(
        address tokenOwner,
        address tokenAddress,
        uint256 tokenAmount,
        address addressToAllow
    )
        internal
        view
        returns (bool)
    {
        return (
            ERC20(tokenAddress).allowance(tokenOwner, addressToAllow) >= tokenAmount &&
            ERC20(tokenAddress).balanceOf(tokenOwner) >= tokenAmount
        );
    }

    function calcDstQty(uint srcQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns (uint) {
        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(uint dstQty, uint srcDecimals, uint dstDecimals, uint rate) internal pure returns (uint) {

         
        uint numerator;
        uint denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator;  
    }

    function calcDestAmount(ERC20 src, ERC20 dest, uint srcAmount, uint rate) internal view returns (uint) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(ERC20 src, ERC20 dest, uint destAmount, uint rate) internal view returns (uint) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcRateFromQty(uint srcAmount, uint destAmount, uint srcDecimals, uint dstDecimals)
        internal pure returns (uint)
    {
        require(srcAmount <= MAX_QTY);
        require(destAmount <= MAX_QTY);

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION / ((10 ** (dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
            return (destAmount * PRECISION * (10 ** (srcDecimals - dstDecimals)) / srcAmount);
        }
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

library ERC20SafeTransfer {
    function safeTransfer(address _tokenAddress, address _to, uint256 _value) internal returns (bool success) {

        require(_tokenAddress.call(bytes4(keccak256("transfer(address,uint256)")), _to, _value));

        return fetchReturnData();
    }

    function safeTransferFrom(address _tokenAddress, address _from, address _to, uint256 _value) internal returns (bool success) {

        require(_tokenAddress.call(bytes4(keccak256("transferFrom(address,address,uint256)")), _from, _to, _value));

        return fetchReturnData();
    }

    function safeApprove(address _tokenAddress, address _spender, uint256 _value) internal returns (bool success) {

        require(_tokenAddress.call(bytes4(keccak256("approve(address,uint256)")), _spender, _value));

        return fetchReturnData();
    }

    function fetchReturnData() internal returns (bool success){
        assembly {
            switch returndatasize()
            case 0 {
                success := 1
            }
            case 32 {
                returndatacopy(0, 0, 32)
                success := mload(0)
            }
            default {
                revert(0, 0)
            }
        }
    }

}

 
 
 
contract AllowanceSetter {
    uint256 constant MAX_UINT = 2**256 - 1;

     
     
     
     
     
    function approveAddress(address addressToApprove, address token) internal {
        if(ERC20(token).allowance(address(this), addressToApprove) == 0) {
            require(ERC20SafeTransfer.safeApprove(token, addressToApprove, MAX_UINT));
        }
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

 
 
 
 
contract TotleControl is Ownable {
    mapping(address => bool) public authorizedPrimaries;

     
    modifier onlyTotle() {
        require(authorizedPrimaries[msg.sender]);
        _;
    }

     
     
     
    constructor(address _totlePrimary) public {
        authorizedPrimaries[_totlePrimary] = true;
    }

     
     
     
    function addTotle(
        address _totlePrimary
    ) external onlyOwner {
        authorizedPrimaries[_totlePrimary] = true;
    }

    function removeTotle(
        address _totlePrimary
    ) external onlyOwner {
        authorizedPrimaries[_totlePrimary] = false;
    }
}

 
contract Withdrawable is Ownable {

     
     
     
     
     
    function withdrawToken(address _token, uint256 _amount) external onlyOwner returns (bool) {
        return ERC20SafeTransfer.safeTransfer(_token, owner, _amount);
    }

     
     
     
    function withdrawETH(uint256 _amount) external onlyOwner {
        owner.transfer(_amount);
    }
}

 
contract Pausable is Ownable {
  event Paused();
  event Unpaused();

  bool private _paused = false;

   
  function paused() public view returns (bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused, "Contract is paused.");
    _;
  }

   
  modifier whenPaused() {
    require(_paused, "Contract not paused.");
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused();
  }

   
  function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused();
  }
}

contract ErrorReporter {
    function revertTx(string reason) public pure {
        revert(reason);
    }
}

contract SelectorProvider {
    bytes4 constant getAmountToGiveSelector = bytes4(keccak256("getAmountToGive(bytes)"));
    bytes4 constant staticExchangeChecksSelector = bytes4(keccak256("staticExchangeChecks(bytes)"));
    bytes4 constant performBuyOrderSelector = bytes4(keccak256("performBuyOrder(bytes,uint256)"));
    bytes4 constant performSellOrderSelector = bytes4(keccak256("performSellOrder(bytes,uint256)"));

    function getSelector(bytes4 genericSelector) public pure returns (bytes4);
}

 
contract ExchangeHandler is SelectorProvider, TotleControl, Withdrawable, Pausable {

     

    ErrorReporter public errorReporter;
     
     

     
     
     
    constructor(
        address totlePrimary,
        address _errorReporter
         
    )
        TotleControl(totlePrimary)
        public
    {
        require(_errorReporter != address(0x0));
         
        errorReporter = ErrorReporter(_errorReporter);
         
    }

     
     
     
    function getAmountToGive(
        bytes genericPayload
    )
        public
        view
        returns (uint256 amountToGive)
    {
        bool success;
        bytes4 functionSelector = getSelector(this.getAmountToGive.selector);

        assembly {
            let functionSelectorLength := 0x04
            let functionSelectorOffset := 0x1C
            let scratchSpace := 0x0
            let wordLength := 0x20
            let bytesLength := mload(genericPayload)
            let totalLength := add(functionSelectorLength, bytesLength)
            let startOfNewData := add(genericPayload, functionSelectorOffset)

            mstore(add(scratchSpace, functionSelectorOffset), functionSelector)
            let functionSelectorCorrect := mload(scratchSpace)
            mstore(genericPayload, functionSelectorCorrect)

            success := delegatecall(
                            gas,
                            address,  
                            startOfNewData,  
                            totalLength,  
                            scratchSpace,  
                            wordLength  
                           )
            amountToGive := mload(scratchSpace)
            if eq(success, 0) { revert(0, 0) }
        }
    }

     
     
     
     
    function staticExchangeChecks(
        bytes genericPayload
    )
        public
        view
        returns (bool checksPassed)
    {
        bool success;
        bytes4 functionSelector = getSelector(this.staticExchangeChecks.selector);
        assembly {
            let functionSelectorLength := 0x04
            let functionSelectorOffset := 0x1C
            let scratchSpace := 0x0
            let wordLength := 0x20
            let bytesLength := mload(genericPayload)
            let totalLength := add(functionSelectorLength, bytesLength)
            let startOfNewData := add(genericPayload, functionSelectorOffset)

            mstore(add(scratchSpace, functionSelectorOffset), functionSelector)
            let functionSelectorCorrect := mload(scratchSpace)
            mstore(genericPayload, functionSelectorCorrect)

            success := delegatecall(
                            gas,
                            address,  
                            startOfNewData,  
                            totalLength,  
                            scratchSpace,  
                            wordLength  
                           )
            checksPassed := mload(scratchSpace)
            if eq(success, 0) { revert(0, 0) }
        }
    }

     
     
     
     
     
    function performBuyOrder(
        bytes genericPayload,
        uint256 amountToGiveForOrder
    )
        public
        payable
        returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder)
    {
        bool success;
        bytes4 functionSelector = getSelector(this.performBuyOrder.selector);
        assembly {
            let callDataOffset := 0x44
            let functionSelectorOffset := 0x1C
            let functionSelectorLength := 0x04
            let scratchSpace := 0x0
            let wordLength := 0x20
            let startOfFreeMemory := mload(0x40)

            calldatacopy(startOfFreeMemory, callDataOffset, calldatasize)

            let bytesLength := mload(startOfFreeMemory)
            let totalLength := add(add(functionSelectorLength, bytesLength), wordLength)

            mstore(add(scratchSpace, functionSelectorOffset), functionSelector)

            let functionSelectorCorrect := mload(scratchSpace)

            mstore(startOfFreeMemory, functionSelectorCorrect)

            mstore(add(startOfFreeMemory, add(wordLength, bytesLength)), amountToGiveForOrder)

            let startOfNewData := add(startOfFreeMemory,functionSelectorOffset)

            success := delegatecall(
                            gas,
                            address,  
                            startOfNewData,  
                            totalLength,  
                            scratchSpace,  
                            mul(wordLength, 0x02)  
                          )
            amountSpentOnOrder := mload(scratchSpace)
            amountReceivedFromOrder := mload(add(scratchSpace, wordLength))
            if eq(success, 0) { revert(0, 0) }
        }
    }

     
     
     
     
     
    function performSellOrder(
        bytes genericPayload,
        uint256 amountToGiveForOrder
    )
        public
        returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder)
    {
        bool success;
        bytes4 functionSelector = getSelector(this.performSellOrder.selector);
        assembly {
            let callDataOffset := 0x44
            let functionSelectorOffset := 0x1C
            let functionSelectorLength := 0x04
            let scratchSpace := 0x0
            let wordLength := 0x20
            let startOfFreeMemory := mload(0x40)

            calldatacopy(startOfFreeMemory, callDataOffset, calldatasize)

            let bytesLength := mload(startOfFreeMemory)
            let totalLength := add(add(functionSelectorLength, bytesLength), wordLength)

            mstore(add(scratchSpace, functionSelectorOffset), functionSelector)

            let functionSelectorCorrect := mload(scratchSpace)

            mstore(startOfFreeMemory, functionSelectorCorrect)

            mstore(add(startOfFreeMemory, add(wordLength, bytesLength)), amountToGiveForOrder)

            let startOfNewData := add(startOfFreeMemory,functionSelectorOffset)

            success := delegatecall(
                            gas,
                            address,  
                            startOfNewData,  
                            totalLength,  
                            scratchSpace,  
                            mul(wordLength, 0x02)  
                          )
            amountSpentOnOrder := mload(scratchSpace)
            amountReceivedFromOrder := mload(add(scratchSpace, wordLength))
            if eq(success, 0) { revert(0, 0) }
        }
    }
}

 

contract LibEIP712 {

     
    string constant internal EIP191_HEADER = "\x19\x01";

     
    string constant internal EIP712_DOMAIN_NAME = "0x Protocol";

     
    string constant internal EIP712_DOMAIN_VERSION = "2";

     
    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(abi.encodePacked(
        "EIP712Domain(",
        "string name,",
        "string version,",
        "address verifyingContract",
        ")"
    ));

     
     
    bytes32 public EIP712_DOMAIN_HASH;

    constructor ()
        public
    {
        EIP712_DOMAIN_HASH = keccak256(abi.encodePacked(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            bytes32(address(this))
        ));
    }

     
     
     
    function hashEIP712Message(bytes32 hashStruct)
        internal
        view
        returns (bytes32 result)
    {
        bytes32 eip712DomainHash = EIP712_DOMAIN_HASH;

         
         
         
         
         
         

        assembly {
             
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000)   
            mstore(add(memPtr, 2), eip712DomainHash)                                             
            mstore(add(memPtr, 34), hashStruct)                                                  

             
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}

 

contract LibOrder is
    LibEIP712
{
     
    bytes32 constant internal EIP712_ORDER_SCHEMA_HASH = keccak256(abi.encodePacked(
        "Order(",
        "address makerAddress,",
        "address takerAddress,",
        "address feeRecipientAddress,",
        "address senderAddress,",
        "uint256 makerAssetAmount,",
        "uint256 takerAssetAmount,",
        "uint256 makerFee,",
        "uint256 takerFee,",
        "uint256 expirationTimeSeconds,",
        "uint256 salt,",
        "bytes makerAssetData,",
        "bytes takerAssetData",
        ")"
    ));

     
     
    enum OrderStatus {
        INVALID,                      
        INVALID_MAKER_ASSET_AMOUNT,   
        INVALID_TAKER_ASSET_AMOUNT,   
        FILLABLE,                     
        EXPIRED,                      
        FULLY_FILLED,                 
        CANCELLED                     
    }

     
    struct Order {
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
     

    struct OrderInfo {
        uint8 orderStatus;                     
        bytes32 orderHash;                     
        uint256 orderTakerAssetFilledAmount;   
    }

     
     
     
    function getOrderHash(Order memory order)
        internal
        view
        returns (bytes32 orderHash)
    {
        orderHash = hashEIP712Message(hashOrder(order));
        return orderHash;
    }

     
     
     
    function hashOrder(Order memory order)
        internal
        pure
        returns (bytes32 result)
    {
        bytes32 schemaHash = EIP712_ORDER_SCHEMA_HASH;
        bytes32 makerAssetDataHash = keccak256(order.makerAssetData);
        bytes32 takerAssetDataHash = keccak256(order.takerAssetData);

         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         

        assembly {
             
            let pos1 := sub(order, 32)
            let pos2 := add(order, 320)
            let pos3 := add(order, 352)

             
            let temp1 := mload(pos1)
            let temp2 := mload(pos2)
            let temp3 := mload(pos3)

             
            mstore(pos1, schemaHash)
            mstore(pos2, makerAssetDataHash)
            mstore(pos3, takerAssetDataHash)
            result := keccak256(pos1, 416)

             
            mstore(pos1, temp1)
            mstore(pos2, temp2)
            mstore(pos3, temp3)
        }
        return result;
    }
}

 

contract LibFillResults
{
    struct FillResults {
        uint256 makerAssetFilledAmount;   
        uint256 takerAssetFilledAmount;   
        uint256 makerFeePaid;             
        uint256 takerFeePaid;             
    }

    struct MatchedFillResults {
        FillResults left;                     
        FillResults right;                    
        uint256 leftMakerAssetSpreadAmount;   
    }

     
     
     
     
    function addFillResults(FillResults memory totalFillResults, FillResults memory singleFillResults)
        internal
        pure
    {
        totalFillResults.makerAssetFilledAmount = SafeMath.add(totalFillResults.makerAssetFilledAmount, singleFillResults.makerAssetFilledAmount);
        totalFillResults.takerAssetFilledAmount = SafeMath.add(totalFillResults.takerAssetFilledAmount, singleFillResults.takerAssetFilledAmount);
        totalFillResults.makerFeePaid = SafeMath.add(totalFillResults.makerFeePaid, singleFillResults.makerFeePaid);
        totalFillResults.takerFeePaid = SafeMath.add(totalFillResults.takerFeePaid, singleFillResults.takerFeePaid);
    }
}

contract IExchangeCore {

    bytes public ZRX_ASSET_DATA;

     
     
     
     
     
    function fillOrder(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        returns (LibFillResults.FillResults memory fillResults);

    function fillOrderNoThrow(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        returns (LibFillResults.FillResults memory fillResults);

     
     
     
     
    function getOrderInfo(LibOrder.Order memory order)
        public
        view
        returns (LibOrder.OrderInfo memory orderInfo);

     
     
     
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address);

    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        public
        view
        returns (bool isValid);
}

interface WETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

 
 
contract ZeroExExchangeHandler is ExchangeHandler, AllowanceSetter  {

     

    IExchangeCore public exchange;
     
    bytes constant ZRX_ASSET_DATA = "\xf4\x72\x61\xb0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xe4\x1d\x24\x89\x57\x1d\x32\x21\x89\x24\x6d\xaf\xa5\xeb\xde\x1f\x46\x99\xf4\x98";
    address ERC20_ASSET_PROXY;
    WETH weth;

     

     
     
     
    constructor(
        address _exchange,
        address totlePrimary,
        address _weth,
        address errorReporter
         
    )
        ExchangeHandler(totlePrimary, errorReporter )
        public
    {
        require(_exchange != address(0x0));
        exchange = IExchangeCore(_exchange);
        ERC20_ASSET_PROXY = exchange.getAssetProxy(toBytes4(ZRX_ASSET_DATA, 0));
        weth = WETH(_weth);
    }

    struct OrderData {
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
        bytes signature;
    }

     

     

     
     
     
    function getAmountToGive_(
        OrderData data
    )
      public
      view
      onlyTotle
      returns (uint256 amountToGive)
    {
        LibOrder.OrderInfo memory orderInfo = exchange.getOrderInfo(
            getZeroExOrder(data)
        );
        uint makerAssetAvailable = getAssetDataAvailable(data.makerAssetData, data.makerAddress);
        uint feeAssetAvailable = getAssetDataAvailable(ZRX_ASSET_DATA, data.makerAddress);

        uint maxFromMakerFee = data.makerFee == 0 ? Utils.max_uint() : getPartialAmount(feeAssetAvailable, data.makerFee, data.takerAssetAmount);
        amountToGive = Math.min(Math.min(
            getPartialAmount(makerAssetAvailable, data.makerAssetAmount, data.takerAssetAmount),
            maxFromMakerFee),
            SafeMath.sub(data.takerAssetAmount, orderInfo.orderTakerAssetFilledAmount)
        );
         
    }

    function getAssetDataAvailable(bytes assetData, address account) internal view returns (uint){
        address tokenAddress = toAddress(assetData, 16);
        ERC20 token = ERC20(tokenAddress);
        return Math.min(token.balanceOf(account), token.allowance(account, ERC20_ASSET_PROXY));
    }

    function getZeroExOrder(OrderData data) internal pure returns (LibOrder.Order) {
        return LibOrder.Order({
            makerAddress: data.makerAddress,
            takerAddress: data.takerAddress,
            feeRecipientAddress: data.feeRecipientAddress,
            senderAddress: data.senderAddress,
            makerAssetAmount: data.makerAssetAmount,
            takerAssetAmount: data.takerAssetAmount,
            makerFee: data.makerFee,
            takerFee: data.takerFee,
            expirationTimeSeconds: data.expirationTimeSeconds,
            salt: data.salt,
            makerAssetData: data.makerAssetData,
            takerAssetData: data.takerAssetData
        });
    }

     
     
     
     
    function staticExchangeChecks_(
        OrderData data
    )
        public
        view
        onlyTotle
        returns (bool checksPassed)
    {

         
         
         
         
         
         
         
        return (block.timestamp <= data.expirationTimeSeconds &&
                toBytes4(data.takerAssetData, 0) == bytes4(0xf47261b0) &&
                toBytes4(data.makerAssetData, 0) == bytes4(0xf47261b0) &&
                data.takerFee == 0 &&
                (data.takerAddress == address(0x0) || data.takerAddress == address(this)) &&
                (data.senderAddress == address(0x0) || data.senderAddress == address(this))
        );
    }

     
     
     
     
    function performBuyOrder_(
        OrderData data
    )
        public
        payable
        onlyTotle
        returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder)
    {
        uint256 amountToGiveForOrder = toUint(msg.data, msg.data.length - 32);

        approveAddress(ERC20_ASSET_PROXY, toAddress(data.takerAssetData, 16));

        weth.deposit.value(amountToGiveForOrder)();

        LibFillResults.FillResults memory results = exchange.fillOrder(
            getZeroExOrder(data),
            amountToGiveForOrder,
            data.signature
        );
        require(ERC20SafeTransfer.safeTransfer(toAddress(data.makerAssetData, 16), msg.sender, results.makerAssetFilledAmount));

        amountSpentOnOrder = results.takerAssetFilledAmount;
        amountReceivedFromOrder = results.makerAssetFilledAmount;
         
    }

     
     
     
     
    function performSellOrder_(
        OrderData data
    )
        public
        onlyTotle
        returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder)
    {
        uint256 amountToGiveForOrder = toUint(msg.data, msg.data.length - 32);
        approveAddress(ERC20_ASSET_PROXY, toAddress(data.takerAssetData, 16));

        LibFillResults.FillResults memory results = exchange.fillOrder(
            getZeroExOrder(data),
            amountToGiveForOrder,
            data.signature
        );

        weth.withdraw(results.makerAssetFilledAmount);
        msg.sender.transfer(results.makerAssetFilledAmount);

        amountSpentOnOrder = results.takerAssetFilledAmount;
        amountReceivedFromOrder = results.makerAssetFilledAmount;
         
    }

     
     
     
     
     
    function getPartialAmount(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256)
    {
        return SafeMath.div(SafeMath.mul(numerator, target), denominator);
    }

     
     
     
     
    function toAddress(bytes _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toBytes4(bytes _bytes, uint _start) internal pure returns (bytes4) {
        require(_bytes.length >= (_start + 4));
        bytes4 tempBytes4;

        assembly {
            tempBytes4 := mload(add(add(_bytes, 0x20), _start))
        }
        return tempBytes4;
    }

     
     
     
     
    function toUint(bytes _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function getSelector(bytes4 genericSelector) public pure returns (bytes4) {
        if (genericSelector == getAmountToGiveSelector) {
            return bytes4(keccak256("getAmountToGive_((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes,bytes))"));
        } else if (genericSelector == staticExchangeChecksSelector) {
            return bytes4(keccak256("staticExchangeChecks_((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes,bytes))"));
        } else if (genericSelector == performBuyOrderSelector) {
            return bytes4(keccak256("performBuyOrder_((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes,bytes))"));
        } else if (genericSelector == performSellOrderSelector) {
            return bytes4(keccak256("performSellOrder_((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes,bytes))"));
        } else {
            return bytes4(0x0);
        }
    }

     

     
     
    function() public payable {
        require(msg.sender == address(weth));
    }
}