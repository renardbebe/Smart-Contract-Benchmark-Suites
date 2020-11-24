 

 
pragma solidity ^0.4.16;

 
 
 
 
 
 
 
 

 
    }
}


contract bitgrit is ERC223Token {

    string public name = "bitgrit";

    string public symbol = "GRIT";

    uint8 public decimals = 18;

    uint256 public totalSupply = 1000000000 * (10 ** uint256(decimals));

    address public owner;

     
     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
     
     
    function bitgrit() public {
         
        owner = msg.sender;

         
        balances[owner] = totalSupply;
    }

     
     
     
    function destory() public onlyOwner {
        selfdestruct(owner);
    }

}