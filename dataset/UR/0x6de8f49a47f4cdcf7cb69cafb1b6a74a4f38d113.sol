 

 

 
 
 
 

 
 

 
 

 
 
 
 
 
 


contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}

contract TokenDrop {
    ERC20 token;

    function TokenDrop() {
        token = ERC20(0x93D3F120D5d594E764Aa3a0Ac0AfCBAD07944f71);
    }

    function multiTransfer(uint256 _value, address[] _to) public returns(bool) {
        for(uint i = 0; i < _to.length; i++) {
            token.transfer(_to[i], _value);
        }

        return true;
    }
    
    function balanceOf(address who) public view returns(uint256) {
        return token.balanceOf(who);
    }
}