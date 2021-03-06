 

pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

 
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
                decimals := 18  
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

contract ErrorReporter {
    function revertTx(string reason) public pure {
        revert(reason);
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
    address public totlePrimary;

     
    modifier onlyTotle() {
        require(msg.sender == totlePrimary);
        _;
    }

     
     
     
    constructor(address _totlePrimary) public {
        require(_totlePrimary != address(0x0));
        totlePrimary = _totlePrimary;
    }

     
     
     
    function setTotle(
        address _totlePrimary
    ) external onlyOwner {
        require(_totlePrimary != address(0x0));
        totlePrimary = _totlePrimary;
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

contract SelectorProvider {
    bytes4 constant getAmountToGive = bytes4(keccak256("getAmountToGive(bytes)"));
    bytes4 constant staticExchangeChecks = bytes4(keccak256("staticExchangeChecks(bytes)"));
    bytes4 constant performBuyOrder = bytes4(keccak256("performBuyOrder(bytes,uint256)"));
    bytes4 constant performSellOrder = bytes4(keccak256("performSellOrder(bytes,uint256)"));

    function getSelector(bytes4 genericSelector) public pure returns (bytes4);
}

 
contract ExchangeHandler is TotleControl, Withdrawable, Pausable {

     

    SelectorProvider public selectorProvider;
    ErrorReporter public errorReporter;
     
     

    modifier onlySelf() {
        require(msg.sender == address(this));
        _;
    }

     
     
     
     
    constructor(
        address _selectorProvider,
        address totlePrimary,
        address _errorReporter
         
    )
        TotleControl(totlePrimary)
        public
    {
        require(_selectorProvider != address(0x0));
        require(_errorReporter != address(0x0));
         
        selectorProvider = SelectorProvider(_selectorProvider);
        errorReporter = ErrorReporter(_errorReporter);
         
    }

     
     
     
    function getAmountToGive(
        bytes genericPayload
    )
        public
        view
        onlyTotle
        whenNotPaused
        returns (uint256 amountToGive)
    {
        bool success;
        bytes4 functionSelector = selectorProvider.getSelector(this.getAmountToGive.selector);

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

            success := call(
                            gas,
                            address,  
                            callvalue,
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
        onlyTotle
        whenNotPaused
        returns (bool checksPassed)
    {
        bool success;
        bytes4 functionSelector = selectorProvider.getSelector(this.staticExchangeChecks.selector);
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

            success := call(
                            gas,
                            address,  
                            callvalue,
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
        onlyTotle
        whenNotPaused
        returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder)
    {
        bool success;
        bytes4 functionSelector = selectorProvider.getSelector(this.performBuyOrder.selector);
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

            success := call(
                            gas,
                            address,  
                            callvalue,
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
        onlyTotle
        whenNotPaused
        returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder)
    {
        bool success;
        bytes4 functionSelector = selectorProvider.getSelector(this.performSellOrder.selector);
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

            success := call(
                            gas,
                            address,  
                            callvalue,
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

interface TokenStoreExchange {

    
   function trade(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive,
       uint _expires, uint _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s, uint _amount) external;

    
   function fee() external constant returns(uint256);
   function availableVolume(address _tokenGet, uint _amountGet, address _tokenGive, uint _amountGive, uint _expires,
       uint _nonce, address _user, uint8 _v, bytes32 _r, bytes32 _s) external constant returns(uint);

    
   function deposit() external payable;  
   function withdraw(uint256 amount) external;  
   function depositToken(address _token, uint _amount) external;
   function withdrawToken(address _token, uint _amount) external;

}

 
 
contract TokenStoreSelectorProvider is SelectorProvider {
    function getSelector(bytes4 genericSelector) public pure returns (bytes4) {
        if (genericSelector == getAmountToGive) {
            return bytes4(keccak256("getAmountToGive((address,uint256,address,uint256,uint256,uint256,address,uint8,bytes32,bytes32))"));
        } else if (genericSelector == staticExchangeChecks) {
            return bytes4(keccak256("staticExchangeChecks((address,uint256,address,uint256,uint256,uint256,address,uint8,bytes32,bytes32))"));
        } else if (genericSelector == performBuyOrder) {
            return bytes4(keccak256("performBuyOrder((address,uint256,address,uint256,uint256,uint256,address,uint8,bytes32,bytes32),uint256)"));
        } else if (genericSelector == performSellOrder) {
            return bytes4(keccak256("performSellOrder((address,uint256,address,uint256,uint256,uint256,address,uint8,bytes32,bytes32),uint256)"));
        } else {
            return bytes4(0x0);
        }
    }
}

 
contract TokenStoreHandler is ExchangeHandler, AllowanceSetter {

     
    struct OrderData {
        address takerToken;  
        uint256 takerAmount;
        address makerToken;  
        uint256 makerAmount;
        uint256 expires;
        uint256 nonce;
        address user;  
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    TokenStoreExchange exchange;

     
     
     
     
     
    constructor(
        address _exchange,
        address _selectorProvider,
        address _totlePrimary,
        address errorReporter 
    ) ExchangeHandler(_selectorProvider, _totlePrimary, errorReporter ) public {
        exchange = TokenStoreExchange(_exchange);
    }

     

     
     
     
    function getAmountToGive(
        OrderData data
    )
        public
        view
        whenNotPaused
        onlySelf
        returns (uint256 amountToGive)
    {
        uint256 feePercentage = exchange.fee();
        uint256 availableVolume = exchange.availableVolume(data.takerToken, data.takerAmount, data.makerToken, data.makerAmount, data.expires,
            data.nonce, data.user, data.v, data.r, data.s);
        uint256 fee = SafeMath.div(SafeMath.mul(availableVolume, feePercentage), 1 ether);
        return SafeMath.add(availableVolume, fee);
    }

     
     
     
     
    function staticExchangeChecks(
        OrderData data
    )
        public
        view
        whenNotPaused
        onlySelf
        returns (bool checksPassed)
    {
        bytes32 hash = sha256(abi.encodePacked(address(exchange), data.takerToken, data.takerAmount, data.makerToken, data.makerAmount, data.expires, data.nonce));
        if (ecrecover(sha3(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), data.v, data.r, data.s) != data.user || block.number > data.expires) {
            return false;
        }
        return true;
    }

     
     
     
     
     
    function performBuyOrder(
        OrderData data,
        uint256 amountToGiveForOrder
    )
        public
        payable
        whenNotPaused
        onlySelf
        returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder)
    {
        amountSpentOnOrder = amountToGiveForOrder;
        exchange.deposit.value(amountToGiveForOrder)();
        uint256 amountToSpend = removeFee(amountToGiveForOrder);
        amountReceivedFromOrder = SafeMath.div(SafeMath.mul(amountToSpend, data.makerAmount), data.takerAmount);
        exchange.trade(data.takerToken, data.takerAmount, data.makerToken, data.makerAmount, data.expires, data.nonce, data.user, data.v, data.r, data.s, amountToSpend);
         
        exchange.withdrawToken(data.makerToken, amountReceivedFromOrder);
        if (!ERC20SafeTransfer.safeTransfer(data.makerToken, totlePrimary, amountReceivedFromOrder)){
            errorReporter.revertTx("Failed to transfer tokens to totle primary");
        }

    }

     
     
     
     
     
    function performSellOrder(
        OrderData data,
        uint256 amountToGiveForOrder
    )
        public
        whenNotPaused
        onlySelf
        returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder)
    {
        amountSpentOnOrder = amountToGiveForOrder;
        approveAddress(address(exchange), data.takerToken);
        exchange.depositToken(data.takerToken, amountToGiveForOrder);
        uint256 amountToSpend = removeFee(amountToGiveForOrder);
        amountReceivedFromOrder = SafeMath.div(SafeMath.mul(amountToSpend, data.makerAmount), data.takerAmount);
        exchange.trade(data.takerToken, data.takerAmount, data.makerToken, data.makerAmount, data.expires, data.nonce, data.user, data.v, data.r, data.s, amountToSpend);
         
        exchange.withdraw(amountReceivedFromOrder);
        totlePrimary.transfer(amountReceivedFromOrder);
    }

    function removeFee(uint256 totalAmount) internal constant returns (uint256){
      uint256 feePercentage = exchange.fee();
      return SafeMath.div(SafeMath.mul(totalAmount, 1 ether), SafeMath.add(feePercentage, 1 ether));

    }

     
     
    function() public payable {
         
        uint256 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }
        require(size > 0);
    }
}