 

pragma solidity ^0.4.15;



contract IPFSEvents {
  event HashAdded(address PubKey, string IPFSHash, uint ttl);
  event HashRemoved(address PubKey, string IPFSHash);
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


contract Parameters is IPFSEvents,Ownable {
  mapping (string => string) parameters;

  event ParameterSet(string name, string value);
  uint defaultTTL;

  function Parameters(uint _defaultTTL) public {
    defaultTTL = _defaultTTL;
  }

  function setTTL(uint _ttl) onlyOwner public {
    defaultTTL = _ttl;
  }

  function setParameter(string _name, string _value) onlyOwner public {
    ParameterSet(_name,_value);
    parameters[_name] = _value;
  }

  function setIPFSParameter(string _name, string _ipfsValue) onlyOwner public {
    setParameter(_name,_ipfsValue);
    HashAdded(this,_ipfsValue,defaultTTL);
  }

  function getParameter(string _name) public constant returns (string){
    return parameters[_name];
  }

}