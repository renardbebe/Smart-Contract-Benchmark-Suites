 

pragma solidity 0.5.12;

 

contract Message {
 address payable public owner;
 constructor() public {
  owner = msg.sender;
 }
 modifier onlyOwner() {
  require(msg.sender == owner);
  _;
 }
 function execute(uint256 _value, address payable _to, bytes memory _data) public payable onlyOwner returns (bytes memory) {
  (bool _success, bytes memory _result) = _to.call.value(_value)(_data);
  require(_success);
  return _result;
 }

event Message2(string);
  function ping(address payable recipeint, string memory message) public payable onlyOwner {
    recipeint.transfer(msg.value);
    emit Message2(message);
 }
    
 
function response(string memory email) public {
   emit Message2(email);
 }
}