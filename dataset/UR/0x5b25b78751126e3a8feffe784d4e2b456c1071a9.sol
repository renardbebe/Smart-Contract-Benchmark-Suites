 

pragma solidity ^0.4.22;
 
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




 
contract StandardToken  {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}



 
contract GESCrowdsale is Ownable {

     

    StandardToken public token;


     

     
    constructor(StandardToken _token) public {
        require(_token != address(0));
        token = _token;
    }

     
    function setTokenAddress(address _addr) public onlyOwner returns (bool) {
        token = StandardToken(_addr);
        return true;

    }

     
    function sendTokensToRecipients(address[] _recipients, uint256[] _values) onlyOwner public returns (bool) {
        require(_recipients.length == _values.length);
        uint256 i = 0;
        while (i < _recipients.length) {
            if (_values[i] > 0) {
                StandardToken(token).transfer(_recipients[i], _values[i]);
            }
            i += 1;
        }
        return true;
    }
}