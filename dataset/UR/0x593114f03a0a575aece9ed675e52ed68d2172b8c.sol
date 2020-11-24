 
    constructor(
        address _beneficiary,
        uint256 _cap
    ) public {
        require(_cap > 0, "MissingCap");

        totalSupply_ = totalSupply_.add(_cap);
        balances[_beneficiary] = balances[_beneficiary].add(_cap);

        emit Mint(_beneficiary, _cap);
        emit Transfer(address(0), _beneficiary, _cap);
    }

     
    function burn(uint256 _value) public {
        uint256 allowance = burnAllowance(msg.sender);

        require(_value > 0, "MissingValue");
        require(allowance >= _value, "NotEnoughAllowance");

        _setBurnAllowance(msg.sender, allowance.sub(_value));

        _burn(msg.sender, _value);
    }

     
    function burnAllowance(address _who)
        public
        view
        returns (uint256)
    {
        return _burnAllowance[_who];
    }

     

     
    function setBurnAllowance(
        address _who,
        uint256 _amount
    )
        public
        onlyIfWhitelisted(msg.sender)
    {
        require(_amount <= balances[_who]);
        _setBurnAllowance(_who, _amount);
    }

     

     
    function _setBurnAllowance(
        address _who,
        uint256 _amount
    ) internal {
        _burnAllowance[_who] = _amount;
    }
}
