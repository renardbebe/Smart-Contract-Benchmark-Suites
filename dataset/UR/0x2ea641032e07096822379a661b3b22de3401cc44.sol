 

pragma solidity 0.4.19;

 

contract SaleInterfaceForAllocations {

     
    function allocateTokens(address _contributor) external;

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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract TokenAllocator is Ownable {

    SaleInterfaceForAllocations public sale;

     
    function TokenAllocator(SaleInterfaceForAllocations _sale) public {
        sale = _sale;
    }

     
    function updateSale(SaleInterfaceForAllocations _sale) external onlyOwner {
        sale = _sale;
    }

     
    function allocateTokens(address[] _contributors) external {
        for (uint256 i = 0; i < _contributors.length; i++) {
            sale.allocateTokens(_contributors[i]);
        }
    }

}