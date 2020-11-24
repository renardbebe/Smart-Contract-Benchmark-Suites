 

pragma solidity ^0.4.18;

 

interface InkMediator {
  function mediationExpiry() external returns (uint32);
  function requestMediator(uint256 _transactionId, uint256 _transactionAmount, address _transactionOwner) external returns (bool);
  function confirmTransactionFee(uint256 _transactionAmount) external returns (uint256);
  function confirmTransactionAfterExpiryFee(uint256 _transactionAmount) external returns (uint256);
  function confirmTransactionAfterDisputeFee(uint256 _transactionAmount) external returns (uint256);
  function confirmTransactionByMediatorFee(uint256 _transactionAmount) external returns (uint256);
  function refundTransactionFee(uint256 _transactionAmount) external returns (uint256);
  function refundTransactionAfterExpiryFee(uint256 _transactionAmount) external returns (uint256);
  function refundTransactionAfterDisputeFee(uint256 _transactionAmount) external returns (uint256);
  function refundTransactionByMediatorFee(uint256 _transactionAmount) external returns (uint256);
  function settleTransactionByMediatorFee(uint256 _buyerAmount, uint256 _sellerAmount) external returns (uint256, uint256);
}

 

interface InkOwner {
  function authorizeTransaction(uint256 _id, address _buyer) external returns (bool);
}

 

interface InkProtocolInterface {
   
  event TransactionInitiated(
    uint256 indexed id,
    address owner,
    address indexed buyer,
    address indexed seller,
    address policy,
    address mediator,
    uint256 amount,
     
     
     
     
    bytes32 metadata
  );

   
  event TransactionAccepted(
    uint256 indexed id
  );

   
  event TransactionDisputed(
    uint256 indexed id
  );

   
   
  event TransactionEscalated(
    uint256 indexed id
  );

   
  event TransactionRevoked(
    uint256 indexed id
  );

   
  event TransactionRefundedByMediator(
    uint256 indexed id,
    uint256 mediatorFee
  );

   
  event TransactionSettledByMediator(
    uint256 indexed id,
    uint256 buyerAmount,
    uint256 sellerAmount,
    uint256 buyerMediatorFee,
    uint256 sellerMediatorFee
  );

   
  event TransactionConfirmedByMediator(
    uint256 indexed id,
    uint256 mediatorFee
  );

   
  event TransactionConfirmed(
    uint256 indexed id,
    uint256 mediatorFee
  );

   
  event TransactionRefunded(
    uint256 indexed id,
    uint256 mediatorFee
  );

   
   
  event TransactionConfirmedAfterExpiry(
    uint256 indexed id,
    uint256 mediatorFee
  );

   
   
  event TransactionConfirmedAfterDispute(
    uint256 indexed id,
    uint256 mediatorFee
  );

   
   
  event TransactionRefundedAfterDispute(
    uint256 indexed id,
    uint256 mediatorFee
  );

   
   
  event TransactionRefundedAfterExpiry(
    uint256 indexed id,
    uint256 mediatorFee
  );

   
   
  event TransactionConfirmedAfterEscalation(
    uint256 indexed id
  );

   
   
  event TransactionRefundedAfterEscalation(
    uint256 indexed id
  );

   
   
