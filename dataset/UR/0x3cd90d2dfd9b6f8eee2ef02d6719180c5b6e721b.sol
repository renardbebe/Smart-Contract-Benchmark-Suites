 

pragma solidity ^0.4.20;

 
 

contract UploadIMG{
    
     
    mapping(address => mapping(uint256 => string)) public Data;
    
    function UploadIMG() public {
 
    }
     
    function UploadURL(uint256 ID, string URL) public {
        Data[msg.sender][ID] = URL;
    }

    function GetURL(address ADDR, uint256 ID) public returns (string) {
        return Data[ADDR][ID];
    }
    
     
    function() payable public{
        if (msg.value > 0){
            msg.sender.transfer(msg.value);
        }
    }
}