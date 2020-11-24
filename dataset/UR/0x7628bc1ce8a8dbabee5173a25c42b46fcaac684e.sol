 

pragma solidity ^0.4.23;


 
contract Version {
    string public semanticVersion;

     
     
    constructor(string _version) internal {
        semanticVersion = _version;
    }
}


 
contract Factory is Version {
    event FactoryAddedContract(address indexed _contract);

    modifier contractHasntDeployed(address _contract) {
        require(contracts[_contract] == false);
        _;
    }

    mapping(address => bool) public contracts;

    constructor(string _version) internal Version(_version) {}

    function hasBeenDeployed(address _contract) public constant returns (bool) {
        return contracts[_contract];
    }

    function addContract(address _contract)
        internal
        contractHasntDeployed(_contract)
        returns (bool)
    {
        contracts[_contract] = true;
        emit FactoryAddedContract(_contract);
        return true;
    }
}


contract PaymentAddress {
    event PaymentMade(address indexed _payer, address indexed _collector, uint256 _value);

    address public collector;

    constructor(address _collector) public {
        collector = _collector;
    }

    function () public payable {
        emit PaymentMade(msg.sender, collector, msg.value);
        collector.transfer(msg.value);
    }
}


contract PaymentAddressFactory is Factory {
     
    mapping (address => address[]) public paymentAddresses;

    constructor() public Factory("1.0.0") {}

     
    function newPaymentAddress(address _collector)
        public
        returns(address newContract)
    {
        PaymentAddress paymentAddress = new PaymentAddress(_collector);
        paymentAddresses[_collector].push(paymentAddress);
        addContract(paymentAddress);
        return paymentAddress;
    }
}