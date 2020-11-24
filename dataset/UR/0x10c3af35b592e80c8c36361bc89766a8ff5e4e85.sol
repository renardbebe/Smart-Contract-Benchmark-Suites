 
    function burnFrom(address _from, uint256 _value) onlyOwner public returns (bool success) {
        require(balances[_from] >= _value);                 
        balances[_from] = balances[_from].sub(_value);                          
        totalSupply_ = totalSupply_.sub(_value);                               
        emit Burn(_from, _value);
        return true;
    }

     
    function mintToken(address _to, uint256 _mintedAmount) onlyOwner public {
        balances[_to] = balances[_to].add(_mintedAmount);
        totalSupply_ = totalSupply_.add(_mintedAmount);
        emit Transfer(address(0), owner, _mintedAmount);
        emit Transfer(owner, _to, _mintedAmount);
    }

     
    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }
}


