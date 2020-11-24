 

pragma solidity 0.4.18;

 
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


 
contract Administrable is Pausable {

     
    mapping(address => uint8) public trustedCurrencyContracts;

     
    event NewTrustedContract(address newContract);
    event RemoveTrustedContract(address oldContract);

     
    function adminAddTrustedCurrencyContract(address _newContractAddress)
        external
        onlyOwner
    {
        trustedCurrencyContracts[_newContractAddress] = 1;  
        NewTrustedContract(_newContractAddress);
    }

     
    function adminRemoveTrustedCurrencyContract(address _oldTrustedContractAddress)
        external
        onlyOwner
    {
        require(trustedCurrencyContracts[_oldTrustedContractAddress] != 0);
        trustedCurrencyContracts[_oldTrustedContractAddress] = 0;
        RemoveTrustedContract(_oldTrustedContractAddress);
    }

     
    function getStatusContract(address _contractAddress)
        view
        external
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
         
        require(_creator!=0);  
         
        require(isTrustedContract(msg.sender));  

         
        requestId = generateRequestId();

        address mainPayee;
        int256 mainExpectedAmount;
         
        if(_payees.length!=0) {
            mainPayee = _payees[0];
            mainExpectedAmount = _expectedAmounts[0];
        }

         
        requests[requestId] = Request(_payer, msg.sender, State.Created, Payee(mainPayee, mainExpectedAmount, 0));

         
        Created(requestId, mainPayee, _payer, _creator, _data);
        
         
        initSubPayees(requestId, _payees, _expectedAmounts);

        return requestId;
    }

      
    function createRequestFromBytes(bytes _data) 
        external
        whenNotPaused 
        returns (bytes32 requestId) 
    {
         
        require(isTrustedContract(msg.sender));  

         
        address creator = extractAddress(_data, 0);

        address payer = extractAddress(_data, 20);

         
        require(creator!=0);
        
         
        uint8 payeesCount = uint8(_data[40]);

         
         
        uint256 offsetDataSize = uint256(payeesCount).mul(52).add(41);

         
        uint8 dataSize = uint8(_data[offsetDataSize]);
        string memory dataStr = extractString(_data, dataSize, offsetDataSize.add(1));

        address mainPayee;
        int256 mainExpectedAmount;
         
        if(payeesCount!=0) {
            mainPayee = extractAddress(_data, 41);
            mainExpectedAmount = int256(extractBytes32(_data, 61));
        }

         
        requestId = generateRequestId();

         
        requests[requestId] = Request(payer, msg.sender, State.Created, Payee(mainPayee, mainExpectedAmount, 0));

         
        Created(requestId, mainPayee, payer, creator, dataStr);

         
        for(uint8 i = 1; i < payeesCount; i = i.add(1)) {
            address subPayeeAddress = extractAddress(_data, uint256(i).mul(52).add(41));

             
            require(subPayeeAddress != 0);

            subPayees[requestId][i-1] =  Payee(subPayeeAddress, int256(extractBytes32(_data, uint256(i).mul(52).add(61))), 0);
            NewSubPayee(requestId, subPayeeAddress);
        }

        return requestId;
    }

      
    function accept(bytes32 _requestId) 
        external
    {
        Request storage r = requests[_requestId];
        require(r.currencyContract==msg.sender); 
        r.state = State.Accepted;
        Accepted(_requestId);
    }

      
    function cancel(bytes32 _requestId)
        external
    {
        Request storage r = requests[_requestId];
        require(r.currencyContract==msg.sender);
        r.state = State.Canceled;
        Canceled(_requestId);
    }   

      
    function updateBalance(bytes32 _requestId, uint8 _payeeIndex, int256 _deltaAmount)
        external
    {   
        Request storage r = requests[_requestId];
        require(r.currencyContract==msg.sender);

        if( _payeeIndex == 0 ) {
             
            r.payee.balance = r.payee.balance.add(_deltaAmount);
        } else {
             
            Payee storage sp = subPayees[_requestId][_payeeIndex-1];
            sp.balance = sp.balance.add(_deltaAmount);
        }
        UpdateBalance(_requestId, _payeeIndex, _deltaAmount);
    }

      
    function updateExpectedAmount(bytes32 _requestId, uint8 _payeeIndex, int256 _deltaAmount)
        external
    {   
        Request storage r = requests[_requestId];
        require(r.currencyContract==msg.sender); 

        if( _payeeIndex == 0 ) {
             
            r.payee.expectedAmount = r.payee.expectedAmount.add(_deltaAmount);    
        } else {
             
            Payee storage sp = subPayees[_requestId][_payeeIndex-1];
            sp.expectedAmount = sp.expectedAmount.add(_deltaAmount);
        }
        UpdateExpectedAmount(_requestId, _payeeIndex, _deltaAmount);
    }

      
    function initSubPayees(bytes32 _requestId, address[] _payees, int256[] _expectedAmounts)
        internal
    {
        require(_payees.length == _expectedAmounts.length);
     
        for (uint8 i = 1; i < _payees.length; i = i.add(1))
        {
             
            require(_payees[i] != 0);
            subPayees[_requestId][i-1] = Payee(_payees[i], _expectedAmounts[i], 0);
            NewSubPayee(_requestId, _payees[i]);
        }
    }


     
      
    function getPayeeAddress(bytes32 _requestId, uint8 _payeeIndex)
        public
        constant
        returns(address)
    {
        if(_payeeIndex == 0) {
            return requests[_requestId].payee.addr;
        } else {
            return subPayees[_requestId][_payeeIndex-1].addr;
        }
    }

      
    function getPayer(bytes32 _requestId)
        public
        constant
        returns(address)
    {
        return requests[_requestId].payer;
    }

          
    function getPayeeExpectedAmount(bytes32 _requestId, uint8 _payeeIndex)
        public
        constant
        returns(int256)
    {
        if(_payeeIndex == 0) {
            return requests[_requestId].payee.expectedAmount;
        } else {
            return subPayees[_requestId][_payeeIndex-1].expectedAmount;
        }
    }

          
    function getSubPayeesCount(bytes32 _requestId)
        public
        constant
        returns(uint8)
    {
        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1)) {
             
        }
        return i;
    }

     
    function getCurrencyContract(bytes32 _requestId)
        public
        constant
        returns(address)
    {
        return requests[_requestId].currencyContract;
    }

          
    function getPayeeBalance(bytes32 _requestId, uint8 _payeeIndex)
        public
        constant
        returns(int256)
    {
        if(_payeeIndex == 0) {
            return requests[_requestId].payee.balance;    
        } else {
            return subPayees[_requestId][_payeeIndex-1].balance;
        }
    }

          
    function getBalance(bytes32 _requestId)
        public
        constant
        returns(int256)
    {
        int256 balance = requests[_requestId].payee.balance;

        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1))
        {
            balance = balance.add(subPayees[_requestId][i].balance);
        }

        return balance;
    }


          
    function areAllBalanceNull(bytes32 _requestId)
        public
        constant
        returns(bool isNull)
    {
        isNull = requests[_requestId].payee.balance == 0;

        for (uint8 i = 0; isNull && subPayees[_requestId][i].addr != address(0); i = i.add(1))
        {
            isNull = subPayees[_requestId][i].balance == 0;
        }

        return isNull;
    }

          
    function getExpectedAmount(bytes32 _requestId)
        public
        constant
        returns(int256)
    {
        int256 expectedAmount = requests[_requestId].payee.expectedAmount;

        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1))
        {
            expectedAmount = expectedAmount.add(subPayees[_requestId][i].expectedAmount);
        }

        return expectedAmount;
    }

      
    function getState(bytes32 _requestId)
        public
        constant
        returns(State)
    {
        return requests[_requestId].state;
    }

     
    function getPayeeIndex(bytes32 _requestId, address _address)
        public
        constant
        returns(int16)
    {
         
        if(requests[_requestId].payee.addr == _address) return 0;

        for (uint8 i = 0; subPayees[_requestId][i].addr != address(0); i = i.add(1))
        {
            if(subPayees[_requestId][i].addr == _address) {
                 
                return i+1;
            }
        }
        return -1;
    }

      
    function getRequest(bytes32 _requestId) 
        external
        constant
        returns(address payer, address currencyContract, State state, address payeeAddr, int256 payeeExpectedAmount, int256 payeeBalance)
    {
        Request storage r = requests[_requestId];
        return ( r.payer, 
                 r.currencyContract, 
                 r.state, 
                 r.payee.addr, 
                 r.payee.expectedAmount, 
                 r.payee.balance );
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

     
    function extractAddress(bytes _data, uint offset)
        internal
        pure
        returns (address m)
    {
        require(offset >=0 && offset + 20 <= _data.length);
        assembly {
            m := and( mload(add(_data, add(20, offset))), 
                      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

     
    function extractBytes32(bytes _data, uint offset)
        public
        pure
        returns (bytes32 bs)
    {
        require(offset >=0 && offset + 32 <= _data.length);
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
}

 
contract RequestEthereumCollect is Pausable {
    using SafeMath for uint256;

     
    uint256 public feesPer10000;

     
    uint256 public maxFees;

     
    address public requestBurnerContract;

       
    function RequestEthereumCollect(address _requestBurnerContract) 
        public
    {
        requestBurnerContract = _requestBurnerContract;
    }

       
    function collectForREQBurning(uint256 _amount)
        internal
        returns(bool)
    {
        return requestBurnerContract.send(_amount);
    }

       
    function collectEstimation(int256 _expectedAmount)
        public
        view
        returns(uint256)
    {
         
        if (_expectedAmount <= 0) {
            return 0;
        }
        uint256 computedCollect = uint256(_expectedAmount).mul(feesPer10000).div(10000);
        return computedCollect < maxFees ? computedCollect : maxFees;
    }

       
    function setFeesPerTenThousand(uint256 _newRate) 
        external
        onlyOwner
    {
        feesPer10000=_newRate;
    }

       
    function setMaxCollectable(uint256 _newMax) 
        external
        onlyOwner
    {
        maxFees=_newMax;
    }

       
    function setRequestBurnerContract(address _requestBurnerContract) 
        external
        onlyOwner
    {
        requestBurnerContract=_requestBurnerContract;
    }
}



 
contract RequestEthereum is RequestEthereumCollect {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using SafeMathUint8 for uint8;

     
    RequestCore public requestCore;

     
    mapping(bytes32 => address[256]) public payeesPaymentAddress;
    mapping(bytes32 => address) public payerRefundAddress;

     
    function RequestEthereum(address _requestCoreAddress, address _requestBurnerAddress) RequestEthereumCollect(_requestBurnerAddress) public
    {
        requestCore=RequestCore(_requestCoreAddress);
    }

     
    function createRequestAsPayee(
        address[]   _payeesIdAddress,
        address[]   _payeesPaymentAddress,
        int256[]    _expectedAmounts,
        address     _payer,
        address     _payerRefundAddress,
        string      _data)
        external
        payable
        whenNotPaused
        returns(bytes32 requestId)
    {
        require(msg.sender == _payeesIdAddress[0] && msg.sender != _payer && _payer != 0);

        uint256 fees;
        (requestId, fees) = createRequest(_payer, _payeesIdAddress, _payeesPaymentAddress, _expectedAmounts, _payerRefundAddress, _data);

         
        require(fees == msg.value);

        return requestId;
    }

     
    function createRequestAsPayer(
        address[]   _payeesIdAddress,
        int256[]    _expectedAmounts,
        address     _payerRefundAddress,
        uint256[]   _payeeAmounts,
        uint256[]   _additionals,
        string      _data)
        external
        payable
        whenNotPaused
        returns(bytes32 requestId)
    {
        require(msg.sender != _payeesIdAddress[0] && _payeesIdAddress[0] != 0);

         
        address[] memory emptyPayeesPaymentAddress = new address[](0);
        uint256 fees;
        (requestId, fees) = createRequest(msg.sender, _payeesIdAddress, emptyPayeesPaymentAddress, _expectedAmounts, _payerRefundAddress, _data);

         
        acceptAndPay(requestId, _payeeAmounts, _additionals, msg.value.sub(fees));

        return requestId;
    }


     
    function broadcastSignedRequestAsPayer(
        bytes       _requestData,  
        address[]   _payeesPaymentAddress,
        uint256[]   _payeeAmounts,
        uint256[]   _additionals,
        uint256     _expirationDate,
        bytes       _signature)
        external
        payable
        whenNotPaused
        returns(bytes32)
    {
         
        require(_expirationDate >= block.timestamp);

         
        require(checkRequestSignature(_requestData, _payeesPaymentAddress, _expirationDate, _signature));

         
        return createAcceptAndPayFromBytes(_requestData,  _payeesPaymentAddress, _payeeAmounts, _additionals);
    }

     
    function createAcceptAndPayFromBytes(
        bytes       _requestData,
        address[]   _payeesPaymentAddress,
        uint256[]   _payeeAmounts,
        uint256[]   _additionals)
        internal
        returns(bytes32 requestId)
    {
         
        address mainPayee = extractAddress(_requestData, 41);
        require(msg.sender != mainPayee && mainPayee != 0);
         
        require(extractAddress(_requestData, 0) == mainPayee);

         
        uint8 payeesCount = uint8(_requestData[40]);
        int256 totalExpectedAmounts = 0;
        for(uint8 i = 0; i < payeesCount; i++) {
             
             
            int256 expectedAmountTemp = int256(extractBytes32(_requestData, 61 + 52 * uint256(i)));
             
            totalExpectedAmounts = totalExpectedAmounts.add(expectedAmountTemp);
             
            require(expectedAmountTemp>0);
        }

         
        uint256 fees = collectEstimation(totalExpectedAmounts);

         
         
        require(collectForREQBurning(fees));

         
        updateBytes20inBytes(_requestData, 20, bytes20(msg.sender));
         
        requestId = requestCore.createRequestFromBytes(_requestData);

         
        for (uint8 j = 0; j < _payeesPaymentAddress.length; j = j.add(1)) {
            payeesPaymentAddress[requestId][j] = _payeesPaymentAddress[j];
        }

         
        acceptAndPay(requestId, _payeeAmounts, _additionals, msg.value.sub(fees));

        return requestId;
    }


     
    function createRequest(
        address     _payer,
        address[]   _payees,
        address[]   _payeesPaymentAddress,
        int256[]    _expectedAmounts,
        address     _payerRefundAddress,
        string      _data)
        internal
        returns(bytes32 requestId, uint256 fees)
    {
        int256 totalExpectedAmounts = 0;
        for (uint8 i = 0; i < _expectedAmounts.length; i = i.add(1))
        {
             
            require(_expectedAmounts[i]>=0);
             
            totalExpectedAmounts = totalExpectedAmounts.add(_expectedAmounts[i]);
        }

         
        fees = collectEstimation(totalExpectedAmounts);
         
        require(collectForREQBurning(fees));

         
        requestId= requestCore.createRequest(msg.sender, _payees, _expectedAmounts, _payer, _data);

         
        for (uint8 j = 0; j < _payeesPaymentAddress.length; j = j.add(1)) {
            payeesPaymentAddress[requestId][j] = _payeesPaymentAddress[j];
        }
         
        if(_payerRefundAddress != 0) {
            payerRefundAddress[requestId] = _payerRefundAddress;
        }
    }

      
    function acceptAndPay(
        bytes32 _requestId,
        uint256[] _payeeAmounts,
        uint256[] _additionals,
        uint256 _amountPaid)
        internal
    {
        requestCore.accept(_requestId);
        
        additionalInternal(_requestId, _additionals);

        if(_amountPaid > 0) {
            paymentInternal(_requestId, _payeeAmounts, _amountPaid);
        }
    }

     

     
    function accept(bytes32 _requestId)
        external
        whenNotPaused
        condition(requestCore.getPayer(_requestId)==msg.sender)
        condition(requestCore.getState(_requestId)==RequestCore.State.Created)
    {
        requestCore.accept(_requestId);
    }

     
    function cancel(bytes32 _requestId)
        external
        whenNotPaused
    {
         
        bool isPayerAndCreated = requestCore.getPayer(_requestId)==msg.sender && requestCore.getState(_requestId)==RequestCore.State.Created;

         
        bool isPayeeAndNotCanceled = requestCore.getPayeeAddress(_requestId,0)==msg.sender && requestCore.getState(_requestId)!=RequestCore.State.Canceled;

        require(isPayerAndCreated || isPayeeAndNotCanceled);

         
        require(requestCore.areAllBalanceNull(_requestId));

        requestCore.cancel(_requestId);
    }

     


     
     
    function paymentAction(
        bytes32 _requestId,
        uint256[] _payeeAmounts,
        uint256[] _additionalAmounts)
        external
        whenNotPaused
        payable
        condition(requestCore.getState(_requestId)!=RequestCore.State.Canceled)
        condition(_additionalAmounts.length == 0 || msg.sender == requestCore.getPayer(_requestId))
    {
         
        if(requestCore.getState(_requestId)==RequestCore.State.Created && msg.sender == requestCore.getPayer(_requestId)) {
            requestCore.accept(_requestId);
        }

        additionalInternal(_requestId, _additionalAmounts);

        paymentInternal(_requestId, _payeeAmounts, msg.value);
    }

     
    function refundAction(bytes32 _requestId)
        external
        whenNotPaused
        payable
    {
        refundInternal(_requestId, msg.sender, msg.value);
    }

     
    function subtractAction(bytes32 _requestId, uint256[] _subtractAmounts)
        external
        whenNotPaused
        condition(requestCore.getState(_requestId)!=RequestCore.State.Canceled)
        onlyRequestPayee(_requestId)
    {
        for(uint8 i = 0; i < _subtractAmounts.length; i = i.add(1)) {
            if(_subtractAmounts[i] != 0) {
                 
                require(requestCore.getPayeeExpectedAmount(_requestId,i) >= _subtractAmounts[i].toInt256Safe());
                 
                requestCore.updateExpectedAmount(_requestId, i, -_subtractAmounts[i].toInt256Safe());
            }
        }
    }

     
    function additionalAction(bytes32 _requestId, uint256[] _additionalAmounts)
        external
        whenNotPaused
        condition(requestCore.getState(_requestId)!=RequestCore.State.Canceled)
        onlyRequestPayer(_requestId)
    {
        additionalInternal(_requestId, _additionalAmounts);
    }
     


     
     
    function additionalInternal(bytes32 _requestId, uint256[] _additionalAmounts)
        internal
    {
         
        require(_additionalAmounts.length <= requestCore.getSubPayeesCount(_requestId).add(1));

        for(uint8 i = 0; i < _additionalAmounts.length; i = i.add(1)) {
            if(_additionalAmounts[i] != 0) {
                 
                requestCore.updateExpectedAmount(_requestId, i, _additionalAmounts[i].toInt256Safe());
            }
        }
    }

     
    function paymentInternal(
        bytes32     _requestId,
        uint256[]   _payeeAmounts,
        uint256     _value)
        internal
    {
         
        require(_payeeAmounts.length <= requestCore.getSubPayeesCount(_requestId).add(1));

        uint256 totalPayeeAmounts = 0;

        for(uint8 i = 0; i < _payeeAmounts.length; i = i.add(1)) {
            if(_payeeAmounts[i] != 0) {
                 
                totalPayeeAmounts = totalPayeeAmounts.add(_payeeAmounts[i]);

                 
                requestCore.updateBalance(_requestId, i, _payeeAmounts[i].toInt256Safe());

                 
                address addressToPay;
                if(payeesPaymentAddress[_requestId][i] == 0) {
                    addressToPay = requestCore.getPayeeAddress(_requestId, i);
                } else {
                    addressToPay = payeesPaymentAddress[_requestId][i];
                }

                 
                fundOrderInternal(addressToPay, _payeeAmounts[i]);
            }
        }

         
        require(_value==totalPayeeAmounts);
    }

     
    function refundInternal(
        bytes32 _requestId,
        address _fromAddress,
        uint256 _amount)
        condition(requestCore.getState(_requestId)!=RequestCore.State.Canceled)
        internal
    {
         
         
        int16 payeeIndex = requestCore.getPayeeIndex(_requestId, _fromAddress);
        if(payeeIndex < 0) {
            uint8 payeesCount = requestCore.getSubPayeesCount(_requestId).add(1);

             
            for (uint8 i = 0; i < payeesCount && payeeIndex == -1; i = i.add(1)) {
                if(payeesPaymentAddress[_requestId][i] == _fromAddress) {
                     
                    payeeIndex = int16(i);
                }
            }
        }
         
        require(payeeIndex >= 0); 

         
        requestCore.updateBalance(_requestId, uint8(payeeIndex), -_amount.toInt256Safe());

         
        address addressToPay = payerRefundAddress[_requestId];
        if(addressToPay == 0) {
            addressToPay = requestCore.getPayer(_requestId);
        }

         
        fundOrderInternal(addressToPay, _amount);
    }

     
    function fundOrderInternal(
        address _recipient,
        uint256 _amount)
        internal
    {
        _recipient.transfer(_amount);
    }

     
    function getRequestHash(
         
        bytes       _requestData,

         
        address[]   _payeesPaymentAddress,
        uint256     _expirationDate)
        internal
        view
        returns(bytes32)
    {
        return keccak256(this, _requestData, _payeesPaymentAddress, _expirationDate);
    }

     
    function isValidSignature(
        address signer,
        bytes32 hash,
        uint8   v,
        bytes32 r,
        bytes32 s)
        public
        pure
        returns (bool)
    {
        return signer == ecrecover(
            keccak256("\x19Ethereum Signed Message:\n32", hash),
            v,
            r,
            s
        );
    }

      
    function checkRequestSignature(
        bytes       _requestData,
        address[]   _payeesPaymentAddress,
        uint256     _expirationDate,
        bytes       _signature)
        public
        view
        returns (bool)
    {
        bytes32 hash = getRequestHash(_requestData, _payeesPaymentAddress, _expirationDate);

         
        uint8 v = uint8(_signature[64]);
        v = v < 27 ? v.add(27) : v;
        bytes32 r = extractBytes32(_signature, 0);
        bytes32 s = extractBytes32(_signature, 32);

         
        return isValidSignature(extractAddress(_requestData, 0), hash, v, r, s);
    }

     
    modifier condition(bool c)
    {
        require(c);
        _;
    }

      
    modifier onlyRequestPayer(bytes32 _requestId)
    {
        require(requestCore.getPayer(_requestId)==msg.sender);
        _;
    }
    
      
    modifier onlyRequestPayee(bytes32 _requestId)
    {
        require(requestCore.getPayeeAddress(_requestId, 0)==msg.sender);
        _;
    }

     
    function updateBytes20inBytes(bytes data, uint offset, bytes20 b)
        internal
        pure
    {
        require(offset >=0 && offset + 20 <= data.length);
        assembly {
            let m := mload(add(data, add(20, offset)))
            m := and(m, 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000)
            m := or(m, div(b, 0x1000000000000000000000000))
            mstore(add(data, add(20, offset)), m)
        }
    }

     
    function extractAddress(bytes _data, uint offset)
        internal
        pure
        returns (address m) 
    {
        require(offset >=0 && offset + 20 <= _data.length);
        assembly {
            m := and( mload(add(_data, add(20, offset))), 
                      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

     
    function extractBytes32(bytes _data, uint offset)
        public
        pure
        returns (bytes32 bs)
    {
        require(offset >=0 && offset + 32 <= _data.length);
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
}