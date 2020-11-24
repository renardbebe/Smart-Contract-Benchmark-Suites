 

pragma solidity 0.4.25;
 
 
 
contract CloneFactory {

  event CloneCreated(address indexed target, address clone);

  function createClone(address target) internal returns (address result) {
    bytes memory clone = hex"3d602d80600a3d3981f3363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3";
    bytes20 targetBytes = bytes20(target);
    for (uint i = 0; i < 20; i++) {
      clone[20 + i] = targetBytes[i];
    }
    assembly {
      let len := mload(clone)
      let data := add(clone, 0x20)
      result := create(0, data, len)
    }
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

contract DeconetPaymentsSplitting {
    using SafeMath for uint;

     
    event DistributionCreated (
        address[] destinations,
        uint[] sharesMantissa,
        uint sharesExponent
    );

     
    event FundsOperation (
        address indexed senderOrAddressee,
        uint amount,
        FundsOperationType indexed operationType
    );

     
    enum FundsOperationType { Incoming, Outgoing }

     
    struct Distribution {
         
        address destination;

         
        uint mantissa;
    }

     
    uint public sharesExponent;

     
    Distribution[] public distributions;

     
    function () public payable {
        emit FundsOperation(msg.sender, msg.value, FundsOperationType.Incoming);
        distributeFunds();
    }

     
    function setUpDistribution(
        address[] _destinations,
        uint[] _sharesMantissa,
        uint _sharesExponent
    )
        external
    {
        require(distributions.length == 0, "Contract can only be initialized once");  
        require(_destinations.length <= 8 && _destinations.length > 0, "There is a maximum of 8 destinations allowed");   
         
         
        require(_sharesExponent <= 4, "The maximum allowed sharesExponent is 4");
         
        require(_destinations.length == _sharesMantissa.length, "Length of destinations does not match length of sharesMantissa");

        uint sum = 0;
        for (uint i = 0; i < _destinations.length; i++) {
             
            require(!isContract(_destinations[i]), "A contract may not be a destination address");
            sum = sum.add(_sharesMantissa[i]);
            distributions.push(Distribution(_destinations[i], _sharesMantissa[i]));
        }
          
        require(sum == 10**(_sharesExponent.add(2)), "The sum of all sharesMantissa should equal 10 ** ( _sharesExponent + 2 ) but it does not.");
        sharesExponent = _sharesExponent;
        emit DistributionCreated(_destinations, _sharesMantissa, _sharesExponent);
    }

     
    function distributeFunds() public {
        uint balance = address(this).balance;
        require(balance >= 10**(sharesExponent.add(2)), "You can not split up less wei than sum of all shares");
        for (uint i = 0; i < distributions.length; i++) {
            Distribution memory distribution = distributions[i];
            uint amount = calculatePayout(balance, distribution.mantissa, sharesExponent);
            distribution.destination.transfer(amount);
            emit FundsOperation(distribution.destination, amount, FundsOperationType.Outgoing);
        }
    }

     
    function distributionsLength() public view returns (uint256) {
        return distributions.length;
    }


     
    function calculatePayout(uint _fullAmount, uint _shareMantissa, uint _shareExponent) private pure returns(uint) {
        return (_fullAmount.div(10 ** (_shareExponent.add(2)))).mul(_shareMantissa);
    }

     
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}

contract DeconetPaymentsSplittingFactory is CloneFactory {

     
    address public libraryAddress;

     
    event PaymentsSplittingCreated(address newCloneAddress);

     
    constructor(address _libraryAddress) public {
        libraryAddress = _libraryAddress;
    }

     
    function createPaymentsSplitting(
        address[] _destinations,
        uint[] _sharesMantissa,
        uint _sharesExponent
    )
        external
        returns(address)
    {
        address clone = createClone(libraryAddress);
        DeconetPaymentsSplitting(clone).setUpDistribution(_destinations, _sharesMantissa, _sharesExponent);
        emit PaymentsSplittingCreated(clone);
        return clone;
    }
}