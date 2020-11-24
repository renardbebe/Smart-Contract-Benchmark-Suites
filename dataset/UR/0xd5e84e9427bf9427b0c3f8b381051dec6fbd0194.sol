 

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

 

 
contract TxRegistry is Ownable {
    address public customer;

     
    struct TxData {
        bytes32 txOrigMcwTransfer;
        uint256 amountMCW;
        uint256 amountKWh;
        uint256 timestampPaymentMCW;
        bytes32 txPaymentKWh;
        uint256 timestampPaymentKWh;
    }

     
    mapping (bytes32 => TxData) private txRegistry;

     
    bytes32[] private txIndex;

         
    constructor(address _customer) public {
        customer = _customer;
    }

     
    function addTxToRegistry(
        bytes32 _txPaymentForMCW,
        bytes32 _txOrigMcwTransfer,
        uint256 _amountMCW,
        uint256 _amountKWh,
        uint256 _timestamp
        ) public onlyOwner returns(bool)
    {
        require(
            _txPaymentForMCW != 0 && _txOrigMcwTransfer != 0 && _amountMCW != 0 && _amountKWh != 0 && _timestamp != 0,
            "All parameters must be not empty."
        );
        require(
            txRegistry[_txPaymentForMCW].timestampPaymentMCW == 0,
            "Tx with such hash is already exist."
        );

        txRegistry[_txPaymentForMCW].txOrigMcwTransfer = _txOrigMcwTransfer;
        txRegistry[_txPaymentForMCW].amountMCW = _amountMCW;
        txRegistry[_txPaymentForMCW].amountKWh = _amountKWh;
        txRegistry[_txPaymentForMCW].timestampPaymentMCW = _timestamp;
        txIndex.push(_txPaymentForMCW);
        return true;
    }

     
    function setTxAsSpent(bytes32 _txPaymentForMCW, bytes32 _txPaymentForKWh, uint256 _timestamp) public onlyOwner returns(bool) {
        require(
            _txPaymentForMCW != 0 && _txPaymentForKWh != 0 && _timestamp != 0,
            "All parameters must be not empty."
        );
        require(
            txRegistry[_txPaymentForMCW].timestampPaymentMCW != 0,
            "Tx with such hash doesn't exist."
        );
        require(
            txRegistry[_txPaymentForMCW].timestampPaymentKWh == 0,
            "Tx with such hash is already spent."
        );

        txRegistry[_txPaymentForMCW].txPaymentKWh = _txPaymentForKWh;
        txRegistry[_txPaymentForMCW].timestampPaymentKWh = _timestamp;
        return true;
    }

        
    function getTxCount() public view returns(uint256) {
        return txIndex.length;
    }

       
    function getTxAtIndex(uint256 _index) public view returns(bytes32) {
        return txIndex[_index];
    }

       
    function getTxOrigMcwTransfer(bytes32 _txPaymentForMCW) public view returns(bytes32) {
        return txRegistry[_txPaymentForMCW].txOrigMcwTransfer;
    }

       
    function getTxAmountMCW(bytes32 _txPaymentForMCW) public view returns(uint256) {
        return txRegistry[_txPaymentForMCW].amountMCW;
    }

       
    function getTxAmountKWh(bytes32 _txPaymentForMCW) public view returns(uint256) {
        return txRegistry[_txPaymentForMCW].amountKWh;
    }

       
    function getTxTimestampPaymentMCW(bytes32 _txPaymentForMCW) public view returns(uint256) {
        return txRegistry[_txPaymentForMCW].timestampPaymentMCW;
    }

       
    function getTxPaymentKWh(bytes32 _txPaymentForMCW) public view returns(bytes32) {
        return txRegistry[_txPaymentForMCW].txPaymentKWh;
    }

       
    function getTxTimestampPaymentKWh(bytes32 _txPaymentForMCW) public view returns(uint256) {
        return txRegistry[_txPaymentForMCW].timestampPaymentKWh;
    }

       
    function isValidTxPaymentForMCW(bytes32 _txPaymentForMCW) public view returns(bool) {
        bool isValid = false;
        if (txRegistry[_txPaymentForMCW].timestampPaymentMCW != 0) {
            isValid = true;
        }
        return isValid;
    }

     
    function isSpentTxPaymentForMCW(bytes32 _txPaymentForMCW) public view returns(bool) {
        bool isSpent = false;
        if (txRegistry[_txPaymentForMCW].timestampPaymentKWh != 0) {
            isSpent = true;
        }
        return isSpent;
    }

     
    function isValidTxPaymentForKWh(bytes32 _txPaymentForKWh) public view returns(bool) {
        bool isValid = false;
        for (uint256 i = 0; i < getTxCount(); i++) {
            if (txRegistry[getTxAtIndex(i)].txPaymentKWh == _txPaymentForKWh) {
                isValid = true;
                break;
            }
        }
        return isValid;
    }

     
    function getTxPaymentMCW(bytes32 _txPaymentForKWh) public view returns(bytes32) {
        bytes32 txMCW = 0;
        for (uint256 i = 0; i < getTxCount(); i++) {
            if (txRegistry[getTxAtIndex(i)].txPaymentKWh == _txPaymentForKWh) {
                txMCW = getTxAtIndex(i);
                break;
            }
        }
        return txMCW;
    }
}

 

 
contract McwCustomerRegistry is Ownable {
     
    mapping (address => address) private registry;

     
    address[] private customerIndex;

     
    event NewCustomer(address indexed customer, address indexed txRegistry);
    event NewCustomerTx(
        address indexed customer,
        bytes32 txPaymentForMCW,
        bytes32 txOrigMcwTransfer,
        uint256 amountMCW,
        uint256 amountKWh,
        uint256 timestamp
    );
    event SpendCustomerTx(address indexed customer, bytes32 txPaymentForMCW, bytes32 txPaymentForKWh, uint256 timestamp);

     
    constructor() public {}

     
    function addCustomerToRegistry(address _customer) public onlyOwner returns(bool) {
        require(
            _customer != address(0),
            "Parameter must be not empty."
        );
        require(
            registry[_customer] == address(0),
            "Customer is already in the registry."
        );

        address txRegistry = new TxRegistry(_customer);
        registry[_customer] = txRegistry;
        customerIndex.push(_customer);
        emit NewCustomer(_customer, txRegistry);
        return true;
    }

     
    function addTxToCustomerRegistry(
        address _customer,
        bytes32 _txOrigMcwTransfer,
        uint256 _amountMCW,
        uint256 _amountKWh
        ) public onlyOwner returns(bool)
    {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txOrigMcwTransfer != 0 && _amountMCW != 0 && _amountKWh != 0,
            "All parameters must be not empty."
        );

        uint256 timestamp = now;
        bytes32 txPaymentForMCW = keccak256(
            abi.encodePacked(
                _customer,
                _amountMCW,
                _amountKWh,
                timestamp)
            );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        require(
            txRegistry.getTxTimestampPaymentMCW(txPaymentForMCW) == 0,
            "Tx with such hash is already exist."
        );

        if (!txRegistry.addTxToRegistry(
            txPaymentForMCW,
            _txOrigMcwTransfer,
            _amountMCW,
            _amountKWh,
            timestamp))
            revert ("Something went wrong.");
        emit NewCustomerTx(
            _customer,
            txPaymentForMCW,
            _txOrigMcwTransfer,
            _amountMCW,
            _amountKWh,
            timestamp);
        return true;
    }

     
    function setCustomerTxAsSpent(address _customer, bytes32 _txPaymentForMCW) public onlyOwner returns(bool) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        require(
            txRegistry.getTxTimestampPaymentMCW(_txPaymentForMCW) != 0,
            "Tx with such hash doesn't exist."
        );
        require(
            txRegistry.getTxTimestampPaymentKWh(_txPaymentForMCW) == 0,
            "Tx with such hash is already spent."
        );

        uint256 timestamp = now;
        bytes32 txPaymentForKWh = keccak256(
            abi.encodePacked(
                _txPaymentForMCW,
                timestamp)
            );

        if (!txRegistry.setTxAsSpent(_txPaymentForMCW, txPaymentForKWh, timestamp))
            revert ("Something went wrong.");
        emit SpendCustomerTx(
            _customer,
            _txPaymentForMCW,
            txPaymentForKWh,
            timestamp);
        return true;
    }

     
    function getCustomerCount() public view returns(uint256) {
        return customerIndex.length;
    }

         
    function getCustomerAtIndex(uint256 _index) public view returns(address) {
        return customerIndex[_index];
    }

        
    function getCustomerTxRegistry(address _customer) public view returns(address) {
        return registry[_customer];
    }

        
    function isValidCustomer(address _customer) public view returns(bool) {
        require(
            _customer != address(0),
            "Parameter must be not empty."
        );

        bool isValid = false;
        address txRegistry = registry[_customer];
        if (txRegistry != address(0)) {
            isValid = true;
        }
        return isValid;
    }

     

        
    function getCustomerTxCount(address _customer) public view returns(uint256) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        uint256 txCount = txRegistry.getTxCount();
        return txCount;
    }

            
    function getCustomerTxAtIndex(address _customer, uint256 _index) public view returns(bytes32) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bytes32 txIndex = txRegistry.getTxAtIndex(_index);
        return txIndex;
    }

       
    function getCustomerTxOrigMcwTransfer(address _customer, bytes32 _txPaymentForMCW) public view returns(bytes32) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bytes32 txOrigMcwTransfer = txRegistry.getTxOrigMcwTransfer(_txPaymentForMCW);
        return txOrigMcwTransfer;
    }

       
    function getCustomerTxAmountMCW(address _customer, bytes32 _txPaymentForMCW) public view returns(uint256) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        uint256 amountMCW = txRegistry.getTxAmountMCW(_txPaymentForMCW);
        return amountMCW;
    }

       
    function getCustomerTxAmountKWh(address _customer, bytes32 _txPaymentForMCW) public view returns(uint256) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        uint256 amountKWh = txRegistry.getTxAmountKWh(_txPaymentForMCW);
        return amountKWh;
    }

       
    function getCustomerTxTimestampPaymentMCW(address _customer, bytes32 _txPaymentForMCW) public view returns(uint256) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        uint256 timestampPaymentMCW = txRegistry.getTxTimestampPaymentMCW(_txPaymentForMCW);
        return timestampPaymentMCW;
    }

       
    function getCustomerTxPaymentKWh(address _customer, bytes32 _txPaymentForMCW) public view returns(bytes32) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bytes32 txPaymentKWh = txRegistry.getTxPaymentKWh(_txPaymentForMCW);
        return txPaymentKWh;
    }

       
    function getCustomerTxTimestampPaymentKWh(address _customer, bytes32 _txPaymentForMCW) public view returns(uint256) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        uint256 timestampPaymentKWh = txRegistry.getTxTimestampPaymentKWh(_txPaymentForMCW);
        return timestampPaymentKWh;
    }

       
    function isValidCustomerTxPaymentForMCW(address _customer, bytes32 _txPaymentForMCW) public view returns(bool) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bool isValid = txRegistry.isValidTxPaymentForMCW(_txPaymentForMCW);
        return isValid;
    }

     
    function isSpentCustomerTxPaymentForMCW(address _customer, bytes32 _txPaymentForMCW) public view returns(bool) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForMCW != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bool isSpent = txRegistry.isSpentTxPaymentForMCW(_txPaymentForMCW);
        return isSpent;
    }

     
    function isValidCustomerTxPaymentForKWh(address _customer, bytes32 _txPaymentForKWh) public view returns(bool) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForKWh != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bool isValid = txRegistry.isValidTxPaymentForKWh(_txPaymentForKWh);
        return isValid;
    }

     
    function getCustomerTxPaymentMCW(address _customer, bytes32 _txPaymentForKWh) public view returns(bytes32) {
        require(
            isValidCustomer(_customer),
            "Customer is not in the registry."
        );
        require(
            _txPaymentForKWh != bytes32(0),
            "Parameter must be not empty."
        );

        TxRegistry txRegistry = TxRegistry(registry[_customer]);
        bytes32 txMCW = txRegistry.getTxPaymentMCW(_txPaymentForKWh);
        return txMCW;
    }
}