  event TransactionSettled(
    uint256 indexed id,
    uint256 buyerAmount,
    uint256 sellerAmount
  );

   
  event FeedbackUpdated(
    uint256 indexed transactionId,
    uint8 rating,
    bytes32 comment
  );

   
   
   
  event AccountLinked(
    address indexed from,
    address indexed to
  );

   
  function link(address _to) external;
  function createTransaction(address _seller, uint256 _amount, bytes32 _metadata, address _policy, address _mediator) external returns (uint256);
  function createTransaction(address _seller, uint256 _amount, bytes32 _metadata, address _policy, address _mediator, address _owner) external returns (uint256);
  function revokeTransaction(uint256 _id) external;
  function acceptTransaction(uint256 _id) external;
  function confirmTransaction(uint256 _id) external;
  function confirmTransactionAfterExpiry(uint256 _id) external;
  function refundTransaction(uint256 _id) external;
  function refundTransactionAfterExpiry(uint256 _id) external;
  function disputeTransaction(uint256 _id) external;
  function escalateDisputeToMediator(uint256 _id) external;
  function settleTransaction(uint256 _id) external;
  function refundTransactionByMediator(uint256 _id) external;
  function confirmTransactionByMediator(uint256 _id) external;
  function settleTransactionByMediator(uint256 _id, uint256 _buyerAmount, uint256 _sellerAmount) external;
  function provideTransactionFeedback(uint256 _id, uint8 _rating, bytes32 _comment) external;

   
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function increaseApproval(address spender, uint addedValue) public returns (bool);
  function decreaseApproval(address spender, uint subtractedValue) public returns (bool);
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract InkProtocolCore is InkProtocolInterface, StandardToken {
  string public constant name = "Ink Protocol";
  string public constant symbol = "XNK";
  uint8 public constant decimals = 18;

  uint256 private constant gasLimitForExpiryCall = 1000000;
  uint256 private constant gasLimitForMediatorCall = 4000000;

  enum Expiry {
    Transaction,  
    Fulfillment,  
    Escalation,   
    Mediation     
  }

  enum TransactionState {
     
    Null,                      

    Initiated,                 
    Accepted,                  
    Disputed,                  
    Escalated,                 
    Revoked,                   
    RefundedByMediator,        
    SettledByMediator,         
    ConfirmedByMediator,       
    Confirmed,                 
    Refunded,                  
    ConfirmedAfterExpiry,      
    ConfirmedAfterDispute,     
    RefundedAfterDispute,      
    RefundedAfterExpiry,       
    ConfirmedAfterEscalation,  
    RefundedAfterEscalation,   
    Settled                    
  }

   
  uint256 private globalTransactionId = 0;

   
  mapping(uint256 => Transaction) internal transactions;

   
  struct Transaction {
     
    address buyer;
     
    address seller;
     
    address policy;
     
    address mediator;
     
    TransactionState state;
     
     
     
    uint256 stateTime;
     
    uint256 amount;
  }


   

  function InkProtocolCore() internal {
     
    totalSupply_ = 500000000000000000000000000;
  }


   

  function transfer(address _to, uint256 _value) public returns (bool) {
    
   require(_to != address(this));

   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    
   require(_to != address(this));

   return super.transferFrom(_from, _to, _value);
  }


   

   
  function link(address _to) external {
    require(_to != address(0));
    require(_to != msg.sender);

    AccountLinked({
      from: msg.sender,
      to: _to
    });
  }


   

  function createTransaction(address _seller, uint256 _amount, bytes32 _metadata, address _policy, address _mediator) external returns (uint256) {
    return _createTransaction(_seller, _amount, _metadata, _policy, _mediator, address(0));
  }

  function createTransaction(address _seller, uint256 _amount, bytes32 _metadata, address _policy, address _mediator, address _owner) external returns (uint256) {
    return _createTransaction(_seller, _amount, _metadata, _policy, _mediator, _owner);
  }

  function revokeTransaction(uint256 _id) external {
    _revokeTransaction(_id, _findTransactionForBuyer(_id));
  }

  function acceptTransaction(uint256 _id) external {
    _acceptTransaction(_id, _findTransactionForSeller(_id));
  }

  function confirmTransaction(uint256 _id) external {
    _confirmTransaction(_id, _findTransactionForBuyer(_id));
  }

  function confirmTransactionAfterExpiry(uint256 _id) external {
    _confirmTransactionAfterExpiry(_id, _findTransactionForSeller(_id));
  }

  function refundTransaction(uint256 _id) external {
    _refundTransaction(_id, _findTransactionForSeller(_id));
  }

  function refundTransactionAfterExpiry(uint256 _id) external {
    _refundTransactionAfterExpiry(_id, _findTransactionForBuyer(_id));
  }

  function disputeTransaction(uint256 _id) external {
    _disputeTransaction(_id, _findTransactionForBuyer(_id));
  }

  function escalateDisputeToMediator(uint256 _id) external {
    _escalateDisputeToMediator(_id, _findTransactionForSeller(_id));
  }

  function settleTransaction(uint256 _id) external {
    _settleTransaction(_id, _findTransactionForParty(_id));
  }

  function refundTransactionByMediator(uint256 _id) external {
    _refundTransactionByMediator(_id, _findTransactionForMediator(_id));
  }

  function confirmTransactionByMediator(uint256 _id) external {
    _confirmTransactionByMediator(_id, _findTransactionForMediator(_id));
  }

  function settleTransactionByMediator(uint256 _id, uint256 _buyerAmount, uint256 _sellerAmount) external {
    _settleTransactionByMediator(_id, _findTransactionForMediator(_id), _buyerAmount, _sellerAmount);
  }

  function provideTransactionFeedback(uint256 _id, uint8 _rating, bytes32 _comment) external {
    _provideTransactionFeedback(_id, _findTransactionForBuyer(_id), _rating, _comment);
  }


   

  function _createTransaction(address _seller, uint256 _amount, bytes32 _metadata, address _policy, address _mediator, address _owner) private returns (uint256) {
    require(_seller != address(0) && _seller != msg.sender);
    require(_owner != msg.sender && _owner != _seller);
    require(_amount > 0);

     
     
    if (_mediator == address(0)) {
      require(_policy == address(0));
    } else {
      require(_policy != address(0));
    }

     
    uint256 id = globalTransactionId++;

     
    Transaction storage transaction = transactions[id];
    transaction.buyer = msg.sender;
    transaction.seller = _seller;
    transaction.state = TransactionState.Initiated;
    transaction.amount = _amount;
    transaction.policy = _policy;

    _resolveMediator(id, transaction, _mediator, _owner);
    _resolveOwner(id, _owner);

     
    TransactionInitiated({
      id: id,
      owner: _owner,
      buyer: msg.sender,
      seller: _seller,
      policy: _policy,
      mediator: _mediator,
      amount: _amount,
      metadata: _metadata
    });

     
    _transferFrom(msg.sender, this, _amount);

     
    return id;
  }

  function _revokeTransaction(uint256 _id, Transaction storage _transaction) private {
    require(_transaction.state == TransactionState.Initiated);

    TransactionRevoked({ id: _id });

    _transferFromEscrow(_transaction.buyer, _transaction.amount);

    _cleanupTransaction(_id, _transaction, false);
  }

  function _acceptTransaction(uint256 _id, Transaction storage _transaction) private {
    require(_transaction.state == TransactionState.Initiated);

    if (_transaction.mediator != address(0)) {
      _updateTransactionState(_transaction, TransactionState.Accepted);
    }

    TransactionAccepted({ id: _id });

    if (_transaction.mediator == address(0)) {
       
      _completeTransaction(_id, _transaction, TransactionState.Confirmed, _transaction.seller);
    }
  }

  function _confirmTransaction(uint256 _id, Transaction storage _transaction) private {
    TransactionState finalState;

    if (_transaction.state == TransactionState.Accepted) {
      finalState = TransactionState.Confirmed;
    } else if (_transaction.state == TransactionState.Disputed) {
      finalState = TransactionState.ConfirmedAfterDispute;
    } else if (_transaction.state == TransactionState.Escalated) {
      require(_afterExpiry(_transaction, _fetchExpiry(_transaction, Expiry.Mediation)));
      finalState = TransactionState.ConfirmedAfterEscalation;
    } else {
      revert();
    }

    _completeTransaction(_id, _transaction, finalState, _transaction.seller);
  }

  function _confirmTransactionAfterExpiry(uint256 _id, Transaction storage _transaction) private {
    require(_transaction.state == TransactionState.Accepted);
    require(_afterExpiry(_transaction, _fetchExpiry(_transaction, Expiry.Transaction)));

    _completeTransaction(_id, _transaction, TransactionState.ConfirmedAfterExpiry, _transaction.seller);
  }

  function _refundTransaction(uint256 _id, Transaction storage _transaction) private {
    TransactionState finalState;

    if (_transaction.state == TransactionState.Accepted) {
      finalState = TransactionState.Refunded;
    } else if (_transaction.state == TransactionState.Disputed) {
      finalState = TransactionState.RefundedAfterDispute;
    } else if (_transaction.state == TransactionState.Escalated) {
      require(_afterExpiry(_transaction, _fetchExpiry(_transaction, Expiry.Mediation)));
      finalState = TransactionState.RefundedAfterEscalation;
    } else {
      revert();
    }

    _completeTransaction(_id, _transaction, finalState, _transaction.buyer);
  }

  function _refundTransactionAfterExpiry(uint256 _id, Transaction storage _transaction) private {
    require(_transaction.state == TransactionState.Disputed);
    require(_afterExpiry(_transaction, _fetchExpiry(_transaction, Expiry.Escalation)));

    _completeTransaction(_id, _transaction, TransactionState.RefundedAfterExpiry, _transaction.buyer);
  }

  function _disputeTransaction(uint256 _id, Transaction storage _transaction) private {
    require(_transaction.state == TransactionState.Accepted);
    require(_afterExpiry(_transaction, _fetchExpiry(_transaction, Expiry.Fulfillment)));

    _updateTransactionState(_transaction, TransactionState.Disputed);

    TransactionDisputed({ id: _id });
  }

  function _escalateDisputeToMediator(uint256 _id, Transaction storage _transaction) private {
    require(_transaction.state == TransactionState.Disputed);

    _updateTransactionState(_transaction, TransactionState.Escalated);

    TransactionEscalated({ id: _id });
  }

  function _settleTransaction(uint256 _id, Transaction storage _transaction) private {
    require(_transaction.state == TransactionState.Escalated);
    require(_afterExpiry(_transaction, _fetchExpiry(_transaction, Expiry.Mediation)));

     
     
     
    uint256 buyerAmount = _transaction.amount.div(2);
     
    uint256 sellerAmount = _transaction.amount.sub(buyerAmount);

    TransactionSettled({
      id: _id,
      buyerAmount: buyerAmount,
      sellerAmount: sellerAmount
    });

    _transferFromEscrow(_transaction.buyer, buyerAmount);
    _transferFromEscrow(_transaction.seller, sellerAmount);

    _cleanupTransaction(_id, _transaction, true);
  }

  function _refundTransactionByMediator(uint256 _id, Transaction storage _transaction) private {
    require(_transaction.state == TransactionState.Escalated);

    _completeTransaction(_id, _transaction, TransactionState.RefundedByMediator, _transaction.buyer);
  }

  function _confirmTransactionByMediator(uint256 _id, Transaction storage _transaction) private {
    require(_transaction.state == TransactionState.Escalated);

    _completeTransaction(_id, _transaction, TransactionState.ConfirmedByMediator, _transaction.seller);
  }

  function _settleTransactionByMediator(uint256 _id, Transaction storage _transaction, uint256 _buyerAmount, uint256 _sellerAmount) private {
    require(_transaction.state == TransactionState.Escalated);
    require(_buyerAmount.add(_sellerAmount) == _transaction.amount);

    uint256 buyerMediatorFee;
    uint256 sellerMediatorFee;

    (buyerMediatorFee, sellerMediatorFee) = InkMediator(_transaction.mediator).settleTransactionByMediatorFee(_buyerAmount, _sellerAmount);

     
    require(buyerMediatorFee <= _buyerAmount && sellerMediatorFee <= _sellerAmount);

    TransactionSettledByMediator({
      id: _id,
      buyerAmount: _buyerAmount,
      sellerAmount: _sellerAmount,
      buyerMediatorFee: buyerMediatorFee,
      sellerMediatorFee: sellerMediatorFee
    });

    _transferFromEscrow(_transaction.buyer, _buyerAmount.sub(buyerMediatorFee));
    _transferFromEscrow(_transaction.seller, _sellerAmount.sub(sellerMediatorFee));
    _transferFromEscrow(_transaction.mediator, buyerMediatorFee.add(sellerMediatorFee));

    _cleanupTransaction(_id, _transaction, true);
  }

  function _provideTransactionFeedback(uint256 _id, Transaction storage _transaction, uint8 _rating, bytes32 _comment) private {
     
     
    require(_transaction.state == TransactionState.Null);

     
     
    require(_rating >= 1 && _rating <= 5);

    FeedbackUpdated({
      transactionId: _id,
      rating: _rating,
      comment: _comment
    });
  }

  function _completeTransaction(uint256 _id, Transaction storage _transaction, TransactionState _finalState, address _transferTo) private {
    uint256 mediatorFee = _fetchMediatorFee(_transaction, _finalState);

    if (_finalState == TransactionState.Confirmed) {
      TransactionConfirmed({ id: _id, mediatorFee: mediatorFee });
    } else if (_finalState == TransactionState.ConfirmedAfterDispute) {
      TransactionConfirmedAfterDispute({ id: _id, mediatorFee: mediatorFee });
    } else if (_finalState == TransactionState.ConfirmedAfterEscalation) {
      TransactionConfirmedAfterEscalation({ id: _id });
    } else if (_finalState == TransactionState.ConfirmedAfterExpiry) {
      TransactionConfirmedAfterExpiry({ id: _id, mediatorFee: mediatorFee });
    } else if (_finalState == TransactionState.Refunded) {
      TransactionRefunded({ id: _id, mediatorFee: mediatorFee });
    } else if (_finalState == TransactionState.RefundedAfterDispute) {
      TransactionRefundedAfterDispute({ id: _id, mediatorFee: mediatorFee });
    } else if (_finalState == TransactionState.RefundedAfterEscalation) {
      TransactionRefundedAfterEscalation({ id: _id });
    } else if (_finalState == TransactionState.RefundedAfterExpiry) {
      TransactionRefundedAfterExpiry({ id: _id, mediatorFee: mediatorFee });
    } else if (_finalState == TransactionState.RefundedByMediator) {
      TransactionRefundedByMediator({ id: _id, mediatorFee: mediatorFee });
    } else if (_finalState == TransactionState.ConfirmedByMediator) {
      TransactionConfirmedByMediator({ id: _id, mediatorFee: mediatorFee });
    }

    _transferFromEscrow(_transferTo, _transaction.amount.sub(mediatorFee));
    _transferFromEscrow(_transaction.mediator, mediatorFee);

    _cleanupTransaction(_id, _transaction, true);
  }

  function _fetchExpiry(Transaction storage _transaction, Expiry _expiryType) private returns (uint32) {
    uint32 expiry;
    bool success;

    if (_expiryType == Expiry.Transaction) {
      success = _transaction.policy.call.gas(gasLimitForExpiryCall)(bytes4(keccak256("transactionExpiry()")));
    } else if (_expiryType == Expiry.Fulfillment) {
      success = _transaction.policy.call.gas(gasLimitForExpiryCall)(bytes4(keccak256("fulfillmentExpiry()")));
    } else if (_expiryType == Expiry.Escalation) {
      success = _transaction.policy.call.gas(gasLimitForExpiryCall)(bytes4(keccak256("escalationExpiry()")));
    } else if (_expiryType == Expiry.Mediation) {
      success = _transaction.mediator.call.gas(gasLimitForExpiryCall)(bytes4(keccak256("mediationExpiry()")));
    }

    if (success) {
      assembly {
        if eq(returndatasize(), 0x20) {
          let _freeMemPointer := mload(0x40)
          returndatacopy(_freeMemPointer, 0, 0x20)
          expiry := mload(_freeMemPointer)
        }
      }
    }

    return expiry;
  }

  function _fetchMediatorFee(Transaction storage _transaction, TransactionState _finalState) private returns (uint256) {
    if (_transaction.mediator == address(0)) {
      return 0;
    }

    uint256 mediatorFee;
    bool success;

    if (_finalState == TransactionState.Confirmed) {
      success = _transaction.mediator.call.gas(gasLimitForMediatorCall)(bytes4(keccak256("confirmTransactionFee(uint256)")), _transaction.amount);
    } else if (_finalState == TransactionState.ConfirmedAfterExpiry) {
      success = _transaction.mediator.call.gas(gasLimitForMediatorCall)(bytes4(keccak256("confirmTransactionAfterExpiryFee(uint256)")), _transaction.amount);
    } else if (_finalState == TransactionState.ConfirmedAfterDispute) {
      success = _transaction.mediator.call.gas(gasLimitForMediatorCall)(bytes4(keccak256("confirmTransactionAfterDisputeFee(uint256)")), _transaction.amount);
    } else if (_finalState == TransactionState.ConfirmedByMediator) {
      mediatorFee = InkMediator(_transaction.mediator).confirmTransactionByMediatorFee(_transaction.amount);
    } else if (_finalState == TransactionState.Refunded) {
      success = _transaction.mediator.call.gas(gasLimitForMediatorCall)(bytes4(keccak256("refundTransactionFee(uint256)")), _transaction.amount);
    } else if (_finalState == TransactionState.RefundedAfterExpiry) {
      success = _transaction.mediator.call.gas(gasLimitForMediatorCall)(bytes4(keccak256("refundTransactionAfterExpiryFee(uint256)")), _transaction.amount);
    } else if (_finalState == TransactionState.RefundedAfterDispute) {
      success = _transaction.mediator.call.gas(gasLimitForMediatorCall)(bytes4(keccak256("refundTransactionAfterDisputeFee(uint256)")), _transaction.amount);
    } else if (_finalState == TransactionState.RefundedByMediator) {
      mediatorFee = InkMediator(_transaction.mediator).refundTransactionByMediatorFee(_transaction.amount);
    }

    if (success) {
      assembly {
        if eq(returndatasize(), 0x20) {
          let _freeMemPointer := mload(0x40)
          returndatacopy(_freeMemPointer, 0, 0x20)
          mediatorFee := mload(_freeMemPointer)
        }
      }

       
      if (mediatorFee > _transaction.amount) {
        mediatorFee = 0;
      }
    } else {
      require(mediatorFee <= _transaction.amount);
    }

    return mediatorFee;
  }

  function _resolveOwner(uint256 _transactionId, address _owner) private {
    if (_owner != address(0)) {
       
      require(InkOwner(_owner).authorizeTransaction(
        _transactionId,
        msg.sender
      ));
    }
  }

  function _resolveMediator(uint256 _transactionId, Transaction storage _transaction, address _mediator, address _owner) private {
    if (_mediator != address(0)) {
       
      require(InkMediator(_mediator).requestMediator(_transactionId, _transaction.amount, _owner));

       
      _transaction.mediator = _mediator;
    }
  }

  function _afterExpiry(Transaction storage _transaction, uint32 _expiry) private view returns (bool) {
    return now.sub(_transaction.stateTime) >= _expiry;
  }

  function _findTransactionForBuyer(uint256 _id) private view returns (Transaction storage transaction) {
    transaction = _findTransaction(_id);
    require(msg.sender == transaction.buyer);
  }

  function _findTransactionForSeller(uint256 _id) private view returns (Transaction storage transaction) {
    transaction = _findTransaction(_id);
    require(msg.sender == transaction.seller);
  }

  function _findTransactionForParty(uint256 _id) private view returns (Transaction storage transaction) {
    transaction = _findTransaction(_id);
    require(msg.sender == transaction.buyer || msg.sender == transaction.seller);
  }

  function _findTransactionForMediator(uint256 _id) private view returns (Transaction storage transaction) {
    transaction = _findTransaction(_id);
    require(msg.sender == transaction.mediator);
  }

  function _findTransaction(uint256 _id) private view returns (Transaction storage transaction) {
    transaction = transactions[_id];
    require(_id < globalTransactionId);
  }

  function _transferFrom(address _from, address _to, uint256 _value) private returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);

