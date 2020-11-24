 

pragma solidity ^0.4.24;

contract demo1 {
    
    
    mapping(address => uint256) private playerVault;
   
    modifier hasEarnings()
    {
        require(playerVault[msg.sender] > 0);
        _;
    }
    
    function myEarnings()
        external
        view
        hasEarnings
        returns(uint256)
    {
        return playerVault[msg.sender];
    }
    
    function withdraw()
        external
        hasEarnings
    {

        uint256 amount = playerVault[msg.sender];
        playerVault[msg.sender] = 0;

        msg.sender.transfer(amount);
    }
    
   

     function deposit() public payable returns (uint) {
         
         
        require((playerVault[msg.sender] + msg.value) >= playerVault[msg.sender]);

        playerVault[msg.sender] += msg.value;
         
         

        return playerVault[msg.sender];
    }
    
}