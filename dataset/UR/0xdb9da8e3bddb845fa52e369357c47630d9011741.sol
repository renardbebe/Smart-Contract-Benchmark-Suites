 

pragma solidity ^0.4.24;



 
contract Ownable {
  address public owner;


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

   
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
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






 
contract TridentDistribution is Ownable {

   
  ERC20 public trident;

   
  struct Order {
    uint256 amount;          
    address account;         
    string metadata;         
  }

   
  Order[] orders;

   
  address[] orderDelegates;

   
  address[] approvalDelegates;

   
  uint public complementaryEthPerOrder;


   
  event ApproveOrderDelegate(
      address indexed orderDelegate
    );
   
  event RevokeOrderDelegate(
      address indexed orderDelegate
    );

   
  event ApproveApprovalDelegate(
      address indexed approvalDelegate
    );
   
  event RevokeApprovalDelegate(
      address indexed approvalDelegate
    );

   
  event OrderPlaced(
    uint indexed orderIndex
    );

   
  event OrderApproved(
    uint indexed orderIndex
    );

   
  event OrderRevoked(
    uint indexed orderIndex
    );

   
  event AllOrdersApproved();

   
  event ComplementaryEthPerOrderSet();



  constructor(ERC20 _tridentSmartContract) public {
      trident = _tridentSmartContract;
  }

   
  function () public payable {
  }


   
  modifier onlyOwnerOrOrderDelegate() {
    bool allowedToPlaceOrders = false;

    if(msg.sender==owner) {
      allowedToPlaceOrders = true;
    }
    else {
      for(uint i=0; i<orderDelegates.length; i++) {
        if(orderDelegates[i]==msg.sender) {
          allowedToPlaceOrders = true;
          break;
        }
      }
    }

    require(allowedToPlaceOrders==true);
    _;
  }

   
  modifier onlyOwnerOrApprovalDelegate() {
    bool allowedToApproveOrders = false;

    if(msg.sender==owner) {
      allowedToApproveOrders = true;
    }
    else {
      for(uint i=0; i<approvalDelegates.length; i++) {
        if(approvalDelegates[i]==msg.sender) {
          allowedToApproveOrders = true;
          break;
        }
      }
    }

    require(allowedToApproveOrders==true);
    _;
  }


   
  function getOrderDelegates() external view returns (address[]) {
    return orderDelegates;
  }

   
  function getApprovalDelegates() external view returns (address[]) {
    return approvalDelegates;
  }

   
  function approveOrderDelegate(address _orderDelegate) onlyOwner external returns (bool) {
    bool delegateFound = false;
    for(uint i=0; i<orderDelegates.length; i++) {
      if(orderDelegates[i]==_orderDelegate) {
        delegateFound = true;
        break;
      }
    }

    if(!delegateFound) {
      orderDelegates.push(_orderDelegate);
    }

    emit ApproveOrderDelegate(_orderDelegate);
    return true;
  }

   
  function revokeOrderDelegate(address _orderDelegate) onlyOwner external returns (bool) {
    uint length = orderDelegates.length;
    require(length > 0);

    address lastDelegate = orderDelegates[length-1];
    if(_orderDelegate == lastDelegate) {
      delete orderDelegates[length-1];
      orderDelegates.length--;
    }
    else {
       
      for(uint i=0; i<length; i++) {
        if(orderDelegates[i]==_orderDelegate) {
          orderDelegates[i] = lastDelegate;
          delete orderDelegates[length-1];
          orderDelegates.length--;
          break;
        }
      }
    }

    emit RevokeOrderDelegate(_orderDelegate);
    return true;
  }

   
  function approveApprovalDelegate(address _approvalDelegate) onlyOwner external returns (bool) {
    bool delegateFound = false;
    for(uint i=0; i<approvalDelegates.length; i++) {
      if(approvalDelegates[i]==_approvalDelegate) {
        delegateFound = true;
        break;
      }
    }

    if(!delegateFound) {
      approvalDelegates.push(_approvalDelegate);
    }

    emit ApproveApprovalDelegate(_approvalDelegate);
    return true;
  }

   
  function revokeApprovalDelegate(address _approvalDelegate) onlyOwner external returns (bool) {
    uint length = approvalDelegates.length;
    require(length > 0);

    address lastDelegate = approvalDelegates[length-1];
    if(_approvalDelegate == lastDelegate) {
      delete approvalDelegates[length-1];
      approvalDelegates.length--;
    }
    else {
       
      for(uint i=0; i<length; i++) {
        if(approvalDelegates[i]==_approvalDelegate) {
          approvalDelegates[i] = lastDelegate;
          delete approvalDelegates[length-1];
          approvalDelegates.length--;
          break;
        }
      }
    }

    emit RevokeApprovalDelegate(_approvalDelegate);
    return true;
  }


   
  function _deleteOrder(uint _orderIndex) internal {
    require(orders.length > _orderIndex);

    uint lastIndex = orders.length-1;
    if(_orderIndex != lastIndex) {
       
      orders[_orderIndex] = orders[lastIndex];
    }
    delete orders[lastIndex];
    orders.length--;
  }

   
  function _executeOrder(uint _orderIndex) internal {
    require(orders.length > _orderIndex);
    require(complementaryEthPerOrder <= address(this).balance);

    Order memory order = orders[_orderIndex];
    _deleteOrder(_orderIndex);

    trident.transfer(order.account, order.amount);

     
    address(order.account).transfer(complementaryEthPerOrder);
  }

   
  function placeOrder(uint256 _amount, address _account, string _metadata) onlyOwnerOrOrderDelegate external returns (bool) {
    orders.push(Order({amount: _amount, account: _account, metadata: _metadata}));

    emit OrderPlaced(orders.length-1);

    return true;
  }

   
  function getOrdersCount() external view returns (uint) {
    return orders.length;
  }

   
  function getOrdersTotalAmount() external view returns (uint) {
    uint total = 0;
    for(uint i=0; i<orders.length; i++) {
        Order memory order = orders[i];
        total += order.amount;
    }

    return total;
  }

   
  function getOrderAtIndex(uint _orderIndex) external view returns (uint256 amount, address account, string metadata) {
    Order memory order = orders[_orderIndex];
    return (order.amount, order.account, order.metadata);
  }

   
  function revokeOrder(uint _orderIndex) onlyOwnerOrApprovalDelegate external returns (bool) {
    _deleteOrder(_orderIndex);

    emit OrderRevoked(_orderIndex);

    return true;
  }

   
  function approveOrder(uint _orderIndex) onlyOwnerOrApprovalDelegate external returns (bool) {
    _executeOrder(_orderIndex);

    emit OrderApproved(_orderIndex);

    return true;
  }

   
  function approveAllOrders() onlyOwnerOrApprovalDelegate external returns (bool) {
    uint orderCount = orders.length;
    uint totalComplementaryEth = complementaryEthPerOrder * orderCount;
    require(totalComplementaryEth <= address(this).balance);

    for(uint i=0; i<orderCount; i++) {
        Order memory order = orders[i];
        trident.transfer(order.account, order.amount);

         
        address(order.account).transfer(complementaryEthPerOrder);
    }

     
    delete orders;


    emit AllOrdersApproved();

    return true;
  }



   
  function setComplementaryEthPerOrder(uint _complementaryEthPerOrder) onlyOwner external returns (bool) {
    complementaryEthPerOrder = _complementaryEthPerOrder;

    emit ComplementaryEthPerOrderSet();

    return true;
  }


   
  function withdrawAllEth() onlyOwner external returns (bool) {
    uint ethBalance = address(this).balance;
    require(ethBalance > 0);

    owner.transfer(ethBalance);

    return true;
  }


   
  function withdrawAllTrident() onlyOwner external returns (bool) {
    uint tridentBalance = trident.balanceOf(address(this));
    require(tridentBalance > 0);

    return trident.transfer(owner, tridentBalance);
  }

}