    return true;
  }

  function _transferFromEscrow(address _to, uint256 _value) private returns (bool) {
    if (_value > 0) {
      return _transferFrom(this, _to, _value);
    }

    return true;
  }

  function _updateTransactionState(Transaction storage _transaction, TransactionState _state) private {
    _transaction.state = _state;
    _transaction.stateTime = now;
  }

  function _cleanupTransaction(uint256 _id, Transaction storage _transaction, bool _completed) private {
     

    if (_completed) {
      delete _transaction.state;
      delete _transaction.seller;
      delete _transaction.policy;
      delete _transaction.mediator;
      delete _transaction.stateTime;
      delete _transaction.amount;
    } else {
      delete transactions[_id];
    }
  }
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 

 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

 

 
contract InkProtocol is InkProtocolCore {
   
  address public constant __address0__ = 0xA13febeEde2B2924Ce8b27c1512874D3576fEC16;
  address public constant __address1__ = 0xc5bA7157b5B69B0fAe9332F30719Eecd79649486;
  address public constant __address2__ = 0x29a4b44364A8Bcb6e4d9dd60c222cCaca286ebf2;
  address public constant __address3__ = 0xc1DC1e5C3970E22201C5DAB0841abB2DD6499D3F;
  address public constant __address4__ = 0x0746d0b67BED258d94D06b15859df8dbd990eC3D;

   

  function InkProtocol() public {
     
    balances[__address0__] = 19625973697895500000000000;
    Transfer(address(0), __address0__, balanceOf(__address0__));

     
     
    TokenVesting vesting1 = new TokenVesting(__address1__, 1519776000, 0, 3 years, false);
    balances[vesting1] = 160000000000000000000000000;
    Transfer(address(0), vesting1, balanceOf(vesting1));

     
     
    TokenVesting vesting2 = new TokenVesting(__address2__, 1519776000, 0, 3 years, false);
    balances[vesting2] = 160000000000000000000000000;
    Transfer(address(0), vesting2, balanceOf(vesting2));

     
    balances[__address3__] = 30000000000000000000000000;
    Transfer(address(0), __address3__, balanceOf(__address3__));

     
    balances[__address4__] = 130374026302104500000000000;
    Transfer(address(0), __address4__, balanceOf(__address4__));
  }
}