 

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


 
contract HtczExchange is Ownable {

    using SafeMath for uint256;

     

     
    event Deposit(address indexed sender, uint eth_amount, uint htcz_amount);

     
    event Exchanged(address indexed receiver, uint indexed htcz_tx, uint htcz_amount, uint eth_amount);

     
    event ReserveChanged(uint indexed htcz_tx, uint old_htcz_amount, uint new_htcz_amount);

     
    event OperatorChanged(address indexed new_operator);


     

     
    address public htcz_token;

     
    address public htcz_cold_wallet;

     
    address public htcz_exchange_wallet;

     
    address public operator;

     
    uint public htcz_exchanged_amount;

     
    uint public htcz_reserve;

     
    uint public exchange_rate;

     
    uint constant GAS_FOR_TRANSFER = 49483;

     

     
    modifier onlyOperator() {
        require(msg.sender == operator);
        _;
    }

    constructor(    address _htcz_token,
                    address _htcz_cold_wallet,
                    address _htcz_exchange_wallet,
                    address _operator,
                    uint _exchange_rate ) public {

	    require(_htcz_token != address(0));
	    require(_htcz_cold_wallet != address(0));
	    require(_htcz_exchange_wallet != address(0));
	    require(_operator != address(0));
	    require(_exchange_rate>0);

	    htcz_token = _htcz_token;
	    htcz_cold_wallet = _htcz_cold_wallet;
	    htcz_exchange_wallet = _htcz_exchange_wallet;
	    exchange_rate = _exchange_rate;
	    operator = _operator;

    }

     
    function() external payable {

        require( msg.value > 0 );

        uint eth_amount = msg.value;
        uint htcz_amount = eth_amount.mul(exchange_rate);

        htcz_exchanged_amount = htcz_exchanged_amount.add(htcz_amount);

        require( htcz_reserve >= htcz_exchanged_amount );

        emit Deposit(msg.sender, eth_amount, htcz_amount);
    }

     
    function change(address _receiver, uint _htcz_tx, uint _htcz_amount) external onlyOperator {

        require(_receiver != address(0));

        uint gas_value = GAS_FOR_TRANSFER.mul(tx.gasprice);
        uint eth_amount = _htcz_amount / exchange_rate;

        require(eth_amount > gas_value);

        eth_amount = eth_amount.sub(gas_value);

        require(htcz_exchanged_amount >= _htcz_amount );

        htcz_exchanged_amount = htcz_exchanged_amount.sub(_htcz_amount);

        msg.sender.transfer(gas_value);
        _receiver.transfer(eth_amount);

        emit Exchanged(_receiver, _htcz_tx, _htcz_amount, eth_amount);

    }

     
    function increaseReserve(uint _htcz_tx, uint _amount) external onlyOperator {

        uint old_htcz_reserve = htcz_reserve;
        uint new_htcz_reserve = old_htcz_reserve.add(_amount);

        require( new_htcz_reserve > old_htcz_reserve);

        htcz_reserve = new_htcz_reserve;

        emit ReserveChanged(_htcz_tx, old_htcz_reserve, new_htcz_reserve);

    }

     
    function decreaseReserve(uint _htcz_tx, uint _amount) external onlyOperator {

        uint old_htcz_reserve = htcz_reserve;
        uint new_htcz_reserve = old_htcz_reserve.sub(_amount);

        require( new_htcz_reserve < old_htcz_reserve);
        require( new_htcz_reserve >= htcz_exchanged_amount );

        htcz_reserve = new_htcz_reserve;

        emit ReserveChanged(_htcz_tx, old_htcz_reserve, new_htcz_reserve);

    }


     
    function changeOperator(address _operator) external onlyOwner {
        require(_operator != operator);
        operator = _operator;
        emit OperatorChanged(_operator);
    }


}