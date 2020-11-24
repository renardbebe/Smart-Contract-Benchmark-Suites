 

pragma solidity ^0.4.23;

 
library SafeMathUint96 {
  function mul(uint96 a, uint96 b) internal pure returns (uint96) {
    uint96 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint96 a, uint96 b) internal pure returns (uint96) {
     
    uint96 c = a / b;
     
    return c;
  }

  function sub(uint96 a, uint96 b) internal pure returns (uint96) {
    assert(b <= a);
    return a - b;
  }

  function add(uint96 a, uint96 b) internal pure returns (uint96) {
    uint96 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
library SafeMathUint8 {
  function mul(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint8 a, uint8 b) internal pure returns (uint8) {
     
    uint8 c = a / b;
     
    return c;
  }

  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    assert(b <= a);
    return a - b;
  }

  function add(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a + b;
    assert(c >= a);
    return c;
  }
}


 
library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {
     
     
    assert(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

    int256 c = a * b;
    assert((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
     
     
    assert(!(a == - 2**255 && b == -1));

     
    int256 c = a / b;
     
    return c;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    assert((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    assert((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    assert(a>=0);
    return uint256(a);
  }
}

 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;

    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    assert(b >= 0);
    return b;
  }
}


 
library Bytes {
     
    function extractAddress(bytes data, uint offset)
        internal
        pure
        returns (address m) 
    {
        require(offset >= 0 && offset + 20 <= data.length, "offset value should be in the correct range");

         
        assembly {
            m := and(
                mload(add(data, add(20, offset))), 
                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            )
        }
    }

     
    function extractBytes32(bytes data, uint offset)
        internal
        pure
        returns (bytes32 bs)
    {
        require(offset >= 0 && offset + 32 <= data.length, "offset value should be in the correct range");

         
        assembly {
            bs := mload(add(data, add(32, offset)))
        }
    }

     
    function updateBytes20inBytes(bytes data, uint offset, bytes20 b)
        internal
        pure
    {
        require(offset >= 0 && offset + 20 <= data.length, "offset value should be in the correct range");

         
        assembly {
            let m := mload(add(data, add(20, offset)))
            m := and(m, 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000)
            m := or(m, div(b, 0x1000000000000000000000000))
            mstore(add(data, add(20, offset)), m)
        }
    }

      
    function extractString(bytes data, uint8 size, uint _offset) 
        internal 
        pure 
        returns (string) 
    {
        bytes memory bytesString = new bytes(size);
        for (uint j = 0; j < size; j++) {
            bytesString[j] = data[_offset+j];
        }
        return string(bytesString);
    }
}

 
library Signature {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using SafeMathUint8 for uint8;

     	
    function checkRequestSignature(
        bytes 		requestData,
        address[] 	payeesPaymentAddress,
        uint256 	expirationDate,
        bytes 		signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = getRequestHash(requestData, payeesPaymentAddress, expirationDate);

         
        uint8 v = uint8(signature[64]);
        v = v < 27 ? v.add(27) : v;
        bytes32 r = Bytes.extractBytes32(signature, 0);
        bytes32 s = Bytes.extractBytes32(signature, 32);

         
        return isValidSignature(
            Bytes.extractAddress(requestData, 0),
            hash,
            v,
            r,
            s
        );
    }

     	
    function checkBtcRequestSignature(
        bytes 		requestData,
        bytes 	    payeesPaymentAddress,
        uint256 	expirationDate,
        bytes 		signature)
        internal
        view
        returns (bool)
    {
        bytes32 hash = getBtcRequestHash(requestData, payeesPaymentAddress, expirationDate);

         
        uint8 v = uint8(signature[64]);
        v = v < 27 ? v.add(27) : v;
        bytes32 r = Bytes.extractBytes32(signature, 0);
        bytes32 s = Bytes.extractBytes32(signature, 32);

         
        return isValidSignature(
            Bytes.extractAddress(requestData, 0),
            hash,
            v,
            r,
            s
        );
    }
    
     
    function getBtcRequestHash(
        bytes 		requestData,
        bytes 	payeesPaymentAddress,
        uint256 	expirationDate)
        private
        view
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                this,
                requestData,
                payeesPaymentAddress,
                expirationDate
            )
        );
    }

     
    function getRequestHash(
        bytes 		requestData,
        address[] 	payeesPaymentAddress,
        uint256 	expirationDate)
        private
        view
        returns(bytes32)
    {
        return keccak256(
            abi.encodePacked(
                this,
                requestData,
                payeesPaymentAddress,
                expirationDate
            )
        );
    }
    
     
    function isValidSignature(
        address signer,
        bytes32 hash,
        uint8 	v,
        bytes32 r,
        bytes32 s)
        private
        pure
        returns (bool)
    {
        return signer == ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
            v,
            r,
            s
        );
    }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract FeeCollector is Ownable {
    using SafeMath for uint256;

    uint256 public rateFeesNumerator;
    uint256 public rateFeesDenominator;
    uint256 public maxFees;

     
    address public requestBurnerContract;

    event UpdateRateFees(uint256 rateFeesNumerator, uint256 rateFeesDenominator);
    event UpdateMaxFees(uint256 maxFees);

       
    constructor(address _requestBurnerContract) 
        public
    {
        requestBurnerContract = _requestBurnerContract;
    }

       
    function setRateFees(uint256 _rateFeesNumerator, uint256 _rateFeesDenominator)
        external
        onlyOwner
    {
        rateFeesNumerator = _rateFeesNumerator;
        rateFeesDenominator = _rateFeesDenominator;
        emit UpdateRateFees(rateFeesNumerator, rateFeesDenominator);
    }

       
    function setMaxCollectable(uint256 _newMaxFees) 
        external
        onlyOwner
    {
        maxFees = _newMaxFees;
        emit UpdateMaxFees(maxFees);
    }

       
    function setRequestBurnerContract(address _requestBurnerContract) 
        external
        onlyOwner
    {
        requestBurnerContract = _requestBurnerContract;
    }

       
    function collectEstimation(int256 _expectedAmount)
        public
        view
        returns(uint256)
    {
        if (_expectedAmount<0) {
            return 0;
        }

        uint256 computedCollect = uint256(_expectedAmount).mul(rateFeesNumerator);

        if (rateFeesDenominator != 0) {
            computedCollect = computedCollect.div(rateFeesDenominator);
        }

        return computedCollect < maxFees ? computedCollect : maxFees;
    }

       
    function collectForREQBurning(uint256 _amount)
        internal
    {
         
        requestBurnerContract.transfer(_amount);
    }
}






 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}



 
contract Administrable is Pausable {

     
    mapping(address => uint8) public trustedCurrencyContracts;

     
    event NewTrustedContract(address newContract);
    event RemoveTrustedContract(address oldContract);

     
    function adminAddTrustedCurrencyContract(address _newContractAddress)
        external
        onlyOwner
    {
        trustedCurrencyContracts[_newContractAddress] = 1;  
        emit NewTrustedContract(_newContractAddress);
    }

     
    function adminRemoveTrustedCurrencyContract(address _oldTrustedContractAddress)
        external
        onlyOwner
    {
        require(trustedCurrencyContracts[_oldTrustedContractAddress] != 0, "_oldTrustedContractAddress should not be 0");
        trustedCurrencyContracts[_oldTrustedContractAddress] = 0;
        emit RemoveTrustedContract(_oldTrustedContractAddress);
    }

     
    function getStatusContract(address _contractAddress)
        external
        view
        returns(uint8) 
    {
        return trustedCurrencyContracts[_contractAddress];
    }

     
    function isTrustedContract(address _contractAddress)
        public
        view
        returns(bool)
    {
        return trustedCurrencyContracts[_contractAddress] == 1;
    }
}


 
contract RequestCore is Administrable {
    using SafeMath for uint256;
    using SafeMathUint96 for uint96;
    using SafeMathInt for int256;
    using SafeMathUint8 for uint8;

    enum State { Created, Accepted, Canceled }

    struct Request {
         
        address payer;

         
        address currencyContract;

         
        State state;

         
        Payee payee;
    }

     
     
    struct Payee {
         
        address addr;

         
         
        int256 expectedAmount;

         
        int256 balance;
    }

     
     
     
    uint96 public numRequests; 
    
     
     
     
    mapping(bytes32 => Request) requests;

     
     
    mapping(bytes32 => Payee[256]) public subPayees;

     
    event Created(bytes32 indexed requestId, address indexed payee, address indexed payer, address creator, string data);
    event Accepted(bytes32 indexed requestId);
    event Canceled(bytes32 indexed requestId);

     
     
    event NewSubPayee(bytes32 indexed requestId, address indexed payee); 
    event UpdateExpectedAmount(bytes32 indexed requestId, uint8 payeeIndex, int256 deltaAmount);
    event UpdateBalance(bytes32 indexed requestId, uint8 payeeIndex, int256 deltaAmount);

     
    function createRequest(
        address     _creator,
        address[]   _payees,
        int256[]    _expectedAmounts,
        address     _payer,
        string      _data)
        external
        whenNotPaused 
        returns (bytes32 requestId) 
    {
         
        require(_creator != 0, "creator should not be 0");  
         
        require(isTrustedContract(msg.sender), "caller should be a trusted contract");  

         
        requestId = generateRequestId();

        address mainPayee;
        int256 mainExpectedAmount;
         
        if (_payees.length!=0) {
            mainPayee = _payees[0];
            mainExpectedAmount = _expectedAmounts[0];
        }

         
        requests[requestId] = Request(
            _payer,
            msg.sender,
            State.Created,
            Payee(
                mainPayee,
                mainExpectedAmount,
                0
            )
        );

         
        emit Created(
            requestId,
            mainPayee,
            _payer,
            _creator,
            _data
        );
        
         
        initSubPayees(requestId, _payees, _expectedAmounts);

        return requestId;
    }

      
    function createRequestFromBytes(bytes _data) 
        external
        whenNotPaused 
        returns (bytes32 requestId) 
    {
         
        require(isTrustedContract(msg.sender), "caller should be a trusted contract");  

         
        address creator = extractAddress(_data, 0);

        address payer = extractAddress(_data, 20);

         
        require(creator!=0, "creator should not be 0");
        
         
        uint8 payeesCount = uint8(_data[40]);

         
         
        uint256 offsetDataSize = uint256(payeesCount).mul(52).add(41);

         
        uint8 dataSize = uint8(_data[offsetDataSize]);
        string memory dataStr = extractString(_data, dataSize, offsetDataSize.add(1));

        address mainPayee;
        int256 mainExpectedAmount;
         
        if (payeesCount!=0) {
            mainPayee = extractAddress(_data, 41);
            mainExpectedAmount = int256(extractBytes32(_data, 61));
        }

         
        requestId = generateRequestId();

         
        requests[requestId] = Request(
            payer,
            msg.sender,
            State.Created,
            Payee(
                mainPayee,
                mainExpectedAmount,
                0
            )
        );

         
        emit Created(
            requestId,
            mainPayee,
            payer,
            creator,
            dataStr
        );

         
        for (uint8 i = 1; i < payeesCount; i = i.add(1)) {
            address subPayeeAddress = extractAddress(_data, uint256(i).mul(52).add(41));

             
            require(subPayeeAddress != 0, "subpayee should not be 0");

            subPayees[requestId][i-1] = Payee(subPayeeAddress, int256(extractBytes32(_data, uint256(i).mul(52).add(61))), 0);
            emit NewSubPayee(requestId, subPayeeAddress);
        }

        return requestId;
    }

      
    function accept(bytes32 _requestId) 
        external
    {
        Request storage r = requests[_requestId];
        require(r.currencyContract == msg.sender, "caller should be the currency contract of the request"); 
        r.state = State.Accepted;
        emit Accepted(_requestId);
    }

      
    function cancel(bytes32 _requestId)
        external
    {
        Request storage r = requests[_requestId];
        require(r.currencyContract == msg.sender, "caller should be the currency contract of the request"); 
        r.state = State.Canceled;
        emit Canceled(_requestId);
    }   

      
    function updateBalance(bytes32 _requestId, uint8 _payeeIndex, int256 _deltaAmount)
        external
    {   
        Request storage r = requests[_requestId];
        require(r.currencyContract == msg.sender, "caller should be the currency contract of the request"); 

        if ( _payeeIndex == 0 ) {
             
            r.payee.balance = r.payee.balance.add(_deltaAmount);
        } else {
             
            Payee storage sp = subPayees[_requestId][_payeeIndex-1];
            sp.balance = sp.balance.add(_deltaAmount);
        }
        emit UpdateBalance(_requestId, _payeeIndex, _deltaAmount);
    }

      
    function updateExpectedAmount(bytes32 _requestId, uint8 _payeeIndex, int256 _deltaAmount)
        external
    {   
        Request storage r = requests[_requestId];
        require(r.currencyContract == msg.sender, "caller should be the currency contract of the request");  

        if ( _payeeIndex == 0 ) {
             
            r.payee.expectedAmount = r.payee.expectedAmount.add(_deltaAmount);    
        } else {
             
            Payee storage sp = subPayees[_requestId][_payeeIndex-1];
            sp.expectedAmount = sp.expectedAmount.add(_deltaAmount);
        }
        emit UpdateExpectedAmount(_requestId, _payeeIndex, _deltaAmount);
    }

      
    function getRequest(bytes32 _requestId) 
        external
        view
        returns(address payer, address currencyContract, State state, address payeeAddr, int256 payeeExpectedAmount, int256 payeeBalance)
    {
        Request storage r = requests[_requestId];
        return (
            r.payer,
            r.currencyContract,
            r.state,
            r.payee.addr,
            r.payee.expectedAmount,
            r.payee.balance
        );
    }

      
    function getPayeeAddress(bytes32 _requestId, uint8 _payeeIndex)
        public
        view
        returns(address)
    {
        if (_payeeIndex == 0) {
            return requests[_requestId].payee.addr;
        } else {
            return subPayees[_requestId][_payeeIndex-1].addr;
        }
    }

      
    function getPayer(bytes32 _requestId)
        public
        view
        returns(address)
    {
        return requests[_requestId].payer;
    }

          
    function getPayeeExpectedAmount(bytes32 _requestId, uint8 _payeeIndex)
        public
        view
        returns(int256)
    {
        if (_payeeIndex == 0) {
            return requests[_requestId].payee.expectedAmount;
        } else {
            return subPayees[_requestId][_payeeIndex-1].expectedAmount;
        }
    }

          
    function getSubPayeesCount(bytes32 _requestId)
        public
        view
        returns(uint8)
    {
         
        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1)) {}
        return i;
    }

     
    function getCurrencyContract(bytes32 _requestId)
        public
        view
        returns(address)
    {
        return requests[_requestId].currencyContract;
    }

          
    function getPayeeBalance(bytes32 _requestId, uint8 _payeeIndex)
        public
        view
        returns(int256)
    {
        if (_payeeIndex == 0) {
            return requests[_requestId].payee.balance;    
        } else {
            return subPayees[_requestId][_payeeIndex-1].balance;
        }
    }

          
    function getBalance(bytes32 _requestId)
        public
        view
        returns(int256)
    {
        int256 balance = requests[_requestId].payee.balance;

        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1)) {
            balance = balance.add(subPayees[_requestId][i].balance);
        }

        return balance;
    }

          
    function areAllBalanceNull(bytes32 _requestId)
        public
        view
        returns(bool isNull)
    {
        isNull = requests[_requestId].payee.balance == 0;

        for (uint8 i = 0; isNull && subPayees[_requestId][i].addr != address(0); i = i.add(1)) {
            isNull = subPayees[_requestId][i].balance == 0;
        }

        return isNull;
    }

          
    function getExpectedAmount(bytes32 _requestId)
        public
        view
        returns(int256)
    {
        int256 expectedAmount = requests[_requestId].payee.expectedAmount;

        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1)) {
            expectedAmount = expectedAmount.add(subPayees[_requestId][i].expectedAmount);
        }

        return expectedAmount;
    }

      
    function getState(bytes32 _requestId)
        public
        view
        returns(State)
    {
        return requests[_requestId].state;
    }

     
    function getPayeeIndex(bytes32 _requestId, address _address)
        public
        view
        returns(int16)
    {
         
        if (requests[_requestId].payee.addr == _address) {
            return 0;
        }

        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1)) {
            if (subPayees[_requestId][i].addr == _address) {
                 
                return i+1;
            }
        }
        return -1;
    }

     
    function extractBytes32(bytes _data, uint offset)
        public
        pure
        returns (bytes32 bs)
    {
        require(offset >= 0 && offset + 32 <= _data.length, "offset value should be in the correct range");

         
        assembly {
            bs := mload(add(_data, add(32, offset)))
        }
    }

     
    function emergencyERC20Drain(ERC20 token, uint amount )
        public
        onlyOwner 
    {
        token.transfer(owner, amount);
    }

     
    function extractAddress(bytes _data, uint offset)
        internal
        pure
        returns (address m)
    {
        require(offset >= 0 && offset + 20 <= _data.length, "offset value should be in the correct range");

         
        assembly {
            m := and( mload(add(_data, add(20, offset))), 
                      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }
    
      
    function initSubPayees(bytes32 _requestId, address[] _payees, int256[] _expectedAmounts)
        internal
    {
        require(_payees.length == _expectedAmounts.length, "payee length should equal expected amount length");
     
        for (uint8 i = 1; i < _payees.length; i = i.add(1)) {
             
            require(_payees[i] != 0, "payee should not be 0");
            subPayees[_requestId][i-1] = Payee(_payees[i], _expectedAmounts[i], 0);
            emit NewSubPayee(_requestId, _payees[i]);
        }
    }

      
    function extractString(bytes data, uint8 size, uint _offset) 
        internal 
        pure 
        returns (string) 
    {
        bytes memory bytesString = new bytes(size);
        for (uint j = 0; j < size; j++) {
            bytesString[j] = data[_offset+j];
        }
        return string(bytesString);
    }

      
    function generateRequestId()
        internal
        returns (bytes32)
    {
         
        numRequests = numRequests.add(1);
         
        return bytes32((uint256(this) << 96).add(numRequests));
    }
}


 
contract CurrencyContract is Pausable, FeeCollector {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using SafeMathUint8 for uint8;

    RequestCore public requestCore;

     
    constructor(address _requestCoreAddress, address _addressBurner) 
        FeeCollector(_addressBurner)
        public
    {
        requestCore = RequestCore(_requestCoreAddress);
    }

     
    function acceptAction(bytes32 _requestId)
        public
        whenNotPaused
        onlyRequestPayer(_requestId)
    {
         
        require(requestCore.getState(_requestId) == RequestCore.State.Created, "request should be created");

         
        requestCore.accept(_requestId);
    }

     
    function cancelAction(bytes32 _requestId)
        public
        whenNotPaused
    {
         
         
        require(
             
            (requestCore.getPayer(_requestId) == msg.sender && requestCore.getState(_requestId) == RequestCore.State.Created) ||
            (requestCore.getPayeeAddress(_requestId,0) == msg.sender && requestCore.getState(_requestId) != RequestCore.State.Canceled),
            "payer should cancel a newly created request, or payee should cancel a not cancel request"
        );

         
        require(requestCore.areAllBalanceNull(_requestId), "all balanaces should be = 0 to cancel");

         
        requestCore.cancel(_requestId);
    }

     
    function additionalAction(bytes32 _requestId, uint256[] _additionalAmounts)
        public
        whenNotPaused
        onlyRequestPayer(_requestId)
    {

         
        require(requestCore.getState(_requestId) != RequestCore.State.Canceled, "request should not be canceled");

         
        require(
            _additionalAmounts.length <= requestCore.getSubPayeesCount(_requestId).add(1),
            "number of amounts should be <= number of payees"
        );

        for (uint8 i = 0; i < _additionalAmounts.length; i = i.add(1)) {
             
            if (_additionalAmounts[i] != 0) {
                 
                requestCore.updateExpectedAmount(_requestId, i, _additionalAmounts[i].toInt256Safe());
            }
        }
    }

     
    function subtractAction(bytes32 _requestId, uint256[] _subtractAmounts)
        public
        whenNotPaused
        onlyRequestPayee(_requestId)
    {
         
        require(requestCore.getState(_requestId) != RequestCore.State.Canceled, "request should not be canceled");

         
        require(
            _subtractAmounts.length <= requestCore.getSubPayeesCount(_requestId).add(1),
            "number of amounts should be <= number of payees"
        );

        for (uint8 i = 0; i < _subtractAmounts.length; i = i.add(1)) {
             
            if (_subtractAmounts[i] != 0) {
                 
                require(
                    requestCore.getPayeeExpectedAmount(_requestId,i) >= _subtractAmounts[i].toInt256Safe(),
                    "subtract should equal or be lower than amount expected"
                );

                 
                requestCore.updateExpectedAmount(_requestId, i, -_subtractAmounts[i].toInt256Safe());
            }
        }
    }

     
    function createCoreRequestInternal(
        address 	_payer,
        address[] 	_payeesIdAddress,
        int256[] 	_expectedAmounts,
        string 		_data)
        internal
        whenNotPaused
        returns(bytes32 requestId, uint256 collectedFees)
    {
        int256 totalExpectedAmounts = 0;
        for (uint8 i = 0; i < _expectedAmounts.length; i = i.add(1)) {
             
            require(_expectedAmounts[i] >= 0, "expected amounts should be positive");

             
            totalExpectedAmounts = totalExpectedAmounts.add(_expectedAmounts[i]);
        }

         
        requestId = requestCore.createRequest(
            msg.sender,
            _payeesIdAddress,
            _expectedAmounts,
            _payer,
            _data
        );

         
        collectedFees = collectEstimation(totalExpectedAmounts);
        collectForREQBurning(collectedFees);
    }

     	
    modifier onlyRequestPayee(bytes32 _requestId)
    {
        require(requestCore.getPayeeAddress(_requestId, 0) == msg.sender, "only the payee should do this action");
        _;
    }

     	
    modifier onlyRequestPayer(bytes32 _requestId)
    {
        require(requestCore.getPayer(_requestId) == msg.sender, "only the payer should do this action");
        _;
    }
}


 
contract RequestERC20 is CurrencyContract {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using SafeMathUint8 for uint8;

     
    mapping(bytes32 => address[256]) public payeesPaymentAddress;
    mapping(bytes32 => address) public payerRefundAddress;

     
    ERC20 public erc20Token;

     
    constructor (address _requestCoreAddress, address _requestBurnerAddress, ERC20 _erc20Token) 
        CurrencyContract(_requestCoreAddress, _requestBurnerAddress)
        public
    {
        erc20Token = _erc20Token;
    }

     
    function createRequestAsPayeeAction(
        address[] 	_payeesIdAddress,
        address[] 	_payeesPaymentAddress,
        int256[] 	_expectedAmounts,
        address 	_payer,
        address 	_payerRefundAddress,
        string 		_data)
        external
        payable
        whenNotPaused
        returns(bytes32 requestId)
    {
        require(
            msg.sender == _payeesIdAddress[0] && msg.sender != _payer && _payer != 0,
            "caller should be the payee"
        );

        uint256 collectedFees;
        (requestId, collectedFees) = createCoreRequestInternal(
            _payer,
            _payeesIdAddress,
            _expectedAmounts,
            _data
        );
        
         
        require(collectedFees == msg.value, "fees should be the correct amout");

         
        for (uint8 j = 0; j < _payeesPaymentAddress.length; j = j.add(1)) {
            payeesPaymentAddress[requestId][j] = _payeesPaymentAddress[j];
        }
         
        if (_payerRefundAddress != 0) {
            payerRefundAddress[requestId] = _payerRefundAddress;
        }

        return requestId;
    }

     
    function broadcastSignedRequestAsPayerAction(
        bytes 		_requestData,  
        address[] 	_payeesPaymentAddress,
        uint256[] 	_payeeAmounts,
        uint256[] 	_additionals,
        uint256 	_expirationDate,
        bytes 		_signature)
        external
        payable
        whenNotPaused
        returns(bytes32 requestId)
    {
         
         
        require(_expirationDate >= block.timestamp, "expiration should be after current time");

         
        require(
            Signature.checkRequestSignature(
                _requestData,
                _payeesPaymentAddress,
                _expirationDate,
                _signature
            ),
            "signature should be correct"
        );

        return createAcceptAndPayFromBytes(
            _requestData,
            _payeesPaymentAddress,
            _payeeAmounts,
            _additionals
        );
    }

     
    function paymentAction(
        bytes32 _requestId,
        uint256[] _payeeAmounts,
        uint256[] _additionalAmounts)
        external
        whenNotPaused
    {
         
        if (requestCore.getState(_requestId)==RequestCore.State.Created && msg.sender == requestCore.getPayer(_requestId)) {
            acceptAction(_requestId);
        }

        if (_additionalAmounts.length != 0) {
            additionalAction(_requestId, _additionalAmounts);
        }

        paymentInternal(_requestId, _payeeAmounts);
    }

     
    function refundAction(bytes32 _requestId, uint256 _amountToRefund)
        external
        whenNotPaused
    {
        refundInternal(_requestId, msg.sender, _amountToRefund);
    }

     
    function createRequestAsPayerAction(
        address[] 	_payeesIdAddress,
        int256[] 	_expectedAmounts,
        address 	_payerRefundAddress,
        uint256[] 	_payeeAmounts,
        uint256[] 	_additionals,
        string 		_data)
        public
        payable
        whenNotPaused
        returns(bytes32 requestId)
    {
        require(msg.sender != _payeesIdAddress[0] && _payeesIdAddress[0] != 0, "caller should not be the main payee");

        uint256 collectedFees;
        (requestId, collectedFees) = createCoreRequestInternal(
            msg.sender,
            _payeesIdAddress,
            _expectedAmounts,
            _data
        );

         
        require(collectedFees == msg.value, "fees should be the correct amout");

         
        if (_payerRefundAddress != 0) {
            payerRefundAddress[requestId] = _payerRefundAddress;
        }
        
         
         
        int256 totalExpectedAmounts = 0;
        for (uint8 i = 0; i < _expectedAmounts.length; i = i.add(1)) {
            totalExpectedAmounts = totalExpectedAmounts.add(_expectedAmounts[i]);
        }

         
        acceptAndPay(
            requestId,
            _payeeAmounts,
            _additionals,
            totalExpectedAmounts
        );

        return requestId;
    }

     
    function createAcceptAndPayFromBytes(
        bytes 		_requestData,
        address[] 	_payeesPaymentAddress,
        uint256[] 	_payeeAmounts,
        uint256[] 	_additionals)
        internal
        returns(bytes32 requestId)
    {
         
        address mainPayee = Bytes.extractAddress(_requestData, 41);
        require(msg.sender != mainPayee && mainPayee != 0, "caller should not be the main payee");

         
        require(Bytes.extractAddress(_requestData, 0) == mainPayee, "creator should be the main payee");

         
        uint8 payeesCount = uint8(_requestData[40]);
        int256 totalExpectedAmounts = 0;
        for (uint8 i = 0; i < payeesCount; i++) {
             
            int256 expectedAmountTemp = int256(Bytes.extractBytes32(_requestData, uint256(i).mul(52).add(61)));
            
             
            totalExpectedAmounts = totalExpectedAmounts.add(expectedAmountTemp);
            
             
            require(expectedAmountTemp > 0, "expected amount should be > 0");
        }

         
        uint256 fees = collectEstimation(totalExpectedAmounts);
        require(fees == msg.value, "fees should be the correct amout");
        collectForREQBurning(fees);

         
        Bytes.updateBytes20inBytes(_requestData, 20, bytes20(msg.sender));
         
        requestId = requestCore.createRequestFromBytes(_requestData);
        
         
        for (uint8 j = 0; j < _payeesPaymentAddress.length; j = j.add(1)) {
            payeesPaymentAddress[requestId][j] = _payeesPaymentAddress[j];
        }

         
        acceptAndPay(
            requestId,
            _payeeAmounts,
            _additionals,
            totalExpectedAmounts
        );

        return requestId;
    }

     
    function paymentInternal(
        bytes32 	_requestId,
        uint256[] 	_payeeAmounts)
        internal
    {
        require(requestCore.getState(_requestId) != RequestCore.State.Canceled, "request should not be canceled");

         
        require(
            _payeeAmounts.length <= requestCore.getSubPayeesCount(_requestId).add(1),
            "number of amounts should be <= number of payees"
        );

        for (uint8 i = 0; i < _payeeAmounts.length; i = i.add(1)) {
            if (_payeeAmounts[i] != 0) {
                 
                requestCore.updateBalance(_requestId, i, _payeeAmounts[i].toInt256Safe());

                 
                address addressToPay;
                if (payeesPaymentAddress[_requestId][i] == 0) {
                    addressToPay = requestCore.getPayeeAddress(_requestId, i);
                } else {
                    addressToPay = payeesPaymentAddress[_requestId][i];
                }

                 
                fundOrderInternal(msg.sender, addressToPay, _payeeAmounts[i]);
            }
        }
    }

     	
    function acceptAndPay(
        bytes32 _requestId,
        uint256[] _payeeAmounts,
        uint256[] _additionals,
        int256 _payeeAmountsSum)
        internal
    {
        acceptAction(_requestId);
        
        additionalAction(_requestId, _additionals);

        if (_payeeAmountsSum > 0) {
            paymentInternal(_requestId, _payeeAmounts);
        }
    }

     
    function refundInternal(
        bytes32 _requestId,
        address _address,
        uint256 _amount)
        internal
    {
        require(requestCore.getState(_requestId) != RequestCore.State.Canceled, "request should not be canceled");

         
        int16 payeeIndex = requestCore.getPayeeIndex(_requestId, _address);

         
        uint8 payeesCount = requestCore.getSubPayeesCount(_requestId).add(1);

        if (payeeIndex < 0) {
             
            for (uint8 i = 0; i < payeesCount && payeeIndex == -1; i = i.add(1)) {
                if (payeesPaymentAddress[_requestId][i] == _address) {
                     
                    payeeIndex = int16(i);
                }
            }
        }
         
        require(payeeIndex >= 0, "fromAddress should be a payee"); 

         
        requestCore.updateBalance(_requestId, uint8(payeeIndex), -_amount.toInt256Safe());

         
        address addressToPay = payerRefundAddress[_requestId];
        if (addressToPay == 0) {
            addressToPay = requestCore.getPayer(_requestId);
        }

         
        fundOrderInternal(_address, addressToPay, _amount);
    }

     
    function fundOrderInternal(
        address _from,
        address _recipient,
        uint256 _amount)
        internal
    {	
        require(erc20Token.transferFrom(_from, _recipient, _amount), "erc20 transfer should succeed");
    }
}