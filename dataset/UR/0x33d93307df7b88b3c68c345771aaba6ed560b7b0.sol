 

pragma solidity ^0.4.19;


interface CornFarm
{
    function buyObject(address _beneficiary) public payable;
}

interface JGWentworth
{
    function claimFunds() public;
}


interface Corn
{
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}


 
contract howbadlycouldthisgowrong {
   
  address public destinationAddress = 0x3D14410609731Ec7924ea8B1f13De544BB46A9A6;

   
  function() payable public {
        destinationAddress.transfer(msg.value);
  }

address public farmer = 0x3D14410609731Ec7924ea8B1f13De544BB46A9A6;


    function getMoney(address soil)external
    {
    JGWentworth(soil);
    }
    
    function sowCorn(address soil, uint8 seeds) external
    {
        for(uint8 i = 0; i < seeds; ++i)
        {
            CornFarm(soil).buyObject(this);
        }
    }
    
    function reap(address corn) external
    {
        Corn(corn).transfer(farmer, Corn(corn).balanceOf(this));
    }


}