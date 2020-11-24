 

pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

 
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

 
contract Withdrawable is Ownable {

     
     
     
     
     
    function withdrawToken(address _token, uint256 _amount) external onlyOwner returns (bool) {
        return ERC20SafeTransfer.safeTransfer(_token, owner, _amount);
    }

     
     
     
    function withdrawETH(uint256 _amount) external onlyOwner {
        owner.transfer(_amount);
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

 

 
 
contract TokenTransferProxy is Ownable {

     
    modifier onlyAuthorized {
        require(authorized[msg.sender]);
        _;
    }

    modifier targetAuthorized(address target) {
        require(authorized[target]);
        _;
    }

    modifier targetNotAuthorized(address target) {
        require(!authorized[target]);
        _;
    }

    mapping (address => bool) public authorized;
    address[] public authorities;

    event LogAuthorizedAddressAdded(address indexed target, address indexed caller);
    event LogAuthorizedAddressRemoved(address indexed target, address indexed caller);

     

     
     
    function addAuthorizedAddress(address target)
        public
        onlyOwner
        targetNotAuthorized(target)
    {
        authorized[target] = true;
        authorities.push(target);
        emit LogAuthorizedAddressAdded(target, msg.sender);
    }

     
     
    function removeAuthorizedAddress(address target)
        public
        onlyOwner
        targetAuthorized(target)
    {
        delete authorized[target];
        for (uint i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                authorities[i] = authorities[authorities.length - 1];
                authorities.length -= 1;
                break;
            }
        }
        emit LogAuthorizedAddressRemoved(target, msg.sender);
    }

     
     
     
     
     
     
    function transferFrom(
        address token,
        address from,
        address to,
        uint value)
        public
        onlyAuthorized
        returns (bool)
    {
        require(ERC20SafeTransfer.safeTransferFrom(token, from, to, value));
        return true;
    }

     

     
     
    function getAuthorizedAddresses()
        public
        view
        returns (address[])
    {
        return authorities;
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

contract ErrorReporter {
    function revertTx(string reason) public pure {
        revert(reason);
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

 
contract TotlePrimary is Withdrawable, Pausable {

     

    mapping(address => bool) public handlerWhitelistMap;
    address[] public handlerWhitelistArray;

    address public tokenTransferProxy;
    ErrorReporter public errorReporter;
     

     

     
    struct Trade {
        bool isSell;
        address tokenAddress;
        uint256 tokenAmount;
        bool optionalTrade;
        uint256 minimumExchangeRate;
        uint256 minimumAcceptableTokenAmount;
        Order[] orders;
    }

    struct Order {
        address exchangeHandler;
        bytes genericPayload;
    }

    struct TradeFlag {
        bool ignoreTrade;
        bool[] ignoreOrder;
    }

    struct CurrentAmounts {
        uint256 amountSpentOnTrade;
        uint256 amountReceivedFromTrade;
        uint256 amountLeftToSpendOnTrade;
    }

     

    event LogRebalance(
        bytes32 id
    );

     

    modifier handlerWhitelisted(address handler) {
        if (!handlerWhitelistMap[handler]) {
            errorReporter.revertTx("Handler not in whitelist");
        }
        _;
    }

    modifier handlerNotWhitelisted(address handler) {
        if (handlerWhitelistMap[handler]) {
            errorReporter.revertTx("Handler already whitelisted");
        }
        _;
    }

     
     
     
    constructor (address _tokenTransferProxy, address _errorReporter ) public {
        require(_tokenTransferProxy != address(0x0));
        require(_errorReporter != address(0x0));
         
        tokenTransferProxy = _tokenTransferProxy;
        errorReporter = ErrorReporter(_errorReporter);
         
    }

     

     
     
     
    function addHandlerToWhitelist(address handler)
        public
        onlyOwner
        handlerNotWhitelisted(handler)
    {
        handlerWhitelistMap[handler] = true;
        handlerWhitelistArray.push(handler);
    }

     
     
     
    function removeHandlerFromWhitelist(address handler)
        public
        onlyOwner
        handlerWhitelisted(handler)
    {
        delete handlerWhitelistMap[handler];
        for (uint i = 0; i < handlerWhitelistArray.length; i++) {
            if (handlerWhitelistArray[i] == handler) {
                handlerWhitelistArray[i] = handlerWhitelistArray[handlerWhitelistArray.length - 1];
                handlerWhitelistArray.length -= 1;
                break;
            }
        }
    }

     
     
    function performRebalance(
        Trade[] trades,
        bytes32 id
    )
        public
        payable
        whenNotPaused
    {
        emit LogRebalance(id);
         

        TradeFlag[] memory tradeFlags = initialiseTradeFlags(trades);

        staticChecks(trades, tradeFlags);

         

        transferTokens(trades, tradeFlags);

         

        uint256 etherBalance = msg.value;

         

        for (uint256 i; i < trades.length; i++) {
            Trade memory thisTrade = trades[i];
            TradeFlag memory thisTradeFlag = tradeFlags[i];

            CurrentAmounts memory amounts = CurrentAmounts({
                amountSpentOnTrade: 0,
                amountReceivedFromTrade: 0,
                amountLeftToSpendOnTrade: thisTrade.isSell ? thisTrade.tokenAmount : calculateMaxEtherSpend(thisTrade, etherBalance)
            });
             

            performTrade(
                thisTrade,
                thisTradeFlag,
                amounts
            );

             

            if (amounts.amountReceivedFromTrade == 0 && thisTrade.optionalTrade) {
                 
                continue;
            }

             

            if (!checkIfTradeAmountsAcceptable(thisTrade, amounts.amountSpentOnTrade, amounts.amountReceivedFromTrade)) {
                errorReporter.revertTx("Amounts spent/received in trade not acceptable");
            }

             

            if (thisTrade.isSell) {
                 
                etherBalance = SafeMath.add(etherBalance, amounts.amountReceivedFromTrade);
            } else {
                 
                etherBalance = SafeMath.sub(etherBalance, amounts.amountSpentOnTrade);
            }

             

            transferTokensToUser(
                thisTrade.tokenAddress,
                thisTrade.isSell ? amounts.amountLeftToSpendOnTrade : amounts.amountReceivedFromTrade
            );

        }

        if(etherBalance > 0) {
             
            msg.sender.transfer(etherBalance);
        }
    }

     
     
     
     
    function staticChecks(
        Trade[] trades,
        TradeFlag[] tradeFlags
    )
        public
        view
        whenNotPaused
    {
        bool previousBuyOccured = false;

        for (uint256 i; i < trades.length; i++) {
            Trade memory thisTrade = trades[i];
            if (thisTrade.isSell) {
                if (previousBuyOccured) {
                    errorReporter.revertTx("A buy has occured before this sell");
                }

                if (!Utils.tokenAllowanceAndBalanceSet(msg.sender, thisTrade.tokenAddress, thisTrade.tokenAmount, tokenTransferProxy)) {
                    if (!thisTrade.optionalTrade) {
                        errorReporter.revertTx("Taker has not sent allowance/balance on a non-optional trade");
                    }
                     
                    tradeFlags[i].ignoreTrade = true;
                    continue;
                }
            } else {
                previousBuyOccured = true;
            }

             
            for (uint256 j; j < thisTrade.orders.length; j++) {
                Order memory thisOrder = thisTrade.orders[j];
                if ( !handlerWhitelistMap[thisOrder.exchangeHandler] ) {
                     
                    tradeFlags[i].ignoreOrder[j] = true;
                    continue;
                }
            }
        }
    }

     

     
     
     
    function initialiseTradeFlags(Trade[] trades)
        internal
        returns (TradeFlag[])
    {
         
        TradeFlag[] memory tradeFlags = new TradeFlag[](trades.length);
        for (uint256 i = 0; i < trades.length; i++) {
            tradeFlags[i].ignoreOrder = new bool[](trades[i].orders.length);
        }
        return tradeFlags;
    }

     
     
     
    function transferTokensToUser(
        address tokenAddress,
        uint256 tokenAmount
    )
        internal
    {
         
        if (tokenAmount > 0) {
            if (!ERC20SafeTransfer.safeTransfer(tokenAddress, msg.sender, tokenAmount)) {
                errorReporter.revertTx("Unable to transfer tokens to user");
            }
        }
    }

     
     
     
     
     
    function performTrade(
        Trade trade,
        TradeFlag tradeFlag,
        CurrentAmounts amounts
    )
        internal
    {
         

        for (uint256 j; j < trade.orders.length; j++) {

             

             
            if( amounts.amountReceivedFromTrade >= trade.minimumAcceptableTokenAmount ) {
                 
                return;
            }

            if (tradeFlag.ignoreOrder[j] || amounts.amountLeftToSpendOnTrade == 0) {
                 
                continue;
            }

            uint256 amountSpentOnOrder = 0;
            uint256 amountReceivedFromOrder = 0;

            Order memory thisOrder = trade.orders[j];

             
            ExchangeHandler thisHandler = ExchangeHandler(thisOrder.exchangeHandler);

            uint256 amountToGiveForOrder = Utils.min(
                thisHandler.getAmountToGive(thisOrder.genericPayload),
                amounts.amountLeftToSpendOnTrade
            );

            if (amountToGiveForOrder == 0) {
                 
                continue;
            }

             

            if( !thisHandler.staticExchangeChecks(thisOrder.genericPayload) ) {
                 
                continue;
            }

            if (trade.isSell) {
                 
                if (!ERC20SafeTransfer.safeTransfer(trade.tokenAddress,address(thisHandler), amountToGiveForOrder)) {
                    if( !trade.optionalTrade ) errorReporter.revertTx("Unable to transfer tokens to handler");
                    else {
                         
                        return;
                    }
                }

                 
                (amountSpentOnOrder, amountReceivedFromOrder) = thisHandler.performSellOrder(thisOrder.genericPayload, amountToGiveForOrder);
                 
            } else {
                 
                (amountSpentOnOrder, amountReceivedFromOrder) = thisHandler.performBuyOrder.value(amountToGiveForOrder)(thisOrder.genericPayload, amountToGiveForOrder);
                 
            }

            if (amountReceivedFromOrder > 0) {
                amounts.amountLeftToSpendOnTrade = SafeMath.sub(amounts.amountLeftToSpendOnTrade, amountSpentOnOrder);
                amounts.amountSpentOnTrade = SafeMath.add(amounts.amountSpentOnTrade, amountSpentOnOrder);
                amounts.amountReceivedFromTrade = SafeMath.add(amounts.amountReceivedFromTrade, amountReceivedFromOrder);

                 
            }
        }

    }

     
     
     
     
     
     
    function checkIfTradeAmountsAcceptable(
        Trade trade,
        uint256 amountSpentOnTrade,
        uint256 amountReceivedFromTrade
    )
        internal
        view
        returns (bool passed)
    {
         
        uint256 tokenAmount = trade.isSell ? amountSpentOnTrade : amountReceivedFromTrade;
        passed = tokenAmount >= trade.minimumAcceptableTokenAmount;

        if( !passed ) {
             
        }

        if (passed) {
            uint256 tokenDecimals = Utils.getDecimals(ERC20(trade.tokenAddress));
            uint256 srcDecimals = trade.isSell ? tokenDecimals : Utils.eth_decimals();
            uint256 destDecimals = trade.isSell ? Utils.eth_decimals() : tokenDecimals;
            uint256 actualRate = Utils.calcRateFromQty(amountSpentOnTrade, amountReceivedFromTrade, srcDecimals, destDecimals);
            passed = actualRate >= trade.minimumExchangeRate;
        }

        if( !passed ) {
             
        }
    }

     
     
     
    function transferTokens(Trade[] trades, TradeFlag[] tradeFlags) internal {
        for (uint256 i = 0; i < trades.length; i++) {
            if (trades[i].isSell && !tradeFlags[i].ignoreTrade) {

                 
                if (
                    !TokenTransferProxy(tokenTransferProxy).transferFrom(
                        trades[i].tokenAddress,
                        msg.sender,
                        address(this),
                        trades[i].tokenAmount
                    )
                ) {
                    errorReporter.revertTx("TTP unable to transfer tokens to primary");
                }
           }
        }
    }

     
     
     
     
    function calculateMaxEtherSpend(Trade trade, uint256 etherBalance) internal view returns (uint256) {
         
        assert(!trade.isSell);

        uint256 tokenDecimals = Utils.getDecimals(ERC20(trade.tokenAddress));
        uint256 srcDecimals = trade.isSell ? tokenDecimals : Utils.eth_decimals();
        uint256 destDecimals = trade.isSell ? Utils.eth_decimals() : tokenDecimals;
        uint256 maxSpendAtMinRate = Utils.calcSrcQty(trade.tokenAmount, srcDecimals, destDecimals, trade.minimumExchangeRate);

        return Utils.min(etherBalance, maxSpendAtMinRate);
    }

     

     
     
    function() public payable whenNotPaused {
         
        uint256 size;
        address sender = msg.sender;
        assembly {
            size := extcodesize(sender)
        }
        if (size == 0) {
            errorReporter.revertTx("EOA cannot send ether to primary fallback");
        }
    }
}