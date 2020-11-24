 
    function mint(address to, uint256 value)
        public
        requirePermission(CAN_MINT_COINS)
        requireNotFinalized
        returns (bool)
    {
        _mint(to, value);
        return true;
    }

     
    function pause() public requirePermission(CAN_PAUSE_COINS) whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public requirePermission(CAN_PAUSE_COINS) whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function transfer(address to, uint256 value)
        public
        whenNotPaused
        returns (bool)
    {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value)
        public
        whenNotPaused
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value)
        public
        whenNotPaused
        returns (bool)
    {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue)
        public
        whenNotPaused
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue)
        public
        whenNotPaused
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function _burn(address account, uint256 value)
        internal
        requireNotFinalized
    {
        super._burn(account, value);
    }

     
    function _burnFrom(address account, uint256 value)
        internal
        requireNotFinalized
    {
        emit Burn(msg.sender, value);
        if (
            false == hasPermission(msg.sender, CAN_BURN_COINS)
        ) {
            super._burnFrom(account, value);
        } else {
            _burn(account, value);
        }
    }

}

