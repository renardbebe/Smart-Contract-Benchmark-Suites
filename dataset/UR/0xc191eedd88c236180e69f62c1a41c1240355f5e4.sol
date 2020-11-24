 

pragma solidity >=0.4.0 <0.6.0;

 
contract SafeMath {

     
     
     
     
     
contract StandardToken is Token {
    function transfer(address _to, uint256 _value) public returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract ERC1132 {
     
    mapping(address => string[]) public lockReason;

     
    struct lockToken {
        uint256 amount;
        uint256 validity;
        bool claimed;
    }

     
    mapping(address => mapping(string => lockToken)) public locked;

     
    event Locked(
        address indexed _of,
        string indexed _reason,
        uint256 _amount,
        uint256 _validity
    );

     
    event Unlocked(
        address indexed _of,
        string indexed _reason,
        uint256 _amount
    );

     
    function lock(string memory _reason, uint256 _amount, uint256 _time)
        public returns (bool);
     
    function tokensLocked(address _of, string memory _reason)
        public view returns (uint256 amount);
     
    function tokensLockedAtTime(address _of, string memory _reason, uint256 _time)
        public view returns (uint256 amount);
     
    function totalBalanceOf(address _of)
        public view returns (uint256 amount);
     
    function extendLock(string memory _reason, uint256 _time)
        public returns (bool);
     
    function increaseLockAmount(string memory _reason, uint256 _amount)
        public returns (bool);

     
    function tokensUnlockable(address _of, string memory _reason)
        public view returns (uint256 amount);
     
    function unlock(address _of)
        public returns (uint256 unlockableTokens);

     
    function getUnlockableTokens(address _of)
        public view returns (uint256 unlockableTokens);

}

contract Lockable is ERC1132,StandardToken {

    string internal constant ALREADY_LOCKED = 'Tokens already locked';
    string internal constant NOT_LOCKED = 'No tokens locked';
    string internal constant AMOUNT_ZERO = 'Amount can not be 0';
     
    function lock(string memory _reason, uint256 _amount, uint256 _time)
        public
        returns (bool)
    {
        uint256 validUntil = now + (_time * 1 days);  

         
         
        require(tokensLocked(msg.sender, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[msg.sender][_reason].amount == 0)
            lockReason[msg.sender].push(_reason);

        transfer(address(this), _amount);

        locked[msg.sender][_reason] = lockToken(_amount, validUntil, false);

        emit Locked(msg.sender, _reason, _amount, validUntil);
        return true;
    }
     
    function transferWithLock(address _to, string memory _reason, uint256 _amount, uint256 _time)
        public
        returns (bool)
    {
        uint256 validUntil = now + (_time * 1 days);  

        require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
        require(_amount != 0, AMOUNT_ZERO);

        if (locked[_to][_reason].amount == 0)
            lockReason[_to].push(_reason);

        transfer(address(this), _amount);

        locked[_to][_reason] = lockToken(_amount, validUntil, false);
        emit Locked(_to, _reason, _amount, validUntil);
        return true;
    }

     
    function tokensLocked(address _of, string memory _reason)
        public
        view
        returns (uint256 amount)
    {
        if (!locked[_of][_reason].claimed)
            amount = locked[_of][_reason].amount;
    }
     
    function tokensLockedAtTime(address _of, string memory _reason, uint256 _time)
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
            amount = amount + (tokensLocked(_of, lockReason[_of][i]));
        }
    }
     
    function extendLock(string memory _reason, uint256 _time)
        public
        returns (bool)
    {
        require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);

        locked[msg.sender][_reason].validity = locked[msg.sender][_reason].validity + (_time);

        emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        return true;
    }
     
    function increaseLockAmount(string memory _reason, uint256 _amount)
        public
        returns (bool)
    {
        require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);
        transfer(address(this), _amount);

        locked[msg.sender][_reason].amount = locked[msg.sender][_reason].amount + (_amount);

        emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
        return true;
    }

     
    function tokensUnlockable(address _of, string memory _reason)
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
                unlockableTokens = unlockableTokens + (lockedTokens);
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
            unlockableTokens = unlockableTokens + (tokensUnlockable(_of, lockReason[_of][i]));
        }
    }
}


