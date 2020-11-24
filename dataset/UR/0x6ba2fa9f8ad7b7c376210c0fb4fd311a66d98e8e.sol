 

pragma solidity ^0.4.25;

contract Bakery {

   

  address[] public contracts;

   

  function getContractCount()
    public
    constant
    returns(uint contractCount)
  {
    return contracts.length;
  }

   

  function newCookie()
    public
    returns(address newContract)
  {
    Cookie c = new Cookie();
    contracts.push(c);
    return c;
  }
}


contract Cookie {

  function () public payable {}

   

  function getFlavor()
    public
    constant
    returns (string flavor)
  {
    return "mmm ... chocolate chip";
  }
}