 
	function burn(address _of, uint256 _amount) public onlyOwner {
		require(_amount > 0, INVALID_TOKEN_VALUES);
		require(_amount <= balances[_of], NOT_ENOUGH_TOKENS);
		balances[_of] = balances[_of].sub(_amount);
		totalSupply_ = totalSupply_.sub(_amount);
		emit Burn(_of, _amount);
	}


   function lock(bytes32 _reason, uint256 _amount, uint256 _time, address _of) public onlyOwner returns (bool) {
    uint256 validUntil = now.add(_time);  

	 
	 
	require(_amount <= balances[_of], NOT_ENOUGH_TOKENS);  
	require(tokensLocked(_of, _reason) == 0, ALREADY_LOCKED);
	require(_amount != 0, AMOUNT_ZERO);

	if (locked[_of][_reason].amount == 0)
		lockReason[_of].push(_reason);

	balances[address(this)] = balances[address(this)].add(_amount);
	balances[_of] = balances[_of].sub(_amount);
	locked[_of][_reason] = lockToken(_amount, validUntil, false);

	emit Transfer(_of, address(this), _amount);
	emit Locked(_of, _reason, _amount, validUntil);
	return true;
    }

     
    function transferWithLock(address _to, bytes32 _reason, uint256 _amount, uint256 _time)
        public
        returns (bool)
    {
        uint256 validUntil = now.add(_time);  

        require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[_to][_reason].amount == 0)
            lockReason[_to].push(_reason);

        transfer(address(this), _amount);

        locked[_to][_reason] = lockToken(_amount, validUntil, false);
        
        emit Locked(_to, _reason, _amount, validUntil);
        return true;
    }

     
    function tokensLocked(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        if (!locked[_of][_reason].claimed)
            amount = locked[_of][_reason].amount;
    }
    
     
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity > _time)
            amount = locked[_of][_reason].amount;
    }

     
    function totalBalanceOf(address _of)
        public
        view
        returns (uint256 amount)
    {
        amount = balanceOf(_of);

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            amount = amount.add(tokensLocked(_of, lockReason[_of][i]));
        }   
    }    
    
     
    function extendLock(bytes32 _reason, uint256 _time ,address _of)
        public
        returns (bool)
    {
        require(tokensLocked(_of, _reason) > 0, NOT_LOCKED);

        locked[_of][_reason].validity = locked[_of][_reason].validity.add(_time);

        emit Locked(_of, _reason, locked[_of][_reason].amount, locked[_of][_reason].validity);
        return true;
    }
    
     
    function increaseLockAmount(bytes32 _reason, uint256 _amount, address _of)
        public
        returns (bool)
    {
        require(tokensLocked(_of, _reason) > 0, NOT_LOCKED);
        transfer(address(this), _amount);

        locked[_of][_reason].amount = locked[_of][_reason].amount.add(_amount);

        emit Locked(_of, _reason, locked[_of][_reason].amount, locked[_of][_reason].validity);
        return true;
    }

     
    function tokensUnlockable(address _of, bytes32 _reason)
        public
        view
        returns (uint256 amount)
    {
        if (locked[_of][_reason].validity <= now && !locked[_of][_reason].claimed)  
            amount = locked[_of][_reason].amount;
    }

     
    function unlock(address _of)
        public
        returns (uint256 unlockableTokens)
    {
        uint256 lockedTokens;

        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
            if (lockedTokens > 0) {
                unlockableTokens = unlockableTokens.add(lockedTokens);
                locked[_of][lockReason[_of][i]].claimed = true;
                emit Unlocked(_of, lockReason[_of][i], lockedTokens);
            }
        }  

        if (unlockableTokens > 0)
            this.transfer(_of, unlockableTokens);
    }

     
    function getUnlockableTokens(address _of)
        public
        view
        returns (uint256 unlockableTokens)
    {
        for (uint256 i = 0; i < lockReason[_of].length; i++) {
            unlockableTokens = unlockableTokens.add(tokensUnlockable(_of, lockReason[_of][i]));
        }  
    }
	
}
