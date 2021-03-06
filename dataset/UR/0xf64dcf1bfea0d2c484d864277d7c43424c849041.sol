 

 

pragma solidity ^0.4.15;

 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Dist{

     
    address public owner;
    address public tokenAddress;  
    uint public unlockTime;

     
    ERC20Basic token;

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
     
     
     
    
    function Dist(address _owner, uint _unlockTime, address _tokenAddress){
        owner = _owner;
        tokenAddress = _tokenAddress;
        token = ERC20Basic(_tokenAddress);
        unlockTime = _unlockTime;
    }

    function balance() constant returns(uint _balance){
    
        return token.balanceOf(this);
    }

    function isLocked() constant returns (bool) {

        return (now < unlockTime);       
    }

    function withdraw() onlyOwner {

        if(!isLocked()){        
            token.transfer(owner, balance());
        }
    }

}