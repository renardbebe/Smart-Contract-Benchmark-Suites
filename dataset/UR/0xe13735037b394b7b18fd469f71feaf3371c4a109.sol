 

pragma solidity ^0.4.23;

contract TecoIco {
    function bonusOf(address _owner) public view returns (uint256);
}

contract TecoToken {
    function balanceOf(address who) public view returns (uint256);

    function allowance(address _owner, address _spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
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


contract TecoBuyBack is Ownable {
    using SafeMath for uint256;

    TecoIco public tecoIco;
    TecoToken public tecoToken;

    mapping(address => uint256) tokensBought;

    uint256 public rate;
    uint256 public numOrders;

    enum OrderStatus {None, Pending, Payed, Deleted}

    struct Order {
        address investor;
        uint amount;
        OrderStatus status;
    }

    mapping(uint256 => Order) orders;

    constructor(TecoIco _tecoIco, TecoToken _tecoToken) public{
        require(_tecoIco != address(0));
        require(_tecoToken != address(0));

        tecoIco = _tecoIco;
        tecoToken = _tecoToken;
    }

    function() external payable {}

    function withdrawAllFunds()
    public
    onlyOwner
    {
        owner.transfer(address(this).balance);
    }

    function withdrawFunds(uint value)
    public
    onlyOwner
    {
        owner.transfer(value);
    }

    function availableBonuses(address investor) public view returns (uint256) {
        if (tecoIco.bonusOf(investor) <= tokensBought[investor]) return 0;
        return tecoIco.bonusOf(investor).sub(tokensBought[investor]);
    }

    function setRate(uint256 _rate)
    public
    onlyOwner
    {
        rate = _rate;
    }

    function createOrder(uint256 _amount)
    public
    returns (uint256)
    {
        require(availableBonuses(msg.sender) >= _amount);
        require(tecoToken.allowance(msg.sender, address(this)) >= _amount);
        orders[numOrders++] = Order(msg.sender, _amount, OrderStatus.Pending);
        return numOrders - 1;
    }

    function calculateSum(uint256 amount)
    public
    view
    returns (uint256)
    {
        return amount.div(rate);
    }

    function orderSum(uint256 orderId)
    public
    view
    returns (uint256)
    {
        return calculateSum(orders[orderId].amount);
    }

    function payOrders(uint256 orderId_1, uint256 orderId_2, uint256 orderId_3, uint256 orderId_4, uint256 orderId_5)
    public
    onlyOwner
    {
        if (orderId_1 >= 0) payOrder(orderId_1);
        if (orderId_2 >= 0) payOrder(orderId_2);
        if (orderId_3 >= 0) payOrder(orderId_3);
        if (orderId_4 >= 0) payOrder(orderId_4);
        if (orderId_5 >= 0) payOrder(orderId_5);
    }

    function payOrder(uint256 orderId)
    public
    onlyOwner
    {
        require(address(this).balance >= orderSum(orderId));
        require(orders[orderId].status == OrderStatus.Pending);

        orders[orderId].status = OrderStatus.Payed;
        orders[orderId].investor.transfer(orderSum(orderId));
        tecoToken.transferFrom(orders[orderId].investor, owner, orders[orderId].amount);
        tokensBought[orders[orderId].investor] += orders[orderId].amount;
    }

    function deleteOrder(uint256 orderId)
    public
    {
        require(orders[orderId].investor == msg.sender || owner == msg.sender);
        require(orders[orderId].status == OrderStatus.Pending);
        orders[orderId].status = OrderStatus.Deleted;
    }

    function getOrderInvestor(uint256 orderId)
    public
    view
    returns (address)
    {
        return orders[orderId].investor;
    }

    function getOrderAmount(uint256 orderId)
    public
    view
    returns (uint256)
    {
        return orders[orderId].amount;
    }

    function getOrderStatus(uint256 orderId)
    public
    view
    returns (OrderStatus)
    {
        return orders[orderId].status;
    }

    function getTokensBought(address investor)
    public
    view
    returns (uint256)
    {
        return tokensBought[investor];
    }
}