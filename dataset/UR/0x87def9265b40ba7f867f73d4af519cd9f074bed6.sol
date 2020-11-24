 
contract OBSR is  ERC1132, ERC20, ERC20Detailed {
    uint8 public constant DECIMALS = 8;
    uint256 public constant INITIAL_SUPPLY = 1500000000000000000;

 


    string internal constant ALREADY_LOCKED = 'Tokens already locked';
    string internal constant NOT_LOCKED = 'No tokens locked';
    string internal constant AMOUNT_ZERO = 'Amount can not be 0';

    address[] lockedAddrs;
    bytes32[] reasons;
    
   

     

    constructor () public ERC20Detailed("OBSR", "OBSR", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

function getListLockedAddrs()public view returns( address  [] memory)
{
     return lockedAddrs;
}
 

function getListResons()public view returns(bytes32 [] memory)
{
     return reasons;
}


 





function getAddrByReason(bytes32 my_reason) public view returns(address)
{
    for (uint256 j = 0; j < lockedAddrs.length; j++)
        {
             uint256 amountLocked =   tokensLockedAtTime(lockedAddrs[j],my_reason,now);
             
             if(amountLocked!=0)
             {
                return   lockedAddrs[j];     
             }
        }
}

function tokensValidityLockedAtTime(address _of, bytes32 _reason, uint256 _time)
        public
        view
        returns (uint256 validity)
    {
        if (locked[_of][_reason].validity > _time)
            validity = locked[_of][_reason].validity;
    }




 
     
 
     
    function lock(bytes32 _reason, uint256 _amount, uint256 _time)
        public
        returns (bool)
    {
        uint256 validUntil = now.add(_time);  

         
         
        require(tokensLocked(msg.sender, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[msg.sender][_reason].amount == 0)
            lockReason[msg.sender].push(_reason);

        transfer(address(this), _amount);

        locked[msg.sender][_reason] = lockToken(_amount, validUntil, false);
        
        lockedAddrs.push(msg.sender);
        
        
        
        reasons.push(_reason);
        
        emit Locked(msg.sender, _reason, _amount, validUntil);
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

        lockedAddrs.push(_to);
        reasons.push(_reason);

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
    
     
    function extendLock(bytes32 _reason, uint256 _time)
        public
        returns (bool)
    {
        require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);

        locked[msg.sender][_reason].validity = locked[msg.sender][_reason].validity.add(_time);

        emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        return true;
    }
    
     
    function increaseLockAmount(bytes32 _reason, uint256 _amount)
        public
        returns (bool)
    {
        require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);
        transfer(address(this), _amount);

        locked[msg.sender][_reason].amount = locked[msg.sender][_reason].amount.add(_amount);

        emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
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
		 for (uint256 k = 0; k < reasons.length; k++) {
                if(lockReason[_of][i]==reasons[k])
                 delete reasons[k];
               }    
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



 


 





