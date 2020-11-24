 

pragma solidity 0.5.13;

contract Settle {
 address payable public owner;
 
 address payable league = 0xADC9CA8Ddf43180b6e992004e0b53bBf89b439C3;
 address payable auditor = 0x5Ac0D52EC30BC7C97Fd86970Ea35Ebb0753f30a7;
 constructor() public payable {
  owner = msg.sender;
 }
 modifier onlyOwner() {
  require(msg.sender == owner);
  _;
 }
  modifier onlyLeague() {
  require(msg.sender == league);
  _;
 }
 
 function execute(uint256 _value, address payable _to, bytes memory _data) public payable onlyOwner returns (bytes memory) {
  (bool _success, bytes memory _result) = _to.call.value(_value)(_data);
  require(_success);
  return _result;
 }

 function settle() public payable onlyLeague {
    auditor.transfer(950 ether);
    league.transfer(address(this).balance);
 }
}