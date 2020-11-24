 

pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

 

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

 
 
interface BancorConverter {
    function quickConvert(address[] _path, uint256 _amount, uint256 _minReturn) external payable returns (uint256);
    function registry() external view returns (IContractRegistry);
    function BANCOR_GAS_PRICE_LIMIT() external view returns (bytes32);
    function BANCOR_NETWORK() external view returns (bytes32);
}

 
 
interface IContractRegistry {
    function getAddress(bytes32 _contractName) external view returns (address);
}

 
 
interface IBancorGasPriceLimit {
    function gasPrice() external view returns (uint256);
}

 
 
interface BancorNetwork {
    function getReturnByPath(address[] _path, uint256 _amount) external view returns (uint256) ;
}

 
 
contract BancorHandler is ExchangeHandler, AllowanceSetter {

     

    struct OrderData {
        address converterAddress;
        address[11] conversionPath;
        address destinationToken;
        uint256 minReturn;
        uint256 amountToGive;
        uint256 expectedReturn;
    }

     
     
     
    constructor(
        address totlePrimary,
        address errorReporter
         
    )
        ExchangeHandler(totlePrimary, errorReporter )
        public
    {}

     

     
     
     
     
     
     
     
    function getAmountToGive(
        OrderData data
    )
        public
        view
        whenNotPaused
        onlyTotle
        returns (uint256 amountToGive)
    {
        amountToGive = data.amountToGive;
    }

     
     
     
     
     
     
     
     
    function staticExchangeChecks(
        OrderData data
    )
        public
        view
        whenNotPaused
        onlyTotle
        returns (bool checksPassed)
    {
        BancorConverter converter = BancorConverter(data.converterAddress);
        IBancorGasPriceLimit gasPriceLimitContract = IBancorGasPriceLimit(
            converter.registry().getAddress(converter.BANCOR_GAS_PRICE_LIMIT())
        );

        uint256 gasPriceLimit = gasPriceLimitContract.gasPrice();
        checksPassed = tx.gasprice <= gasPriceLimit;

         
    }

     
     
     
     
     
     
     
     
     
    function performBuyOrder(
        OrderData data,
        uint256 amountToGiveForOrder
    )
        public
        payable
        whenNotPaused
        onlyTotle
        returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder)
    {
        amountSpentOnOrder = amountToGiveForOrder;
        amountReceivedFromOrder = BancorConverter(data.converterAddress).quickConvert.value(msg.value)(
            trimAddressArray(data.conversionPath),
            amountToGiveForOrder,
            data.minReturn
        );

         

        if (!ERC20SafeTransfer.safeTransfer(data.destinationToken, msg.sender, amountReceivedFromOrder)){
            errorReporter.revertTx("Failed to transfer tokens to totle primary");
        }
    }

     
     
     
     
     
     
     
     
     
    function performSellOrder(
        OrderData data,
        uint256 amountToGiveForOrder
    )
        public
        whenNotPaused
        onlyTotle
        returns (uint256 amountSpentOnOrder, uint256 amountReceivedFromOrder)
    {
        approveAddress(data.converterAddress, data.conversionPath[0]);

        amountSpentOnOrder = amountToGiveForOrder;
        amountReceivedFromOrder = BancorConverter(data.converterAddress).quickConvert(
            trimAddressArray(data.conversionPath),
            amountToGiveForOrder,
            data.minReturn
        );

         

        msg.sender.transfer(amountReceivedFromOrder);
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

     
     
     
    function trimAddressArray(address[11] addresses) internal pure returns (address[]) {
        uint256 length = 0;
        for (uint256 index = 0; index < 11; index++){
            if (addresses[index] == 0x0){
                continue;
            }
            length++;
        }
        address[] memory trimmedArray = new address[](length);
        for (index = 0; index < length; index++){
            trimmedArray[index] = addresses[index];
        }
        return trimmedArray;
    }

    function getSelector(bytes4 genericSelector) public pure returns (bytes4) {
        if (genericSelector == getAmountToGiveSelector) {
            return bytes4(keccak256("getAmountToGive((address,address[11],address,uint256,uint256,uint256))"));
        } else if (genericSelector == staticExchangeChecksSelector) {
            return bytes4(keccak256("staticExchangeChecks((address,address[11],address,uint256,uint256,uint256))"));
        } else if (genericSelector == performBuyOrderSelector) {
            return bytes4(keccak256("performBuyOrder((address,address[11],address,uint256,uint256,uint256),uint256)"));
        } else if (genericSelector == performSellOrderSelector) {
            return bytes4(keccak256("performSellOrder((address,address[11],address,uint256,uint256,uint256),uint256)"));
        } else {
            return bytes4(0x0);
        }
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