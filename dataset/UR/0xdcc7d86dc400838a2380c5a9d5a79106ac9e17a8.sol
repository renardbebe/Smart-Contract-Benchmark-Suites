 

pragma solidity >=0.4.22 <0.6.0;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract SafeMath {
    
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) internal returns (uint256 z) {
        require(x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) internal returns (uint256 z) {
        require(x >= y);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) internal returns (uint256 z) {
        if (y == 0) {
            return 0;
        }
        require(x <= (MAX_UINT256 / y));
        return x * y;
    }
}

contract Owned {
    address public originalOwner;
    address public owner;

    constructor() public {
        originalOwner = msg.sender;
        owner = originalOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != owner);
        owner = newOwner;
    }
}

contract TokenERC20 is SafeMath, Owned{
     
    string public name;
     
    string public symbol;
     
    uint8 public decimals;
     
    uint256 public totalSupply;


    uint256 public unitsOneEthCanBuy;      
    uint256 public totalEthInWei;          
    address payable fundsWallet;            

     
    mapping (address => uint256) public balanceOf;
     
    mapping (address => mapping (address => uint256)) public allowance;
     
    mapping (address => bool) public frozenAccount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
     
    event Burn(address indexed from, uint256 value);
     
    event FrozenFunds(address target, bool frozen);
     
    event Mint(address indexed _to, uint256 _value);



    function() payable external{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balanceOf[fundsWallet] >= amount);

        balanceOf[fundsWallet] = balanceOf[fundsWallet] - amount;
        balanceOf[msg.sender] = balanceOf[msg.sender] + amount;

        fundsWallet.transfer(msg.value);  
        emit Transfer(fundsWallet, msg.sender, amount);  
    }

    function setUnitsOneEthCanBuy(uint256 amount)onlyOwner public returns (bool success){
        unitsOneEthCanBuy = amount;
        return true;
    }

     
    function getTotalSupply() public returns (uint256) {
        return totalSupply;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require(!frozenAccount[_from]);                                      
        require(!frozenAccount[_to]);                                        
        require (_to != address(0x0));                                       
        require (balanceOf[_from] >= _value);                                
        require (safeAdd(balanceOf[_to], _value) >= balanceOf[_to]);         
        uint previousBalances = safeAdd(balanceOf[_from], balanceOf[_to]);   
        balanceOf[_from] = safeSub(balanceOf[_from], _value);                
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);                    
        emit Transfer(_from, _to, _value);
        assert(safeAdd(balanceOf[_from], balanceOf[_to]) == previousBalances);       
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }


     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyOwner public returns (bool success){
        totalSupply = safeAdd(totalSupply, mintedAmount);
        balanceOf[target] = safeAdd(balanceOf[target], mintedAmount);
        emit Mint(target, mintedAmount);
        return true;
    }

     
    function burn(uint256 burnAmount) public returns (bool success) {
        require(balanceOf[msg.sender] >= burnAmount);                            
        totalSupply = safeSub(totalSupply, burnAmount);                          
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], burnAmount);      
        emit Burn(msg.sender, burnAmount);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                                   
        totalSupply = safeSub(totalSupply, _value);                            
        require(_value <= allowance[_from][msg.sender]);                       
        balanceOf[_from] = safeSub(balanceOf[_from], _value);                            
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);    
        emit Burn(_from, _value);
        return true;
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyOwner public returns (bool success) {
        frozenAccount[target] = freeze;                          
        emit FrozenFunds(target, freeze);
        return true;
    }
    
     
    function kill() onlyOwner public returns (bool killed){
        selfdestruct(msg.sender);
        return true;
    }
}

contract FinalToken is TokenERC20{
    uint256 tokenamount;
    
     
    constructor() public{
        name = "XY Oracle";
        symbol = "XYO";
        decimals = 18;
        tokenamount = 14198847000;

        fundsWallet = msg.sender;
        unitsOneEthCanBuy = 70000;

        totalSupply = tokenamount * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }
}