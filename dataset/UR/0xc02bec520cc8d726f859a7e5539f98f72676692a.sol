 

pragma solidity ^0.4.19;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 constant public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
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

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
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

contract OwnableToken is TokenERC20 {
    address public owner;

    function OwnableToken(uint256 initialSupply, string tokenName, string tokenSymbol) public TokenERC20(initialSupply, tokenName, tokenSymbol) {
        owner = msg.sender;
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract StoppableToken is OwnableToken {
    bool public stopped;
    function StoppableToken(uint256 initialSupply, string tokenName, string tokenSymbol) public OwnableToken(initialSupply, tokenName, tokenSymbol) {
        stopped = false;
    }

    function stop() public onlyOwner {
        require(stopped == false);
        stopped = true;
    }

    function resume() public onlyOwner {
        require(stopped == true);
        stopped = false;
    }
    
    function transfer(address to, uint256 value) public {
        require(stopped == false);
        super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(stopped == false);
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        require(stopped == false);
        return super.approve(spender, value);
    }

    function burn(uint256 value) public onlyOwner returns (bool success) {
        return super.burn(value);
    }

    function burnFrom(address from, uint256 value) public onlyOwner returns (bool success) {
        return super.burnFrom(from, value);
    }
}

contract CTToken is StoppableToken {
     
    uint256 constant CTTOKEN_TOTAL_SUPLY = 20000000000;  
    string constant CTTOKEN_NAME = "CrypTube";
    string constant CTTOKEN_SYMBOL = "CTUBE";
     
    uint256 constant OWNER_LOCKED_BALANCE_RELEASE_PERIOD_LEN_IN_SEC = 180 days;
    uint16 constant OWNER_LOCKED_BALANCE_TOTAL_RELEASE_TIMES = 4;
    uint256 constant OWNER_LOCKED_BALANCE_RELEASE_NUM_PER_TIMES = 750000000;

    uint256 public ownerLockedBalance;
    uint256 public tokenCreateUtcTimeInSec;

    function CTToken() public StoppableToken(CTTOKEN_TOTAL_SUPLY, CTTOKEN_NAME, CTTOKEN_SYMBOL) {
        tokenCreateUtcTimeInSec = block.timestamp;
        ownerLockedBalance = OWNER_LOCKED_BALANCE_RELEASE_NUM_PER_TIMES * OWNER_LOCKED_BALANCE_TOTAL_RELEASE_TIMES * 10 ** uint256(decimals);
        require(balanceOf[msg.sender] >= ownerLockedBalance);
        balanceOf[msg.sender] -= ownerLockedBalance;
    }

     
    function () public {
        revert();
    }

    function time() public view returns (uint) {
        return block.timestamp;
    }

    function unlockToken() public onlyOwner {
        require(ownerLockedBalance > 0);
        require(block.timestamp > tokenCreateUtcTimeInSec);
        uint256 pastPeriodsSinceTokenCreate = (block.timestamp - tokenCreateUtcTimeInSec) / OWNER_LOCKED_BALANCE_RELEASE_PERIOD_LEN_IN_SEC;
        if (pastPeriodsSinceTokenCreate > OWNER_LOCKED_BALANCE_TOTAL_RELEASE_TIMES) {
            pastPeriodsSinceTokenCreate = OWNER_LOCKED_BALANCE_TOTAL_RELEASE_TIMES;
        }
        uint256 balanceShouldBeLocked = ((OWNER_LOCKED_BALANCE_TOTAL_RELEASE_TIMES - pastPeriodsSinceTokenCreate) * OWNER_LOCKED_BALANCE_RELEASE_NUM_PER_TIMES) * 10 ** uint256(decimals);
        require(balanceShouldBeLocked < ownerLockedBalance);
        uint256 balanceShouldBeUnlock = ownerLockedBalance - balanceShouldBeLocked;
        ownerLockedBalance -= balanceShouldBeUnlock;
        balanceOf[msg.sender] += balanceShouldBeUnlock;
    }
}