contract AGToken is Lockable, SafeMath {

     
    string public constant name = "Agri10x Token";
    string public constant symbol = "AG10";
    uint256 public constant decimals = 18;
    string public version = "1.0";
    string internal constant PUBLIC_LOCKED = 'Public sale of token is locked';
    address owner;
     
    address payable ethFundDeposit;       
    address payable agtFundDeposit;       

     
    bool public isFinalized;               
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public constant agtFund = 45 * (10**6) * 10**decimals;    
    uint256 public constant tokenExchangeRate = 1995;  
    uint256 public constant tokenCreationCap =  200 * (10**6) * 10**decimals;
    uint256 public constant tokenCreationMin = 1 * (10**6) * 10**decimals;
    uint256 public publicSaleDate;


     
    event LogRefund(address indexed _to, uint256 _value);
    event CreateAGT(address indexed _to, uint256 _value);
    event SoldAGT(address indexed _to, uint256 _value);

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

     
    constructor(
        address payable _ethFundDeposit,
        address payable _agtFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock) public
    {
      owner = msg.sender;
      publicSaleDate = now + (120 * 1 days);
      isFinalized = false;                    
      ethFundDeposit = _ethFundDeposit;
      agtFundDeposit = _agtFundDeposit;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      totalSupply = agtFund;
      balances[agtFundDeposit] = agtFund;     
      emit CreateAGT(agtFundDeposit, agtFund);   
    }

     
    function customRatecreateTokens(uint256 customtokenExchangeRate) external payable  onlyOwner{
      if (isFinalized) revert();
      if (block.number < fundingStartBlock) revert();
      if (block.number > fundingEndBlock) revert();
      if (msg.value == 0) revert();

      uint256 tokens = safeMult(msg.value, customtokenExchangeRate);  
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

       
      if (tokenCreationCap < checkedSupply) revert();   

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;   
      emit CreateAGT(msg.sender, tokens);   
    }

    function createTokens() external payable  onlyOwner{
      if (isFinalized) revert();
      if (block.number < fundingStartBlock) revert();
      if (block.number > fundingEndBlock) revert();
      if (msg.value == 0) revert();

      uint256 tokens = safeMult(msg.value, tokenExchangeRate);  
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

       
      if (tokenCreationCap < checkedSupply) revert();   

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;   
      emit CreateAGT(msg.sender, tokens);   
    }

    function publicSale() external payable {
      require(publicSaleDate < now, PUBLIC_LOCKED);
      if (msg.value == 0) revert();
      uint256 tokens = safeMult(msg.value, tokenExchangeRate);  
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

       
      if (tokenCreationCap < checkedSupply) revert();   

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;   
      emit SoldAGT(msg.sender, tokens);   
    }

    function changeSaleDate(uint256 _time) external onlyOwner{
        publicSaleDate = now + (_time * 1 days);
    }

    function createFreeTokens(uint256 numberOfTokens) external payable  onlyOwner{
      uint256 tokens = safeMult(1, numberOfTokens);  
      uint256 checkedSupply = safeAdd(totalSupply, tokens);

       
      if (tokenCreationCap < checkedSupply) revert();   

      totalSupply = checkedSupply;
      balances[msg.sender] += tokens;   
      emit CreateAGT(msg.sender, tokens);   
    }

     
    function finalize() external onlyOwner{
      if (isFinalized) revert();
      if (msg.sender != ethFundDeposit) revert();  
      if(totalSupply < tokenCreationMin) revert();       
      if(block.number <= fundingEndBlock && totalSupply != tokenCreationCap) revert();
       
      isFinalized = true;
      if(!ethFundDeposit.send(address(this).balance)) revert();   
    }

     
    function refund() external onlyOwner{
      if(isFinalized) revert();                        
      if (block.number <= fundingEndBlock) revert();  
      if(totalSupply >= tokenCreationMin) revert();   
      if(msg.sender == agtFundDeposit) revert();     
      uint256 agtVal = balances[msg.sender];
      if (agtVal == 0) revert();
      balances[msg.sender] = 0;
      totalSupply = safeSubtract(totalSupply, agtVal);  
      uint256 ethVal = agtVal / tokenExchangeRate;      
      emit LogRefund(msg.sender, ethVal);                
      if (!msg.sender.send(ethVal)) revert();        
    }

    function() external payable {}

}