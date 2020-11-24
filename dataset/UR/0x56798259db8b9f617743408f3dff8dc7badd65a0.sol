 

pragma solidity ^0.4.24;

 


library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a < b ? a : b;
  }
}


interface IERC20 {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address tokenOwner)  external returns (uint balance);

}


contract Ownable {
    address public owner;

    function Ownable() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public{
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

 

contract Bulksender is Ownable{

    using SafeMath for uint;

    event LogTokenBulkSent(address token,uint256 total);
    event LogGetToken(address token, address receiver, uint256 balance);

    address public receiverAddress;
    uint public txFee = 0.02 ether;
    uint public VIPFee = 2 ether;

     
    mapping(address => bool) public vipList;

     
    mapping(bytes32 => bool) public txRecords;


     
  function getBalance(IERC20 token) onlyOwner public {
      address _receiverAddress = getReceiverAddress();
      if(token == address(0)){
          require(_receiverAddress.send(address(this).balance));
          return;
      }
      uint256 balance = token.balanceOf(this);
      token.transfer(_receiverAddress, balance);
      emit LogGetToken(token,_receiverAddress,balance);
  }

    
  function registerVIP() payable public {
      require(msg.value >= VIPFee);
      address _receiverAddress = getReceiverAddress();
      require(_receiverAddress.send(msg.value));
      vipList[msg.sender] = true;
  }



   
  function addToVIPList(address[] _vipList) onlyOwner public {
    for (uint i =0;i<_vipList.length;i++){
      vipList[_vipList[i]] = true;

    }
  }

   
  function removeFromVIPList(address[] _vipList) onlyOwner public {
    for (uint i =0;i<_vipList.length;i++){
      vipList[_vipList[i]] = false;
    }
   }

     
    function isVIP(address _addr) public view returns (bool) {
        return _addr == owner || vipList[_addr];
    }

     
    function setReceiverAddress(address _addr) onlyOwner public {
        require(_addr != address(0));
        receiverAddress = _addr;
    }

     
    function getReceiverAddress() public view returns  (address){
        if(receiverAddress == address(0)){
            return owner;
        }

        return receiverAddress;
    }

      
    function setVIPFee(uint _fee) onlyOwner public {
        VIPFee = _fee;
    }

     
    function setTxFee(uint _fee) onlyOwner public {
        txFee = _fee;
    }

    function checkTxExist(bytes32 _txRecordId)  public view returns  (bool){
        return txRecords[_txRecordId];
    }

    function addTxRecord(bytes32 _txRecordId) internal{
        txRecords[_txRecordId] = true;
    }

    function _bulksendEther(address[] _to, uint256[] _values) internal {

        uint sendAmount = _values[0];
		uint remainingValue = msg.value;

	    bool vip = isVIP(msg.sender);
        if(vip){
            require(remainingValue >= sendAmount);
        }else{
            require(remainingValue >= sendAmount.add(txFee)) ;
        }
		require(_to.length == _values.length);

		for (uint256 i = 1; i < _to.length; i++) {
			remainingValue = remainingValue.sub(_values[i]);
			require(_to[i].send(_values[i]));
		}
	    emit LogTokenBulkSent(0x000000000000000000000000000000000000bEEF,msg.value);

    }

     function _bulksendTokenSimple(IERC20 _token, address[] _to, uint[] _values) internal {
       	uint sendValue = msg.value;
	    bool vip = isVIP(msg.sender);
        if(!vip){
		    require(sendValue >= txFee);
        }
		require(_to.length == _values.length);

        uint256 sendAmount = _values[0];
		for (uint256 i = 1; i < _to.length; i++) {
		    _token.transferFrom(msg.sender, _to[i], _values[i]);
		}
        emit LogTokenBulkSent(_token,sendAmount);
    }

    function _bulksendToken(IERC20 _token, address[] _to, uint256[] _values)  internal  {
		uint sendValue = msg.value;
	    bool vip = isVIP(msg.sender);
        if(!vip){
		    require(sendValue >= txFee);
        }
		require(_to.length == _values.length);

        uint256 sendAmount = _values[0];
        _token.transferFrom(msg.sender,address(this), sendAmount);

		for (uint256 i = 1; i < _to.length; i++) {
		    _token.transfer(_to[i], _values[i]);
		}
        emit LogTokenBulkSent(_token,sendAmount);

    }


    function bulksendTokenSimple(IERC20 _token, address[] _to, uint256[] _values, bytes32 _uniqueId) payable public {
        if(checkTxExist(_uniqueId)){
            if (msg.value > 0)
                require(msg.sender.send(msg.value)); 
        }else{
            addTxRecord(_uniqueId);
	        _bulksendTokenSimple(_token, _to, _values);
        }
    }

    function bulksendToken(IERC20 _token, address[] _to, uint256[] _values, bytes32 _uniqueId) payable public {
        if(checkTxExist(_uniqueId)){
            if (msg.value > 0)
                require(msg.sender.send(msg.value)); 
        }else{
            addTxRecord(_uniqueId);
	        _bulksendToken(_token, _to, _values);
        }
    }

    function bulksendEther(address[] _to, uint256[] _values,bytes32 _uniqueId) payable public {
        if(checkTxExist(_uniqueId)){
            if (msg.value > 0)
                require(msg.sender.send(msg.value)); 
        }else{
            addTxRecord(_uniqueId);
	        _bulksendEther(_to, _values);
        }
	}

}