 

 

 
 
 
 

 
 

 
 

 
 
 
 
 
 


contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}

contract TokenDrop {
    ERC20 token;

    function TokenDrop() {
        token = ERC20(0xec662B61C129fcF9fc6DD6F1A672021A539CE45d);
    }

    function multiTransfer(uint256 _value, address[] _to) public returns(bool) {
        for(uint i = 0; i < _to.length; i++) {
            token.transfer(_to[i], _value);
        }

        return true;
    }
    
    function tokenFallback(address _from, uint256 _value, bytes _data) external {  }

    function balanceOf(address who) public view returns(uint256) {
        return token.balanceOf(who);
    }
}