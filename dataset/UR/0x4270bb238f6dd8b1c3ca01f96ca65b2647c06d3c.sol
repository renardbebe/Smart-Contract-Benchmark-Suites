 

pragma solidity ^0.4.18;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint256 _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool ok){
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) 
        public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal  pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

contract LockedToken is owned, TokenERC20, SafeMath {

    struct TokenLocked {
        uint256 amount;
        uint256 startDate;
        uint256 lastDate;  
        uint256 batches;
    }

    mapping (address => TokenLocked) internal lockedTokenOf;
    mapping (address => bool) internal isLocked;

    modifier canTransfer(address _sender, uint256 _value) {
        require(_value <= spendableBalanceOf(_sender));
        _;
    }   

    function LockedToken (
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    )TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    function transfer(address _to, uint256 _value)
            canTransfer(msg.sender, _value)
            public
            returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
            canTransfer(_from, _value)
            public
            returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    function transferAndLock(
            address _to, 
            uint256 _value,
            uint256 _startDate,
            uint256 _lastDate,
            uint256 _batches) 
            onlyOwner public {
         
        require(_to != 0x0);
        require(_startDate < _lastDate);
        require(_batches > 0);
        TokenLocked memory tokenLocked = TokenLocked(_value, _startDate, _lastDate, _batches);
        lockedTokenOf[_to] = tokenLocked;
        isLocked[_to] = true;

         
        super.transfer(_to, _value);
    }

    function spendableBalanceOf(address _holder) constant public returns (uint) {
        return transferableTokens(_holder, uint64(now));
    }

    function transferableTokens(address holder, uint256 time) constant public returns (uint256) {
        
        TokenLocked storage tokenLocked = lockedTokenOf[holder];

        if (!isLocked[holder]) return balanceOf[holder];

        uint256 amount = tokenLocked.amount;
        uint256 startDate = tokenLocked.startDate;
        uint256 lastDate = tokenLocked.lastDate;
        uint256 batches = tokenLocked.batches;

        if (time < startDate) return 0;
        if (time >= lastDate) return balanceOf[holder]; 

         
        uint256 originalTransferableTokens = safeMul(safeDiv(amount, batches), 
                                        safeDiv(
                                        safeMul(safeSub(time, startDate), batches),
                                        safeSub(lastDate, startDate)
                                        ));

        uint256 lockedAmount = safeSub(amount, originalTransferableTokens);

        if (balanceOf[holder] <= lockedAmount) return 0;

        uint256 actualTransferableTokens = safeSub(balanceOf[holder], lockedAmount);                             

        return  actualTransferableTokens;
    }

    function  lastTokenIsTransferableDate(address holder) constant public returns(uint256 date) {
        date = uint256(now);
        if (!isLocked[holder]) return date;
        
        TokenLocked storage tokenLocked = lockedTokenOf[holder];       
        return tokenLocked.lastDate;
    }

    function ()  payable public {
        revert();
    }
}