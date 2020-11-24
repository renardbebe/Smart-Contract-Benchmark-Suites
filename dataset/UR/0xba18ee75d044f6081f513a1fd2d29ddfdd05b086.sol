 

pragma solidity ^0.4.19;

contract Ownable {

   
  address public owner = msg.sender;

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Investors is Ownable {

     
     
    address[] public investors;

     
     
    mapping (address => uint) public investorPercentages;


     
    function addInvestors(address[] _investors, uint[] _investorPercentages) onlyOwner public {
        for (uint i = 0; i < _investors.length; i++) {
            investors.push(_investors[i]);
            investorPercentages[_investors[i]] = _investorPercentages[i];
        }
    }


     
    function getInvestorsCount() public constant returns (uint) {
        return investors.length;
    }


     
    function getInvestorsFee() public constant returns (uint8) {
         
        if (now >= 1577836800) {
            return 1;
        }
         
        if (now >= 1546300800) {
            return 5;
        }
        return 10;
    }

}