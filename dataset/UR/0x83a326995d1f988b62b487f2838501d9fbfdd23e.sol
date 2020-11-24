 

 
 

pragma solidity ^0.4.15;


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns(uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract PreSalePTARK {
    using SafeMath for uint256;
     
    address public owner;
     
    string public name  = "Tarka Pre-Sale Token";
    string public symbol = "PTARK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balances;
     
    event Transfer(address _from, address _to, uint256 amount); 
    event Burned(address _from, uint256 amount);
     
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }  

    
    function PreSalePTARK() {
        owner = msg.sender;
    }

    
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    
    function balanceOf(address _investor) public constant returns(uint256) {
        return balances[_investor];
    }

    
    function mintTokens(address _investor, uint256 _mintedAmount) external onlyOwner {
        require(_mintedAmount > 0);
        balances[_investor] = balances[_investor].add(_mintedAmount);
        totalSupply = totalSupply.add(_mintedAmount);
        Transfer(this, _investor, _mintedAmount);
        
    }

    
    function burnTokens(address _investor) external onlyOwner {   
        require(balances[_investor] > 0);
        uint256 tokens = balances[_investor];
        balances[_investor] = 0;
        totalSupply = totalSupply.sub(tokens);
        Burned(_investor, tokens);
    }
}